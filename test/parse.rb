require 'simplex/parse'
require 'minitest/autorun'

describe Simplex::Parse do
  describe "Parse.term" do
    it "must parse valid terms" do
      { "-1.2A" => [-1.2, :A],
        "99x" => [99.0, :x],
        "z" => [1.0, :z],
        "-b" => [-1.0, :b] }.each { |valid, expected|
        Simplex::Parse.term(valid).must_equal expected
      }
    end

    it "must reject invalid terms" do
      ["3xy", "24/7x", "x17", "2*x"].each { |invalid|
        proc { Simplex::Parse.term(invalid) }.must_raise RuntimeError
      }
    end
  end

  describe "Parse.objective" do
    it "must parse valid expressions" do
      { "x + y" => [[1.0, 1.0], [:x, :y]],
        "2x - 5y" => [[2.0, -5.0], [:x, :y]],
        "-2x - 3y + -42.7z" => [[-2.0, -3.0, -42.7], [:x, :y, :z]],
      }.each { |valid, expected|
        Simplex::Parse.objective(valid).must_equal expected
      }
    end

    it "must reject invalid expressions" do
      ["a2 + b2 = c2", "x + xy", "x * 2"].each { |invalid|
        proc { Simplex::Parse.objective(invalid) }.must_raise RuntimeError
      }
    end
  end
end
