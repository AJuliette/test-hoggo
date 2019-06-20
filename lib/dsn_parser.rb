class DsnParser < Parslet::Parser
  rule(:name) { 
    match(/[0-9A-Z]/).repeat(1) >> str(".") >> match(/[0-9A-Z]/).repeat(1) >> str(".") >> match(/[0-9]/).repeat(1) >> str(".") >> match(/[0-9]/).repeat(1)
   }

  rule(:assignment) { str(",") }

  rule(:newline) { str("\n") }
  rule(:value) {
    str("'") >>
    (str("'\\").absent? >> any).repeat.as(:string) >> str("'\\")
  }

  rule(:item) { name.as(:name) >> assignment >> value.as(:value) >> newline }
  
  rule(:identity) { str('S21.G00.30.001').as(:name) >> assignment >> value.as(:value).as >> newline }

  rule(:employee) { (str('S21.G00.30.001').as(:name) >> assignment >> value.as(:value)).as(:employee) >> newline >> follower_of_employee.repeat(1) }

  rule(:follower_of_employee) { info | item }

  rule(:info) { str('S90.G00.90.001').as(:name) >> assignment >> value.as(:value) >> newline >> item }

  rule(:follower_of_company) { employee | item }

  rule(:company) { str('S10.G00.00.001').as(:name) >> assignment >> value.as(:value) >> newline >> follower_of_company.repeat(1) }

  rule(:body) { item.repeat }

  root :body
end