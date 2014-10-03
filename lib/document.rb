require_relative 'record'

module Docserver
  class Document < Record

    def toc
      children.map &:sections
    end

  end
end
