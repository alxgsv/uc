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

ActiveRecord::Schema[7.1].define(version: 2023_11_05_071018) do
  create_table "files", id: :string, force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "uuid"
    t.string "upload_token"
    t.string "source_url"
    t.string "access_token", null: false
    t.datetime "expires_at"
    t.string "uploadcare_show_response_json"
    t.boolean "is_chunked_upload", default: false
    t.boolean "is_chunked_upload_complete", default: false
    t.integer "chunked_upload_chunk_size"
    t.string "chunked_upload_urls_json"
    t.string "video_thumbnails_group_uuid"
    t.string "status"
    t.string "request_id_aws_rekognition_detect_labels"
    t.string "request_id_aws_rekognition_moderate"
    t.string "request_id_clamav"
    t.string "request_id_remove_bg"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_files_on_access_token", unique: true
    t.index ["project_id"], name: "index_files_on_project_id"
    t.index ["uuid"], name: "index_files_on_uuid"
  end

  create_table "groups", id: :string, force: :cascade do |t|
    t.string "status", default: "pending", null: false
    t.string "project_id", null: false
    t.string "file_ids", null: false
    t.string "uuid"
    t.string "access_token", null: false
    t.string "uploadcare_show_response_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["access_token"], name: "index_groups_on_access_token"
    t.index ["project_id"], name: "index_groups_on_project_id"
    t.index ["uuid"], name: "index_groups_on_uuid"
  end

  create_table "project_secret_keys", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "secret_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "uuid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "webhooks", id: :string, force: :cascade do |t|
    t.string "project_id", null: false
    t.string "target_url", null: false
    t.string "signing_secret", null: false
    t.string "events", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_webhooks_on_project_id"
  end

end
