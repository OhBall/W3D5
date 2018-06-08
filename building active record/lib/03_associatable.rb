require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    self.class_name.to_s.downcase + 's'
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || (name.to_s + '_id').to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || (self_class_name.to_s.downcase + '_id').to_sym
    @primary_key = options[:primary_key] || :id
    @class_name = options[:class_name] || name.to_s.camelcase.singularize
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      
      data = DBConnection.instance.execute(<<-SQL)
        SELECT
          #{options.table_name}.*
        FROM
          #{self.class.table_name}
        JOIN
          #{options.table_name} ON 
            #{self.class.table_name}.#{options.foreign_key} = 
            #{options.table_name}.#{options.primary_key}
        WHERE
          #{self.class.table_name}.id = #{self.id}      
      SQL
      
      return nil if data.empty?
      options.class_name.constantize.new(data.first)


    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.class.to_s, options)
    
    define_method(name) do 
      data = DBConnection.instance.execute(<<-SQL)
        SELECT
          #{options.table_name}.*
        FROM 
          #{self.class.table_name}
        JOIN 
          #{options.table_name} ON   
          #{self.class.table_name}.#{options.primary_key} = 
          #{options.table_name}.#{options.foreign_key}
        WHERE 
          #{self.class.table_name}.id = #{self.id}
      SQL
      return [] if data.empty?
      data.map{ |datum| options.class_name.constantize.new(datum)}
    end
    
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
