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
      collection do |col,conn|
        col.get(id).update(data).run(conn)
      end
      self
    end

    private
    def collection
      self.class.collection do |col, conn|
        yield col, conn
      end
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
        create(data)
      end

      def create(data={})
        data[:id] ||= new_id(data[:document_id])
        collection do |col,conn|
          col.insert(data).run(conn)
        end
        find( data[:id] )
      end

      def new_id(doc_id)
        loop do
          ts = Time.now.to_i.to_s(32) + "-" + rand(1000).to_s(32)
          id = doc_id ? "d#{doc_id}-#{ts}" : "d#{ts}"
          break id unless exists?(id)
        end
      end

      def find(id)
        result = nil
        collection do |col,conn|
          result = col.get(id).run(conn)
        end
        if result
          data = result.symbolize_keys! # does rethink already do this??
        else
          raise "Record Not Found: #{id.inspect}"
        end
        self.new(data)
      end

      def where(hash={})
        data = nil
        collection do |col,conn|
          data = col.filter(hash).run(conn)
        end
        from_dataset(data)
      end

      def all
        data = nil
        collection do |col,conn|
          data = col.run(conn)
        end
        from_dataset(data)
      end

      def from_dataset(data)
        data.map do |d|
          d.symbolize_keys! # maybe not needed?
          self.new(d)
        end
      end

      def exists?(id)
        data = nil
        collection do |col,conn|
          data = col.get(id).run(conn)
        end
        !!data
      end

      def collection
        cname = name.demodulize.downcase.pluralize
        db do |c|
          col = r.table(cname)
          yield col, c
        end
      end
    end
  end
end
