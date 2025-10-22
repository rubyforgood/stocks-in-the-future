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

ActiveRecord::Schema[8.0].define(version: 2025_10_22_024557) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "announcements", force: :cascade do |t|
    t.string "title"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_announcements_on_created_at", order: :desc
  end

  create_table "classrooms", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "school_year_id"
    t.integer "grade"
    t.boolean "archived", default: false, null: false
    t.boolean "trading_enabled", default: false, null: false
    t.index ["school_year_id"], name: "index_classrooms_on_school_year_id"
  end

  create_table "grade_books", force: :cascade do |t|
    t.bigint "quarter_id", null: false
    t.bigint "classroom_id", null: false
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_grade_books_on_classroom_id"
    t.index ["quarter_id", "classroom_id"], name: "index_grade_books_on_quarter_id_and_classroom_id", unique: true
    t.index ["quarter_id"], name: "index_grade_books_on_quarter_id"
  end

  create_table "grade_entries", force: :cascade do |t|
    t.bigint "grade_book_id", null: false
    t.bigint "user_id", null: false
    t.string "math_grade"
    t.string "reading_grade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "attendance_days"
    t.boolean "is_perfect_attendance", default: false, null: false
    t.index ["grade_book_id", "user_id"], name: "index_grade_entries_on_grade_book_id_and_user_id", unique: true
    t.index ["grade_book_id"], name: "index_grade_entries_on_grade_book_id"
    t.index ["user_id"], name: "index_grade_entries_on_user_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "stock_id", null: false
    t.decimal "shares"
    t.integer "status", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "portfolio_stock_id"
    t.bigint "portfolio_transaction_id"
    t.string "action", null: false
    t.index ["portfolio_stock_id"], name: "index_orders_on_portfolio_stock_id"
    t.index ["portfolio_transaction_id"], name: "index_orders_on_portfolio_transaction_id"
    t.index ["stock_id"], name: "index_orders_on_stock_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "portfolio_snapshots", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.date "date", null: false
    t.integer "worth_cents", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "date"], name: "index_portfolio_snapshots_on_portfolio_id_and_date", unique: true
    t.index ["portfolio_id"], name: "index_portfolio_snapshots_on_portfolio_id"
  end

  create_table "portfolio_stocks", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.bigint "stock_id", null: false
    t.decimal "shares", precision: 15, scale: 2
    t.decimal "purchase_price", precision: 15, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "stock_id"], name: "index_portfolio_stocks_on_portfolio_and_stock"
    t.index ["portfolio_id"], name: "index_portfolio_stocks_on_portfolio_id"
    t.index ["stock_id"], name: "index_portfolio_stocks_on_stock_id"
  end

  create_table "portfolio_transactions", force: :cascade do |t|
    t.bigint "portfolio_id", null: false
    t.integer "transaction_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount_cents", null: false
    t.string "reason"
    t.text "description"
    t.index ["portfolio_id"], name: "index_portfolio_transactions_on_portfolio_id"
  end

  create_table "portfolios", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.float "current_position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_portfolios_on_user_id"
  end

  create_table "quarters", force: :cascade do |t|
    t.string "name"
    t.bigint "school_year_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "number", null: false
    t.index ["school_year_id", "number"], name: "index_quarters_on_school_year_id_and_number", unique: true
    t.index ["school_year_id"], name: "index_quarters_on_school_year_id"
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

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
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
    t.integer "price_cents"
    t.boolean "archived", default: false, null: false
    t.integer "yesterday_price_cents"
    t.index ["ticker"], name: "index_stocks_on_ticker", unique: true
  end

  create_table "teacher_classrooms", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.bigint "classroom_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classroom_id"], name: "index_teacher_classrooms_on_classroom_id"
    t.index ["teacher_id", "classroom_id"], name: "index_teacher_classrooms_on_teacher_id_and_classroom_id", unique: true
    t.index ["teacher_id"], name: "index_teacher_classrooms_on_teacher_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "username", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "classroom_id"
    t.boolean "admin", default: false
    t.string "type", default: "User", null: false
    t.datetime "discarded_at"
    t.string "name"
    t.index ["classroom_id"], name: "index_users_on_classroom_id"
    t.index ["discarded_at"], name: "index_users_on_discarded_at"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "((email IS NOT NULL) AND ((email)::text <> ''::text))"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "years", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_years_on_name", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "classrooms", "school_years"
  add_foreign_key "grade_books", "classrooms"
  add_foreign_key "grade_books", "quarters"
  add_foreign_key "grade_entries", "grade_books"
  add_foreign_key "grade_entries", "users"
  add_foreign_key "orders", "portfolio_stocks"
  add_foreign_key "orders", "portfolio_transactions"
  add_foreign_key "orders", "stocks"
  add_foreign_key "orders", "users"
  add_foreign_key "portfolio_snapshots", "portfolios"
  add_foreign_key "portfolio_stocks", "portfolios"
  add_foreign_key "portfolio_stocks", "stocks"
  add_foreign_key "portfolio_transactions", "portfolios"
  add_foreign_key "portfolios", "users"
  add_foreign_key "quarters", "school_years"
  add_foreign_key "school_years", "schools"
  add_foreign_key "school_years", "years"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "teacher_classrooms", "classrooms"
  add_foreign_key "teacher_classrooms", "users", column: "teacher_id"
  add_foreign_key "users", "classrooms"
end
