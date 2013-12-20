require 'matrix'

class Matrix
  unless method_defined?(:[]=)
    def []=(i, j, x)
      @rows[i][j] = x
    end
  end

  unless method_defined?(:row_count)
    def row_count
      @rows.size
    end
  end

  unless method_defined?(:column_count)
    def column_count
      column_vectors.length
    end
  end
end

class Vector
  public :[]=
end

class Simplex
  DEFAULT_MAX_PIVOTS = 10_000

  attr_accessor :max_pivots

  def initialize(c, a, b)
    @pivot_count = 0
    @max_pivots = DEFAULT_MAX_PIVOTS

    # Problem dimensions
    @num_non_slack_vars = a.first.length
    @num_constraints    = b.length
    @num_vars           = @num_non_slack_vars + @num_constraints
    @x                  = Array.new(@num_vars)

    # Set up initial matrix A and vectors b, c
    @c = Vector[*c.map {|c1| -1*c1 } + [0]*@num_constraints]
    @a = Matrix[*a.map {|a1| a1.clone + [0]*@num_constraints}]
    @b = Vector[*b.clone]
    0.upto(@num_constraints - 1) {|i| @a[i, @num_non_slack_vars + i] = 1 }

    # set initial solution: all non-slack variables = 0
    @basic_vars = ((@num_non_slack_vars)...(@num_vars)).to_a
    update_solution
  end

  def solve
    while can_improve?
      @pivot_count += 1
      raise "Too many pivots" if @pivot_count > max_pivots 
      pivot
    end
  end

  def pivot
    pivot_column = entering_variable_ix
    pivot_row    = minimum_coefficient_ratio_row_ix(pivot_column)
    leaving_var = leaving_variable(pivot_row)
    @basic_vars.delete(leaving_var)

    # update objective
    c_ratio = Rational(@c[pivot_column], @a[pivot_row, pivot_column])
    @c = @c - (@a.row(pivot_row)*c_ratio)

    # update pivot row
    ratio = Rational(1, @a[pivot_row, pivot_column])
    0.upto(@a.column_count - 1) do |column_ix|
      @a[pivot_row, column_ix] = ratio * @a[pivot_row, column_ix]
    end
    @b[pivot_row] = ratio * @b[pivot_row]

    # update A and B
    0.upto(@a.row_count - 1) do |row_ix|
      next if row_ix == pivot_row
      ratio = @a[row_ix, pivot_column]
      0.upto(@a.column_count - 1) do |column_ix|
        @a[row_ix, column_ix] = @a[row_ix, column_ix] - ratio*@a[pivot_row, column_ix]
      end
      @b[row_ix] = @b[row_ix] - ratio*@b[pivot_row]
    end

    @basic_vars << pivot_column
    @basic_vars.sort!
    update_solution
  end

  def update_solution
    0.upto(@num_vars - 1) {|i| @x[i] = 0 }
    @basic_vars.each do |basic_var|
      row_coeff_1 = nil
      0.upto(@a.row_count - 1) do |row_ix|
        coeff = @a[row_ix, basic_var]
        if coeff == 1
          if row_coeff_1 == nil
            row_coeff_1 = row_ix
          end
        end
      end
      @x[basic_var] = @b[row_coeff_1]
    end
  end

  def solution
    solve
    @x.to_a[0...@num_non_slack_vars]
  end

  def can_improve?
    !!entering_variable_ix
  end

  def entering_variable_ix
    current_min_value = nil
    current_min_index = nil
    @c.each_with_index do |v, i| 
      if v < 0
        if current_min_value == nil || v < current_min_value
          current_min_value = v
          current_min_index = i
        end
      end
    end
    current_min_index
  end

  def leaving_variable(pivot_row)
    0.upto(@a.column_count - 1) do |column_ix|
      if @a[pivot_row, column_ix] == 1 and @basic_vars.include?(column_ix)
        return column_ix
      end
    end
  end

  def formatted_tableau(pivot_column=nil, pivot_row=nil)
    num_cols = @c.size + 1
    c = @c.to_a.map {|c| "%2.3f" % c }
    b = @b.to_a.map {|b| "%2.3f" % b }
    a = @a.to_a.map {|ar| ar.map {|a| "%2.3f" % a}}
    if pivot_row
      a[pivot_row][pivot_column] = "*" + a[pivot_row][pivot_column]
    end
    max = (c + b + a + ["1234567"]).flatten.map(&:length).max
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

  def minimum_coefficient_ratio_row_ix(column_ix)
    current_min_value = nil
    current_min_index = nil
    0.upto(@a.row_count - 1) do |row_ix|
      next if @a[row_ix, column_ix] == 0
      b_val = @b[row_ix]
      a_val = @a[row_ix, column_ix]
      ratio = Rational(b_val, a_val)
      is_negative = (@b[row_ix] < 0 || @a[row_ix, column_ix] < 0) && !(@b[row_ix] < 0 && @a[row_ix, column_ix] < 0)
      if !is_negative && (!current_min_value || ratio <= current_min_value)
        current_min_value = ratio
        current_min_index = row_ix
      end
    end
    return current_min_index
  end
end

