# frozen_string_literal: true

class DropDelayedJobsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :delayed_jobs, if_exists: true
  end

  def down
    create_table "delayed_jobs" do |t|
      t.integer "priority", default: 0, null: false
      t.integer "attempts", default: 0, null: false
      t.text "handler", null: false
      t.text "last_error"
      t.datetime "run_at"
      t.datetime "locked_at"
      t.datetime "failed_at"
      t.string "locked_by"
      t.string "queue"
      t.timestamps null: true
      
      t.index ["priority", "run_at"], name: "delayed_jobs_priority"
    end
  end
end
