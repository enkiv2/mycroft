
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

PROLOG, partly for historical reasons, is quite slow (high time complexity for both worst-case and average-case, compared to solutions implemented in other languages for many classes of problems). It performs a depth-first search on the logic tree, in a single thread. Automatic memoization can't be used because determinate 'pure prolog' predicates can be freely mixed with indeterminate predicates like i/o and random number generation. Implicit parallelism is complicated to implement because programs assume that branches will be run in order -- meaning that any implicitly parallel PROLOG needs to be able to interrupt and roll back branches that would not have run in a purely linear execution model in order to remain standard.


Mycroft has notation for whether or not predicates are determinate. It memoizes the results of determinate predicates, meaning that a determinate predicate will finish immediately the second time it's run. It memoizes intermediate results for determinate predicates, meaning that even an indeterminate predicate will run faster the second time it's run, if it depends upon determinate predicates. Additionally, a group of Mycroft instances can be formed into a cluster, wherein the results for any determinate predicates will be distributed to all instances, and the work of evaluating a predicate can be distributed across instances.

## How does Mycroft differ from PROLOG?

1. Mycroft doesn't perform real unification -- meaning that

    ?- set(X, hello), print(X).

is not the same as

    ?- print(X), set(X, hello).

Instead, Mycroft enforces functional-style single-assignment of values to identifiers within predicates.

2. Because of the use of composite truth values, Mycroft implicitly supports the open-world assumption -- in other words, queries that cannot be resolved as true are resolved as some non-true value rather than necessarily false, and queries that cannot be resolved at all are evaluated as unknown (the truth value |0>, also known as NC or 'No Confidence'). This means that you can't prove by exhaustion -- there is no direct Mycroft equivalent of the PROLOG built-in '/+'.

3. Mycroft does not attempt to expand possible values for a variable. This is related to differences #1 and #2 -- we can't expand to the whole Herbrand universe because we assume that the universe is open, and so we can't do real unification because the set of atoms that could be substituted is unbounded. This is both positive -- you can't run into an accidental infinite loop trying to evaluate a predicate for all integers -- and negative -- you can't implicitly use this system for discovery, but instead must produce the set of atoms you're interested in and iterate over them yourself.

## What are composite truth values?

A composite truth value is a concept borrowed from Probablistic Logic Networks, and consists of two components -- a percentage truth (or percentage likelihood of truth) and a percentage confidence. A truth value of 1 with a confidence value of 1 is 100% true with 100% confidence; a truth value of 0 with a confidence of 1 is false with 100% confidence; a truth value of 0.5 with a confidence of 0.75 indicates that the system is 75% sure that the predicate is 50% likely to be true (or is 75% sure that the predicate is 50% true).

# Future plans

Eventually, I'd like this software to run reasonably well on the ESP8266 under NodeMCU. One of the reasons that logic languages failed back in the 80s is that even projects that attempted parallelism (such as the Japanese government's 5th Generation Computing initiative) attempted parallelism in a context of single large computers in a strictly ordered environment; however, running a distributed caching logic language on a network of $3 standalone wifi controllers means that someone can spend $60 and get a 20-node cluster that'll fit in their pocket, or embed multiple nodes in clothing and allow temporary networks to form whenever multiple nodes come within wifi range of each other.
