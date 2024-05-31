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

ActiveRecord::Schema[7.1].define(version: 2024_05_31_175716) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "classrooms", force: :cascade do |t|
    t.string "name"
    t.bigint "year_id", null: false
    t.bigint "school_id", null: false
    t.string "grade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id"], name: "index_classrooms_on_school_id"
    t.index ["year_id"], name: "index_classrooms_on_year_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "stock_id", null: false
    t.decimal "shares"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_orders_on_stock_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "portfolio_stocks", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.bigint "stock_id", null: false
    t.float "shares"
    t.float "purchase_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "stock_id"], name: "index_portfolio_stocks_on_portfolio_and_stock", unique: true
    t.index ["portfolio_id"], name: "index_portfolio_stocks_on_portfolio_id"
    t.index ["stock_id"], name: "index_portfolio_stocks_on_stock_id"
  end

  create_table "portfolio_transactions", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.integer "transaction_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "amount", precision: 8, scale: 2, null: false
    t.index ["portfolio_id"], name: "index_portfolio_transactions_on_portfolio_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.float "current_position"
    t.json "transactions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "school_years", force: :cascade do |t|
    t.bigint "school_id", null: false
    t.bigint "year_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_id", "year_id"], name: "index_school_years_on_school_id_and_year_id", unique: true
    t.index ["school_id"], name: "index_school_years_on_school_id"
    t.index ["year_id"], name: "index_school_years_on_year_id"
  end

  create_table "schools", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stocks", force: :cascade do |t|
    t.string "ticker"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "stock_exchange"
    t.string "company_name"
    t.string "company_website"
    t.text "description"
    t.string "industry"
    t.text "management"
    t.integer "employees"
    t.text "competitor_names"
    t.decimal "sales_growth", precision: 15, scale: 2
    t.decimal "industry_avg_sales_growth", precision: 15, scale: 2
    t.decimal "debt_to_equity", precision: 15, scale: 2
    t.decimal "industry_avg_debt_to_equity", precision: 15, scale: 2
    t.decimal "profit_margin", precision: 15, scale: 2
    t.decimal "industry_avg_profit_margin", precision: 15, scale: 2
    t.decimal "cash_flow", precision: 15, scale: 2
    t.decimal "debt", precision: 15, scale: 2
    t.decimal "price"
    t.index ["ticker"], name: "index_stocks_on_ticker", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: ""
    t.string "username", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "classroom_id"
    t.index ["classroom_id"], name: "index_users_on_classroom_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "years", force: :cascade do |t|
    t.integer "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["year"], name: "index_years_on_year", unique: true
  end

  add_foreign_key "classrooms", "schools"
  add_foreign_key "classrooms", "years"
  add_foreign_key "orders", "stocks"
  add_foreign_key "orders", "users"
  add_foreign_key "portfolio_stocks", "portfolios"
  add_foreign_key "portfolio_stocks", "stocks"
  add_foreign_key "portfolio_transactions", "portfolios"
  add_foreign_key "portfolios", "users"
  add_foreign_key "school_years", "schools"
  add_foreign_key "school_years", "years"
  add_foreign_key "users", "classrooms"
end
