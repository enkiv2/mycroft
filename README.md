
       __  ___                  _____ 
      /  |/  /_ _____________  / _/ /_ Composite
     / /|_/ / // / __/ __/ _ \/ _/ __/     Logic
    /_/  /_/\_, /\__/_/  \___/_/ \__/   Language
           /___/  v. 0.01

=======
A prolog-like language with compound truth value logic

See [the language documentation](mycroft-lang.md), or [some simple example code from the test suite](test.myc).

For best performance, use with luajit and install readline and luasocket:

    luarocks-5.1 install readline luasocket
    luajit mycroft.lua

Or, alternately, built and install from the rockspec file:

    luarocks-5.1 build mycroft-0.01-1.rockspec


# FAQ

## What is Mycroft?

Mycroft is a logic language with a syntax similar to PROLOG. It additionally has support for transparent distributed computing and composite truth values.

## Why not just use PROLOG?

PROLOG, partly for historical reasons, is quite slow. It performs a depth-first search on the logic tree, in a single thread. Automatic memoization can't be used because determinate 'pure prolog' predicates can be freely mixed with indeterminate predicates like i/o and random number generation.

Mycroft has notation for whether or not predicates are determinate. It memoizes the results of determinate predicates, meaning that a determinate predicate will finish immediately the second time it's run. It memoizes intermediate results for determinate predicates, meaning that even an indeterminate predicate will run faster the second time it's run, if it depends upon determinate predicates. Additionally, a group of Mycroft instances can be formed into a cluster, wherein the results for any determinate predicates will be distributed to all instances, and the work of evaluating a predicate can be distributed across instances.

## What are composite truth values?

A composite truth value is a concept borrowed from Probablistic Logic Networks, and consists of two components -- a percentage truth (or percentage likelihood of truth) and a percentage confidence. A truth value of 1 with a confidence value of 1 is 100% true with 100% confidence; a truth value of 0 with a confidence of 1 is false with 100% confidence; a truth value of 0.5 with a confidence of 0.75 indicates that the system is 75% sure that the predicate is 50% likely to be true (or is 75% sure that the predicate is 50% true).

