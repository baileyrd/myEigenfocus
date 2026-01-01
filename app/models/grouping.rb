class Grouping < ApplicationRecord
  # Associations
  belongs_to :visualization
  has_one :project, through: :visualization
  has_many :allocations, -> { order(position: :asc) },
            foreign_key: "grouping_id",
            class_name: "GroupingIssueAllocation",
            dependent: :destroy
  has_many :issues, through: :allocations

  positioned on: :visualization, column: :position

  # Validations
  validates :title, presence: true
  validates :projection_key, uniqueness: { scope: :visualization_id }, allow_nil: true

  # Broadcasts
  after_create_commit -> {
    broadcast_append_later_to(
      visualization,
      partial: "visualizations/column",
      locals: {
        grouping: self,
        visualization: visualization
      },
      target: "js-kanban-board"
    )
  }
  after_update_commit -> {
    broadcast_replace_later_to(
      visualization,
      partial: "visualizations/column",
      locals: {
        grouping: self,
        visualization: visualization
      }
    )
  }, unless: :saved_change_to_position?
  after_update_commit -> {
    Visualizations::GroupingsChannel.broadcast_update(self)
  }
  after_destroy_commit -> { broadcast_remove_to visualization }

  def self.ransackable_attributes(auth_object = nil)
    [ "title" ]
  end

  def allocate_issue(issue)
    allocations.create(issue: issue, position: :last)
  end

  # Phase 4: Projection helpers
  def auto_generated?
    projection_key.present?
  end

  def manual?
    projection_key.nil?
  end

  def projected_issues
    return [] unless auto_generated?
    return [] unless visualization.projection_mode?

    case visualization.group_by
    when "status"
      status_id = projection_key.split("_").last.to_i
      project.issues.where(issue_status_id: status_id)
    when "assignee"
      if projection_key == "assignee_unassigned"
        project.issues.unassigned
      else
        user_id = projection_key.split("_").last.to_i
        project.issues.assigned_to(User.find(user_id))
      end
    when "type"
      type_id = projection_key.split("_").last.to_i
      project.issues.where(issue_type_id: type_id)
    when "label"
      label_id = projection_key.split("_").last.to_i
      project.issues.joins(:labels).where(issue_labels: { id: label_id })
    else
      []
    end
  end
end
