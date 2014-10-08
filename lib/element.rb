require_relative 'record'

# MISSING METHODS:
# insert_child({element, position, reference_id?})
# ^ this should accomplish a move by removing any previous references as well

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

    # Note: if there is no parent, this seems to return a random record?
    def parent
      @parent ||= self.class.where({
        document_id: document_id,
        child_ids: id
      }).first
    end

    def children
      @children ||= load_children!
    end

    # Note: if there are pre-existing instances of the parent element,
    # when the child is deleted the parent needs to be reloaded for the
    # parent object instance to reflect the modified database state
    def delete!
      if parent
        parent.child_ids.delete(id)
        parent.save
        @parent = nil
      end
      collection.remove(_id: id)
      self.id = nil
      true
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
