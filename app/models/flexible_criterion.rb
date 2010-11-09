require 'fastercsv'
require 'csv'
# Represents a flexible criterion used to mark an assignment that
# has the marking_scheme_type attribute set to 'flexible'. 
class FlexibleCriterion < Criterion
  has_one :flexible_criterion_attributes, :class_name => "FlexibleCriterionAttribute"
  accepts_nested_attributes_for :flexible_criterion_attributes
  default_scope :include => :flexible_criterion_attributes
  
#  before_save :update_assigned_groups_count

  DEFAULT_MAX = 1
  
  # Instantiate a FlexibleCriterion from a CSV row and attach it to the supplied
  # assignment.
  #
  # ===Params:
  #
  # row::         An array representing one CSV file row. Should be in the following
  #               format: [name, max, description] where description is optional.
  # assignment::  The assignment to which the newly created criterion should belong.
  #
  # ===Raises:
  #
  # CSV::IllegalFormatError:: If the row does not contains enough information, if the max value
  #                           is zero (or doesn't evaluate to a float) or if the
  #                           supplied name is not unique.
  def create_or_update_from_csv_row(row)
    if row.length < 2
      raise CSV::IllegalFormatError.new(I18n.t('criteria_csv_error.incomplete_row'))
    end
    working_row = row.clone
    criterion_name = working_row.shift
    # If a FlexibleCriterion of the same name exits, load it up.  Otherwise,
    # create a new one.
    criterion = FlexibleCriterion.find_or_create_by_criterion_name_and_assignment_id(criterion_name,assignment.id)
    attribute = FlexibleCriterionAttribute.find_or_create_by_flexible_criterion_id(criterion.id)
    attribute.max = working_row.shift
    if attribute.max == 0
      raise CSV::IllegalFormatError.new(I18n.t('criteria_csv_error.max_zero'))
    end
    
    criterion.flexible_criterion_attributes = attribute
    criterion.description = working_row.shift
    criterion.weight = FlexibleCriterion::DEFAULT_WEIGHT
    # Only set the position if this is a new record.
    if criterion.new_record?
      criterion.position = assignment.next_criterion_position
    end
    
    if !criterion.save
      raise CSV::IllegalFormatError.new(criterion.errors)
    end
    
    return criterion
  end
  
  # Create a CSV string from all the rubric criteria related to an assignment.
  #
  # ===Returns:
  #
  # A string. See create_or_update_from_csv_row for format reference.
  def read_csv_row_for_download
    csv_string = FasterCSV.generate do |csv|
      criterion_array = [self.criterion_name, self.flexible_criterion_attributes.max,
                        self.description]
      csv << criterion_array
    end
    
    return csv_string
  end
  
  def get_weight
    return 1
  end
  
end
