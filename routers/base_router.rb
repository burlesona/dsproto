require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/namespace'
require 'uri'
require 'json'

require_relative '../lib/couchdb'


module Docserver
  class BaseRouter < Sinatra::Base
    register Sinatra::Namespace

    # DB Helper
    before do
      @db ||= CouchDB::Server.new('docserver')
    end
  end
end
