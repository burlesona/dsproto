require_relative './base_router'

module Docserver
  class RootRouter < BaseRouter

    get '/' do
      "Hello!"
    end

  end
end
