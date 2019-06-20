require 'parslet'
require 'strscan'
require 'time'
require 'json'
require_relative 'lib/string.rb'
require_relative 'lib/job.rb'
require_relative 'lib/dsn_to_hash.rb'
require_relative 'lib/dsn_parser.rb'

puts Job.new(file: "data/TestDSN.rtf").run
