module VisualizationsHelper
  # Phase 5: Grid View Helper Methods

  def issues_data(visualization)
    visualization.project.issues.map do |issue|
      {
        id: issue.id,
        title: issue.title,
        issue_status_id: issue.issue_status_id,
        issue_type_id: issue.issue_type_id,
        assigned_user_id: issue.assigned_user_id,
        due_date: issue.due_date&.iso8601,
        created_at: issue.created_at.iso8601,
        updated_at: issue.updated_at.iso8601
      }
    end
  end

  def statuses_data(project)
    project.issue_statuses.ordered.map do |status|
      {
        id: status.id,
        name: status.name,
        color: status.color,
        is_default: status.is_default,
        is_closed: status.is_closed
      }
    end
  end

  def types_data(project)
    project.issue_types.ordered.map do |type|
      {
        id: type.id,
        name: type.name,
        icon: type.icon,
        color: type.color,
        is_default: type.is_default
      }
    end
  end

  def members_data(project)
    project.members.map do |user|
      {
        id: user.id,
        name: user.display_name,
        email: user.email,
        initials: user.initials
      }
    end
  end
end
