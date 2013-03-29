#!/usr/bin/lua
package.path = package.path .. ";../src/?.lua"
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

