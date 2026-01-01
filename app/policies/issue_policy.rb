# frozen_string_literal: true

class IssuePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      # Users can only see issues from projects they have access to
      scope.joins(:project)
           .merge(Project.accessible_by(user))
    end
  end

  def index?
    # Users can view issues if they have access to the project
    project_accessible?
  end

  def show?
    # Users can view issues if they have access to the project
    project_accessible?
  end

  def create?
    # Users can create issues if they can edit the project
    project_editable?
  end

  def new?
    create?
  end

  def update?
    # Users can update issues if they can edit the project
    project_editable?
  end

  def edit?
    update?
  end

  def destroy?
    # Users can delete issues if they can edit the project
    project_editable?
  end

  def archive?
    # Users can archive issues if they can edit the project
    project_editable?
  end

  def unarchive?
    # Users can unarchive issues if they can edit the project
    project_editable?
  end

  def finish?
    # Users can finish issues if they can edit the project
    project_editable?
  end

  def unfinish?
    # Users can unfinish issues if they can edit the project
    project_editable?
  end

  def update_description?
    # Users can update description if they can edit the project
    project_editable?
  end

  def pick_grouping?
    # Users can pick grouping if they can edit the project
    project_editable?
  end

  def add_label?
    # Users can add labels if they can edit the project
    project_editable?
  end

  def remove_label?
    # Users can remove labels if they can edit the project
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
