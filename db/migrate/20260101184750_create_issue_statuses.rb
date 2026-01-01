class CreateIssueStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :issue_statuses do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, default: "#6B7280"
      t.integer :position, null: false, default: 0
      t.boolean :is_default, default: false, null: false
      t.boolean :is_closed, default: false, null: false

      t.timestamps
    end

    add_index :issue_statuses, [:project_id, :name], unique: true
    add_index :issue_statuses, [:project_id, :position]
  end
end
