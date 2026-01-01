class AddProjectionFieldsToVisualizations < ActiveRecord::Migration[8.1]
  def change
    add_column :visualizations, :group_by, :string, default: "manual"
    add_column :visualizations, :auto_generate_groups, :boolean, default: false, null: false

    add_index :visualizations, [:project_id, :group_by]
  end
end
