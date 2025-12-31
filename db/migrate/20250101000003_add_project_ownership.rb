# frozen_string_literal: true

class AddProjectOwnership < ActiveRecord::Migration[8.1]
  def change
    # Add owner to projects
    add_reference :projects, :owner, foreign_key: { to_table: :users }, index: true

    # Create project memberships table
    create_table :project_memberships do |t|
      t.references :project, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.string :role, null: false, default: "viewer"
      # Roles: owner, editor, viewer

      t.timestamps
    end

    # Unique constraint: one membership per user per project
    add_index :project_memberships, [:project_id, :user_id], unique: true
  end
end
