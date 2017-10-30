require 'matrix'

class Vector
  public :[]=
end

class Simplex
  DEFAULT_MAX_PIVOTS = 10_000

  class UnboundedProblem < StandardError
  end

  attr_accessor :max_pivots

  # c - coefficients of objective function; size: num_vars
  # a - inequality lhs coefficients;   2dim size: num_inequalities, num_vars
  # b - inequality rhs constants            size: num_inequalities
  def initialize(c, a, b)
    num_vars = c.size
    num_inequalities = b.size
    raise(ArgumentError, "a doesn't match b") unless a.size == num_inequalities
    raise(ArgumentError, "a doesn't match c") unless a.first.size == num_vars

    @max_pivots = DEFAULT_MAX_PIVOTS

    # Problem dimensions; these never change
    @num_non_slack_vars = num_vars
    @num_constraints    = num_inequalities
    @num_vars           = @num_non_slack_vars + @num_constraints

    # Set up initial matrix A and vectors b, c
    @c = Vector[*(c.map { |flt| -1 * flt } + Array.new(@num_constraints, 0))]
    @a = a.map.with_index { |ary, i|
      if ary.size != @num_non_slack_vars
        raise ArgumentError, "a is inconsistent"
      end
      constraints = Array.new(@num_constraints) { |ci| ci == i ? 1 : 0 }
      Vector[*(ary + constraints)]
    }
    @b = Vector.elements(b, true)

    # set initial solution: all non-slack variables = 0
    @basic_vars = (@num_non_slack_vars...@num_vars).to_a
    update_solution
  end

  def solution
    solve
    current_solution
  end

  def current_solution
    @x[0...@num_non_slack_vars]
  end

  def update_solution
    @x = Array.new(@num_vars, 0)

    @basic_vars.each do |basic_var|
      row_with_1 = row_indices.detect do |row_ix|
        @a[row_ix][basic_var] == 1
      end
      @x[basic_var] = @b[row_with_1]
    end
  end

  def solve
    count = 0
    while can_improve?
      count += 1
      raise "too many pivots: #{count}" unless count < @max_pivots
      self.pivot
    end
  end

  def can_improve?
    !!entering_variable
  end

  def entering_variable
    (0...@c.size).to_a.select { |var|
      @c[var] < 0
    }.min_by { |var| @c[var] }
  end

  def pivot
    pivot_column = entering_variable
    pivot_row    = pivot_row(pivot_column)
    raise UnboundedProblem unless pivot_row
    leaving_var = self.column_indices.detect { |idx|
      @a[pivot_row][idx] == 1 and @basic_vars.include?(idx)
    }

    @basic_vars.delete(leaving_var)
    @basic_vars.push(pivot_column)
    @basic_vars.sort!

    pivot_ratio = Rational(1, @a[pivot_row][pivot_column])

    # update pivot row
    @a[pivot_row] *= pivot_ratio
    @b[pivot_row] = pivot_ratio * @b[pivot_row]

    # update objective
    @c -= @c[pivot_column] * @a[pivot_row]

    # update A and B
    (row_indices - [pivot_row]).each do |row_ix|
      r = @a[row_ix][pivot_column]
      @a[row_ix] -= r * @a[pivot_row]
      @b[row_ix] -= r * @b[pivot_row]
    end

    update_solution
  end

  def pivot_row(column_ix)
    row_ix_a_and_b = row_indices.map { |row_ix|
      [row_ix, @a[row_ix][column_ix], @b[row_ix]]
    }.reject { |_, a, b|
      a == 0
    }.reject { |_, a, b|
      (b < 0) ^ (a < 0) # negative sign check
    }
    row_ix, _, _ = *last_min_by(row_ix_a_and_b) { |_, a, b|
      Rational(b, a)
    }
    row_ix
  end

  def row_indices
    (0...@a.length).to_a
  end

  def column_indices
    (0...@a.first.size).to_a
  end

  def formatted_tableau
    if can_improve?
      pivot_column = entering_variable
      pivot_row    = pivot_row(pivot_column)
    else
      pivot_row = nil
    end
    # num_cols = @c.size + 1
    c = formatted_values(@c.to_a)
    b = formatted_values(@b.to_a)
    a = @a.to_a.map {|ar| formatted_values(ar.to_a) }
    if pivot_row
      a[pivot_row][pivot_column] = "*" + a[pivot_row][pivot_column]
    end
    max = (c + b + a + ["1234567"]).flatten.map(&:size).max
    result = []
    # result << c.map {|c| c.rjust(max, " ") }
    result << c.map {|c1| c1.rjust(max, " ") }
    a.zip(b) do |arow, brow|
      # result << (arow + [brow]).map {|a| a.rjust(max, " ") }
      result << (arow + [brow]).map {|a1| a1.rjust(max, " ") }
      result.last.insert(arow.length, "|")
    end
    # lines = result.map {|b| b.join("  ") }
    lines = result.map {|b1| b1.join("  ") }
    max_line_length = lines.map(&:length).max
    lines.insert(1, "-"*max_line_length)
    lines.join("\n")
  end

  def formatted_values(array)
    array.map {|c| "%2.3f" % c }
  end

  # like Enumerable#min_by except if multiple values are minimum
  # it returns the last
  def last_min_by(array)
    best_element, best_value = nil, nil
    array.each do |element|
      value = yield element
      if !best_element || value <= best_value
        best_element, best_value = element, value
      end
    end
    best_element
  end
end
