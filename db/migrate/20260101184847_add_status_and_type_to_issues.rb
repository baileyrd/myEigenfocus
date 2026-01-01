class AddStatusAndTypeToIssues < ActiveRecord::Migration[8.1]
  def change
    add_reference :issues, :issue_status, foreign_key: true, index: true
    add_reference :issues, :issue_type, foreign_key: true, index: true
  end
end
