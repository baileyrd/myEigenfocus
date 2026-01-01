# frozen_string_literal: true

class IssueStatusPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can only see statuses from projects they have access to
      scope.joins(:project)
           .merge(Project.accessible_by(user))
    end
  end

  def index?
    # Users can view statuses if they have access to the project
    project_accessible?
  end

  def show?
    project_accessible?
  end

  def create?
    # Users can create statuses if they can edit the project
    project_editable?
  end

  def new?
    create?
  end

  def update?
    # Users can update statuses if they can edit the project
    project_editable?
  end

  def edit?
    update?
  end

  def destroy?
    # Users can delete statuses if they can edit the project
    project_editable?
  end

  private

  def project_accessible?
    record.project.accessible_by?(user)
  end

  def project_editable?
    record.project.editable_by?(user)
  end
end
