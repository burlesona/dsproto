require_relative 'record'

module Docserver
  class Document < Record

    def root
      @root ||= Element.new(db.elements.root.run(
        startkey: id,
        endkey: id,
        include_docs: true
      ).first[:doc])
    end

    def toc(depth = 2)
      db.elements.by_depth.toc.run(
        startkey: [root.id],
        endkey: [root.id, depth],
        include_docs: true
      )
    end

    # requires {element, position, reference_id}
    def create_element(opts={})
      el = Element.create(opts[:element])
      move_element opts.merge(element: el)
    end

    # requires {element || element_id, position, reference_id}
    def move_element(opts={})
      el = opts[:element] || Element.find(opts[:element_id])
      ref = Element.find(opts[:reference_id])

      case p = opts[:position]
      when "before", "after"
        ref.parent.insert_child(element: el, position: p, reference_id: ref.id)
      when "prepend", "append"
        ref.insert_child(element: el, position: p)
      else
        raise "Invalid position given."
      end
    end
  end
end
