require_relative 'record'

module Docserver
  class Document < Record

    def root
      @root ||= Element.where({
        book_id: id, type: "Section", depth: 0
      }).first
    end

    def toc
      root.sections
    end

  end
end
