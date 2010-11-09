class FlexibleCriterionAttribute < ActiveRecord::Base
  belongs_to  :flexible_criterion, :class_name => "FlexibleCriterion"
  validates_presence_of :max
  validates_numericality_of :max, :message => "must be a number greater than 0.0", :greater_than => 0.0
  
  DEFAULT_MAX = 1
  
end

