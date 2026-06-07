# eBilling System

## Recent Changes

### Birthdate Matching in Confirm Demographics
- Character-by-character comparison of captured vs search result birthdates
- Green highlighting for matching characters, red for mismatches
- Match percentage badge on search results (green >=50%, red <50%)
- Search results sorted by match score (best matches first)
- Match Score field added to detail view

### Location Update Flow
- snackbar notification "Location updated. Label printed." after update
- Added `print_and_redirect.html.erb` template for label printing workflow
- Support for `return_url` parameter in redirects

### Dashboard Performance
- Optimized MainController#index queries using `sum()/count()` directly
- Uses covering indexes for range queries on `created_at`, `order_date`, and `payment_stamp`
- Query response time: ~12-13ms

## Configuration

### Environment Variables
- `config/database.yml` - Database configuration (gitignored)
- `config/dde_connection.yml` - DDE service configuration (gitignored)
- `config/globlas.yml` - Global settings (gitignored)
- `config/master.key` - Credentials master key (gitignored)

### Required setup
1. Copy `config/database.yml.example` to `config/database.yml`
2. Configure database connections for `billing_import` and `openmrs`
3. Run `bin/rails db:migrate` for database migrations

## Usage

### Running the application
```bash
bin/rails server
```

### Running tests
```bash
bin/rails test
```

### Database migrations
```bash
bin/rails db:migrate RAILS_ENV=development
```
