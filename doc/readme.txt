![luaepnf Logo](luaepnf.png)

#               luaepnf -- Extended PEG Notation Format              #

##                           Introduction                           ##

The [LPeg][1] library is a powerful tool to parse text and extract
parts of it using captures. It even provides grammars, which can be
used to parse non-regular languages, but the complexer the language
gets, the more difficult error handling and keeping track of captured
information becomes. `luaepnf` enhances usage of LPeg grammars by
building an abstract syntax tree (AST) for the input and providing
tools for error reporting, as well as offering syntax sugar and
shortcuts for accessing LPeg's features.


##                           Basic Usage                            ##

The `luaepnf` module provides syntax sugar for defining [LPeg][1]
grammars with error handling and AST building:

    $ cat > test.lua
    local epnf = require( "epnf" )

    local g = epnf.define( function(_ENV)
      local _ = WS^0
      local number = C( P"-"^-1 * R"09"^1 )
      local err = E"variable, number, or '(' expected"
    
      START "expr"
      expr = _ * (V"aexpr"+err) * EOF"operator (+-*/) expected"
      aexpr = V"mexpr" * (S"+-" * _ * (V"mexpr"+err))^0
      mexpr = V"term" * (S"*/" * _ * (V"term"+err))^0
      term = (ID + number + (P"(" * _ *
             (V"aexpr"+err) * (P")"+E") expected"))) * _
    end )

    local s = "12 + 9"
    --local s = "12 + 9 * (c+11)"
    --local s = "1 1"
    --local s = "*"
    print( '"' .. s .. '"' )
    local ast = epnf.parsestring( g, s )
    epnf.dumpast( ast )
    ^D

The output is the abstract syntax tree (or an error message):
    $ lua test.lua
    "12 + 9"
    {
      id = expr,  pos = 1
      1 = {
        id = aexpr,  pos = 1
        1 = {
          id = mexpr,  pos = 1
          1 = {
            id = term,  pos = 1
            1 = 12
          }
        }
        2 = {
          id = mexpr,  pos = 6
          1 = {
            id = term,  pos = 6
            1 = 9
          }
        }
      }
    }

  [1]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html      (LPeg)


##                             Reference                            ##

The `luaepnf` module provides the following public functions:

*   `epnf.define( func [, g] ) -> g`

    This function provides a suitable environment for the given
    function `func()` which must take a single parameter called `_ENV`
    for Lua 5.2 and up, and calls it to execute the rule definitions
    contained in `func()`. It returns an LPeg grammar table containing
    the patterns for the rule definitions. If a table is given as a
    second argument, the patterns are stored there. This can be used
    to change/complete an existing grammar.

*   `epnf.parse( g, name, input [, ...] ) -> ast, name, input`

    This function calls LPeg's `match()` function with the given
    grammar `g` and `input` string. The input's `name` is passed
    via `Carg( 1 )`, and is used in error messages. All remaining
    arguments are free for use and can be accessed in the grammar
    using `Carg( 2 )` and up.

    Return value is a tree structure representing the AST of the
    input under the given grammar. This function can return nil or
    raise an error depending on the error handling strategy in the
    grammar if the matching fails. The last two return values are only
    useful if you intend to use the `epnf.raise()` function.

*   `epnf.parsefile( g, filename [, ...] ) -> ast, name, input`

    Calls `epnf.parse()` with the contents of the given file.

*   `epnf.parsestring( g, string [, ...] ) -> ast, name, input`

    Calls `epnf.parse()` with a name derived from the input string.

*   `epnf.dumpast( ast )`

    This function prints a human readable representation of the `ast`
    to `stderr`. It is useful during development or debugging.

*   `epnf.raise( name, msg, source, position )`

    This function raises an error similar to the LPeg pattern
    `E( msg )` (see below) with input name, line number and a visual
    marker for `position`. It can be used during validation of the
    AST, which has suitable positions in the `pos` field of its nodes.
    `name` and `source` are typically kept from the `epnf.parse*()`
    function calls.


###            Custom Environment for Grammar Definition           ###

The `epnf.define()` function calls its argument with a custom
environment, which contains all LPeg patterns and the extra patterns
and functions listed below. The environment also has a `__newindex`
metamethod which creates rules on each global assignment, that later
can be referenced using LPeg's `V( name )` operator. The pattern on
the right handside of an assignment is enhanced to construct an AST
node (a table) when matched. Each AST node contains an `id` field with
the name of the matching rule, a `pos` field with the byte position of
the match in the input string, and all captures and AST nodes for
matching rule references in the pattern in the array part of the
table.

*   `START( name )`

    This function sets the name of the starting rule of the resulting
    LPeg grammar.

*   `E( [msg] )`

    Creates an LPeg pattern that, when matched by LPeg, raises a parse
    error using the custom error message with input name, line number,
    and error location. If `msg` is absent or nil, a generic parse
    error is raised.

*   `EOF( [msg] )`

    Raises a parse error using the optional error message if there are
    any unprocessed input characters left. Never use this pattern in
    recursive rules!

*   `ID`

    An LPeg pattern that matches and captures an identifier as used in
    programming languages, i.e. letters and `_` followed by letters,
    digits, or `_`.

*   `W( word )`

    Creates an LPeg pattern similar to `P( word )`, but makes sure,
    that word is not followed by letters, numbers, or `_` (so it
    matches complete words only). Does not capture anything.

*   `WS`

    Matches a single whitespace character. Captures nothing.

Every predefined pattern or function in the custom environment starts
with a capital letter, so using lower-case rule names is advisable to
avoid naming conflicts.


##                             Download                             ##

The source code (with documentation and test scripts) is available on
[github][2].

  [2]:  https://github.com/siffiejoe/lua-luaepnf/


##                           Installation                           ##

There are two ways to install this module, either using luarocks (if
this module already ended up in the [main luarocks repository][3]) or
manually.

Using luarocks, simply type:

    luarocks install luaepnf

To install the module manually just drop `epnf.lua` somewhere into
your Lua `package.path`.

  [3]:  http://luarocks.org/repositories/rocks/    (Main Repository)


##                             Contact                              ##

Philipp Janda, siffiejoe(a)gmx.net

Comments and feedback are always welcome.


##                             License                              ##

luaepnf is *copyrighted free software* distributed under the MIT
license (the same license as Lua 5.1). The full license text follows:

    luaepnf (c) 2013 Philipp Janda

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHOR OR COPYRIGHT HOLDER BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


