require 'strscan'
require 'pp'
require 'time'
require 'json'
require_relative 'lib/string.rb'
require_relative 'lib/job.rb'

Job.new(file: "data/TestDSN.rtf").run
