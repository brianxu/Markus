class UpdateForNewCriterionDesign < ActiveRecord::Migration
  def self.up
    create_table :criteria do |t|
      t.column :type, :string
      t.column :criterion_name, :string
      t.column :assignment_id, :int
      t.column :weight, :float
      t.column :position, :int
      t.column :description, :text
      t.timestamps
    end
    
    create_table :rubric_criterion_levels do |t|
      t.integer :rubric_criterion_id
      t.string :level_name
      t.text :level_description
      t.integer :level_index
      
      t.timestamps
    end
    
    create_table :flexible_criterion_attributes do |t|
      t.column :flexible_criterion_id, :int
      t.column :max, :float
      t.timestamps
    end
    
    change_table :marks do |t|
      t.remove :markable_id
      t.column :criterion_id, :integer
      #TODO remove markable_type in future
    end
    
    #TODO remove FlexibleCriteria and RubricCriteria
  end

  def self.down
    change_table :marks do |t|
      t.remove :criterion_id
      t.column :markable_id, :integer
    end
    drop_table :flexible_criterion_attributes
    drop_table :rubric_criterion_levels
    drop_table :criteria
  end
end

