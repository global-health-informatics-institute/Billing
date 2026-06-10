# Hospital Billing System Workflow Diagram

## System Overview
This billing system manages patient registration, service ordering, payments, deposits, and medical insurance schemes for a hospital facility.

---

## 1) Patient Registration & Search

### Start
↓
**Login to System**
↓
**Search Patient** (by National ID, Name, Gender)
↓
**Decision: Patient Exists?**
- **YES** → Go to Patient Dashboard
- **NO** → Register New Patient
  ↓
  **Enter Patient Demographics**
  - Names (Given, Family, Middle, Maiden)
  - Gender
  - Date of Birth / Age
  - National ID
  - Contact Information (Cell, Home, Office Phone)
  - Address (Current & Home: District, T/A, Village, Landmark)
  - Occupation
  - Nationality/Citizenship
  ↓
  **Validate with DDE** (if configured)
  ↓
  **Generate National ID** (if needed)
  ↓
  **Print National ID Label**
  ↓
  **End** → Patient Dashboard

---

## 2) Medical Scheme Management (Insurance)

### Start (from Patient Dashboard)
↓
**Decision: Has Medical Scheme?**
- **NO** → Patient Account = "None"
- **YES** → Create Patient Account
  ↓
  **Select Medical Scheme Provider**
  ↓
  **Select Medical Scheme**
  ↓
  **Enter Scheme Number**
  ↓
  **Set Active Period** (From/To dates)
  ↓
  **Save Patient Account**
  ↓
  **End** → Patient Dashboard

---

## 3) Service Ordering (Order Entry)

### Start (from Patient Dashboard)
↓
**Click "New Order"**
↓
**Determine Patient Category**
- Age < 5 years → Child Services
- Age ≥ 5 & Male → Male Services  
- Age ≥ 5 & Female → Female Services
↓
**Select Service Categories**
- Consultation
- Laboratory Tests
- Radiology/Imaging
- Procedures
- Admission
- Pharmacy/Medications
- Other Services
↓
**For Each Category:**
  ↓
  **Select Services** (from category list)
  ↓
  **Enter Quantity** (if applicable)
  ↓
  **For Medications:**
  - Dose
  - Frequency (OD, BD, TDS, QID)
  - Duration (days)
  - Auto-calculate total quantity
  ↓
  **For Admission:**
  - Stay duration
  - Ward type
  ↓
  **For Service Panels:**
  - Select panel (group of services)
  - All panel services added automatically
↓
**Determine Service Location**
- General Clinic → General Pricing
- Private Clinic → Private Pricing
↓
**Calculate Full Price**
- Price = Service Price × Quantity
- Store: service_id, quantity, full_price, location
↓
**Save Order Entries**
↓
**End** → Patient Dashboard (shows unpaid orders)

---

## 4) Deposit Management

### A) Make Deposit
**Start** (from Patient Dashboard)
↓
**Click "New Deposit"**
↓
**Enter Deposit Amount**
↓
**Record Creator/Cashier**
↓
**Save Deposit**
- amount_received = amount entered
- amount_available = amount entered
↓
**Print Deposit Receipt**
↓
**End** → Patient Dashboard

### B) Reclaim Deposit
**Start** (from Patient Dashboard)
↓
**Click "Reclaim Deposit"**
↓
**Retrieve All Available Deposits**
↓
**Calculate Totals:**
- Total Received
- Total Used
- Balance Available
↓
**Set amount_available = 0** (for all deposits)
↓
**Print Refund Receipt**
↓
**End** → Patient Dashboard

---
## 5) Payment Processing

