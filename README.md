
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


