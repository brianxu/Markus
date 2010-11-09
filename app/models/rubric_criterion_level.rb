class RubricCriterionLevel < ActiveRecord::Base
#  attr_accessor :level_name, :level_description, :level_index
  belongs_to :rubric_criterion
  validates_associated :rubric_criterion, :message => "must have a rubric criterion"
  validates_presence_of :rubric_criterion_id, :message => "must have a rubric criterion id"
  validates_presence_of :level_name, :message => "must have a level name"
  validates_uniqueness_of :level_name, :scope => :rubric_criterion_id, :message => "is already taken"

end
