require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/namespace'
require 'uri'
require 'json'

module Docserver
  class BaseRouter < Sinatra::Base
    register Sinatra::Namespace

    # DB Helper
    before do
      @db = Mongo::MongoClient.new.db('docserver')
    end
  end
end
