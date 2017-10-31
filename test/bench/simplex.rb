require 'simplex'
require 'benchmark/ips'

Benchmark.ips do |b|
  b.config time: 3, warmup: 0.5

  b.report("Simplex Array") {
    Simplex.new([1, 1],
                [[2,  1],
                 [1,  2]],
                [4, 3]).solution

    Simplex.new([3, 4],
                [[1, 1],
                 [2, 1]],
                [4, 5]).solution

    Simplex.new([2, -1],
                [[1, 2],
                 [3, 2],],
                [6, 12]).solution

    Simplex.new([60, 90, 300],
                [[1, 1, 1],
                 [1, 3, 0],
                 [2, 0, 1]],
                [600, 600, 900]).solution

    Simplex.new([70, 210, 140],
                [[1, 1, 1],
                 [5, 4, 4],
                 [40, 20, 30]],
                [100, 480, 3200]).solution

    Simplex.new([2, -1, 2],
                [[2, 1, 0],
                 [1, 2, -2],
                 [0, 1, 2]],
                [10, 20, 5]).solution

    Simplex.new([11, 16, 15],
                [[1, 2, Rational(3, 2)],
                 [Rational(2, 3), Rational(2, 3), 1],
                 [Rational(1, 2), Rational(1, 3), Rational(1, 2)]],
                [12_000, 4_600, 2_400]).solution

    Simplex.new([5, 4, 3],
                [[2, 3, 1],
                 [4, 1, 2],
                 [3, 4, 2]],
                [5, 11, 8]).solution

    Simplex.new([3, 2, -4],
                [[1, 4, 0],
                 [2, 4,-2],
                 [1, 1,-2]],
                [5, 6, 2]).solution

    Simplex.new([2, -1, 8],
                [[2, -4, 6],
                 [-1, 3, 4],
                 [0, 0, 2]],
                [3, 2, 1]).solution

    Simplex.new([100_000, 40_000, 18_000],
                [[20, 6, 3],
                 [0, 1, 0],
                 [-1,-1, 1],
                 [-9, 1, 1]],
                [182, 10, 0, 0]).solution

    Simplex.new([1, 2, 1, 2],
                [[1, 0, 1, 0],
                 [0, 1, 0, 1],
                 [1, 1, 0, 0],
                 [0, 0, 1, 1]],
                [1, 4, 2, 2]).solution

    Simplex.new([10, -57, -9, -24],
                [[0.5, -5.5, -2.5, 9],
                 [0.5, -1.5, -0.5, 1],
                 [ 1,    0,    0, 0]],
                [0, 0, 1]).solution

    Simplex.new([25, 20],
                [[20, 12],
                 [1, 1]],
                [1800, 8*15]).solution
  }

#b.report("Simplex Array") {
#}

#b.report("Simplex Matrix") {
#}

#  b.compare!
end
