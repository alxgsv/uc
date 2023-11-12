class CreateFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :files, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.bigint :project_id, null: false, index: true
      t.string :uuid, index: true
      t.string :upload_token
      t.string :source_url
      t.string :access_token, null: false, index: { unique: true }
      t.datetime :expires_at
      t.string :uploadcare_show_response_json
      t.boolean :is_multipart_upload, default: false
      t.boolean :is_multipart_upload_complete, default: false
      t.integer :multipart_upload_part_size
      t.string :multipart_upload_urls_json
      t.string :video_thumbnails_group_uuid
      t.string :status

      t.string :request_id_aws_rekognition_detect_labels
      t.string :request_id_aws_rekognition_moderate
      t.string :request_id_clamav
      t.string :request_id_remove_bg

      t.timestamps
    end
  end
end
