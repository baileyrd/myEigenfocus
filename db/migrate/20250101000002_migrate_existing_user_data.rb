# frozen_string_literal: true

class MigrateExistingUserData < ActiveRecord::Migration[8.1]
  def up
    # Get the existing single user
    user = User.first

    if user && user.email.blank?
      # Use environment variables or defaults
      email = ENV.fetch("ADMIN_EMAIL", "admin@eigenfocus.local")
      password = ENV.fetch("ADMIN_PASSWORD") { SecureRandom.hex(16) }

      user.update!(
        email: email,
        password: password,
        password_confirmation: password,
        name: "Admin User",
        role: "admin"
      )

      # Log credentials for first-time setup
      Rails.logger.info "=" * 80
      Rails.logger.info "ADMIN USER CREATED:"
      Rails.logger.info "Email: #{email}"
      Rails.logger.info "Password: #{password}" unless ENV["ADMIN_PASSWORD"]
      Rails.logger.info "IMPORTANT: Change this password after first login!"
      Rails.logger.info "=" * 80

      # Also output to console
      puts "=" * 80
      puts "ADMIN USER CREATED:"
      puts "Email: #{email}"
      puts "Password: #{password}" unless ENV["ADMIN_PASSWORD"]
      puts "IMPORTANT: Change this password after first login!"
      puts "=" * 80
    end
  end

  def down
    # No rollback needed
  end
end
