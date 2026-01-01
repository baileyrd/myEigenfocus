# frozen_string_literal: true

class ProjectMembershipPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can only see memberships for projects they own
      scope.joins(:project)
           .where(projects: { owner_id: user.id })
    end
  end

  def index?
    # Users can view memberships if they own the project
    project_owner?
  end

  def show?
    # Users can view membership if they own the project
    project_owner?
  end

  def create?
    # Only project owners can add members
    project_owner?
  end

  def new?
    create?
  end

  def update?
    # Only project owners can update member roles
    project_owner?
  end

  def edit?
    update?
  end

  def destroy?
    # Only project owners can remove members
    project_owner?
  end

  private

  def project_owner?
    record.project.owner_id == user.id
  end
end
