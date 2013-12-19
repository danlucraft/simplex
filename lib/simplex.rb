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
  DEFAULT_MAX_ITERATIONS = 10_000

  attr_accessor :max_iterations

  def initialize(c, a, b)
    @max_iterations = DEFAULT_MAX_ITERATIONS
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

    @basic_vars = ((@num_non_slack_vars)...(@num_vars)).to_a

    # set initial solution: all non-slack variables = 0
    update_solution
    @solved = false
  end

  def solve
    return if @solved
    i = 0
    while can_improve?
      i += 1
      raise "Too many iterations" if i > max_iterations 

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
    @solved = true
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

