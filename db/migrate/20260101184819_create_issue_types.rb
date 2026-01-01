class CreateIssueTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :issue_types do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :icon, default: "📋"
      t.string :color, default: "#6B7280"
      t.integer :position, null: false, default: 0
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :issue_types, [:project_id, :name], unique: true
    add_index :issue_types, [:project_id, :position]
  end
end
