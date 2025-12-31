# frozen_string_literal: true

class MigrateExistingProjects < ActiveRecord::Migration[8.1]
  def up
    # Set existing user as owner of all projects
    user = User.first

    if user
      Project.update_all(owner_id: user.id)

      # Create memberships for owner
      Project.find_each do |project|
        ProjectMembership.create!(
          project: project,
          user: user,
          role: "owner"
        )
      end
    end
  end

  def down
    ProjectMembership.delete_all
    Project.update_all(owner_id: nil)
  end
end
