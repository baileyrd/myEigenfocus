class IssueStatus < ApplicationRecord
  # Associations
  belongs_to :project
  has_many :issues, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :color, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :ordered, -> { order(:position) }
  scope :default_status, -> { where(is_default: true) }
  scope :closed_statuses, -> { where(is_closed: true) }
  scope :open_statuses, -> { where(is_closed: false) }

  # Callbacks
  before_validation :set_position, on: :create, if: -> { position.nil? }

  # Class methods
  def self.ransackable_attributes(auth_object = nil)
    ["name", "color", "is_default", "is_closed", "created_at", "updated_at"]
  end

  private

  def set_position
    self.position = project.issue_statuses.maximum(:position).to_i + 1
  end
end
