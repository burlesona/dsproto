require 'json'

module Docserver
  class Element
    def initialize(attrs={})
      @attributes = attrs
    end

    def children
      @children ||= load_children!
    end

    def to_hash
      hash = @attributes.dup
      hash[:children] = children.map(&:to_hash) if children
      hash
    end

    def to_json(opts={})
      JSON.generate(self.to_hash)
    end

    private
    def load_children!
      if @attributes[:children]
        @attributes[:children]
      elsif @attributes[:child_ids]
        children = []
        @attributes[:child_ids].each do |cid|
          children << self.class.find(cid)
        end
        children
      end
    end

    def method_missing(name, *args, &block)
      if a = @attributes[name]
        a
      else
        super
      end
    end

    class << self
      def create(data={})
        raise "Please provide an element ID\nDATA:\n#{data.inspect}" unless data[:id]
        raise "Element Already Exists:\nDATA:\n#{data.inspect}" if exists?(data[:id])
        data[:_id] = data.delete :id
        collection.insert data
        find( data[:_id] )
      end

      def find(id,opts={})
        if result = collection.find_one(_id: id)
          data = result.symbolize_keys
        else
          raise "Element Not Found: #{id.inspect}"
        end
        data[:id] = data.delete :_id
        instance = self.new(data)
        if opts[:include_children]
          instance.children
        end
        instance
      end

      def exists?(id)
        !!collection.find_one(_id: id)
      end

      def collection
        db.collection('elements')
      end
    end
  end
end
