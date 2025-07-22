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

ActiveRecord::Schema[7.1].define(version: 2025_07_22_143506) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "entry_tags", force: :cascade do |t|
    t.bigint "journal_entry_id", null: false
    t.bigint "mood_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["journal_entry_id"], name: "index_entry_tags_on_journal_entry_id"
    t.index ["mood_id"], name: "index_entry_tags_on_mood_id"
  end

  create_table "journal_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "title"
    t.text "content"
    t.string "input_type"
    t.date "entry_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ai_mood_label"
    t.text "ai_color_theme"
    t.text "ai_background_style"
    t.text "ai_summary"
    t.index ["user_id"], name: "index_journal_entries_on_user_id"
    t.check_constraint "(input_type::text = ANY (ARRAY['text'::character varying, 'speech'::character varying, 'image'::character varying]::text[])) OR input_type IS NULL", name: "valid_input_type"
  end

  create_table "mood_summaries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "average_mood_summary"
    t.string "dominant_moods"
    t.integer "entry_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_mood_summaries_on_user_id"
  end

  create_table "moods", force: :cascade do |t|
    t.text "category"
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
    t.string "name"
    t.string "surname"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "entry_tags", "journal_entries"
  add_foreign_key "entry_tags", "moods"
  add_foreign_key "journal_entries", "users"
  add_foreign_key "mood_summaries", "users"
end
