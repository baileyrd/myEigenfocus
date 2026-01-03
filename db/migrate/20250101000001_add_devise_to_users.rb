# frozen_string_literal: true

class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    # Devise Database Authenticatable
    add_column :users, :email, :string, null: false, default: ""
    add_column :users, :encrypted_password, :string, null: false, default: ""

    # Devise Recoverable
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime

    # Devise Rememberable
    add_column :users, :remember_created_at, :datetime

    # Devise Trackable
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Additional fields for multi-user
    add_column :users, :name, :string
    add_column :users, :avatar_url, :string
    # Note: role column added separately in 20260103153407_add_role_to_users.rb

    # Indexes
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true

    # Set credentials for existing user (if any exists)
    reversible do |dir|
      dir.up do
        # Update existing user with admin credentials
        if User.exists?
          execute <<-SQL
            UPDATE users
            SET email = 'admin@eigenfocus.local',
                encrypted_password = '$2a$12$8vC0jX9YqGxqYK4vGqK0ZeFjqK5mQp5rZqK5mQp5rZqK5mQp5rZqKu',
                name = 'Admin User'
            WHERE id = (SELECT MIN(id) FROM users)
          SQL
        end
      end
    end
  end
end
