require 'simplex/parse'
require 'minitest/autorun'

describe Simplex::Parse do
  P = Simplex::Parse

  describe "Parse.term" do
    it "must parse valid terms" do
      { "-1.2A" => [-1.2, :A],
        "99x" => [99.0, :x],
        "z" => [1.0, :z],
        "-b" => [-1.0, :b] }.each { |valid, expected|
        P.term(valid).must_equal expected
      }
    end

    it "must reject invalid terms" do
      ["3xy", "24/7x", "x17", "2*x"].each { |invalid|
        proc { P.term(invalid) }.must_raise RuntimeError
      }
    end
  end

  describe "Parse.expression" do
    it "must parse valid expressions" do
      { "x + y" => [[1.0, 1.0], [:x, :y]],
        "2x - 5y" => [[2.0, -5.0], [:x, :y]],
        "-2x - 3y + -42.7z" => [[-2.0, -3.0, -42.7], [:x, :y, :z]],
        " -5y + -x  " => [[-5.0, -1.0], [:y, :x]],
        "a - -b" => [[1.0, 1.0], [:a, :b]],
        "a b c" => [[1.0, 1.0, 1.0], [:a, :b, :c]],
      }.each { |valid, expected|
        P.expression(valid).must_equal expected
      }
    end

    it "must reject invalid expressions" do
      ["a2 + b2 = c2",
       "x + xy",
       "x * 2"].each { |invalid|
        proc { P.expression(invalid) }.must_raise P::Error
      }
    end
  end

  describe "Parse.tokenize" do
    it "ignores leading or trailing whitespace" do
      P.tokenize("  5x + 2.9y ").must_equal ["5x", "+", "2.9y"]
    end

    it "ignores multiple spaces" do
      P.tokenize("5x   +   2.9y").must_equal ["5x", "+", "2.9y"]
    end
  end

  describe "Parse.inequality" do
    it "must parse valid inequalities" do
      { "x + y <= 4" => [[1.0, 1.0], [:x, :y], 4.0],
        "0.94a - 22.1b <= -14.67" => [[0.94, -22.1], [:a, :b], -14.67],
        "x <= 0" => [[1.0], [:x], 0],
      }.each { |valid, expected|
        P.inequality(valid).must_equal expected
      }
    end

    it "must reject invalid inequalities" do
      ["x + y >= 4",
       "0.94a - 22.1b <= -14.67c",
       "x < 0",
      ].each { |invalid|
        proc { P.inequality(invalid) }.must_raise P::Error
      }
    end
  end
end
