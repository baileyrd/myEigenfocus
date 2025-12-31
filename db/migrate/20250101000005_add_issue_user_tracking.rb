# frozen_string_literal: true

class AddIssueUserTracking < ActiveRecord::Migration[8.1]
  def change
    add_reference :issues, :creator, foreign_key: { to_table: :users }, index: true
    add_reference :issues, :assigned_user, foreign_key: { to_table: :users }, index: true
  end
end
