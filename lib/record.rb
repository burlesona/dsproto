require 'json'

module Docserver
  class Record
    def initialize(attrs={})
      @attributes = attrs
    end

    def children
      @children ||= load_children!
    end

    def to_hash &block
      hash = @attributes.dup
      block ||= ->(c){ c.to_hash }
      hash[:children] = children.map(&block) if children
      hash
    end

    def to_json(opts={})
      JSON.generate(self.to_hash)
    end

    def save
      data = @attributes.dup
      id = data.delete(:id)
      collection.update({_id: id}, data)
    end

    private
    def collection
      self.class.collection
    end
    # Note this method refrences the Element class
    # directly so that Document will know its children
    # are of the Element type. This may not be a good idea,
    # perhaps there should be a root element instead and
    # therefore Document doesn't have "children" but instead
    # has a single "Root"
    def load_children!
      if @attributes[:children]
        @attributes[:children]
      elsif ids = @attributes[:child_ids]
        Element.where(id: {'$in' => ids}).sort_by{|e| ids.index(e.id)}
      end
    end

    def method_missing(name, *args, &block)
      # Getter
      if a = @attributes[name]
        a
      else
        # Setter
        a = name.to_s.gsub("=","").to_sym
        if @attributes[a]
          @attributes[a] = args[0]
        else
          super
        end
      end
    end

    class << self
      def create(data={})
        raise "Please provide an ID\nDATA:\n#{data.inspect}" unless data[:id]
        raise "Record Already Exists:\nDATA:\n#{data.inspect}" if exists?(data[:id])
        data[:_id] = data.delete :id
        collection.insert data
        find( data[:_id] )
      end

      def find(id)
        if result = collection.find_one(_id: id)
          data = result.symbolize_keys
        else
          raise "Record Not Found: #{id.inspect}"
        end
        data = collection.find_one(_id: id).symbolize_keys
        data[:id] = data.delete :_id
        self.new(data)
      end

      def where(hash={})
        hash[:_id] = hash.delete(:id) if hash[:id]
        data = collection.find(hash)
        data.map do |d|
          d.symbolize_keys!
          d[:id] = d.delete(:_id)
          self.new(d)
        end
      end

      def all
        where()
      end

      def exists?(id)
        !!collection.find_one(_id: id)
      end

      def collection
        db.collection( name.demodulize.downcase.pluralize )
      end
    end
  end
end
