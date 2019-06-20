class Job
  attr_accessor :input_data, :log, :file

  def initialize(args)
    @file = args[:file]
    @input_data = File.read(file)
    @log = {}
    @log[:employees] = []
  end

  def run
    clean_input_data
    company_data
    employees_data
    sending_info_data
    output_json(data, "data/data.json")

    pp log
  end

  def clean_input_data
    info_file = StringScanner.new(input_data).scan_until(/cf0 /)
    input_data.sub!(info_file,'')
    input_data.sub!('}', '')
  end

  def scan_string(regex, string)
    scanned_string = StringScanner.new(string).scan_until(regex)
    scanned_string.sub!(regex,'')
  end
  
  def company_data
    company_string = scan_string(/S21\.G00\.30\.001/, input_data)
    company = company_string.split("\\\n")
    log[:company] = parse_data(company).reduce({}, :merge)
    input_data.sub!(company_string, '')
  end

  def employees_data
    employees = scan_string(/S90\.G00\.90\.001/, input_data)
    input_data.sub!(employees, '')
    employees = employees.split("\\\n")
    employees = employees.slice_before(/S21\.G00\.30\.001/).to_a
    employees.each do |employee|
      organize_data_employee(employee)
    end
  end

  def organize_data_employee(employee)
    identity = employee.slice_before(/S21\.G00\.50\.001/).to_a.shift
    identity = parse_data(identity).reduce({}, :merge)
    payment = employee.slice_before(/S21\.G00\.50\.001/).to_a[1].slice_before(/S21\.G00\.78\.001/).to_a.shift
    details_of_payment(payment)
    payment = details_of_payment(payment)
    untreated_data = employee.slice_before(/S21\.G00\.78\.001/).to_a.pop
    untreated_data = parse_data(untreated_data)
    log[:employees] << {identity: identity, payment: payment, untreated_data: untreated_data}
  end

  def details_of_payment(payment)
    payment = payment.slice_before(/S21\.G00\.51\.001/).to_a
    payment = payment.map { |detail| parse_data(detail) }
    payment = payment.map { |array| array.reduce({}, :merge)}
  end

  def sending_info_data
    info_array = input_data.split("\\\n")
    log[:sending_information] = parse_data(info_array).reduce({}, :merge)
  end

  def parse_data(data)
    new_array = []
    data.each do |element|
      hash = Hash[*element.split(',')]
      hash.each { |k,v| hash[k] = v.delete_prefix("'").delete_suffix("'") }
      new_array << hash
    end
    new_array
  end

  def number_of_employees
    log[:employees].count
  end

  def types_of_employees
    log[:employees].each_with_object(Hash.new(0)) { |h1, h2| h2[h1[:identity]["S21.G00.40.002"]] += 1 }
  end

  def number_of_executives
    types_of_employees
    if types_of_employees.key?("03") || types_of_employees.key?("04")
      number_of_executives = types_of_employees["03"] + types_of_employees["04"]
    else
      number_of_executives = 0
    end
    number_of_executives
  end

  def number_of_non_executives
    number_of_employees - number_of_executives
  end
  
  def age(employee)
    birthday = employee[:identity]["S21.G00.30.006"]
    birthday = DateTime.strptime(birthday, '%d%m%Y')
    now = Time.now.utc.to_date
    now.year - birthday.year - ((now.month > birthday.month || (now.month == birthday.month && now.day >= birthday.day)) ? 0 : 1)
  end

  def average_age(employees, number_of_employees)
    total_age = 0
    employees.each do |employee|
      total_age += age(employee)
    end
    total_age / number_of_employees
  end

  def executive_employees(employees)
    code_executives = ["03", "04"]
    employees.select{|h| code_executives.include?(h[:identity]["S21.G00.40.002"])}
  end

  def non_executive_employees(employees)
    employees - executive_employees(employees)
  end

  def employee_salaries(employees)
    array = []
    employees.each do |employee|
      array << { id: employee[:identity]["S21.G00.30.001"].to_i, salary_corrected: salary_corrected(employee)}
    end
    array
  end

  def salary_corrected(employee)
    detail_payment = employee[:payment].select {|detail| detail["S21.G00.51.011"] == "003"}.pop
    detail_payment["S21.G00.51.013"].to_f
  end

  def name_of_company(company)
    company["S10.G00.01.003"] 
  end

  def output_json(data, output_file_name)
    File.open(output_file_name,"w") do |f|
      f.write(JSON.pretty_generate(data))
    end
  end

  def data
    { company_data:
      { company_name: name_of_company(log[:company]),
       number_of_employees: number_of_employees,
       average_age_of_employees: average_age(log[:employees], number_of_employees),
       number_of_executives: number_of_executives,
       average_age_of_executives: average_age(executive_employees(log[:employees]), number_of_executives),
       number_of_non_executives: number_of_non_executives,
       average_age_of_non_executives: average_age(non_executive_employees(log[:employees]), number_of_non_executives),
       employee_salaries: employee_salaries(log[:employees]) }}
  end
end