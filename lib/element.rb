require_relative 'record'

module Docserver
  class Element < Record

    def sections
      if section?
        hash = @attributes.except(:child_ids,:deprecated)
        if children
          hash[:children] = children.map{|c| c.sections }.compact
        end
        hash
      end
    end

    def section?
      type == "Section"
    end

    def parent
      @parent ||= self.class.where({
        book_id: book_id,
        child_ids: id
      }).first
    end

    def children
      @children ||= load_children!
    end

    def to_hash
      hash = super
      hash[:children] = children.map(&:to_hash) if children
      hash
    end

    private
    def load_children!
      if @attributes[:children]
        @attributes[:children]
      elsif ids = @attributes[:child_ids]
        Element.where(id: {'$in' => ids}).sort_by{|e| ids.index(e.id)}
      end
    end
  end
end