### Start (from Patient Dashboard)
↓
**View Unpaid/Partially Paid Orders**
↓
**Select Orders to Pay** (or pay all)
↓
**Enter Payment Details:**
- Payment Amount
- Payment Mode (Cash, Card, Mobile Money, etc.)
- Use Deposits? (Yes/No)
↓
**Calculate Total Payment**
- Total = Cash Amount + Deposit Amount
↓
**Decision: Payment > 0 OR Zero-Price Services?**
- **NO** → Return to Dashboard
- **YES** → Process Payment
  ↓
  **Create Receipt** (generate receipt number)
  ↓
  **For Each Selected Order:**
    ↓
    **Decision: Already Fully Paid?**
    - **YES** → Skip to next order
    - **NO** → Continue
      ↓
      **Decision: Service Price = 0?**
      - **YES** → Create payment record (amount = 0)
      - **NO** → Calculate payment
        ↓
        **Calculate Amount Due**
        - amount_due = full_price - amount_paid
        ↓
        **Determine Payment Amount**
        - pay_amount = MIN(amount_due, available_payment)
        ↓
        **Update Order Entry**
        - amount_paid += pay_amount
        ↓
        **Create Order Payment Record**
        - Link to receipt
        - Record amount paid
        ↓
        **Deduct from Available Payment**
        - available_payment -= pay_amount
  ↓
  **Decision: Use Deposits?**
  - **YES** → Apply Deposit
    ↓
    **Retrieve Patient Deposits** (amount_available > 0)
    ↓
    **For Each Deposit:**
      ↓
      **Calculate Used Amount**
      - used = MIN(deposit.amount_available, remaining_payment)
      ↓
      **Update Deposit**
      - amount_available -= used
      ↓
      **Deduct from Payment**
      - remaining_payment -= used
  ↓
  **Calculate Change**
  - change = remaining_payment
  ↓
  **Decision: Patient Age > 5 years?**
  - **YES** → Print Receipt
  - **NO** → Skip printing
  ↓
  **End** → Patient Dashboard

---
## 6) Void/Cancel Transactions

### A) Void Order Entries
**Start** (from Patient Dashboard)
↓
**Select Orders to Void**
↓
**Enter Void Reason**
↓
**For Each Order:**
  ↓
  **Mark Order as Voided**
  - voided = true
  - voided_by = current_user
  - voided_reason = reason
↓
**End** → Patient Dashboard

### B) Void Payments
**Start** (from Patient Dashboard)
↓
**Select Paid Orders to Void**
↓
**Enter Void Reason**
↓
**Collect Receipt Numbers**
↓
**For Each Order:**
  ↓
  **Void All Payments**
  - Mark payment as voided
  ↓
  **Void Order Entry**
  - Mark order as voided
↓
**Mark Original Receipts as Voided**
↓
**Decision: Other Payments on Same Receipt?**
- **NO** → End
- **YES** → Reissue Receipt
  ↓
  **Create New Receipt**
  ↓
  **Transfer Remaining Payments** to new receipt
  ↓
  **Print New Receipt**
  ↓
  **End** → Patient Dashboard

---

## 7) Reports & Summaries

### Available Reports:
1. **Income Summary** (by date range)
   - Total revenue by service category
   - Payment modes breakdown

2. **Cashier Summary** (by cashier, date range)
   - Individual cashier collections
   - Payment modes per cashier

3. **Daily Cash Summary** (by date)
   - Total collections
   - Cash vs other payment modes
   - Deposits received

4. **Census Report** (by date range)
   - Patient visits
   - Services rendered
   - Demographics breakdown

5. **Income Listing** (detailed transactions)
   - All payments with details
   - Service-wise breakdown

6. **Cashier Listing** (detailed by cashier)
   - Transaction-level details per cashier

7. **Void Listing** (voided transactions)
   - All voided orders and payments
   - Void reasons and timestamps

---
## 8) Patient Dashboard View

### Dashboard Components:

**Patient Information:**
- Full Name
- National ID
- Date of Birth / Age
- Gender
- Current Address
- Medical Scheme (if any)
- Available Deposits

**Unpaid Orders Section:**
- Service Name
- Quantity
- Full Price
- Amount Paid
- Amount Due
- Status (UNPAID / PARTIAL PAYMENT / PAID)

