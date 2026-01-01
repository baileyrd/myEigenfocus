class ProjectMembership < ApplicationRecord
  # Enums
  enum :role, {
    owner: "owner",
    editor: "editor",
    viewer: "viewer"
  }

  # Associations
  belongs_to :project
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :project_id, message: "is already a member of this project" }
  validates :role, presence: true

  # Scopes
  scope :owners, -> { where(role: "owner") }
  scope :editors, -> { where(role: "editor") }
  scope :viewers, -> { where(role: "viewer") }

  # Permission methods
  def can_edit?
    owner? || editor?
  end

  def can_manage_members?
    owner?
  end

  def can_delete_project?
    owner?
  end
end
