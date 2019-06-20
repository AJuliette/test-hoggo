class DsnToHash < Parslet::Transform

  rule(string: simple(:s)) {
    case s
    when "true"
      true
    when "false"
      false
    when /\A[1-9]+\z/
      Integer(s)
    else
      String(s)
    end
  }

  rule(name: simple(:n), value: simple(:v)) { [String(n), v]}

  rule(document: subtree(:i)) { i.to_h }
end