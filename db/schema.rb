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

ActiveRecord::Schema[7.0].define(version: 2023_08_01_024946) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "school_week_id", null: false
    t.integer "school_period_id"
    t.boolean "verified", default: false, null: false
    t.boolean "attended", default: false, null: false
    t.integer "quarter_bonus", limit: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_week_id"], name: "index_attendances_on_school_week_id"
    t.index ["user_id"], name: "index_attendances_on_user_id"
  end

  create_table "school_weeks", force: :cascade do |t|
    t.integer "week_number", default: 0
    t.integer "cohort_id"
    t.integer "week_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name", limit: 50
    t.string "last_name", limit: 50
    t.string "username", limit: 50
    t.boolean "active", default: true, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "attendances", "school_weeks"
  add_foreign_key "attendances", "users"
end
