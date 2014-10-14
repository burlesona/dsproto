require 'json'

module Docserver
  class Record
    attr_reader :attributes

    def initialize(attrs={})
      @attributes = attrs
    end

    def to_hash
      @attributes.dup
    end

    def to_json(opts={})
      JSON.generate(self.to_hash, opts)
    end

    def update(hash)
      @attributes.merge!(hash)
      save
    end

    def save(opts = {})
      doc = @attributes.clone
      doc[:_id] = doc.delete(:id) if doc[:id]
      db.save doc, opts
      self
    end

    private

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
        create(data)
      end

      def create(data = {}, opts = {})
        self.new(data).save(opts)
      end

      def find(id)
        data = db.find id
        raise "Record Not Found: #{id.inspect}" unless data

        data[:id] = data.delete :_id
        self.new(data)
      end

      def all
        db.elements.all.run
      end

      def exists?(id)
        db.exists? id
      end
    end
  end
end
