require 'minitest/autorun'
$:.push(File.expand_path("../../lib", __FILE__))
require 'simplex'

class SimplexTest < MiniTest::Unit::TestCase
  def test_2x2
    result = Simplex.new(
      [1, 1],
      [
        [ 2,  1],
        [ 1,  2],
      ],
      [4, 3]
    ).solution
    assert_equal [Rational(5, 3), Rational(2, 3)], result
  end

  def test_2x2_b
    result = Simplex.new(
      [3, 4],
      [
        [ 1,  1],
        [ 2,  1],
      ],
      [4, 5]
    ).solution
    assert_equal [0, 4], result
  end

  def test_2x2_c
    result = Simplex.new(
      [2, -1],
      [
        [ 1,  2],
        [ 3,  2],
      ],
      [6, 12]
    ).solution
    assert_equal [4, 0], result
  end

  def test_3x3_a
    result = Simplex.new(
      [60, 90, 300],
      [
        [1, 1, 1],
        [1, 3, 0],
        [2, 0, 1]
      ],
      [600, 600, 900]
    ).solution
    assert_equal [0, 0, 600], result
  end

  def test_3x3_b
    result = Simplex.new(
      [70, 210, 140],
      [
        [ 1,  1,  1],
        [ 5,  4,  4],
        [40, 20, 30]
      ],
      [100, 480, 3200]
    ).solution
    assert_equal [0, 100, 0], result
  end

  def test_3x3_c
    result = Simplex.new(
      [2, -1, 2],
      [
        [ 2,  1,  0],
        [ 1,  2, -2],
        [ 0,  1,  2]
      ],
      [10, 20, 5]
    ).solution
    assert_equal [5, 0, Rational(5, 2)], result
  end

  def test_3x3_d
    result = Simplex.new(
      [11, 16, 15],
      [
        [             1,              2, Rational(3, 2)],
        [Rational(2, 3), Rational(2, 3),              1],
        [Rational(1, 2), Rational(1, 3), Rational(1, 2)]
      ],
      [12_000, 4_600, 2_400]
    ).solution
    assert_equal [600, 5_100, 800], result
  end

  def test_3x3_e
    result = Simplex.new(
      [100_000, 40_000, 18_000],
      [
        [20, 6, 3],
        [ 0, 1, 0],
        [-1,-1, 1],
        [-9, 1, 1]
      ],
      [182, 10, 0, 0]
    ).solution
    assert_equal [4, 10, 14], result
  end

  def test_4x4
    result = Simplex.new(
      [1, 2, 1, 2],
      [
        [1, 0, 1, 0],
        [0, 1, 0, 1],
        [1, 1, 0, 0],
        [0, 0, 1, 1]
      ],
      [1, 4, 2, 2]
    ).solution
    assert_equal [0, 2, 0, 2], result
  end

end
