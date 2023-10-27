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

ActiveRecord::Schema[7.1].define(version: 2023_08_11_165329) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "academic_years", force: :cascade do |t|
    t.text "year_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cohorts", force: :cascade do |t|
    t.text "name", null: false
    t.bigint "school_id", null: false
    t.bigint "academic_year_id", null: false
    t.integer "grade_level", null: false
    t.bigint "teacher_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["academic_year_id"], name: "index_cohorts_on_academic_year_id"
    t.index ["school_id"], name: "index_cohorts_on_school_id"
    t.index ["teacher_id"], name: "index_cohorts_on_teacher_id"
  end

  create_table "school_periods", force: :cascade do |t|
    t.integer "period_number"
    t.integer "cohort_id", null: false
    t.integer "school_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "school_weeks", force: :cascade do |t|
    t.integer "week_number", default: 0
    t.integer "cohort_id"
    t.integer "school_period_id", null: false
    t.integer "week_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schools", force: :cascade do |t|
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "academic_year_id", null: false
    t.index ["academic_year_id"], name: "index_schools_on_academic_year_id"
  end

  create_table "student_attendances", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "school_week_id", null: false
    t.boolean "verified"
    t.boolean "attended"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_week_id"], name: "index_student_attendances_on_school_week_id"
    t.index ["student_id"], name: "index_student_attendances_on_student_id"
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
    t.integer "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "weeks", force: :cascade do |t|
    t.integer "academic_year_id", null: false
    t.date "start_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "cohorts", "academic_years"
  add_foreign_key "cohorts", "schools"
  add_foreign_key "cohorts", "users", column: "teacher_id"
  add_foreign_key "schools", "academic_years"
  add_foreign_key "student_attendances", "school_weeks"
  add_foreign_key "student_attendances", "users", column: "student_id"
end
