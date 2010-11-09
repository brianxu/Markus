require 'fastercsv'
require 'csv'

class RubricCriterion < Criterion
  has_many :rubric_criterion_levels, :order => :level_index, :dependent => :delete_all

  def validate_total_weight
    errors.add(:assignment, I18n.t("rubric_criteria.error_total")) if self.assignment.total_mark + (4 * (self.weight - self.weight_was)) <= 0
  end

  # Just a small effort here to remove magic numbers...
  RUBRIC_LEVELS = 5
  DEFAULT_WEIGHT = 1.0
  DEFAULT_LEVELS = [
    {'name'=> I18n.t("rubric_criteria.defaults.level_0"), 'description'=> I18n.t("rubric_criteria.defaults.description_0")},
    {'name'=> I18n.t("rubric_criteria.defaults.level_1"), 'description'=> I18n.t("rubric_criteria.defaults.description_1")},
    {'name'=> I18n.t("rubric_criteria.defaults.level_2"), 'description'=> I18n.t("rubric_criteria.defaults.description_2")},
    {'name'=> I18n.t("rubric_criteria.defaults.level_3"), 'description'=> I18n.t("rubric_criteria.defaults.description_3")},
    {'name'=> I18n.t("rubric_criteria.defaults.level_4"), 'description'=> I18n.t("rubric_criteria.defaults.description_4")}
  ]

  def set_default_levels
    if (rubric_criterion_levels.exists? )
      rubric_criterion_levels.clear
    end
    DEFAULT_LEVELS.each_with_index do |level, index|
      rubric_criterion_levels << RubricCriterionLevel.new(
        {:level_index => index,
         :level_name => level['name'],
         :level_description => level['description']})
    end
  end

  # Set all the level names at once and saves the object.
  #
  # ===Params:
  #
  # levels::  An array containing every level name. A rubric criterion contains
  #           RUBRIC_LEVELS levels. If the array is smaller, only the first levels
  #           are set. If the array is bigger, higher indexes are ignored.
  #
  # ===Returns:
  #
  # Wether the save operation was successful or not.
  def set_level_names(levels)
    levels.each_with_index do |level, index|
      if (index < rubric_criterion_levels.size)
        criterion_level = rubric_criterion_levels[index]
      end
      if (criterion_level.nil?)
        criterion_level = rubric_criterion_levels.create({:level_index => index})
      end
      criterion_level.update_attributes({:level_name => level})
    end
    save
  end

  # Create a CSV string from all the rubric criteria related to an assignment.
  #
  # ===Returns:
  #
  # A string. See create_or_update_from_csv_row for format reference.
  def read_csv_row_for_download
    criterion_array = [criterion_name, criterion.weight]
    rubric_criterion_levels.each do |level|
      criterion_array.push(level.level_name)
    end
    
    rubric_criterion_levels.each do |i|
      criterion_array.push(level.level_descripton)
    end
    return csv_string
  end

  # Instantiate a RubricCriterion from a CSV row and attach it to the supplied
  # assignment.
  #
  # ===Params:
  #
  # row::         An array representing one CSV file row. Should be in the following
  #               format: [name, weight, _names_, _descriptions_] where the _names_ part
  #               must contain RUBRIC_LEVELS elements representing the name of each
  #               level and the _descriptions_ part (optional) can contain up to
  #               RUBRIC_LEVELS description (one for each level).
  # assignment::  The assignment to which the newly created criterion should belong.
  #
  # ===Raises:
  #
  # RuntimeError If the row does not contains enough information, if the weight value
  #                           is zero (or doesn't evaluate to a float)
  def create_or_update_from_csv_row(row)
    if row.length < RUBRIC_LEVELS + 2
      raise I18n.t('criteria_csv_error.incomplete_row')
    end
    working_row = row.clone
    rubric_criterion_name = working_row.shift
    # If a RubricCriterion of the same name exits, load it up.  Otherwise,
    # create a new one.
    criterion = RubricCriterion.find_or_create_by_criterion_name_and_assignment_id(rubric_criterion_name, assignment.id)
    #Check that the weight is not a string.
    begin
      criterion.weight = Float(working_row.shift)
    rescue ArgumentError => e
      raise I18n.t('criteria_csv_error.weight_not_number')
    end
    # Only set the position if this is a new record.
    if criterion.new_record?
      criterion.position = assignment.next_criterion_position
    end
    
    if (!criterion.save)
      raise RuntimeError.new(criterion.errors)
    end
    criterion.rubric_criterion_levels.clear
    # next comes the level names.
    (0..RUBRIC_LEVELS-1).each do |i|
      criterion.rubric_criterion_levels.build({
        :level_name => working_row.shift,
        :level_index => i})
    end
    # the rest of the values are level descriptions.
    working_row.each_with_index do |desc, i|
      criterion.rubric_criterion_levels[i].update_attribute(:level_description,
      working_row.shift)
    end
    if !criterion.save
      raise RuntimeError.new(criterion.errors)
    end
    return criterion
  end

end
