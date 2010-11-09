class Criterion < ActiveRecord::Base
  before_save :truncate_weight
  belongs_to  :assignment, :counter_cache => true
  has_many    :marks, :dependent => :destroy
  has_many    :tas, :through => :criterion_ta_associations
  validates_associated  :assignment, :on => :create, :message => 'association is not strong with an assignment'
  validates_uniqueness_of :criterion_name, :scope => :assignment_id, :message => 'is already taken'
  validates_presence_of :criterion_name, :weight, :assignment_id, :assigned_groups_count
  validates_numericality_of :assignment_id, :only_integer => true, :greater_than => 0, :message => "can only be whole number greater than 0"
  validates_numericality_of :weight, :assigned_groups_count, :message => "must be a number greater than 0.0", :greater_than => 0.0
  set_table_name :criteria
  validate_on_update :validate_total_weight
  before_validation :update_assigned_groups_count

  
  def mark_for(result_id)
    return marks.find_by_result_id(result_id)
  end
  
  def get_weight
    return weight
  end
  
  def truncate_weight
    factor = 10.0 ** 2
    self.weight = (self.weight * factor).floor / factor
  end
  
  def create_or_update_from_csv_row(row)
    raise NotImplementedError, "Criterion.create_or_update_from_csv_row Not yet implemented"
  end
  
  def read_csv_row_for_download
    raise NotImplementedError, "Criterion.read_csv_row_for_download Not yet implemented"
  end
  
  def get_full_mark
    raise NotImplementedError, "Criterion.full_mark: Not yet implemented"
  end
  
  def update_assigned_groups_count
    result = []
    criterion_ta_associations.each do |cta|
      result = result.concat(cta.ta.get_groupings_by_assignment(assignment))
    end
    self.assigned_groups_count = result.uniq.length
  end
  
  def all_assigned_groups
    result = []
    tas.each do |ta|
      result = result.concat(ta.get_groupings_by_assignment(assignment))
    end
    return result.uniq
  end
  
  def add_tas(ta_array)
    ta_array = Array(ta_array)
    associations = criterion_ta_associations.all(:conditions => {:ta_id => ta_array})
    ta_array.each do |ta|
      # & is the mathematical set intersection operator between two arrays
      if (ta.criterion_ta_associations & associations).size < 1
        criterion_ta_associations.create(:ta => ta, :criterion => self, :assignment => self.assignment)
      end
    end
  end

  def remove_tas(ta_array)
    ta_array = Array(ta_array)
    associations_for_criteria = criterion_ta_associations.all(:conditions => {:ta_id => ta_array})
    ta_array.each do |ta|
      # & is the mathematical set intersection operator between two arrays
      assoc_to_remove = (ta.criterion_ta_associations & associations_for_criteria)
      if assoc_to_remove.size > 0
        criterion_ta_associations.delete(assoc_to_remove)
        assoc_to_remove.first.destroy
      end
    end
  end
  
  def get_name()
    return criterion_name
  end
  
  def get_ta_names()
    return criterion_ta_associations.collect {|association| association.ta.user_name}
  end
  
  def has_associated_ta?(ta)
    if !ta.ta?
      return false
    end
    return !(criterion_ta_associations.find_by_ta_id(ta.id) == nil)  
  end
  
  def add_tas_by_user_name_array(ta_user_name_array)
    result = ta_user_name_array.map{|ta_user_name|
      Ta.find_by_user_name(ta_user_name)}.compact
    add_tas(result)
  end
  
  # Updates results already entered with new criteria
  def update_existing_results
    self.assignment.submissions.each { |submission| submission.result.update_total_mark }
  end
  
  def validate_total_weight
    errors.add(:assignment, I18n.t("rubric_criteria.error_total")) if self.assignment.total_mark + (4 * (self.weight - self.weight_was)) <= 0
  end
  
end
