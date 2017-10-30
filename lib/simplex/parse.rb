class Simplex
  module Parse
    TERM_RGX = %r{
      \A                  # starts with
        (-)?              # possible negative sign
        (\d+\.?\d*)?      # possible float (optional)
        ([a-zA-Z])        # single letter variable
      \z                  # end str
    }x

    # rules: variables are a single letter
    #        may have a coefficient (default: 1.0)
    #        only sum and difference operations allowed
    #        normalize to all sums with possibly negative coefficients
    # valid inputs:
    #   'x + y'          => [1.0, 1.0],         [:x, :y]
    #   '2x - 5y'        => [2.0, -5.0],        [:x, :y]
    #   '-2x - 3y + -4z' => [-2.0, -3.0, -4.0], [:x, :y, :z]
    def self.objective(str)
      terms = str.split(/\s+/)
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

    def self.term(term_str)
      matches = term_str.match TERM_RGX
      raise "bad term: #{term_str}" unless matches
      flt = (matches[2] || 1).to_f * (matches[1] ? -1 : 1)
      sym = matches[3].to_sym # consider matches[3].downcase.to_sym
      return flt, sym
    end
  end
end
