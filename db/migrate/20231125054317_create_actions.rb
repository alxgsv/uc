class CreateActions < ActiveRecord::Migration[7.1]
  def change
    create_table :actions, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :file_id, null: false
      t.string :project_id, null: false
      t.string :action_type, null: false

      t.timestamps
    end
  end
end
