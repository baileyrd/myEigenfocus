class Visualization < ApplicationRecord
  self.inheritance_column = "_type"

  VALID_TYPES = [ "board" ]
  VALID_GROUP_BY = [ "manual", "status", "assignee", "type", "label" ]

  # Associations
  belongs_to :project
  has_many :groupings, -> { order(position: :asc) }, dependent: :destroy

  # Validations
  validates :type, inclusion: { in: VALID_TYPES }
  validates :group_by, inclusion: { in: VALID_GROUP_BY }

  # Scopes
  scope :manual_grouping, -> { where(group_by: "manual") }
  scope :projected, -> { where.not(group_by: "manual") }
  scope :auto_generated, -> { where(auto_generate_groups: true) }

  # Callbacks (Phase 4)
  after_save :sync_projection_groups, if: -> { saved_change_to_group_by? && auto_generate_groups? }

  # Broadcasts
  after_update_commit :broadcast_favorite_issue_labels, if: -> { saved_change_to_favorite_issue_labels? }
  def broadcast_favorite_issue_labels
    broadcast_replace_later_to(
      self,
      targets: "[data-visualization-favorite-labels-list='#{id}']".html_safe,
      partial: "visualizations/favorite_labels_dropdown_list",
      locals: { visualization: self }
    )
  end

  # Phase 4: Projection methods
  def projection_mode?
    group_by != "manual"
  end

  def manual_mode?
    group_by == "manual"
  end

  def grouped_issues
    case group_by
    when "status"
      group_by_status
    when "assignee"
      group_by_assignee
    when "type"
      group_by_type
    when "label"
      group_by_label
    else
      {}
    end
  end

  private

  def sync_projection_groups
    return unless projection_mode?

    # Synchronize groupings based on projection type
    case group_by
    when "status"
      sync_status_groups
    when "assignee"
      sync_assignee_groups
    when "type"
      sync_type_groups
    when "label"
      sync_label_groups
    end
  end

  def group_by_status
    project.issue_statuses.ordered.index_with do |status|
      project.issues.where(issue_status: status)
    end
  end

  def group_by_assignee
    # Group by assigned user + unassigned
    assigned_groups = project.members.index_with do |user|
      project.issues.assigned_to(user)
    end
    assigned_groups.merge("Unassigned" => project.issues.unassigned)
  end

  def group_by_type
    project.issue_types.ordered.index_with do |type|
      project.issues.where(issue_type: type)
    end
  end

  def group_by_label
    project.issue_labels.index_with do |label|
      project.issues.joins(:labels).where(issue_labels: { id: label.id })
    end
  end

  def sync_status_groups
    project.issue_statuses.ordered.each_with_index do |status, index|
      groupings.find_or_create_by!(projection_key: "status_#{status.id}") do |g|
        g.title = status.name
        g.position = index
      end
    end
    # Remove groupings for deleted statuses
    groupings.where("projection_key LIKE 'status_%'")
             .where.not(projection_key: project.issue_statuses.pluck(:id).map { |id| "status_#{id}" })
             .destroy_all
  end

  def sync_assignee_groups
    # Create groups for each project member
    project.members.each_with_index do |user, index|
      groupings.find_or_create_by!(projection_key: "assignee_#{user.id}") do |g|
        g.title = user.display_name
        g.position = index
      end
    end
    # Unassigned group
    groupings.find_or_create_by!(projection_key: "assignee_unassigned") do |g|
      g.title = "Unassigned"
      g.position = project.members.count
    end
    # Remove groupings for removed members
    valid_keys = project.members.pluck(:id).map { |id| "assignee_#{id}" } + ["assignee_unassigned"]
    groupings.where("projection_key LIKE 'assignee_%'")
             .where.not(projection_key: valid_keys)
             .destroy_all
  end

  def sync_type_groups
    project.issue_types.ordered.each_with_index do |type, index|
      groupings.find_or_create_by!(projection_key: "type_#{type.id}") do |g|
        g.title = "#{type.icon} #{type.name}"
        g.position = index
      end
    end
    # Remove groupings for deleted types
    groupings.where("projection_key LIKE 'type_%'")
             .where.not(projection_key: project.issue_types.pluck(:id).map { |id| "type_#{id}" })
             .destroy_all
  end

  def sync_label_groups
    project.issue_labels.each_with_index do |label, index|
      groupings.find_or_create_by!(projection_key: "label_#{label.id}") do |g|
        g.title = label.title
        g.position = index
      end
    end
    # Remove groupings for deleted labels
    groupings.where("projection_key LIKE 'label_%'")
             .where.not(projection_key: project.issue_labels.pluck(:id).map { |id| "label_#{id}" })
             .destroy_all
  end
end
