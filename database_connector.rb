require 'sqlite3'

class DatabaseConnector
  attr_reader :db

  def initialize(database_name)
    @db = SQLite3::Database.new(database_name)
  end

  def execute(sql)
    db.execute(sql)
  end

  def table_exists?(table_name)
    db.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='#{table_name}';").any?
  end
end
