class AddProjectionKeyToGroupings < ActiveRecord::Migration[8.1]
  def change
    add_column :groupings, :projection_key, :string
    add_index :groupings, :projection_key
    add_index :groupings, [:visualization_id, :projection_key], unique: true, where: "projection_key IS NOT NULL"
  end
end
