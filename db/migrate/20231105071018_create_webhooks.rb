class CreateWebhooks < ActiveRecord::Migration[7.1]
  def change
    create_table :webhooks, id: false do |t|
      t.string :id, primary_key: true
      t.string :project_id, null: false, index: true
      t.string :target_url, null: false
      t.string :signing_secret, null: false
      t.string :events, null: false
      t.string :version, null: false, default: "1"
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
  end
end
