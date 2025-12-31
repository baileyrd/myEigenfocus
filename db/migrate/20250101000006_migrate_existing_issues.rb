# frozen_string_literal: true

class MigrateExistingIssues < ActiveRecord::Migration[8.1]
  def up
    user = User.first

    if user
      # Set existing user as creator for all issues
      Issue.update_all(creator_id: user.id)
    end
  end

  def down
    Issue.update_all(creator_id: nil, assigned_user_id: nil)
  end
end
