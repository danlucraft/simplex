class Simplex
  module Parse
    class Error < RuntimeError; end
    class InvalidExpression < Error; end
    class InvalidInequality < Error; end
    class InvalidTerm < Error; end

    # coefficient concatenated with a single letter variable, e.g. "-1.23x"
    TERM_RGX = %r{
      \A                  # starts with
        (-)?              # possible negative sign
        (\d+(?:\.\d*)?)?  # possible float (optional)
        ([a-zA-Z])        # single letter variable
      \z                  # end str
    }x

    # a float or integer, possibly negative
    CONSTANT_RGX = %r{
      \A           # starts with
        -?         # possible negative sign
        \d+        # integer portion
        (?:\.\d*)? # possible decimal portion
      \z           # end str
    }x

    def self.inequality(str)
      lhs, rhs = str.split('<=')
      lhco, lhvar = self.expression(lhs)
      rht = self.tokenize(rhs)
      raise(InvalidInequality, "#{str}; bad rhs: #{rhs}") unless rht.size == 1
      c = rht.first
      raise(InvalidInequality, "bad rhs: #{rhs}") if !c.match CONSTANT_RGX
      return lhco, lhvar, c.to_f
    end

    # ignore leading and trailing spaces
    # ignore multiple spaces
    def self.tokenize(str)
      str.strip.split(/\s+/)
    end

    # rules: variables are a single letter
    #        may have a coefficient (default: 1.0)
    #        only sum and difference operations allowed
    #        normalize to all sums with possibly negative coefficients
    # valid inputs:
    #   'x + y'          => [1.0, 1.0],         [:x, :y]
    #   '2x - 5y'        => [2.0, -5.0],        [:x, :y]
    #   '-2x - 3y + -4z' => [-2.0, -3.0, -4.0], [:x, :y, :z]
    def self.expression(str)
      terms = self.tokenize(str)
      negative = false
      coefficients = []
      variables = []
      while !terms.empty?
        # consume plus and minus operations
        term = terms.shift
        if term == '-'
          negative = true
          term = terms.shift
        elsif term == '+'
          negative = false
          term = terms.shift
        end

        coefficient, variable = self.term(term)
        coefficient *= -1 if negative
        coefficients << coefficient
        variables << variable
      end
      return coefficients, variables
    end

    def self.term(str)
      matches = str.match TERM_RGX
      raise(InvalidTerm, str) unless matches
      flt = (matches[2] || 1).to_f * (matches[1] ? -1 : 1)
      sym = matches[3].to_sym # consider matches[3].downcase.to_sym
      return flt, sym
    end
  end
end
