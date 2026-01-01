class User < ApplicationRecord
  # Devise modules for authentication
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  # Enums
  enum :role, { member: "member", admin: "admin" }

  # Relations - Existing
  has_many :time_entries
  has_many :running_time_entries, -> { running }, class_name: "TimeEntry"
  has_one :preferences, class_name: "User::Preferences"

  # Relations - Multi-user (Phase 1)
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :owned_projects, class_name: "Project", foreign_key: :owner_id, dependent: :destroy
  has_many :created_issues, class_name: "Issue", foreign_key: :creator_id, dependent: :nullify
  has_many :assigned_issues, class_name: "Issue", foreign_key: :assigned_user_id, dependent: :nullify

  # Validations
  validates :locale,
    inclusion: { in:  I18n.available_locales.map(&:to_s) },
    if: -> { locale.present? }

  validates :timezone,
    inclusion: { in:  ActiveSupport::TimeZone.all.map(&:name) },
    if: -> { timezone.present? }

  validates :role, presence: true

  def is_profile_complete?
    locale.present? and
    timezone.present?
  end

  def preferences
    super || build_preferences
  end

  # Multi-user methods
  def admin?
    role == "admin"
  end

  def display_name
    name.presence || email.split("@").first
  end

  def initials
    if name.present?
      name.split.map(&:first).join.upcase[0..1]
    else
      email[0..1].upcase
    end
  end
end
