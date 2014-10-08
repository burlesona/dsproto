require_relative 'record'

# MISSING METHODS:
# insert_child({element, position, reference_id?})
# ^ this should accomplish a move by removing any previous references as well
# delete!
# ^ this should update any parent references as well


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
        document_id: document_id,
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
