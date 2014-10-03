#!usr/bin/env ruby
require_relative '../initializer'
require 'rest_client'
require 'json'
require 'pry'
require 'optparse'
require 'ostruct'

# Setup Import Options
$options = OpenStruct.new
$options.scholar_url = "http://local-scholar.flatworldknowledge.com:9393/api"

optparser = OptionParser.new do |opts|
  opts.banner = 'Usage: ruby import.rb [options]'

  opts.on('-b', '--book=', 'Book Id') do |b|
    $options.book_id = b.to_i
  end

  opts.on('-s', '--scholar=', 'Scholar API URL') do |s|
    $options.scholar_url = s
  end

  opts.on('-c', '--clean', 'Clean the database before import') do
    Docserver::Document.collection.remove
    Docserver::Element.collection.remove
  end
end
optparser.parse!

abort 'Must specify book ID' if $options.book_id.nil?

# Define Utility Methods
def get(path,opts={})
  url = File.join($options.scholar_url,$options.book_id.to_s,path)
  opts.merge({accept: :json})
  response = RestClient.get(url,opts)
  JSON.parse(response.body, symbolize_names: true) if response.code == 200
end

# Run anything you want before the import script executes.
binding.pry

# Create Document Data
book_data = get('toc')
toc = book_data.delete(:toc)
book_data[:id] = $options.book_id.to_i
book_data[:child_ids] = toc.map{|c| c[:id]}
doc = Docserver::Document.create(book_data)

def create_element(edata,depth:1)
  edata[:book_id] = $options.book_id

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
  Docserver::Element.create(edata)
end

# Create lookup of chapter sections:
toc_hash = toc.each_with_object({}) do |c,hash|
  hash[ c[:id] ] = c
end

# Since the Scholar API is still using varying types
# for section elements (chapter, article, appendix etc.),
# normalize that on import.
# The depth level for all sections will be set in the
# create element function (above).
doc.child_ids.each do |cid|
  puts "Importing #{cid}"
  toc_data = toc_hash[cid]
  edata = get("elements/#{cid}")
  edata[:type] = "Section"
  edata[:domain] = toc_data[:domain]
  edata[:previewable] = toc_data[:previewable]
  # If element is in the TOC Hash it is a chapter
  # and the sections need to be appended manually
  if sections = toc_data[:children]
    sections.each do |s|
      puts "Importing #{s[:id]}"
      child = get("elements/#{s[:id]}")
      child[:type] = "Section"
      child[:domain] = s[:domain]
      child[:previewable] = s[:previewable]
      edata[:children] << child
    end
  end
  create_element(edata,depth: 1)
end

binding.pry

