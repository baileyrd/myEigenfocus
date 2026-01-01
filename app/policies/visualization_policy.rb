# frozen_string_literal: true

class VisualizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can only see visualizations from projects they have access to
      scope.joins(:project)
           .merge(Project.accessible_by(user))
    end
  end

  def index?
    # Users can view visualizations if they have access to the project
    project_accessible?
  end

  def show?
    project_accessible?
  end

  def create?
    # Users can create visualizations if they can edit the project
    project_editable?
  end

  def new?
    create?
  end

  def update?
    # Users can update visualizations if they can edit the project
    project_editable?
  end

  def edit?
    update?
  end

  def destroy?
    # Users can delete visualizations if they can edit the project
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
