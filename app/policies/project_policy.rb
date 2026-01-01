# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can only see projects they own or are members of
      scope.accessible_by(user)
    end
  end

  def index?
    # All authenticated users can view the projects index
    true
  end

  def show?
    # Users can view projects they have access to
    accessible?
  end

  def create?
    # All authenticated users can create projects
    true
  end

  def new?
    create?
  end

  def update?
    # Only project owners and editors can update
    editable?
  end

  def edit?
    update?
  end

  def destroy?
    # Only project owners can delete projects
    owner?
  end

  def archive?
    # Only project owners and editors can archive
    editable?
  end

  def unarchive?
    # Only project owners and editors can unarchive
    editable?
  end

  private

  def owner?
    record.owner_id == user.id
  end

  def accessible?
    record.accessible_by?(user)
  end

  def editable?
    record.editable_by?(user)
  end
end
