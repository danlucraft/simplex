
simplex
=======

A naive pure-Ruby implementation of the Simplex algorithm for solving linear programming problems.

## Why?

I wrote this because I needed to solve some small allocation problems for a web game I'm writing, 
and there didn't seem to be any Ruby 2.0 bindings for the "pro" solver libraries, 
and anyway they are hard to install on Heroku.

 * *Use it for*: small LP problems, when you have trouble loading native or Java solvers,
     and when you can accept not that great performance. 
 * *Don't use it for*: large LP problems, when you have access to native solvers, when you need very fast solving time.

It's written for legibility over efficiency, so you may find the code useful as an example of
how to write a Simplex solver.

## Usage

## Performance

