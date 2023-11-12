class CreateGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :groups, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :status, null: false, default: "pending"
      t.string :project_id, null: false, index: true
      t.string :file_ids, null: false
      t.string :uuid, index: true
      t.string :access_token, null: false, index: true
      t.string :uploadcare_show_response_json

      t.timestamps
    end
  end
end
