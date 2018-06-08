require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_arr = []
    question_marks = []
    params.each do |key, value| 
      where_arr << "#{key} = ?"
      question_marks << value
    end
    where_str = where_arr.join(" AND ")
    
    data = DBConnection.instance.execute(<<-SQL, *question_marks)
    SELECT
      *
    FROM 
      #{self.table_name}
    WHERE
      #{where_str}
    SQL
    
    data.map { |datum| self.new(datum) }
    
  end
end

class SQLObject 
  extend Searchable
  
end
