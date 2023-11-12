class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :uuid, null: false
      t.timestamps
    end
  end
end
