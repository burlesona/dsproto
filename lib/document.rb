require 'json'

module Docserver
  class Document
    attr_reader :id, :type, :title, :version, :authors, :name, :child_ids

    def initialize(attrs={})
      attrs.each do |k,v|
        instance_variable_set "@#{k}", v
      end
    end

    def children
      @children ||= load_children!
    end

    def to_hash
      hash = {
        :id => id,
        :type => type,
        :title => title,
        :version => version,
        :authors => authors,
        :name => name
      }
      hash[:children] = children.map &:to_hash
      hash
    end

    def to_json(opts={})
      JSON.generate(self.to_hash)
    end

    private
    def load_children!
      if child_ids
        children = []
        child_ids.each do |cid|
          children << Element.find(cid)
        end
        children
      end
    end

    class << self
      def create(data={})
        raise "Please provide a document ID" unless data[:id]
        raise "Document Already Exists" if exists?(data[:id])
        data[:_id] = data.delete :id
        collection.insert data.slice(:_id, :type, :title, :version, :authors, :name, :child_ids)
        find( data[:_id] )
      end

      def find(id)
        data = collection.find_one(_id: id).symbolize_keys
        data[:id] = data.delete :_id
        self.new(data)
      end

      def exists?(id)
        !!collection.find_one(_id: id)
      end

      def collection
        db.collection('documents')
      end
    end
  end
end
