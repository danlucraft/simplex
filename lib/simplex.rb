require 'matrix'

class Vector
  public :[]=
end

class Simplex
  DEFAULT_MAX_PIVOTS = 10_000

  class UnboundedProblem < StandardError
  end

  attr_accessor :max_pivots

  def initialize(c, a, b)
    @pivot_count = 0
    @max_pivots = DEFAULT_MAX_PIVOTS

    # Problem dimensions
    @num_non_slack_vars = a.first.length
    @num_constraints    = b.length
    @num_vars           = @num_non_slack_vars + @num_constraints

    # Set up initial matrix A and vectors b, c
    @c = Vector[*c.map {|c1| -1*c1 } + [0]*@num_constraints]
    @a = a.map {|a1| Vector[*(a1.clone + [0]*@num_constraints)]}
    @b = Vector[*b.clone]

    unless @a.all? {|a| a.size == @c.size } and @b.size == @a.length
      raise ArgumentError, "Input arrays have mismatched dimensions" 
    end

    0.upto(@num_constraints - 1) {|i| @a[i][@num_non_slack_vars + i] = 1 }

    # set initial solution: all non-slack variables = 0
    @x          = Vector[*([0]*@num_vars)]
    @basic_vars = (@num_non_slack_vars...@num_vars).to_a
    update_solution
  end

  def solution
    solve
    current_solution
  end

  def current_solution
    @x.to_a[0...@num_non_slack_vars]
  end

  def update_solution
    0.upto(@num_vars - 1) {|i| @x[i] = 0 }

    @basic_vars.each do |basic_var|
      row_with_1 = row_indices.detect do |row_ix|
        @a[row_ix][basic_var] == 1
      end
      @x[basic_var] = @b[row_with_1]
    end
  end

  def solve
    while can_improve?
      @pivot_count += 1
      raise "Too many pivots" if @pivot_count > max_pivots 
      pivot
    end
  end

  def can_improve?
    !!entering_variable
  end

  def variables
    (0...@c.size).to_a
  end

  def entering_variable
    variables.select { |var| @c[var] < 0 }.
              min_by { |var| @c[var] }
  end

  def pivot
    pivot_column = entering_variable
    pivot_row    = pivot_row(pivot_column)
    raise UnboundedProblem unless pivot_row
    leaving_var  = basic_variable_in_row(pivot_row)
    replace_basic_variable(leaving_var => pivot_column)

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

  def replace_basic_variable(hash)
    from, to = hash.keys.first, hash.values.first
    @basic_vars.delete(from)
    @basic_vars << to
    @basic_vars.sort!
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

  def basic_variable_in_row(pivot_row)
    column_indices.detect do |column_ix|
      @a[pivot_row][column_ix] == 1 and @basic_vars.include?(column_ix)
    end
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
    num_cols = @c.size + 1
    c = formatted_values(@c.to_a)
    b = formatted_values(@b.to_a)
    a = @a.to_a.map {|ar| formatted_values(ar.to_a) }
    if pivot_row
      a[pivot_row][pivot_column] = "*" + a[pivot_row][pivot_column]
    end
    max = (c + b + a + ["1234567"]).flatten.map(&:size).max
    result = []
    result << c.map {|c| c.rjust(max, " ") }
    a.zip(b) do |arow, brow|
      result << (arow + [brow]).map {|a| a.rjust(max, " ") }
      result.last.insert(arow.length, "|")
    end
    lines = result.map {|b| b.join("  ") }
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

  def assert(boolean)
    raise unless boolean
  end

end

