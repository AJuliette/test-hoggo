require 'strscan'
require 'pry'
require 'time'
require 'json'
require_relative 'lib/string.rb'
require_relative 'lib/job.rb'

Job.new(file: "TestDSN.rtf").run
