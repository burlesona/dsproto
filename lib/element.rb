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

  end
end
