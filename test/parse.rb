require 'simplex/parse'
require 'minitest/autorun'

describe Simplex::Parse do
  P = Simplex::Parse

  describe "Parse.term" do
    it "must parse valid terms" do
      { "-1.2A" => [-1.2, :A],
        "99x"   => [99.0, :x],
        "z"     => [ 1.0, :z],
        "-b"    => [-1.0, :b] }.each { |valid, expected|
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
      { "x + y"             => { x:  1.0, y:  1.0 },
        "2x - 5y"           => { x:  2.0, y: -5.0 },
        "-2x - 3y + -42.7z" => { x: -2.0, y: -3.0, z: -42.7 },
        " -5y + -x  "       => { y: -5.0, x: -1.0 },
        "a - -b"            => { a:  1.0, b:  1.0 },
        "a A b"             => { a:  1.0, :A => 1.0, b: 1.0 },
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
      { "x + y <= 4"              => [{ x: 1.0, y: 1.0 }, 4.0],
        "0.94a - 22.1b <= -14.67" => [{ a: 0.94, b: -22.1 }, -14.67],
        "x <= 0"                  => [{ x: 1.0 }, 0],
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

describe "Simplex.maximize" do
  it "must problem stuff" do
    prob = Simplex.problem(maximize: 'x + y',
                           constraints: ['2x + y <= 4',
                                         'x + 2y <= 3'])
    sol = prob.solution
    sol.must_equal [Rational(5, 3), Rational(2, 3)]
  end

  it "must maximize stuff" do
    Simplex.maximize('x + y',
                     '2x + y <= 4',
                     'x + 2y <= 3').must_equal [Rational(5, 3),
                                                Rational(2, 3)]
  end
end
