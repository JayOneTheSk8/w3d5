require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns if @columns
    characteristics = DBConnection.execute2("SELECT * FROM #{self.table_name}")
    @columns = characteristics.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        self.attributes[column]
      end

      define_method("#{column.to_s}=") do |val|
        self.attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    all_obj = DBConnection.execute("SELECT * FROM #{self.table_name}")
    self.parse_all(all_obj)
  end

  def self.parse_all(results)
    parsed = results.map do |params|
      parsed_params = params.to_a
      parsed_params.map { |pair| [pair[0].to_sym, pair[-1]] }
    end
    final_results = parsed.map(&:to_h)
    final_results.map do |params|
      self.new(params)
    end
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE
       #{self.table_name}.id = #{id}
    SQL
    self.parse_all(results).first
  end

  def initialize(params = {})
    your_class = self.class
    unless params.keys.all? { |param| your_class.columns.include?(param) }
      bad_param = params.keys.find { |param| !your_class.columns.include?(param) }
      raise "unknown attribute '#{bad_param.to_s}'"
    else
      characteristics = params.keys
      your_class.columns.each do |column|
        if characteristics.include?(column)
          self.send("#{column}=", params[column])
        end
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def insert
    col_names = self.class.columns
    question_marks = ["?"] * @attributes.legnth
  end

  def update
    # ...
  end

  def save
    # ...
  end
end
