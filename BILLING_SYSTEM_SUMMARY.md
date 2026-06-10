# Hospital Billing System - Executive Summary

## System Purpose
A comprehensive hospital billing management system that handles patient registration, service ordering, payment processing, deposit management, and medical insurance schemes.

## Core Workflows

### 1. Patient Management
- **Registration**: Capture patient demographics, generate National ID
- **Search**: Find patients by ID, name, or demographics
- **DDE Integration**: Optional integration with Data De-Duplication Engine
- **Medical Schemes**: Link patients to insurance providers

### 2. Service Ordering
- **Age/Gender-Based**: Services filtered by patient age and gender
- **Categories**: Consultation, Laboratory, Radiology, Procedures, Admission, Pharmacy
- **Pricing**: Dual pricing (General vs Private clinic)
- **Quantity Calculation**: Automatic calculation for medications (dose × frequency × duration)
- **Service Panels**: Pre-grouped services for common procedures

### 3. Payment Processing
- **Flexible Payments**: Full, partial, or zero-price services
- **Multiple Payment Modes**: Cash, Card, Mobile Money
- **Deposit Application**: Use patient deposits toward bills
- **Receipt Generation**: Unique receipt numbers (format: XXXXXX-YY)
- **Change Calculation**: Automatic change and deposit tracking

### 4. Deposit Management
- **Make Deposits**: Patients can pre-pay amounts
- **Track Usage**: System tracks amount_received vs amount_available
- **Reclaim Deposits**: Refund unused deposits with receipt

### 5. Transaction Management
- **Void Orders**: Cancel orders with reason tracking
- **Void Payments**: Cancel payments and reissue receipts
- **Audit Trail**: Complete tracking of who, what, when, why

## Key Features

### Business Rules
1. **Dual Pricing**: Services have General and Private prices
2. **Partial Payments**: Patients can pay in installments
3. **Zero-Price Services**: Free services still generate receipts
4. **Deposit Priority**: Deposits applied before cash payments
5. **Age-Based Printing**: Receipts only print for patients > 5 years

### Data Integrity
- **Voiding System**: Soft deletes with reason tracking
- **Receipt Reissuing**: Automatic receipt regeneration when partially voided
- **Audit Trail**: Complete history of all transactions
- **User Tracking**: Every action linked to user/cashier

### Reporting
- Income Summary (by date range)
- Cashier Summary (by cashier)
- Daily Cash Summary
- Census Report (patient visits)
- Income Listing (detailed transactions)
- Void Listing (canceled transactions)

## Technical Architecture

### Models
- **Patient**: Demographics, identifiers, accounts, deposits
- **OrderEntry**: Services ordered, pricing, payment status
- **OrderPayment**: Individual payment transactions
- **Receipt**: Payment receipts with unique numbers
- **Deposit**: Patient pre-payments
- **Service**: Service catalog with pricing
- **MedicalScheme**: Insurance provider information

### Key Relationships
```
Patient
  ├─ has_many :order_entries
  ├─ has_many :deposits
  ├─ has_many :patient_accounts (insurance)
  └─ has_one :person (demographics)

OrderEntry
  ├─ belongs_to :patient
  ├─ belongs_to :service
  └─ has_many :order_payments

OrderPayment
  ├─ belongs_to :order_entry
  ├─ belongs_to :receipt
  └─ belongs_to :cashier (User)

Receipt
  ├─ has_many :order_payments
  ├─ belongs_to :patient
  └─ belongs_to :cashier (User)
```

## Workflow States

### Order Entry Status
- **UNPAID**: amount_paid = 0
- **PARTIAL PAYMENT**: 0 < amount_paid < full_price
- **PAID**: amount_paid ≥ full_price

### Payment Flow
1. Create order → Status: UNPAID
2. Make partial payment → Status: PARTIAL PAYMENT
3. Complete payment → Status: PAID
4. Print receipt (if age > 5)

### Deposit Flow
1. Patient makes deposit → amount_available = amount_received
2. Apply to payment → amount_available decreases
3. Reclaim deposit → amount_available = 0, print refund receipt

## Integration Points

### DDE (Data De-Duplication Engine)
- Patient search and validation
- Prevents duplicate patient records
- Synchronizes demographics across facilities

### Location Management
- Determines pricing (General vs Private)
- Used in reporting and analytics
- Tracks service delivery points

### User Management
- Role-based access control
- Cashier assignment and tracking
- Audit trail for all transactions

## Security & Compliance

### Audit Trail
- All transactions tracked by user
- Void reasons required and stored
- Complete history maintained

### Data Validation
- National ID format validation
- Required fields enforcement
- Price calculation verification

### Access Control
- User authentication required
- Role-based permissions
- Location-based access

## Common Use Cases

### Scenario 1: Walk-in Patient
1. Search patient (not found)
2. Register new patient
3. Create service order
4. Process payment
5. Print receipt

### Scenario 2: Patient with Insurance
1. Search patient
2. Link medical scheme
3. Create service order
4. Process payment (with scheme coverage)
5. Print receipt

### Scenario 3: Patient with Deposit
1. Search patient
2. Patient has existing deposit
3. Create service order
4. Apply deposit to payment
5. Print receipt showing deposit usage

### Scenario 4: Correction Needed
1. Identify error in order/payment
2. Void transaction with reason
3. Create corrected order
4. Process new payment
5. Print new receipt

## Performance Considerations

### Optimizations
- Indexed patient searches
- Efficient receipt number generation
- Cached service pricing
- Optimized payment calculations

### Scalability
- Annual receipt number reset
- Archived transaction history
- Efficient database queries
- Minimal external dependencies

## Future Enhancements

### Potential Improvements
1. Online payment integration
2. SMS receipt delivery
3. Insurance claim automation
4. Advanced analytics dashboard
5. Mobile app for patients
6. Inventory integration
7. Appointment scheduling
8. Lab result integration

---

**System Status**: Production-ready
**Technology**: Ruby on Rails
**Database**: MySQL/PostgreSQL
**UI**: Touch-optimized interface
