require 'socket'
require 'json'
require 'dotenv/load'
require_relative 'database_connector'
require_relative 'server'

connector = DatabaseConnector.new("stat_service_database.db")

unless connector.table_exists?("items")
  connector.execute("CREATE TABLE items (id INTEGER PRIMARY KEY, item_id INTEGER UNIQUE, quantity INTEGER)")
end

server = Server.new('localhost', 8080, connector)
server.start
