require 'optparse'
require 'ostruct'

require_relative '../lib/couchdb'


$options = OpenStruct.new
$options.db = nil
$options.doc = nil


optparser = OptionParser.new do |opts|
  opts.banner = 'Usage: ruby bin/upload-views.rb [options]'

  opts.on('-d', '--db=', 'CouchDB Database name') do |d|
    $options.db = d
  end

  opts.on('-n', '--doc-name=', 'Document name') do |d|
    $options.doc = d
  end
end

optparser.parse!

unless $options.db && $options.doc
  puts "Wrong options\n\n"
  puts optparser
  exit 1
end

server = CouchDB::Server.new($options.db)

def read_file(path)
  File.open(path, 'r'){|f| f.readlines.join}
rescue
  nil
end

views = {}
lists = {}

Dir["**/#{$options.doc}/*"].each do |path|
  map = read_file("#{path}/map.js")
  reduce = read_file("#{path}/reduce.js")
  list = read_file("#{path}/list.js")
  name = path.split('/').last

  view = {}
  view[:map] = map if map
  view[:reduce] = reduce if reduce

  lists[name.to_sym] = list if list
  views[name.to_sym] = view
end

server.update_design($options.doc, views: views, lists: lists)
