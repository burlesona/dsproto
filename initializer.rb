require 'dotenv'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'rethinkdb'
include RethinkDB::Shortcuts

# Configure Environment
ROOT_DIR = File.dirname(__FILE__)
Dotenv.load

# Setup DB
def db
  @conn ||= r.connect db: 'docserver'
  yield @conn
end

db do |c|
  # Create docserver DB
  unless r.db_list.run(c).include?('docserver')
    r.db_create('docserver').run(c)
  end

  # Create needed tables
  %w|documents elements|.each do |t|
    unless r.table_list.run(c).include?(t)
      r.table_create(t).run(c)
    end
  end
end

# Require Application Files
Dir[ File.join(ROOT_DIR,"{lib,routers}","**","*.rb") ].each do |file|
  require file
end

