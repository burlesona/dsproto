require 'json'

module Docserver
  class Record
    def initialize(attrs={})
      @attributes = attrs
    end

    def to_hash
      @attributes.dup
    end

    def to_json(opts={})
      JSON.generate(self.to_hash)
    end

    def update(hash)
      @attributes.merge!(hash)
      save
    end

    def save
      data = @attributes.dup
      id = data.delete(:id)
      collection.update({_id: id}, data)
      self
    end

    private
    def collection
      self.class.collection
    end

    def method_missing(name, *args, &block)
      # Getter
      if @attributes.has_key?(name)
        @attributes[name]
      else
        # Setter
        a = name.to_s.gsub("=","").to_sym
        if @attributes.has_key?(a)
          @attributes[a] = args[0]
        else
          super
        end
      end
    end

    class << self
      def import(data={})
        raise "Please provide an ID\nDATA:\n#{data.inspect}" unless data[:id]
        raise "Record Already Exists:\nDATA:\n#{data.inspect}" if exists?(data[:id])
        data[:_id] = data.delete :id
        create(data)
      end

      def create(data={})
        data[:_id] ||= new_id(data[:document_id])
        collection.insert data
        find( data[:_id] )
      end

      def new_id(doc_id)
        loop do
          ts = Time.now.to_i.to_s(32) + "-" + rand(1000).to_s(32)
          id = doc_id ? "d#{doc_id}-#{ts}" : "d#{ts}"
          break id unless exists?(id)
        end
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
