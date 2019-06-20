class Job
  attr_accessor :file

  def initialize(args)
    @file = args[:file]
  end

  def run
    input_data = File.read(file)
    clean_data = clean_input_data(input_data)
    parse_dsn(clean_data)
  end

  def parse_dsn(dsn_string)
    begin
      parsed = DsnParser.new.parse(dsn_string, reporter: Parslet::ErrorReporter::Deepest.new)
    rescue Parslet::ParseFailed => error
      puts error.parse_failure_cause.ascii_tree
    end
    parsed
  end

  def clean_input_data(input_data)
    scanner = StringScanner.new(input_data)
    info_file = scanner.scan_until(/cf0 /)
    input_data.sub!(info_file,'')
    input_data.sub!('}','')
    input_data = input_data + "\\\n"
    input_data
  end
end