#!usr/bin/env ruby
require 'securerandom'
require 'rest_client'
require 'json'
require 'pry'
require 'optparse'
require 'ostruct'
require 'benchmark'

require_relative '../initializer'

# Setup Import Options
$options = OpenStruct.new
$options.scholar_url = "http://local-scholar.flatworldknowledge.com:9393/api"
# $options.scholar_url = "http://scholar.flatworldknowledge.com/api"

optparser = OptionParser.new do |opts|
  opts.banner = 'Usage: ruby import.rb [options]'

  opts.on('-b', '--book=', 'Book Id') do |b|
    $options.document_id = b.to_i.to_s
  end

  opts.on('-s', '--scholar=', 'Scholar API URL') do |s|
    $options.scholar_url = s
  end

  opts.on('-c', '--clean', 'Clean the database before import') do
    db.reset!
    `ruby ./upload-views.rb -d #{db.host} -n ../lib/js/elements`
  end
end

optparser.parse!

abort 'Must specify book ID' if $options.document_id.nil?

# Define Utility Methods
def get(path,opts={})
  url = File.join($options.scholar_url, $options.document_id, path)
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
doc_data[:_id] = $options.document_id

# Since the Scholar API is still using varying types
# for section elements (chapter, article, appendix etc.),
# normalize that on import.

# Here we build a complete hash representation of the document
root = {
  id: doc_data[:_id],
  document_id: doc_data[:_id],
  type: 'Book',
  depth: 0,
  children: []
}
top_level_ids.each do |cid|
  puts "Importing #{cid}"
  toc_data = toc_hash[cid]
  element = get("elements/#{cid}")
  element[:type] = 'Section'
  element[:domain] = toc_data[:domain]
  element[:previewable] = toc_data[:previewable]
  # If element is in the TOC Hash it is a chapter
  # and the sections need to be appended manually
  if sections = toc_data[:children]
    sections.each do |s|
      puts "Importing #{s[:id]}"
      child = get("elements/#{s[:id]}")
      child[:type] = 'Section'
      child[:domain] = s[:domain]
      child[:previewable] = s[:previewable]
      element[:children] << child
    end
  end
  root[:children] << element
end

def create_element(edata, depth: 0, ancestors: [])
  edata[:document_id] = $options.document_id
  edata[:depth] = depth
  edata[:ancestors] = ancestors

  # First create elements for all children of sections
  if ['Book', 'Section'].include? edata[:type]
    edata[:child_ids] = edata.delete(:children).map do |c|
      c[:id] ||= SecureRandom.uuid().gsub('-', '')
      c[:parent_id] = edata[:id]
      create_element(c, depth: depth + 1, ancestors: ancestors + [edata[:id]])
      c[:id]
    end
  end
  # Create the element after handling its children
  # Non-section children become embedded documents
  Docserver::Element.import(edata)
end

time = Benchmark.measure { create_element(root) }
puts "\n\nImported Document in:\n#{time}"

binding.pry
