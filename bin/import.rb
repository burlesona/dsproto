#!usr/bin/env ruby
require_relative '../initializer'
require 'rest_client'
require 'json'
require 'pry'
require 'optparse'
require 'ostruct'
require 'benchmark'

# Setup Import Options
$options = OpenStruct.new
$options.scholar_url = "http://local-scholar.flatworldknowledge.com:9393/api"

optparser = OptionParser.new do |opts|
  opts.banner = 'Usage: ruby import.rb [options]'

  opts.on('-b', '--book=', 'Book Id') do |b|
    $options.document_id = b.to_i
  end

  opts.on('-s', '--scholar=', 'Scholar API URL') do |s|
    $options.scholar_url = s
  end

  opts.on('-c', '--clean', 'Clean the database before import') do
    Docserver::Document.collection do |col,conn|
      col.delete.run(conn)
    end
    Docserver::Element.collection do |col,conn|
      col.delete.run(conn)
    end
  end
end
optparser.parse!

abort 'Must specify book ID' if $options.document_id.nil?

# Define Utility Methods
def get(path,opts={})
  url = File.join($options.scholar_url,$options.document_id.to_s,path)
  opts.merge({accept: :json})
  response = RestClient.get(url,opts)
  JSON.parse(response.body, symbolize_names: true) if response.code == 200
end

# Fetch and Format Document Data
doc_data = get('toc')
toc = doc_data.delete(:toc)
top_level_ids = toc.map{|c| c[:id]}
toc_hash = toc.each_with_object({}) do |c,hash|
  hash[ c[:id] ] = c
end

# Create Document
doc_data[:id] = $options.document_id.to_i
doc = Docserver::Document.import(doc_data)


# Since the Scholar API is still using varying types
# for section elements (chapter, article, appendix etc.),
# normalize that on import.

# Here we build a complete hash representation of the document
root = {
  id: "#{doc.id}-root",
  document_id: doc.id,
  type: "Section",
  depth: 0,
  children: []
}
top_level_ids.each do |cid|
  puts "Importing #{cid}"
  toc_data = toc_hash[cid]
  element = get("elements/#{cid}")
  element[:type] = "Section"
  element[:domain] = toc_data[:domain]
  element[:previewable] = toc_data[:previewable]
  # If element is in the TOC Hash it is a chapter
  # and the sections need to be appended manually
  if sections = toc_data[:children]
    sections.each do |s|
      puts "Importing #{s[:id]}"
      child = get("elements/#{s[:id]}")
      child[:type] = "Section"
      child[:domain] = s[:domain]
      child[:previewable] = s[:previewable]
      element[:children] << child
    end
  end
  root[:children] << element
end

def create_element(edata,depth:0)
  edata[:document_id] = $options.document_id
  # First create elements for all children of sections
  if edata[:type] == "Section"
    edata[:depth] = depth
    edata[:child_ids] = []
    children = edata.delete(:children)
    # Skip and log if a section child has no ID
    children.each do |c|
      if !c[:id]
        puts "SKIPPING:\n#{c.inspect}"
      else
        edata[:child_ids] << c[:id]
        create_element(c, depth: depth+1)
      end
    end
  end
  # Create the element after handling its children
  # Non-section children become embedded documents
  Docserver::Element.import(edata)
end

time = Benchmark.measure { create_element(root) }
puts "\n\nImported Document in:\n#{time}"

binding.pry


