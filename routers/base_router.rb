require 'sinatra/base'
require 'uri'
require 'json'

module Docserver
  class BaseRouter < Sinatra::Base
    # DB Helper
    before do
      @db = Mongo::MongoClient.new.db('docserver')
    end
  end
end
