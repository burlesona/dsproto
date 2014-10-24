require_relative 'record'

module Docserver
  class Element < Record
    def sections
      if section?
        hash = @attributes.except(:child_ids, :deprecated)
        hash[:children] = children.map(&:sections).compact if children
        hash
      end
    end

    def section?
      ['Book', 'Section'].include? type
    end

    # Note: if there is no parent, this can return a random record?
    def parent(reload: false)
      @parent = db.find(document_id) if reload || !defined?(@parent)
      @parent
    end

    def children
      @children ||= load_children!
    end

    def remove_child(child)
      id = child.respond_to?(:id) ? child.id : id
      child_ids.delete(id)
      save
    end

    # Note: This is appropriate for elements that have child references
    # but it would not work for lower level containers that have embedded children
    def insert_child(element: nil, position: nil, reference_id: nil)
      # Remove previous parent if present
      element.parent.remove_child(element) if element.parent

      # Insert child id into child_ids list
      case position
      when 'before', 'after'
        raise 'Reference ID required' unless reference_id
        raise 'Invalid Reference ID' unless child_ids.include?(reference_id)
        index = child_ids.index(reference_id)
        index += 1 if position == "after"
        child_ids.insert(index, element.id)
      when 'prepend'
        child_ids.unshift element.id
      when 'append'
        child_ids.push element.id
      else
        raise 'Invalid position given.'
      end

      # Save element and return updated child instance
      save
      element.parent(reload: true) # Maybe better to replace with just an element.reload! call
      element
    end

    # Note: if there are pre-existing instances of the parent element,
    # when the child is deleted the parent needs to be reloaded for the
    # parent object instance to reflect the modified database state
    def delete!
      if parent
        parent.remove_child(id)
        @parent = nil
      end

      db.delete id
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
      startkey = [document_id]
      startkey << id if id != document_id

      endkey = [document_id]
      endkey << id if id != document_id
      endkey << {}

      children = db.elements.by_ancestors.children.run(
        startkey: startkey,
        endkey: endkey,
        include_docs: true
      )
      children.map{|c| Element.new(c)}
    end
  end
end
