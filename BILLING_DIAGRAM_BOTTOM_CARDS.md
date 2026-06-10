# Bottom Cards Content for Billing System Workflow Diagram

## Card 1: Common Errors & Fixes

### Common Errors:
- **Service not found**: Service name doesn't exist in database - verify service name spelling or add service to system
- **Price not configured**: Service price missing for General/Private type - configure service price before ordering
- **Location not set**: Workstation location not selected - select location at login
- **User not authenticated**: Session expired or not logged in - login again
- **DDE connection failed**: Cannot connect to Data De-Duplication Engine - check network or work offline
- **National ID not found**: Patient identifier missing - search by name or register new patient
- **Void reason required**: Cannot void without reason - provide reason for voiding transaction
- **Deposit insufficient**: Not enough deposit balance - patient needs to add more deposit or pay cash

---

## Card 2: Alert Types

### Alert Categories:
- **Invalid user credentials**: Wrong username or password - re-enter login details
- **Invalid workstation location**: Location not selected or invalid - select valid location
- **Patient with that ID not found**: Patient ID doesn't exist - verify ID or register new patient
- **Something went wrong**: General system error - retry operation or contact administrator
- **Username already in use**: Duplicate username during user creation - choose different username
- **Password Mismatch**: Passwords don't match during user creation/update - re-enter matching passwords
- **No entries found**: Attempting to void non-existent orders - verify order selection
- **Transaction added but not printing labels**: Payment processed but printer unavailable - manual print may be needed

---

## Card 3: User Roles & Locations

### User Roles:
- **Cashier**: Process payments, create receipts, manage deposits
- **Receptionist**: Register patients, search records, update demographics
- **Billing Clerk**: Create orders, manage service entries, void transactions
- **Administrator**: Full system access, manage users, configure services and prices
- **Manager**: View reports, approve voids, monitor daily summaries

### Locations:
- **General Clinic**: Standard pricing, general patient services
- **Private Clinic**: Premium pricing, private patient services
- **Laboratory**: Lab tests and diagnostic services
- **Radiology**: Imaging and X-ray services
- **Pharmacy**: Medication dispensing
- **Admission Ward**: Inpatient services and bed charges
- **Outpatient Department (OPD)**: Consultation and minor procedures
