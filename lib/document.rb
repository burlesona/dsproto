require_relative 'record'

module Docserver
  class Document < Record

    def root
      @root ||= Element.where({
        document_id: id, type: "Section", depth: 0
      }).first
    end

    def toc
      root.sections
    end

    # requires {element, position, reference_id}
    def create_element(opts={})
      el = Element.create(opts[:element])
      move opts.merge(element: el)
    end

    # requires {element || element_id, position, reference_id}
    def move_element(opts={})
      el = opts[:element] || Element.find(opts[:element_id])
      ref = Element.find(opts[:reference_id])
      case p = opts[:position]
      when "before","after"
        ref.parent.insert_child(element: el, position: p, reference_id: ref.id)
      when "prepend","append"
        ref.insert_child(element: el, position: p)
      else
        raise "Invalid position given."
      end
    end
  end
end
