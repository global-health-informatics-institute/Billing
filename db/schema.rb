# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2017_08_21_153231) do

  create_table "deposits", primary_key: "deposit_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "patient_id", null: false
    t.float "amount_received", default: 0.0
    t.float "amount_available", default: 0.0
    t.integer "creator", null: false
    t.integer "updated_by"
    t.boolean "voided", default: false
    t.integer "voided_by"
    t.datetime "date_voided"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "medical_scheme_providers", primary_key: "scheme_provider_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "company_name"
    t.string "company_address"
    t.string "phone_number_1"
    t.string "phone_number_2"
    t.string "email_address"
    t.integer "creator", null: false
    t.boolean "retired", default: false, null: false
    t.integer "retired_by"
    t.string "retired_reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "medical_schemes", primary_key: "medical_scheme_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "medical_scheme_provider", null: false
    t.integer "creator", null: false
    t.boolean "retired", default: false, null: false
    t.integer "retired_by"
    t.string "retired_reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "order_entries", primary_key: "order_entry_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "service_id", null: false
    t.datetime "order_date", null: false
    t.float "quantity", default: 0.0, null: false
    t.float "full_price", default: 0.0, null: false
    t.float "amount_paid", default: 0.0, null: false
    t.integer "cashier", null: false
    t.integer "location"
    t.boolean "voided", default: false
    t.integer "voided_by"
    t.string "voided_reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "order_payments", primary_key: "order_payment_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "receipt_number", null: false
    t.integer "order_entry_id", null: false
    t.float "amount", default: 0.0
    t.integer "cashier", null: false
    t.boolean "voided", default: false
    t.integer "voided_by"
    t.string "voided_reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "patient_accounts", primary_key: "account_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "patient_id", null: false
    t.integer "medical_scheme_id", null: false
    t.date "active_from"
    t.boolean "active", default: true
    t.integer "creator", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "scheme_number"
  end

  create_table "receipts", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "patient_id"
    t.string "receipt_number", null: false
    t.datetime "payment_stamp"
    t.string "payment_mode", default: "CASH", null: false
    t.integer "cashier", null: false
    t.boolean "voided", default: false
    t.integer "voided_by"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "service_panel_details", primary_key: "panel_detail_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "service_panel_id"
    t.integer "service_id"
    t.float "quantity"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "service_panels", primary_key: "service_panel_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "service_type_id", null: false
    t.integer "creator", null: false
    t.boolean "voided", default: false
    t.integer "voided_by"
    t.string "voided_reason"
    t.date "voided_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "service_price_histories", primary_key: "price_history_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "service_id", null: false
    t.float "price", default: 0.0, null: false
    t.string "price_type", null: false
    t.date "active_from", null: false
    t.date "active_to"
    t.integer "creator", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "service_prices", primary_key: "price_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "service_id", null: false
    t.float "price", default: 0.0, null: false
    t.string "price_type", null: false
    t.integer "creator", null: false
    t.integer "updated_by", null: false
    t.boolean "voided", default: false
    t.date "voided_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "service_types", primary_key: "service_type_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "creator", null: false
    t.boolean "retired", default: false, null: false
    t.integer "retired_by"
    t.string "retired_reason"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "services", primary_key: "service_id", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "service_type_id", null: false
    t.string "unit"
    t.integer "rank", default: 999, null: false
    t.integer "creator", null: false
    t.boolean "voided", default: false
    t.integer "voided_by"
    t.string "voided_reason"
    t.date "voided_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
