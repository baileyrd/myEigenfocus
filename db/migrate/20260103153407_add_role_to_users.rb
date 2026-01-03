class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, default: "member", null: false
    add_index :users, :role

    # Set existing users to admin role
    reversible do |dir|
      dir.up do
        # Set the first user (or all existing users) to admin
        execute "UPDATE users SET role = 'admin' WHERE id = (SELECT MIN(id) FROM users)"
      end
    end
  end
end
