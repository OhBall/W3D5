require_relative 'db_connection'

require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    @column_names ||= DBConnection.execute2(<<-SQL)
      SELECT 
        * 
      FROM 
        #{table_name}
    SQL
    @column_names.first.map! {|col| col.to_sym}

  end

  def self.finalize!
    columns.each do |col|
      define_method(col) do 
        attributes[col]
      end
      define_method("#{col}=") do |value|
        attributes[col] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      self.to_s.downcase + 's'
    else 
      @table_name
    end
  end

  def self.all
    data = DBConnection.instance.execute(<<-SQL)
    SELECT
      * 
    FROM 
      #{table_name}
    SQL
    parse_all(data)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    data = DBConnection.instance.execute(<<-SQL, id)
      SELECT *
      FROM #{table_name}
      WHERE id = ?
    SQL
    return nil if data.length == 0
    self.new(data.first)
  end

  def initialize(params = {})
    
    # self.class.columns.each do |col|
    #   self.send("#{col}=", params[col])
    # end
    
    params.each do |attr_name,value|
      # unless self.instance_methods.include?(attr_name)
      begin
        self.send("#{attr_name}=", value)
      rescue NoMethodError
        raise Exception, "unknown attribute '#{attr_name}'"
      end
    end
    
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
  
    col_names = self.class.columns[1..-1].join(',')
    question_marks = (["?"] * (self.class.columns.length - 1)).join(',')
    # debugger
    DBConnection.instance.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name}( #{col_names} )
    VALUES
      (#{question_marks})
    SQL
    
    self.id = DBConnection.last_insert_row_id
    
  end

  def update
    # col_names = self.class.columns[1..-1].join(',')
    # question_marks = (["?"] * (self.class.columns.length)).join(',')
    set_str = self.class.columns[1..-1].map{ |col| "#{col} = ?" }.join(', ')
    
    new_attribs = attribute_values[1..-1] + [attribute_values.first]
    DBConnection.instance.execute(<<-SQL, *(new_attribs))
    UPDATE
      #{self.class.table_name}
    SET
      #{set_str}
    WHERE
      id = ?
    SQL
  end

  def save
    if self.id.nil? 
      self.insert 
    else
      self.update 
    end
  end
end
