class CreateProjectSecretKey < ActiveRecord::Migration[7.1]
  def change
    create_table :project_secret_keys do |t|
      t.bigint :project_id, null: false
      t.string :secret_key, null: false

      t.timestamps
    end
  end
end
