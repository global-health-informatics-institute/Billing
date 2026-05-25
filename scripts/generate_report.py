#!/usr/bin/env python3
"""
Data Analysis Report Generator
Generates reports from live database
"""

import configparser
import mysql.connector
from datetime import datetime, date
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
    def __init__(self, config_file='config.ini'):
        """Initialize the report generator with configuration"""
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        self.connection = None
        self.start_date = self.config.get('report', 'start_date')
        self.end_date = self.config.get('report', 'end_date')
        
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
                WHEN TIMESTAMPDIFF(YEAR, per.birthdate, CURDATE()) < 5 THEN 'under_five'
                WHEN TIMESTAMPDIFF(YEAR, per.birthdate, CURDATE()) BETWEEN 5 AND 12 THEN 'under_thirteen'
                ELSE 'adult'
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
                ELSE 'Other'
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
        """Query 5: Frequency of returning patients"""
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
            HAVING COUNT(*) > 1
        ) AS returning_patient_visits
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
        GROUP BY age_group, p.gender
        ORDER BY age_group, p.gender
        """
        return self.execute_query(query)

    def get_gender_distribution_returning(self):
        """Query 7: Gender distribution of returning patients by age group"""
        query = """
        SELECT 
            CASE 
                WHEN TIMESTAMPDIFF(YEAR, person.birthdate, CURDATE()) < 5 THEN 'Under 5'
                WHEN TIMESTAMPDIFF(YEAR, person.birthdate, CURDATE()) BETWEEN 5 AND 13 THEN '5-13'
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
        for row_data in data:
            row_cells = table.add_row().cells
            for i, header in enumerate(headers):
                value = row_data[header]
                formatted_value = self._format_table_value(value)
                alignment = self._align_table_column(header, value)
                self._set_cell_text(row_cells[i], formatted_value, size=10, align=alignment)
        
        doc.add_paragraph()  # Add spacing
    
    def add_metric(self, doc, label, value):
        """Add a key metric to the document"""
        p = doc.add_paragraph()
        p.add_run(f'{label}: ').bold = True
        p.add_run(str(value))
        p.paragraph_format.space_after = Pt(4)
    
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
        
        # Section 1: Patient Registration Statistics
        self.add_section_header(doc, '1. Patient Registration Statistics')
        total_registered = self.get_total_registered_patients()
        self.add_metric(doc, 'Total Patients Registered in Report Period', total_registered)
        print(f"Total registered patients in report period: {total_registered}")

        total_registered_system = self.get_total_registered_patients_system()
        self.add_metric(doc, 'Total Patients Registered in System', total_registered_system)
        print(f"Total registered patients in system: {total_registered_system}")
        
        # Section 2: Returning Patients
        self.add_section_header(doc, '2. Returning Patients Analysis')
        returning_count = self.get_returning_patients_count()
        self.add_metric(doc, 'Total Returning Patients', returning_count)
        print(f"Returning patients: {returning_count}")
        
        returning_dist = self.get_returning_patients_distribution()
        self.add_table_from_data(doc, returning_dist, 'Distribution by Age and Gender')
        self.add_key_explanation(doc, 'Returning patients are those who made more than one visit during the reporting period. Age categories: Under Five (<5 years), Under Thirteen (5-12 years), and Adult (13+ years).')
        print(f"Returning patients distribution")
        
        # Section 3: Age Group Analysis
        self.add_section_header(doc, '3. Age Group Analysis')
        adolescence_data = self.get_registered_patients_adolescence()
        self.add_table_from_data(doc, adolescence_data, 'Registered Patients by Adolescence Groups')
        self.add_key_explanation(doc, 'Patients are grouped by age ranges: Under 5, 5-9, 10-14, 15-19, 20-24, and Other (25+). This helps identify which age groups are most served by the facility.')
        print(f"Adolescence age group analysis")
        
        # Section 4: Visit Frequency
        self.add_section_header(doc, '4. Visit Frequency Analysis')
        frequency_data = self.get_returning_frequency()
        self.add_table_from_data(doc, frequency_data, 'Frequency of Returning Patients')
        self.add_key_explanation(doc, 'Shows how many patients visited a specific number of times. For example, if 133 patients visited 2 times, it means 133 patients made exactly 2 visits during the reporting period.')
        print(f"Visit frequency analysis")
        
        # Section 5: Gender Distribution
        self.add_section_header(doc, '5. Gender Distribution')
        gender_registered = self.get_gender_distribution_registered()
        self.add_table_from_data(doc, gender_registered, 'Registered Patients by Gender and Age Group')
        
        gender_returning = self.get_gender_distribution_returning()
        self.add_table_from_data(doc, gender_returning, 'Returning Patients by Gender and Age Group')
        self.add_key_explanation(doc, 'Gender distribution across three age groups: Under 5 (children), 5-13 (school age), and Adults (14+). Helps identify service utilization patterns by gender and age.')
        print(f"Gender distribution analysis")
        
        # Section 6: Duplicate Patient Analysis
        self.add_section_header(doc, '6. Duplicate Patient Analysis')
        duplicate_groups = self.get_duplicate_group_counts()
        duplicate_groups_count = len(duplicate_groups) if duplicate_groups else 0
        total_duplicate_records = sum(row['duplicate_count'] - 1 for row in duplicate_groups) if duplicate_groups else 0
        total_patients_in_duplicates = sum(row['duplicate_count'] for row in duplicate_groups) if duplicate_groups else 0
        self.add_metric(doc, 'Duplicate Groups', duplicate_groups_count)
        self.add_metric(doc, 'Extra Duplicate Records', total_duplicate_records)
        self.add_metric(doc, 'Patients In Duplicate Groups', total_patients_in_duplicates)
        self.add_key_explanation(doc, 'Duplicate Groups: Number of unique patients who appear more than once in the system. Extra Duplicate Records: Number of repeated records beyond the first for each duplicated patient. Patients In Duplicate Groups: Total records linked to patients with duplicates, including the first record.')
        print(f"Duplicate patient analysis")
        
        # Section 7: Financial Analysis
        self.add_section_header(doc, '7. Financial Analysis')
        money_collected = self.get_total_money_collected()
        self.add_table_from_data(doc, money_collected, 'Total Money Collected by Cashier')
        
        # Calculate total
        if money_collected:
            total_revenue = sum(row['Total Collected (MKW)'] for row in money_collected if row['Total Collected (MKW)'])
            self.add_metric(doc, 'Total Revenue (MKW)', f'{total_revenue:,.2f}')
            print(f"Financial analysis - Total: {total_revenue:,.2f}")
        
        paying_breakdown = self.get_paying_vs_nonpaying()
        self.add_table_from_data(doc, paying_breakdown, 'Paying vs Non-Paying Patients Breakdown')
        self.add_key_explanation(doc, 'Shows total patients, those who only paid, those who never paid, and those who had both paying and non-paying visits during the reporting period.')
        print(f"Paying vs non-paying breakdown")
        
        # Section 8: Daily Trends
        self.add_section_header(doc, '8. Daily Trends')
        daily_revenue = self.get_daily_revenue_trend()
        self.add_table_from_data(doc, daily_revenue, 'Daily Revenue Trend')
        self.add_key_explanation(doc, 'Daily revenue collected by cashiers. Helps identify peak revenue days and patterns throughout the reporting period.')
        print(f"Daily revenue trend")
        
        daily_visits = self.get_daily_patient_visits()
        self.add_table_from_data(doc, daily_visits, 'Daily Patient Visits')
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
    
    if not os.path.exists(config_file):
        print(f"Configuration file '{config_file}' not found!")
        print("Please create a config.ini file with database and report settings.")
        sys.exit(1)
    
    generator = ReportGenerator(config_file)
    success = generator.generate_report()
    
    if not success:
        sys.exit(1)


if __name__ == '__main__':
    main()
