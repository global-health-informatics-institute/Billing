#!/usr/bin/env python3
"""
Data Analysis Report Generator
Generates reports from live database
"""

import configparser
import mysql.connector
from datetime import datetime, date
from dateutil.relativedelta import relativedelta
import io
import json
import urllib.request
import matplotlib
matplotlib.use('Agg')  # non-interactive backend, safe for server use
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import os
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
import sys
import platform
import subprocess
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders

# Import PDF conversion library (only works on Windows)
try:
    from docx2pdf import convert as docx2pdf_convert
    DOCX2PDF_AVAILABLE = True
except ImportError:
    DOCX2PDF_AVAILABLE = False


class ReportGenerator:
    def __init__(self, config_file='config.ini', auto_dates=False):
        """Initialize the report generator with configuration"""
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        self.connection = None

        if auto_dates:
            # Automatically use the previous calendar month
            today = date.today()
            first_of_this_month = today.replace(day=1)
            last_month_end = first_of_this_month - relativedelta(days=1)
            last_month_start = last_month_end.replace(day=1)
            self.start_date = str(last_month_start)
            self.end_date   = str(last_month_end)
            print(f"Auto date mode: reporting period set to {self.start_date} to {self.end_date}")
        else:
            self.start_date = self.config.get('report', 'start_date')
            self.end_date   = self.config.get('report', 'end_date')
        
    def connect_database(self):
        """Establish database connection"""
        try:
            self.connection = mysql.connector.connect(
                host=self.config.get('database', 'host'),
                port=self.config.getint('database', 'port'),
                database=self.config.get('database', 'database'),
                user=self.config.get('database', 'username'),
                password=self.config.get('database', 'password')
            )
            print("Database connection established")
            return True
        except mysql.connector.Error as err:
            print(f"Database connection failed: {err}")
            return False
    
    def get_previous_period(self):
        """Derive the previous month's date range from the configured period."""
        start = datetime.strptime(self.start_date, '%Y-%m-%d').date()
        end   = datetime.strptime(self.end_date,   '%Y-%m-%d').date()
        prev_start = start - relativedelta(months=1)
        prev_end   = end   - relativedelta(months=1)
        return str(prev_start), str(prev_end)

    def get_comparison_data(self, prev_start, prev_end):
        """Fetch the same key metrics for the previous period."""
        def _query(sql, params):
            result = self.execute_query(sql, params)
            return result

        # Registrations
        reg = _query(
            "SELECT COUNT(patient_id) AS v FROM patient WHERE date_created BETWEEN %s AND %s",
            (prev_start, prev_end)
        )
        prev_registered = reg[0]['v'] if reg else 0

        # Returning patients
        ret = _query("""
            SELECT COUNT(*) AS v FROM (
                SELECT patient_id FROM receipts
                WHERE payment_stamp BETWEEN %s AND %s
                GROUP BY patient_id HAVING COUNT(*) > 1
            ) AS t
        """, (prev_start, prev_end))
        prev_returning = ret[0]['v'] if ret else 0

        # Revenue
        rev = _query("""
            SELECT COALESCE(SUM(full_price), 0) AS v FROM order_entries
            WHERE cashier IN ('8','9') AND created_at BETWEEN %s AND %s
        """, (prev_start, prev_end))
        prev_revenue = float(rev[0]['v']) if rev else 0.0

        # Paying / non-paying
        pay = _query("""
            SELECT
                COUNT(*) AS total_patients,
                SUM(CASE WHEN paying_orders > 0 AND non_paying_orders = 0 THEN 1 ELSE 0 END) AS exclusively_paying,
                SUM(CASE WHEN non_paying_orders > 0 AND paying_orders = 0 THEN 1 ELSE 0 END) AS exclusively_non_paying
            FROM (
                SELECT patient_id,
                    SUM(CASE WHEN full_price >= 1000 THEN 1 ELSE 0 END) AS paying_orders,
                    SUM(CASE WHEN full_price = 0    THEN 1 ELSE 0 END) AS non_paying_orders
                FROM order_entries
                WHERE order_date BETWEEN %s AND %s
                GROUP BY patient_id
            ) AS t
        """, (prev_start, prev_end))
        prev_paying    = pay[0]['exclusively_paying']     if pay else 0
        prev_non_paying = pay[0]['exclusively_non_paying'] if pay else 0
        prev_total     = pay[0]['total_patients']          if pay else 0

        # Duplicates
        dup = _query("""
            SELECT COUNT(*) AS duplicate_count
            FROM patient p
            JOIN person per ON p.patient_id = per.person_id
            JOIN person_name pn ON per.person_id = pn.person_id
            WHERE pn.voided = 0 AND per.voided = 0 AND pn.preferred = 1
            GROUP BY pn.given_name, pn.family_name, per.gender, per.birthdate
            HAVING COUNT(*) > 1
        """, None)
        prev_dup_groups  = len(dup) if dup else 0
        prev_dup_records = sum(r['duplicate_count'] - 1 for r in dup) if dup else 0

        return {
            'period':       f'{prev_start} to {prev_end}',
            'registered':   prev_registered,
            'returning':    prev_returning,
            'revenue':      prev_revenue,
            'paying':       prev_paying,
            'non_paying':   prev_non_paying,
            'total_patients': prev_total,
            'dup_groups':   prev_dup_groups,
            'dup_records':  prev_dup_records,
        }

    def execute_query(self, query, params=None):
        """Execute a query and return results"""
        try:
            cursor = self.connection.cursor(dictionary=True)
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            results = cursor.fetchall()
            cursor.close()
            return results
        except mysql.connector.Error as err:
            print(f"Query execution failed: {err}")
            return None
    
    def get_total_registered_patients(self):
        """Query 1: Total registered patients"""
        query = """
        SELECT COUNT(patient_id) as total_patients 
        FROM patient 
        WHERE date_created BETWEEN %s AND %s
        """
        result = self.execute_query(query, (self.start_date, self.end_date))
        return result[0]['total_patients'] if result else 0

    def get_total_registered_patients_system(self):
        """Query 1b: Total registered patients in the system, regardless of report period."""
        query = """
        SELECT COUNT(patient_id) AS total_patients
        FROM patient
        """
        result = self.execute_query(query)
        return result[0]['total_patients'] if result else 0
    
    def get_total_visits(self):
        """Total patient visits (receipts) in the reporting period."""
        query = """
        SELECT COUNT(*) AS total_visits
        FROM receipts
        WHERE payment_stamp BETWEEN %s AND %s
        """
        result = self.execute_query(query, (self.start_date, self.end_date))
        return result[0]['total_visits'] if result else 0

    def get_returning_patients_count(self):
        """Query 2: Count of returning patients"""
        query = """
        SELECT COUNT(*) as returning_patients FROM (
            SELECT patient_id FROM receipts 
            WHERE payment_stamp BETWEEN %s AND %s
            GROUP BY patient_id 
            HAVING COUNT(*) > 1
        ) as subquery
        """
        result = self.execute_query(query, (self.start_date, self.end_date))
        return result[0]['returning_patients'] if result else 0

    def get_returning_patients_distribution(self):
        """Query 3: Distribution of returning patients by age and gender"""
        query = """
        SELECT 
            CASE 
                WHEN TIMESTAMPDIFF(YEAR, per.birthdate, CURDATE()) < 5 THEN 'Under 5'
                WHEN TIMESTAMPDIFF(YEAR, per.birthdate, CURDATE()) BETWEEN 5 AND 13 THEN '5-13'
                ELSE 'Adults'
            END AS age_category,
            per.gender AS gender,
            COUNT(DISTINCT r.patient_id) AS returning_patient_count
        FROM receipts r
        JOIN patient p ON r.patient_id = p.patient_id
        JOIN person per ON p.patient_id = per.person_id
        WHERE r.payment_stamp BETWEEN %s AND %s
        AND r.patient_id IN (
            SELECT patient_id 
            FROM receipts
            WHERE payment_stamp BETWEEN %s AND %s
            GROUP BY patient_id
            HAVING COUNT(*) > 1
        )
        GROUP BY age_category, per.gender
        ORDER BY age_category, per.gender
        """
        return self.execute_query(query, (self.start_date, self.end_date, self.start_date, self.end_date))
    
    def get_registered_patients_adolescence(self):
        """Query 4: Distribution of registered patients by adolescence age groups"""
        query = """
        SELECT 
            CASE 
                WHEN TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) < 5 THEN 'Under 5'
                WHEN TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) BETWEEN 5 AND 9 THEN '5-9'
                WHEN TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) BETWEEN 10 AND 14 THEN '10-14'
                WHEN TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) BETWEEN 15 AND 19 THEN '15-19'
                WHEN TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) BETWEEN 20 AND 24 THEN '20-24'
                ELSE '25+'
            END AS age_group,
            p.gender,
            COUNT(p.person_id) AS total_patients
        FROM patient pat
        JOIN person p ON pat.patient_id = p.person_id
        WHERE pat.date_created BETWEEN %s AND %s
        GROUP BY age_group, p.gender
        ORDER BY age_group, p.gender
        """
        return self.execute_query(query, (self.start_date, self.end_date))
    
    def get_returning_frequency(self):
        """Query 5: Frequency of patient visits"""
        query = """
        SELECT 
            visit_count AS number_of_visits,
            COUNT(patient_id) AS number_of_patients
        FROM (
            SELECT 
                patient_id, 
                COUNT(*) AS visit_count
            FROM receipts
            WHERE payment_stamp BETWEEN %s AND %s
            GROUP BY patient_id
        ) AS patient_visits
        GROUP BY visit_count
        ORDER BY visit_count
        """
        return self.execute_query(query, (self.start_date, self.end_date))

    def get_duplicate_group_counts(self):
        """Return duplicate patient group sizes based on preferred names and demographics."""
        query = """
        SELECT COUNT(*) AS duplicate_count
        FROM patient p
        JOIN person per ON p.patient_id = per.person_id
        JOIN person_name pn ON per.person_id = pn.person_id
        WHERE pn.voided = 0
          AND per.voided = 0
          AND pn.preferred = 1
        GROUP BY
            pn.given_name,
            pn.family_name,
            per.gender,
            per.birthdate
        HAVING COUNT(*) > 1
        """
        return self.execute_query(query)
    
    def get_gender_distribution_registered(self):
        """Query 6: Gender distribution of registered patients by age group"""
        query = """
        SELECT 
            CASE 
                WHEN TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) < 5 THEN 'Under 5'
                WHEN TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) BETWEEN 5 AND 13 THEN '5-13'
                ELSE 'Adults'
            END AS age_group,
            p.gender,
            COUNT(*) AS total_patients
        FROM patient pat
        JOIN person p ON pat.patient_id = p.person_id
        WHERE p.voided = 0
          AND pat.date_created BETWEEN %s AND %s
        GROUP BY age_group, p.gender
        ORDER BY age_group, p.gender
        """
        return self.execute_query(query, (self.start_date, self.end_date))

    def get_gender_distribution_returning(self):
        """Query 7: Gender distribution of returning patients by age group"""
        query = """
        SELECT 
            CASE 
                WHEN TIMESTAMPDIFF(YEAR, person.birthdate, CURDATE()) < 13 THEN 'Under 13'
                ELSE 'Adults'
            END AS age_group,
            person.gender,
            COUNT(DISTINCT patient.patient_id) AS total
        FROM patient
        JOIN person ON patient.patient_id = person.person_id
        JOIN (
            SELECT patient_id
            FROM receipts
            WHERE payment_stamp BETWEEN %s AND %s
            GROUP BY patient_id
            HAVING COUNT(*) > 1
        ) AS returning_patients ON patient.patient_id = returning_patients.patient_id
        WHERE person.voided = 0
        GROUP BY age_group, person.gender
        ORDER BY age_group
        """
        return self.execute_query(query, (self.start_date, self.end_date))
    
    def get_total_money_collected(self):
        """Query 8: Total money collected by cashier"""
        query = """
        SELECT 
            CASE 
                WHEN cashier = '8' THEN 'James'
                WHEN cashier = '9' THEN 'Elvin'
            END AS cashier_name,
            SUM(full_price) AS 'Total Collected (MKW)'
        FROM order_entries
        WHERE cashier IN ('8', '9')
        AND created_at BETWEEN %s AND %s
        GROUP BY cashier
        """
        return self.execute_query(query, (self.start_date, self.end_date))

    def get_service_breakdown(self):
        """Patient and order count by service area for the reporting period."""
        query = """
        SELECT
            s.name AS service,
            COUNT(DISTINCT oe.patient_id) AS patients,
            COUNT(*) AS total_orders
        FROM order_entries oe
        JOIN services s ON oe.service_id = s.service_id
        WHERE oe.created_at BETWEEN %s AND %s
          AND oe.voided = 0
        GROUP BY s.name
        ORDER BY patients DESC
        """
        return self.execute_query(query, (self.start_date, self.end_date))

    def get_paying_vs_nonpaying(self):
        """Query 9: Breakdown of paying vs non-paying patients"""
        query = """
        SELECT 
            COUNT(*) AS total_patients,
            SUM(CASE WHEN paying_orders > 0 AND non_paying_orders = 0 THEN 1 ELSE 0 END) AS exclusively_paying,
            SUM(CASE WHEN non_paying_orders > 0 AND paying_orders = 0 THEN 1 ELSE 0 END) AS exclusively_non_paying,
            SUM(CASE WHEN paying_orders > 0 AND non_paying_orders > 0 THEN 1 ELSE 0 END) AS both_categories
        FROM (
            SELECT 
                patient_id,
                SUM(CASE WHEN full_price >= 1000 THEN 1 ELSE 0 END) AS paying_orders,
                SUM(CASE WHEN full_price = 0 THEN 1 ELSE 0 END) AS non_paying_orders
            FROM order_entries
            WHERE order_date BETWEEN %s AND %s
            GROUP BY patient_id
        ) AS patient_summary
        """
        return self.execute_query(query, (self.start_date, self.end_date))
    
    def get_daily_revenue_trend(self):
        """Query 10: Daily revenue trend"""
        query = """
        SELECT 
            DATE(created_at) AS transaction_date,
            SUM(full_price) AS 'Total Collected (MKW)'
        FROM order_entries
        WHERE cashier IN ('8', '9')
        AND created_at BETWEEN %s AND %s
        GROUP BY transaction_date
        ORDER BY transaction_date
        """
        return self.execute_query(query, (self.start_date, self.end_date))
    
    def get_daily_patient_visits(self):
        """Query 11: Daily hospital patient visits"""
        query = """
        WITH RECURSIVE DateSeries AS (
            SELECT %s AS dt
            UNION ALL
            SELECT DATE_ADD(dt, INTERVAL 1 DAY)
            FROM DateSeries
            WHERE dt < %s
        ),
        DailyRegistrations AS (
            SELECT DATE(date_created) AS registration_date, COUNT(*) AS total_registrations
            FROM patient
            WHERE DATE(date_created) BETWEEN %s AND %s
            GROUP BY registration_date
        ),
        DailyReturning AS (
            SELECT DATE(r.created_at) AS visit_date, COUNT(DISTINCT r.patient_id) AS total_returning_patients
            FROM receipts r
            WHERE DATE(r.created_at) BETWEEN %s AND %s
              AND EXISTS (
                SELECT 1
                FROM patient p
                WHERE p.patient_id = r.patient_id
                  AND DATE(p.date_created) < DATE(r.created_at)
              )
            GROUP BY visit_date
        )
        SELECT
            ds.dt AS date,
            DAYNAME(ds.dt) AS day_name,
            COALESCE(dr.total_registrations, 0) AS total_registrations,
            COALESCE(dret.total_returning_patients, 0) AS total_returning_patients,
            COALESCE(dr.total_registrations, 0) + COALESCE(dret.total_returning_patients, 0) AS total_visits
        FROM DateSeries ds
        LEFT JOIN DailyRegistrations dr ON ds.dt = dr.registration_date
        LEFT JOIN DailyReturning dret ON ds.dt = dret.visit_date
        ORDER BY ds.dt
        """
        return self.execute_query(query, (self.start_date, self.end_date, self.start_date, self.end_date, self.start_date, self.end_date))

    def create_document(self):
        """Create and format the Word document"""
        doc = Document()

        # Set clean, consistent page margins
        section = doc.sections[0]
        section.top_margin = Inches(0.7)
        section.bottom_margin = Inches(0.7)
        section.left_margin = Inches(0.75)
        section.right_margin = Inches(0.75)

        # Default body font
        normal_style = doc.styles['Normal']
        normal_style.font.name = 'Arial'
        normal_style.font.size = Pt(10)
        
        # Add logo at the top (centered)
        logo_path = os.path.join(os.path.dirname(__file__), 'WKZ_Logo.png')
        if os.path.exists(logo_path):
            logo_paragraph = doc.add_paragraph()
            logo_paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
            logo_run = logo_paragraph.add_run()
            logo_run.add_picture(logo_path, width=Inches(0.8))  # 0.8 inches wide
            logo_paragraph.space_after = Pt(6)
        
        # Add title
        title = doc.add_heading('Wandikweza Billing and Registration Report', 0)
        title.alignment = WD_ALIGN_PARAGRAPH.CENTER
        title.runs[0].font.name = 'Arial'
        title.runs[0].font.bold = True
        title.runs[0].font.size = Pt(22)
        title.runs[0].font.color.rgb = RGBColor(31, 78, 121)
        
        # Add report period
        period = doc.add_paragraph()
        period.add_run(f'Reporting Period: {self.start_date} to {self.end_date}').bold = True
        period.alignment = WD_ALIGN_PARAGRAPH.CENTER
        period.runs[0].font.name = 'Arial'
        period.runs[0].font.size = Pt(11)
        
        # Add generation date
        generated = doc.add_paragraph()
        generated.alignment = WD_ALIGN_PARAGRAPH.CENTER
        generated_run = generated.add_run(f'Generated on: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}')
        generated_run.italic = True
        generated_run.font.name = 'Arial'
        generated_run.font.size = Pt(9)
        generated_run.font.color.rgb = RGBColor(90, 90, 90)

        divider = doc.add_paragraph()
        divider.alignment = WD_ALIGN_PARAGRAPH.CENTER
        divider_run = divider.add_run('_' * 90)
        divider_run.font.color.rgb = RGBColor(180, 180, 180)
        
        return doc
    
    def _ollama_narrative(self, prompt, fallback=''):
        """Call local Ollama to generate narrative text. Returns fallback if unavailable."""
        try:
            import re
            payload = json.dumps({
                'model': 'llama3.2:3b',
                'think': False,
                'messages': [
                    {
                        'role': 'system',
                        'content': (
                            'You are a professional medical report writer. '
                            'Write clear, concise, factual paragraphs for hospital management reports. '
                            'Never use bullet points. Never add headers. Never explain your reasoning. '
                            'Output only the requested paragraph text.'
                        )
                    },
                    {'role': 'user', 'content': prompt}
                ],
                'stream': False,
                'options': {'temperature': 0.3, 'num_predict': 400}
            }).encode()
            req = urllib.request.Request(
                'http://localhost:11434/api/chat',
                data=payload,
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            with urllib.request.urlopen(req, timeout=180) as resp:
                result = json.loads(resp.read())
                text = result.get('message', {}).get('content', fallback)
                text = re.sub(r'<think>.*?</think>', '', text, flags=re.DOTALL).strip()
                return text or fallback
        except Exception as e:
            print(f"Ollama unavailable, using fallback text: {e}")
            return fallback

    def add_executive_summary(self, doc, total_registered, total_visits, returning_count,
                               total_revenue, duplicate_groups_count,
                               total_duplicate_records, paying_breakdown,
                               gender_data, daily_visits, prev, service_data):
        """Narrative executive summary answering: what happened, what's notable, what action to take."""

        def _sub_heading(text):
            h = doc.add_heading(text, level=2)
            h.alignment = WD_ALIGN_PARAGRAPH.LEFT
            if h.runs:
                h.runs[0].font.name = 'Arial'
                h.runs[0].font.bold = True
                h.runs[0].font.size = Pt(12)
                h.runs[0].font.color.rgb = RGBColor(31, 78, 121)

        def _trim(text, max_chars=320):
            """Trim text to the last complete sentence within max_chars."""
            if len(text) <= max_chars:
                return text
            cut = text[:max_chars]
            # Find the last sentence-ending punctuation within the limit
            for punct in ('. ', '! ', '? '):
                idx = cut.rfind(punct)
                if idx != -1:
                    return cut[:idx + 1]
            # No sentence boundary found, hard cut at max_chars
            return cut.rstrip() + '.'

        def _para(text, bold_phrases=None):
            """Add a paragraph, optionally bolding specific phrases."""
            p = doc.add_paragraph()
            p.paragraph_format.space_after = Pt(6)
            if not bold_phrases:
                r = p.add_run(text)
                r.font.name = 'Arial'
                r.font.size = Pt(10)
            else:
                # Split text around bold phrases and render accordingly
                remaining = text
                for phrase in bold_phrases:
                    idx = remaining.find(phrase)
                    if idx == -1:
                        continue
                    before = remaining[:idx]
                    if before:
                        r = p.add_run(before)
                        r.font.name = 'Arial'
                        r.font.size = Pt(10)
                    br = p.add_run(phrase)
                    br.bold = True
                    br.font.name = 'Arial'
                    br.font.size = Pt(10)
                    remaining = remaining[idx + len(phrase):]
                if remaining:
                    r = p.add_run(remaining)
                    r.font.name = 'Arial'
                    r.font.size = Pt(10)

        def _bullet(text, bold_prefix=None):
            p = doc.add_paragraph(style='List Bullet')
            p.paragraph_format.space_after = Pt(3)
            if bold_prefix:
                br = p.add_run(bold_prefix)
                br.bold = True
                br.font.name = 'Arial'
                br.font.size = Pt(10)
                r = p.add_run(text)
                r.font.name = 'Arial'
                r.font.size = Pt(10)
            else:
                r = p.add_run(text)
                r.font.name = 'Arial'
                r.font.size = Pt(10)

        # --- Computed values ---
        exclusively_paying   = paying_breakdown[0]['exclusively_paying']   if paying_breakdown else 0
        exclusively_non_paying = paying_breakdown[0]['exclusively_non_paying'] if paying_breakdown else 0
        total_patients       = paying_breakdown[0]['total_patients']        if paying_breakdown else 0
        pay_pct = (exclusively_paying / total_patients * 100) if total_patients else 0

        # Gender/age breakdown from registered pivot
        adults_total = next((r['Total'] for r in gender_data if r.get('Age Category') == 'Adults'), 0)
        under5_total = next((r['Total'] for r in gender_data if r.get('Age Category') == 'Under 5'), 0)
        mid_total    = next((r['Total'] for r in gender_data if r.get('Age Category') == '5-13'), 0)
        female_total = sum(r.get('Female', 0) for r in gender_data if r.get('Age Category') != 'Total')
        reg_total_check = sum(r.get('Total', 0) for r in gender_data if r.get('Age Category') != 'Total')
        adult_pct  = (adults_total / reg_total_check * 100) if reg_total_check else 0
        under14_pct = ((under5_total + mid_total) / reg_total_check * 100) if reg_total_check else 0
        female_pct = (female_total / reg_total_check * 100) if reg_total_check else 0

        # Peak attendance day from daily visits
        peak_day = None
        if daily_visits:
            peak_row = max(daily_visits, key=lambda r: int(r.get('total_visits') or 0))
            peak_day = f"{peak_row.get('day_name', '')} {peak_row.get('date', '')}"
            peak_visits = int(peak_row.get('total_visits') or 0)

        returning_pct = (returning_count / total_registered * 100) if total_registered else 0
        revenue_millions = total_revenue / 1_000_000

        # --- Section title ---
        title = doc.add_heading('Executive Summary', level=1)
        title.alignment = WD_ALIGN_PARAGRAPH.LEFT
        if title.runs:
            title.runs[0].font.name = 'Arial'
            title.runs[0].font.bold = True
            title.runs[0].font.size = Pt(14)
            title.runs[0].font.color.rgb = RGBColor(31, 78, 121)

        # Build a shared data context string for all prompts
        top_services_str = ', '.join(
            f'{r["service"]} ({r["patients"]:,} patients)'
            for r in (service_data or [])[:3]
        ) or 'not available'
        least_service_str = (
            f'{service_data[-1]["service"]} ({service_data[-1]["patients"]:,} patients)'
            if service_data else 'not available'
        )
        peak_str = f'{peak_day} with {peak_visits:,} visits' if peak_day else 'not available'
        reg_change = total_registered - prev['registered']
        rev_change = total_revenue - prev['revenue']

        data_context = f"""
Reporting period: {self.start_date} to {self.end_date}
Previous period: {prev['period']}
New registrations: {total_registered:,} (previous: {prev['registered']:,}, change: {reg_change:+,})
Total patient visits: {total_visits:,}
Returning patients: {returning_count:,} ({returning_pct:.1f}% of new registrations)
Total revenue: MWK {total_revenue:,.0f} (previous: MWK {prev['revenue']:,.0f}, change: MWK {rev_change:+,.0f})
Paying patients: {exclusively_paying:,}, Non-paying: {exclusively_non_paying:,}
Adult patients: {adult_pct:.1f}%, Female patients: {female_pct:.1f}%, Under 14: {under14_pct:.1f}%
Top services: {top_services_str}
Peak attendance: {peak_str}
Duplicate groups: {duplicate_groups_count:,} ({total_duplicate_records:,} excess records)
"""

        print("Generating AI narrative for executive summary...")

        # Single Ollama call for all narrative sections
        full_prompt = f"""You are writing narrative paragraphs for a hospital monthly performance report executive summary.
Write exactly 5 short paragraphs in this order, each 2-3 sentences. Be factual and professional.
Use ONLY these exact labels on their own line before each paragraph (no other formatting):
OVERVIEW:
DEMOGRAPHICS:
UTILIZATION:
FINANCIAL:
QUALITY:

Data:
Reporting period: {self.start_date} to {self.end_date} (previous: {prev['period']})
New registrations: {total_registered:,} (prev: {prev['registered']:,}, change: {reg_change:+,})
Total patient visits: {total_visits:,}
Returning patients: {returning_count:,} ({returning_pct:.1f}% of new registrations)
Revenue: MWK {total_revenue:,.0f} (prev: MWK {prev['revenue']:,.0f}, change: MWK {rev_change:+,.0f})
Paying: {exclusively_paying:,}, Non-paying: {exclusively_non_paying:,}
Adults: {adult_pct:.1f}%, Females: {female_pct:.1f}%, Under 14: {under14_pct:.1f}%
Top services: {top_services_str}
Least used service: {least_service_str}
Peak attendance: {peak_str}
Duplicate groups: {duplicate_groups_count:,} ({total_duplicate_records:,} excess records)

For UTILIZATION: name the most used service with its patient count, the second most used, and the least used service. Do not include scheduling advice or generic recommendations.
"""
        fallbacks = {
            'OVERVIEW': (
                f'During the reporting period ({self.start_date} to {self.end_date}), the facility registered '
                f'{total_registered:,} new patients and recorded {total_visits:,} total patient visits. '
                f'Of these, {returning_count:,} were returning patients. '
                f'Revenue collected amounted to MWK {revenue_millions:,.2f} million, '
                f'with {pay_pct:.1f}% of patients having paid transactions.'
            ),
            'DEMOGRAPHICS': (
                f'Adult patients (14 years and above) accounted for {adult_pct:.1f}% of registrations, '
                f'with females representing {female_pct:.1f}% of all registered patients. '
                f'Children under 14 years accounted for {under14_pct:.1f}% of registrations.'
            ),
            'UTILIZATION': (
                f'The most utilised service was {service_data[0]["service"]} with {service_data[0]["patients"]:,} patients, '
                f'followed by {service_data[1]["service"]} with {service_data[1]["patients"]:,} patients. '
                f'The least utilised service was {service_data[-1]["service"]} with {service_data[-1]["patients"]:,} patients.'
                if service_data and len(service_data) >= 2
                else f'Returning patients represented {returning_pct:.1f}% of all new registrations during the reporting period.'
            ),
            'FINANCIAL': (
                f'The facility generated MWK {revenue_millions:,.2f} million during the reporting period. '
                f'Of the {total_patients:,} patients served, {exclusively_non_paying:,} had exclusively '
                f'non-paying transactions, representing {100 - pay_pct:.1f}% of patients.'
            ),
            'QUALITY': (
                f'A total of {duplicate_groups_count:,} duplicate patient groups ({total_duplicate_records:,} '
                f'excess records) were identified. Efforts to improve patient search and registration practices are recommended.'
                if duplicate_groups_count > 0
                else 'No duplicate patient records were identified during this period. Data quality is good.'
            ),
        }

        # Parse the single response into sections
        import re
        raw = self._ollama_narrative(full_prompt, fallback='')
        sections = {}
        if raw:
            for key in fallbacks:
                match = re.search(
                    rf'{key}:\s*(.*?)(?=(?:OVERVIEW|DEMOGRAPHICS|UTILIZATION|FINANCIAL|QUALITY|ASSESSMENT):|$)',
                    raw, re.DOTALL | re.IGNORECASE
                )
                sections[key] = match.group(1).strip() if match else fallbacks[key]
        else:
            sections = fallbacks

        # --- Overview ---
        _sub_heading('Overview')
        _para(_trim(sections.get('OVERVIEW', fallbacks['OVERVIEW'])))

        # --- Key Highlights with Month-to-Month Comparison ---
        _sub_heading('Key Highlights')

        def _delta(current, previous, is_currency=False, min_base=50):
            if previous == 0:
                return ''
            diff = current - previous
            pct  = abs(diff / previous * 100)
            arrow = '↑' if diff > 0 else ('↓' if diff < 0 else '—')
            if diff == 0:
                return ' (no change vs previous period)'
            if is_currency:
                return f' ({arrow} MWK {abs(diff):,.0f}, {pct:.1f}% vs previous period)'
            if previous < min_base:
                return f' ({arrow} {abs(int(diff)):,} vs previous period)'
            return f' ({arrow} {abs(int(diff)):,}, {pct:.1f}% vs previous period)'

        _bullet(f'{total_registered:,} patients{_delta(total_registered, prev["registered"])}',
                bold_prefix='Total new registrations: ')
        _bullet(f'{returning_count:,} patients{_delta(returning_count, prev["returning"])}',
                bold_prefix='Returning patients: ')
        _bullet(f'MWK {total_revenue:,.0f}{_delta(total_revenue, prev["revenue"], is_currency=True)}',
                bold_prefix='Total revenue collected: ')
        _bullet(f'{exclusively_paying:,}{_delta(exclusively_paying, prev["paying"])}',
                bold_prefix='Paying patients: ')
        _bullet(f'{exclusively_non_paying:,}{_delta(exclusively_non_paying, prev["non_paying"])}',
                bold_prefix='Non-paying patients: ')
        _bullet(
            f'{duplicate_groups_count:,} ({total_duplicate_records:,} duplicate records requiring review)'
            f'{_delta(duplicate_groups_count, prev["dup_groups"])}',
            bold_prefix='Duplicate patient groups identified: '
        )

        # --- Patient Demographics ---
        _sub_heading('Patient Demographics')
        _para(_trim(sections.get('DEMOGRAPHICS', fallbacks['DEMOGRAPHICS'])))

        # --- Service Utilization ---
        _sub_heading('Service Utilization')
        _para(_trim(sections.get('UTILIZATION', fallbacks['UTILIZATION'])))

        # --- Financial Performance ---
        _sub_heading('Financial Performance')
        _para(_trim(sections.get('FINANCIAL', fallbacks['FINANCIAL'])))

        # --- Data Quality ---
        _sub_heading('Data Quality')
        _para(_trim(sections.get('QUALITY', fallbacks['QUALITY'])))

        # --- Management Considerations ---
        # _sub_heading('Management Considerations')
        # _bullet('Continue monitoring patient growth and returning patient trends.')
        # _bullet('Review causes of duplicate registrations and strengthen patient identification procedures.')
        # _bullet('Investigate factors contributing to high-performing revenue and attendance days to inform service planning.')
        # _bullet('Monitor non-paying patient records to ensure appropriate documentation of exemptions and free services.')

        doc.add_page_break()

    def add_section_header(self, doc, text):
        """Add a formatted section header"""
        heading = doc.add_heading(text, level=1)
        heading.alignment = WD_ALIGN_PARAGRAPH.LEFT
        if heading.runs:
            heading.runs[0].font.name = 'Arial'
            heading.runs[0].font.bold = True
            heading.runs[0].font.size = Pt(14)
            heading.runs[0].font.color.rgb = RGBColor(31, 78, 121)
        return heading

    def _set_cell_text(self, cell, text, bold=False, color=None, size=10, align=WD_ALIGN_PARAGRAPH.LEFT):
        """Write formatted text into a table cell."""
        cell.text = ''
        paragraph = cell.paragraphs[0]
        paragraph.alignment = align
        run = paragraph.add_run(text)
        run.bold = bold
        run.font.name = 'Arial'
        run.font.size = Pt(size)
        if color:
            run.font.color.rgb = color
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER

    def _format_table_value(self, value):
        """Format values for readable table output."""
        from decimal import Decimal
        if value is None:
            return ''
        if isinstance(value, bool):
            return 'Yes' if value else 'No'
        if isinstance(value, datetime):
            return value.strftime('%Y-%m-%d %H:%M:%S')
        if isinstance(value, date):
            return value.strftime('%Y-%m-%d')
        if isinstance(value, int):
            return f'{value:,}'
        if isinstance(value, float):
            if value.is_integer():
                return f'{int(value):,}'
            return f'{value:,.2f}'
        if isinstance(value, Decimal):
            if value == value.to_integral_value():
                return f'{int(value):,}'
            return f'{value:,.2f}'
        return str(value)

    def _align_table_column(self, header_name, value):
        """Choose a sensible alignment for a table cell."""
        if isinstance(value, (int, float)):
            return WD_ALIGN_PARAGRAPH.RIGHT
        numeric_keywords = ('count', 'total', 'sum', 'amount', 'price', 'visits', 'revenue')
        if any(keyword in header_name.lower() for keyword in numeric_keywords):
            return WD_ALIGN_PARAGRAPH.RIGHT
        return WD_ALIGN_PARAGRAPH.LEFT
    
    def add_table_from_data(self, doc, data, title=None):
        """Add a formatted table to the document"""
        if title:
            doc.add_heading(title, level=2)
        
        if not data or len(data) == 0:
            doc.add_paragraph("No data available")
            return
        
        # Create table with headers
        headers = list(data[0].keys())
        table = doc.add_table(rows=1, cols=len(headers))
        table.style = 'Light Grid Accent 1'
        table.alignment = WD_TABLE_ALIGNMENT.CENTER
        table.autofit = True
        
        # Add headers with background color
        header_cells = table.rows[0].cells
        for i, header in enumerate(headers):
            label = str(header).replace('_', ' ').title()
            cell = header_cells[i]
            
            # Set cell background color (blue header)
            from docx.oxml.ns import nsdecls
            from docx.oxml import parse_xml
            shading_elm = parse_xml(r'<w:shd {} w:fill="1F4E79"/>'.format(nsdecls('w')))
            cell._element.get_or_add_tcPr().append(shading_elm)
            
            # Set text with white color for contrast
            self._set_cell_text(
                cell,
                label,
                bold=True,
                color=RGBColor(255, 255, 255),
                size=10,
                align=WD_ALIGN_PARAGRAPH.CENTER
            )
        
        # Add data rows
        for row_idx, row_data in enumerate(data):
            row_cells = table.add_row().cells
            is_total_row = str(list(row_data.values())[0]).strip().lower() == 'total'
            for i, header in enumerate(headers):
                value = row_data[header]
                formatted_value = self._format_table_value(value)
                alignment = self._align_table_column(header, value)
                self._set_cell_text(row_cells[i], formatted_value, bold=is_total_row, size=10, align=alignment)
        
        doc.add_paragraph()  # Add spacing
    
    def pivot_age_gender_table(self, data, age_col, gender_col, value_col, age_order=None):
        """
        Pivot raw age+gender rows into Age Category | Male | Female | Total format.
        age_order: optional list of age labels defining row order.
        """
        counts = {}
        for row in (data or []):
            age = row[age_col]
            gender = str(row[gender_col]).upper()
            val = int(row[value_col] or 0)
            if age not in counts:
                counts[age] = {'M': 0, 'F': 0}
            if gender in ('M', 'MALE'):
                counts[age]['M'] += val
            elif gender in ('F', 'FEMALE'):
                counts[age]['F'] += val

        if age_order:
            ordered_ages = age_order[:]
            # append any ages in data not covered by age_order
            ordered_ages += [a for a in counts if a not in age_order]
        else:
            ordered_ages = sorted(counts.keys())

        pivoted = []
        total_m = total_f = 0
        for age in ordered_ages:
            m = counts.get(age, {'M': 0, 'F': 0})['M']
            f = counts.get(age, {'M': 0, 'F': 0})['F']
            total_m += m
            total_f += f
            pivoted.append({
                'Age Category': age,
                'Male': m,
                'Female': f,
                'Total': m + f,
            })
        pivoted.append({
            'Age Category': 'Total',
            'Male': total_m,
            'Female': total_f,
            'Total': total_m + total_f,
        })
        return pivoted

    def add_side_by_side_registration(self, doc, metrics, gender_data):
        """
        Render Section 1: metrics stacked, then gender table directly below, no title.
        """
        from docx.oxml.ns import nsdecls
        from docx.oxml import parse_xml

        # Metrics
        for label, value in metrics:
            p = doc.add_paragraph()
            p.paragraph_format.space_after = Pt(4)
            run_label = p.add_run(f'{label}: ')
            run_label.bold = True
            run_label.font.name = 'Arial'
            run_label.font.size = Pt(10)
            run_val = p.add_run(str(value))
            run_val.font.name = 'Arial'
            run_val.font.size = Pt(10)

        # Gender table — with title, left-aligned
        if gender_data:
            title_p = doc.add_paragraph()
            title_p.paragraph_format.space_before = Pt(6)
            title_p.paragraph_format.space_after = Pt(4)
            title_run = title_p.add_run('Registered Patients by Gender and Age Group')
            title_run.bold = True
            title_run.font.name = 'Arial'
            title_run.font.size = Pt(11)
            title_run.font.color.rgb = RGBColor(31, 78, 121)
            headers = list(gender_data[0].keys())
            table = doc.add_table(rows=1, cols=len(headers))
            table.style = 'Light Grid Accent 1'
            table.alignment = WD_TABLE_ALIGNMENT.LEFT
            table.autofit = True

            for i, header in enumerate(headers):
                label = str(header).replace('_', ' ').title()
                cell = table.rows[0].cells[i]
                shading = parse_xml(r'<w:shd {} w:fill="1F4E79"/>'.format(nsdecls('w')))
                cell._element.get_or_add_tcPr().append(shading)
                self._set_cell_text(cell, label, bold=True,
                                    color=RGBColor(255, 255, 255), size=10,
                                    align=WD_ALIGN_PARAGRAPH.CENTER)

            for row_data in gender_data:
                row_cells = table.add_row().cells
                is_total = str(list(row_data.values())[0]).strip().lower() == 'total'
                for i, header in enumerate(headers):
                    value = row_data[header]
                    self._set_cell_text(row_cells[i],
                                        self._format_table_value(value),
                                        bold=is_total, size=10,
                                        align=self._align_table_column(header, value))

        doc.add_paragraph()

        doc.add_paragraph()

    def add_metric(self, doc, label, value):
        """Add a key metric to the document"""
        p = doc.add_paragraph()
        p.add_run(f'{label}: ').bold = True
        p.add_run(self._format_table_value(value))
        p.paragraph_format.space_after = Pt(4)
    
    def add_registration_pie_chart(self, doc, gender_data):
        """Pie chart: registered patients by age category (Under 5, 5-13, Adults)."""
        rows = [r for r in (gender_data or []) if r.get('Age Category') != 'Total']
        if not rows:
            return
        labels = [r['Age Category'] for r in rows]
        sizes  = [r['Total'] for r in rows]
        if sum(sizes) == 0:
            return

        colors = ['#1F4E79', '#2E75B6', '#9DC3E6']
        fig, ax = plt.subplots(figsize=(3, 2))
        wedges, texts, autotexts = ax.pie(
            sizes, labels=labels, colors=colors,
            autopct='%1.1f%%', startangle=90,
            textprops={'fontsize': 8}
        )
        for at in autotexts:
            at.set_color('white')
            at.set_fontweight('bold')
        ax.set_title('Registered Patients by Age Group', fontsize=10,
                     fontweight='bold', color='#1F4E79', pad=10)
        fig.tight_layout()

        stream = self._chart_to_image_stream(fig)
        p = doc.add_paragraph()
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run()
        run.add_picture(stream, width=Inches(2.5))

    def _chart_to_image_stream(self, fig):
        """Save a matplotlib figure to an in-memory PNG stream."""
        buf = io.BytesIO()
        fig.savefig(buf, format='png', dpi=150, bbox_inches='tight')
        buf.seek(0)
        plt.close(fig)
        return buf

    def add_daily_visits_chart(self, doc, daily_visits):
        """Bar chart: daily new registrations vs returning patients."""
        if not daily_visits:
            return
        dates   = [datetime.strptime(str(r['date']), '%Y-%m-%d') for r in daily_visits]
        new_reg = [int(r['total_registrations'] or 0) for r in daily_visits]
        ret_pat = [int(r['total_returning_patients'] or 0) for r in daily_visits]

        fig, ax = plt.subplots(figsize=(10, 3.5))
        x = range(len(dates))
        bar_w = 0.45
        ax.bar([i - bar_w/2 for i in x], new_reg, width=bar_w,
               label='New Registrations', color='#1F4E79', alpha=0.9)
        ax.bar([i + bar_w/2 for i in x], ret_pat, width=bar_w,
               label='Returning Patients', color='#2E75B6', alpha=0.7)

        ax.set_xticks(list(x))
        ax.set_xticklabels([d.strftime('%d %b') for d in dates],
                           rotation=45, ha='right', fontsize=7)
        ax.set_ylabel('Patients', fontsize=9)
        ax.set_title('Daily Patient Visits', fontsize=11, fontweight='bold', color='#1F4E79')
        ax.legend(fontsize=8)
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.yaxis.grid(True, linestyle='--', alpha=0.5)
        ax.set_axisbelow(True)
        fig.tight_layout()

        stream = self._chart_to_image_stream(fig)
        doc.add_picture(stream, width=Inches(6.5))
        doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER

    def add_daily_revenue_chart(self, doc, daily_revenue):
        """Line chart: daily revenue trend."""
        if not daily_revenue:
            return
        dates   = [datetime.strptime(str(r['transaction_date']), '%Y-%m-%d') for r in daily_revenue]
        revenue = [float(r['Total Collected (MKW)'] or 0) for r in daily_revenue]

        fig, ax = plt.subplots(figsize=(10, 3.5))
        ax.fill_between(range(len(dates)), revenue, alpha=0.2, color='#1F4E79')
        ax.plot(range(len(dates)), revenue, color='#1F4E79', linewidth=1.8, marker='o',
                markersize=3)

        ax.set_xticks(range(len(dates)))
        ax.set_xticklabels([d.strftime('%d %b') for d in dates],
                           rotation=45, ha='right', fontsize=7)
        ax.set_ylabel('MWK', fontsize=9)
        ax.set_title('Daily Revenue Trend', fontsize=11, fontweight='bold', color='#1F4E79')
        ax.yaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: f'{v:,.0f}'))
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.yaxis.grid(True, linestyle='--', alpha=0.5)
        ax.set_axisbelow(True)
        fig.tight_layout()

        stream = self._chart_to_image_stream(fig)
        doc.add_picture(stream, width=Inches(6.5))
        doc.paragraphs[-1].alignment = WD_ALIGN_PARAGRAPH.CENTER

    def add_key_explanation(self, doc, text):
        """Add a KEY explanation box to help interpret the data"""
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(8)
        p.paragraph_format.space_after = Pt(8)
        
        key_run = p.add_run('KEY: ')
        key_run.bold = True
        key_run.font.name = 'Arial'
        key_run.font.size = Pt(9)
        key_run.font.color.rgb = RGBColor(31, 78, 121)
        
        text_run = p.add_run(text)
        text_run.font.name = 'Arial'
        text_run.font.size = Pt(9)
        text_run.font.color.rgb = RGBColor(60, 60, 60)
        text_run.italic = True
    
    def send_email_report(self, pdf_filepath):
        """Send the PDF report via email"""
        try:
            # Check if email sending is enabled
            send_email = self.config.get('email', 'send_email', fallback='no').lower()
            if send_email != 'yes':
                print("\nEmail sending is disabled in configuration")
                return False
            
            # Get email configuration
            smtp_server = self.config.get('email', 'smtp_server')
            smtp_port = self.config.getint('email', 'smtp_port')
            sender_email = self.config.get('email', 'sender_email')
            sender_password = self.config.get('email', 'sender_password')
            recipient_email = self.config.get('email', 'recipient_email')
            
            # Create message
            msg = MIMEMultipart()
            msg['From'] = sender_email
            msg['To'] = recipient_email
            msg['Subject'] = f'Wandikweza Hospital Monthly Report - {self.start_date} to {self.end_date}'
            
            # Email body
            body = f"""Dear Wandikweza M&E Team,

Please find attached the monthly billing and registration report for the period from {self.start_date} to {self.end_date}.

This report includes:
- Patient registration statistics
- Returning patients analysis
- Age group and gender distribution
- Financial analysis and revenue trends
- Daily patient visit trends

Best regards,
Wandikweza Health Center - Automated Reporting System
"""
            
            msg.attach(MIMEText(body, 'plain'))
            
            # Attach PDF file
            if os.path.exists(pdf_filepath):
                with open(pdf_filepath, 'rb') as attachment:
                    part = MIMEBase('application', 'octet-stream')
                    part.set_payload(attachment.read())
                    encoders.encode_base64(part)
                    filename = os.path.basename(pdf_filepath)
                    part.add_header('Content-Disposition', f'attachment; filename= {filename}')
                    msg.attach(part)
            else:
                print(f"Warning: PDF file not found: {pdf_filepath}")
                return False
            
            # Send email
            print("\nSending email report...")
            print(f"From: {sender_email}")
            print(f"To: {recipient_email}")
            
            server = smtplib.SMTP(smtp_server, smtp_port)
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
            server.quit()
            
            print("Email sent successfully!")
            return True
            
        except Exception as e:
            print(f"Failed to send email: {e}")
            return False
    
    def generate_report(self):
        """Main method to generate the complete report"""
        print("\n" + "="*60)
        print("Hospital Data Analysis Report Generator")
        print("="*60)
        
        # Connect to database
        if not self.connect_database():
            print("Failed to connect to database. Please check your configuration.")
            return False
        
        print(f"Report period: {self.start_date} to {self.end_date}")
        print("\nGenerating report sections...")
        
        # Create document
        doc = self.create_document()

        # Gather data needed for executive summary (reused later in sections)
        print("Gathering data for executive summary...")
        total_registered = self.get_total_registered_patients()
        total_visits = self.get_total_visits()
        returning_count = self.get_returning_patients_count()
        duplicate_groups = self.get_duplicate_group_counts()
        duplicate_groups_count = len(duplicate_groups) if duplicate_groups else 0
        total_duplicate_records = sum(row['duplicate_count'] - 1 for row in duplicate_groups) if duplicate_groups else 0
        total_patients_in_duplicates = sum(row['duplicate_count'] for row in duplicate_groups) if duplicate_groups else 0
        money_collected = self.get_total_money_collected()
        total_revenue = sum(row['Total Collected (MKW)'] for row in money_collected if row['Total Collected (MKW)']) if money_collected else 0
        paying_breakdown = self.get_paying_vs_nonpaying()
        daily_visits = self.get_daily_patient_visits()
        gender_registered = self.get_gender_distribution_registered()
        pivoted_gender_reg = self.pivot_age_gender_table(
            gender_registered, 'age_group', 'gender', 'total_patients',
            age_order=['Under 5', '5-13', 'Adults']
        )

        # Previous period comparison
        prev_start, prev_end = self.get_previous_period()
        print(f"Fetching comparison data for previous period: {prev_start} to {prev_end}")
        prev = self.get_comparison_data(prev_start, prev_end)
        service_data = self.get_service_breakdown()

        # Executive Summary (page 1)
        self.add_executive_summary(doc, total_registered, total_visits, returning_count,
                                   total_revenue, duplicate_groups_count,
                                   total_duplicate_records, paying_breakdown,
                                   pivoted_gender_reg, daily_visits, prev, service_data)

        # Section 1: Patient Registration Statistics
        # Detailed report title
        detailed_title = doc.add_heading('Detailed Performance Report', level=1)
        detailed_title.alignment = WD_ALIGN_PARAGRAPH.LEFT
        if detailed_title.runs:
            detailed_title.runs[0].font.name = 'Arial'
            detailed_title.runs[0].font.bold = True
            detailed_title.runs[0].font.size = Pt(16)
            detailed_title.runs[0].font.color.rgb = RGBColor(31, 78, 121)
        sub = doc.add_paragraph()
        sub_run = sub.add_run(f'Reporting Period: {self.start_date} to {self.end_date}')
        sub_run.italic = True
        sub_run.font.name = 'Arial'
        sub_run.font.size = Pt(10)
        sub_run.font.color.rgb = RGBColor(90, 90, 90)
        sub.paragraph_format.space_after = Pt(12)

        self.add_section_header(doc, '1. Patient Registration Statistics')
        print(f"Total registered patients in report period: {total_registered}")

        self.add_side_by_side_registration(doc, [
            ('Total Patients Registered in Report Period', f'{total_registered:,}'),
        ], pivoted_gender_reg)
        self.add_registration_pie_chart(doc, pivoted_gender_reg)

        # Section 2: Returning Patients
        self.add_section_header(doc, '2. Returning Patients Analysis')
        self.add_metric(doc, 'Total Returning Patients', returning_count)
        print(f"Returning patients: {returning_count}")
        
        returning_dist = self.get_returning_patients_distribution()
        pivoted_returning = self.pivot_age_gender_table(
            returning_dist, 'age_category', 'gender', 'returning_patient_count',
            age_order=['Under 5', '5-13', 'Adults']
        )
        self.add_table_from_data(doc, pivoted_returning, 'Distribution by Age and Gender')
        self.add_key_explanation(doc, 'Returning patients are those who made more than one visit during the reporting period. Under 5: below age 5. 5-13: ages 5 to 13. Adults: 14 and above.')
        print(f"Returning patients distribution")
        
        # Section 3: Age Group Analysis
        self.add_section_header(doc, '3. Age Group Analysis')
        adolescence_data = self.get_registered_patients_adolescence()
        pivoted_adolescence = self.pivot_age_gender_table(
            adolescence_data, 'age_group', 'gender', 'total_patients',
            age_order=['Under 5', '5-9', '10-14', '15-19', '20-24', '25+']
        )
        self.add_table_from_data(doc, pivoted_adolescence, 'Patient Age distribution')
        self.add_key_explanation(doc, 'Patients are grouped by age ranges: Under 5, 5-9, 10-14, 15-19, 20-24, and 25+. This helps identify which age groups are most served by the facility.')
        print(f"Adolescence age group analysis")
        
        # Section 4: Visit Frequency
        self.add_section_header(doc, '4. Visit Frequency Analysis')
        frequency_data = self.get_returning_frequency()
        visit_words = ['One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten+']

        # Build a lookup from visit count -> patient count
        freq_lookup = {}
        max_visit = 0
        for row in (frequency_data or []):
            n = int(row['number_of_visits'])
            count = int(row['number_of_patients'])
            if n <= 10:
                freq_lookup[n] = freq_lookup.get(n, 0) + count
            else:
                freq_lookup[11] = freq_lookup.get(11, 0) + count  # bucket 10+
            max_visit = max(max_visit, n)

        # Build rows 1 through 10, then 10+ if applicable — no gaps
        frequency_display = []
        for n in range(1, 11):
            label = visit_words[n - 1] + ' Visit' + ('' if n == 1 else 's')
            frequency_display.append({
                'Number of Visits': label,
                'Number of Patients': freq_lookup.get(n, 0),
            })
        if max_visit > 10:
            frequency_display.append({
                'Number of Visits': '10+ Visits',
                'Number of Patients': freq_lookup.get(11, 0),
            })

        # Table title
        doc.add_heading('Frequency of Returning Patients', level=2)

        # Render table with left-aligned visit label column
        if frequency_display:
            headers = list(frequency_display[0].keys())
            table = doc.add_table(rows=1, cols=len(headers))
            table.style = 'Light Grid Accent 1'
            table.alignment = WD_TABLE_ALIGNMENT.LEFT
            table.autofit = True
            from docx.oxml.ns import nsdecls
            from docx.oxml import parse_xml
            for i, header in enumerate(headers):
                cell = table.rows[0].cells[i]
                shading = parse_xml(r'<w:shd {} w:fill="1F4E79"/>'.format(nsdecls('w')))
                cell._element.get_or_add_tcPr().append(shading)
                self._set_cell_text(cell, header, bold=True,
                                    color=RGBColor(255, 255, 255), size=10,
                                    align=WD_ALIGN_PARAGRAPH.CENTER)
            for row_data in frequency_display:
                row_cells = table.add_row().cells
                self._set_cell_text(row_cells[0], row_data['Number of Visits'],
                                    size=10, align=WD_ALIGN_PARAGRAPH.LEFT)
                self._set_cell_text(row_cells[1], self._format_table_value(row_data['Number of Patients']),
                                    size=10, align=WD_ALIGN_PARAGRAPH.RIGHT)
            doc.add_paragraph()

        self.add_key_explanation(doc, '"Number of Visits" = how many times a patient came during the reporting period. "Number of Patients" = how many patients came exactly that many times.')
        print(f"Visit frequency analysis")

        # Section 5: Clinical Service Breakdown
        self.add_section_header(doc, '5. Clinical Service Breakdown')
        if service_data:
            # Add % of total patients column
            total_service_patients = sum(r['patients'] for r in service_data)
            enriched = [
                {
                    'Service': r['service'],
                    'Patients': r['patients'],
                    '% of Total': f"{r['patients'] / total_service_patients * 100:.1f}%",
                    'Total Orders': r['total_orders'],
                }
                for r in service_data
            ]
            self.add_table_from_data(doc, enriched, 'Patients by Service Area')
            self.add_key_explanation(doc, 'Shows how many unique patients used each service during the reporting period. "Total Orders" = number of individual service transactions. A patient may appear in multiple services.')
        else:
            doc.add_paragraph('No service data available for this period.')
        print(f"Clinical service breakdown")

        # Section 6: Duplicate Patient Analysis
        self.add_section_header(doc, '6. Duplicate Patient Analysis')
        self.add_metric(doc, 'Duplicate Groups', duplicate_groups_count)
        self.add_metric(doc, 'Extra Duplicate Records', total_duplicate_records)
        self.add_metric(doc, 'Patients In Duplicate Groups', total_patients_in_duplicates)
        self.add_key_explanation(doc, '"Duplicate Groups" = number of real patients registered more than once (e.g. 10 groups means 10 patients have duplicates). "Extra Duplicate Records" = redundant registrations that should be removed (e.g. registered 3 times = 2 extra records). "Patients In Duplicate Groups" = total registrations belonging to those patients, including the original. Ideally all three values should be 0.')
        print(f"Duplicate patient analysis")

        # Section 7: Financial Analysis
        self.add_section_header(doc, '7. Financial Analysis')
        self.add_table_from_data(doc, money_collected, 'Total Money Collected by Cashier')
        
        if money_collected:
            self.add_metric(doc, 'Total Revenue (MKW)', f'{total_revenue:,.2f}')
            print(f"Financial analysis - Total: {total_revenue:,.2f}")
        
        self.add_table_from_data(doc, paying_breakdown, 'Paying vs Non-Paying Patients Breakdown')
        self.add_key_explanation(doc, 'Shows total patients, those who only paid, those who never paid, and those who had both paying and non-paying visits during the reporting period.')
        print(f"Paying vs non-paying breakdown")
        
        # Section 7: Daily Trends
        self.add_section_header(doc, '8. Daily Trends')
        daily_revenue = self.get_daily_revenue_trend()
        self.add_table_from_data(doc, daily_revenue, 'Daily Revenue Trend')
        self.add_daily_revenue_chart(doc, daily_revenue)
        self.add_key_explanation(doc, 'Daily revenue collected by cashiers. Helps identify peak revenue days and patterns throughout the reporting period.')
        print(f"Daily revenue trend")

        self.add_table_from_data(doc, daily_visits, 'Daily Patient Visits')
        self.add_daily_visits_chart(doc, daily_visits)
        self.add_key_explanation(doc, 'Daily breakdown of new registrations, returning patients, and total visits. Total visits = new registrations + returning patients for each day.')
        print(f"Daily patient visits")
        
        # Section 9: Key Findings
        #self.add_section_header(doc, '9. Key Findings')
        
        # Save document
        output_dir = self.config.get('output', 'output_directory')
        os.makedirs(output_dir, exist_ok=True)
        
        filename_prefix = self.config.get('output', 'filename_prefix')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        base_filename = f"{filename_prefix}_{self.start_date}_to_{self.end_date}_{timestamp}"
        
        # Save DOCX file
        docx_filename = f"{base_filename}.docx"
        docx_filepath = os.path.join(output_dir, docx_filename)
        doc.save(docx_filepath)
        
        print("\n" + "="*60)
        print(f"DOCX report generated successfully!")
        print(f"Saved to: {docx_filepath}")
        
        # Generate PDF file
        pdf_filepath = os.path.join(output_dir, f"{base_filename}.pdf")
        pdf_generated = False
        
        print("\nGenerating PDF version...")
        
        # Try platform-specific PDF conversion
        system = platform.system()
        
        if system == 'Windows' and DOCX2PDF_AVAILABLE:
            # Use docx2pdf on Windows (requires MS Word)
            try:
                docx2pdf_convert(docx_filepath, pdf_filepath)
                pdf_generated = True
            except Exception as e:
                print(f"Warning: docx2pdf failed: {e}")
        
        elif system in ['Linux', 'Darwin']:  # Linux or macOS
            # Use LibreOffice for conversion
            try:
                # Check if LibreOffice is available
                libreoffice_cmd = 'libreoffice' if system == 'Linux' else 'soffice'
                
                # Convert using LibreOffice headless mode
                result = subprocess.run(
                    [libreoffice_cmd, '--headless', '--convert-to', 'pdf', 
                     '--outdir', output_dir, docx_filepath],
                    capture_output=True,
                    text=True,
                    timeout=60
                )
                
                if result.returncode == 0:
                    pdf_generated = True
                else:
                    print(f"Warning: LibreOffice conversion failed: {result.stderr}")
            except FileNotFoundError:
                print(f"Warning: LibreOffice not found. Install with: sudo apt-get install libreoffice")
            except subprocess.TimeoutExpired:
                print("Warning: PDF conversion timed out")
            except Exception as e:
                print(f"Warning: Failed to generate PDF: {e}")
        
        if pdf_generated:
            print(f"PDF report generated successfully!")
            print(f"Saved to: {pdf_filepath}")
            
            # Send email with PDF attachment
            self.send_email_report(pdf_filepath)
        else:
            print("PDF generation failed, but DOCX file is available.")
        
        print("="*60 + "\n")
        
        # Close database connection
        if self.connection:
            self.connection.close()
            print("Database connection closed")
        
        return True

def main():
    """Main entry point"""
    config_file = 'config.ini'
    auto_dates = '--auto' in sys.argv

    if not os.path.exists(config_file):
        print(f"Configuration file '{config_file}' not found!")
        print("Please create a config.ini file with database and report settings.")
        sys.exit(1)

    generator = ReportGenerator(config_file, auto_dates=auto_dates)
    success = generator.generate_report()

    if not success:
        sys.exit(1)


if __name__ == '__main__':
    main()
