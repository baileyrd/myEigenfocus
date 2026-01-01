class Project < ApplicationRecord
  # Attributes
  attribute :use_template, :string

  # Relations - Existing
  has_many :visualizations, dependent: :destroy
  has_many :time_entries, dependent: :destroy
  has_many :issues, dependent: :destroy
  has_many :issue_labels, dependent: :destroy

  # Relations - Multi-user (Phase 1)
  belongs_to :owner, class_name: "User", optional: true
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user

  # Relations - Custom Statuses & Types (Phase 3)
  has_many :issue_statuses, dependent: :destroy
  has_many :issue_types, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :use_template, inclusion: { in: Project::Templatable::Template::AVAILABLE_TEMPLATES }, on: :create, if: -> { use_template.present? }
  before_destroy :ensure_is_archived

  # Scopes
  scope :active, -> { where(archived_at: nil) }
  scope :accessible_by, ->(user) {
    left_joins(:project_memberships)
      .where(project_memberships: { user_id: user.id })
      .or(where(owner_id: user.id))
      .distinct
  }

  # Hooks
  after_create :apply_template, if: -> { use_template.present? }
  after_create :create_owner_membership, if: :owner_id?

  def default_visualization
    visualizations.first_or_create
  end

  def archived?
    archived_at.present?
  end

  def unarchive!
    self.archived_at = nil
    save!
  end

  def archive!
    self.archived_at = Time.current
    save!
  end

  private def apply_template
    template = Project::Templatable::Template.find(use_template)
    Project::Templatable::TemplateApplier.new(self, template).apply
  end

  private def ensure_is_archived
    unless archived?
      errors.add(:base, :must_be_archived_to_destroy)
      throw(:abort)
    end
  end

  # Multi-user methods
  def accessible_by?(user)
    return false unless user
    owner_id == user.id || project_memberships.exists?(user_id: user.id)
  end

  def editable_by?(user)
    return false unless user
    return true if owner_id == user.id
    project_memberships.where(user_id: user.id).where(role: ["owner", "editor"]).exists?
  end

  def membership_for(user)
    project_memberships.find_by(user_id: user.id)
  end

  private def create_owner_membership
    project_memberships.create!(user: owner, role: "owner")
  end
end
