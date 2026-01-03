class AddMultiUserSupport < ActiveRecord::Migration[8.1]
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

    # Add user tracking to issues
    add_reference :issues, :creator, foreign_key: { to_table: :users }, index: true
    add_reference :issues, :assigned_user, foreign_key: { to_table: :users }, index: true

    # Migrate existing data
    reversible do |dir|
      dir.up do
        # Get the first (admin) user
        admin_user = execute("SELECT id FROM users ORDER BY id ASC LIMIT 1").first

        if admin_user
          admin_id = admin_user['id']

          # Set all existing projects to be owned by admin
          execute "UPDATE projects SET owner_id = #{admin_id} WHERE owner_id IS NULL"

          # Create project memberships for admin as owner of all projects
          execute <<-SQL
            INSERT INTO project_memberships (project_id, user_id, role, created_at, updated_at)
            SELECT id, #{admin_id}, 'owner', datetime('now'), datetime('now')
            FROM projects
          SQL

          # Set all existing issues to be created by admin
          execute "UPDATE issues SET creator_id = #{admin_id} WHERE creator_id IS NULL"
        end
      end
    end
  end
end
