# Feature modifications


### 1) `patients/search` UI and search logic

File: `app/views/patients/search.html.erb`  
Controller action: `PatientsController#search`  
Search endpoint: `PatientsController#ajax_search`

- The page has two tabs:
  - **Scan Barcode**: captures scanner/manual barcode input and routes to `/patients/patient_by_id/:identifier?source=scan`.
  - **Manual Entry (Lost Card)**: captures `given_name`, `family_name`, and `gender`, then calls `/patients/ajax_search`.
- Action buttons:
  - `Cancel`=> `/`
  - `New Patient` => `/patients/new` with prefilled query params from manual entry
  - `Clear` => clears active tab inputs/state
  - `Back` => returns to scan/manual previous state (or `/`)
  - `Next` => continues with selected patient
- Manual matching behavior:
  - Local candidates are scored using `classify_duplicate_match`:
    - identifiers and phone 
    - exact/partial names, birthdate, gender, and address fields
  - Match categories:
    - `likely_match` 
    - `possible_match`
    - `no_match` (excluded)
  - flow keeps `source=scan` or `source=manual` and forwards it to demographics/confirm step.

### 2) `patient_demographics` display and confirmation

File: `app/views/patients/patient_demographics.html.erb`  
Controller action: `PatientsController#patient_demographics`

- Controller loads `@person = Patient.find(params[:id]).person`.
- View shows:
  - session user, location, role in the header
  - patient banner (name and ID)
  - core demographics: first/last name, gender, DOB, home district, TA, village

- Footer actions:
  - `Cancel` => `/`
  - `Update Location` => `/patients/:patient_id/edit?field=address2`
  - `Confirm & Add Transaction` => `/patients/:id/confirm_and_proceed?source=<safe_source>`

### 3) Update patient location logic

Edit entry point: `GET /patients/:id/edit?field=address2`  
Update action: `PATCH/PUT /patients/:person_id` via `PatientsController#update`

- For location update (`update_field == 'address2'`):
  - `PersonAddress.where(person_id: person.id).first_or_initialize`
  - updates:
    - `address2` (home district)
    - `county_district` (home T/A)
    - `city_village` (home village)
  - saves address and triggers barcode print redirect.
- Redirect after update returns to:
  - `/patients/patient_demographics/:patient_id`

### 4) Routing changes  endpoints

File: `config/routes.rb`

- Search and scan routes under `patients` collection:
  - `GET /patients/search`
  - `GET /patients/scan`
  - `GET /patients/ajax_search`
- Demographics route:
  - `GET /patients/patient_demographics(/:id)` => `patients#patient_demographics`
- Processing routes:
  - `POST /patients/process_result`
  - `POST /patients/confirm_demographics`
  - `POST /patients/ajax_process_result`
  - `POST /patients/ajax_process_data`
- Patient lookup route used by scan/manual identifier flow:
  - `GET /patients/patient_by_id(/:id)` => `patients#patient_by_id`
- Confirm route used from demographics page:
  - `GET /patients/:id/confirm_and_proceed`
### 5) Add Back to home button to improve user experience