**Today's Payments:**
- Receipt Numbers
- Payment Amounts
- Payment Times

**Order History:**
- Past orders (before today)
- Services received
- Payment status

**Action Buttons:**
- New Order
- Make Payment
- New Deposit
- Reclaim Deposit
- View Deposits
- Edit Demographics
- Void Orders

---

## Key Data Models & Relationships

### Patient
- person (demographics)
- patient_identifiers (National ID, etc.)
- patient_accounts (medical schemes)
- deposits
- order_entries

### Order Entry
- patient
- service
- quantity
- full_price
- amount_paid
- location (General/Private)
- order_payments
- Status: UNPAID / PARTIAL / PAID

### Order Payment
- order_entry
- receipt
- amount
- cashier
- payment_mode

### Receipt
- receipt_number (format: XXXXXX-YY)
- order_payments
- patient
- cashier
- payment_mode
- payment_stamp

### Deposit
- patient
- amount_received
- amount_available
- creator

### Service
- name
- service_type (category)
- service_prices (General/Private)
- unit

### Medical Scheme
- medical_scheme_provider (insurance company)
- name
- coverage details

---
## Business Rules

1. **Pricing:**
   - Services have two price types: GENERAL and PRIVATE
   - Price determined by service location/clinic type
   - Final price = Service Price × Quantity

2. **Payments:**
   - Partial payments allowed
   - Multiple payments can be made on same order
   - Deposits can be applied to payments
   - Change is calculated and returned
   - Zero-price services generate receipts without payment

3. **Deposits:**
   - Can be made at any time
   - Automatically applied during payment (if selected)
   - Can be reclaimed (refunded)
   - Tracks: amount_received, amount_available

4. **Receipts:**
   - Unique receipt number per transaction
   - Format: XXXXXX-YY (sequence-year)
   - Resets annually
   - Can be voided and reissued

5. **Service Categories:**
   - Age-based filtering (< 5 years = child)
   - Gender-based filtering (male/female services)
   - Service panels (grouped services)

6. **Voiding:**
   - Orders can be voided (with reason)
   - Payments can be voided (with reason)
   - Voided receipts are reissued if other payments exist
   - Audit trail maintained (voided_by, voided_reason)

7. **Medical Schemes:**
   - Optional insurance coverage
   - Linked to patient account
   - Has active period (from/to dates)
   - Scheme number required

8. **Printing:**
   - Receipts printed for adults (age > 5 years)
   - Deposit receipts
   - Refund receipts
   - National ID labels

---

## System Integration

### DDE (Data De-Duplication Engine)
- Optional external patient registry
- Used for patient search and validation
- Prevents duplicate patient records
- Synchronizes patient demographics

### Location Management
- Tracks service location (General/Private)
- Affects pricing
- Used in reporting

### User Management
- Role-based access
- Cashier tracking
- Audit trail for all transactions

---

## Common Workflows

### Scenario 1: New Patient Visit
1. Register patient → 2. Create order → 3. Make payment → 4. Print receipt

### Scenario 2: Returning Patient
1. Search patient → 2. Create order → 3. Make payment → 4. Print receipt

### Scenario 3: Patient with Deposit
1. Patient makes deposit → 2. Create order → 3. Apply deposit to payment → 4. Print receipt

### Scenario 4: Partial Payment
1. Create order → 2. Make partial payment → 3. Return later → 4. Complete payment

### Scenario 5: Void and Correct
1. Identify error → 2. Void transaction → 3. Create new order → 4. Process payment

---

## Error Handling

### Common Errors & Fixes:
- **Patient not found:** Register new patient or search with different criteria
- **Bottle exists:** Check for duplicate orders, void if necessary
- **Pack expired:** Verify service details, update if needed
- **Pack not expired:** Validate order dates
- **Insufficient payment:** Request additional payment or apply deposits
- **Location not set:** Select active location before processing

---

**End of Billing System Workflow Documentation**
