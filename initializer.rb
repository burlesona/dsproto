require 'dotenv'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/string'
require 'mongo'

# Configure Environment
ROOT_DIR = File.dirname(__FILE__)
Dotenv.load

# Setup DB
def db
  @db ||= Mongo::MongoClient.new.db('docserver')
end

# Require Application Files
Dir[ File.join(ROOT_DIR,"{lib,routers}","**","*.rb") ].each do |file|
  require file
end

