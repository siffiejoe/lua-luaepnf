#!/usr/bin/lua

package.path = "../src/?.lua;" .. package.path
local epnf = require( "epnf" )


-- luacheck: ignore _ENV dsl dir file owner group mode action
local g = epnf.define( function(_ENV)
  local _ = WS^0
  local str_E = P'"' * C( (P( 1 )-P'"')^0 ) * P'"'
                + E"string literal expected"

  START "dsl"
  dsl = _ * (V"dir"+V"file")^0 * EOF"directory or file expected"
  dir = W"directory" * _ * (str_E) * _ * (P"{"+E"{ expected") * _ *
        (V"owner" + V"group" + V"mode" + V"action")^0 *
        (P"}"+E"owner|group|mode|action|} expected") * _
  file = W"file" * _ * (str_E) * _ * (P"{"+E"{ expected") * _ *
         (V"owner" + V"group" + V"mode" + V"action")^0 *
         (P"}"+E"owner|group|mode|action|} expected") * _
  owner = W"owner" * _ * (str_E) * _
  group = W"group" * _ * (str_E) * _
  mode = W"mode" * _ * (str_E) * _
  action = W"action" * _ * (str_E) * _
end )

local function check_ast( node, name, inp )
  if node.id == "mode" then -- obviously LPeg grammar could check ...
    if not string.match( node[ 1 ], "^0[0-7][0-7][0-7]$" ) then
      epnf.raise( name, "invalid mode string", inp, node.pos )
    end
  end
  -- add more tests here ...
  for _,v in ipairs( node ) do
    if type( v ) == "table" and v.id then
      check_ast( v, name, inp )
    end
  end
end

local function test( s )
  local ok, ast, name, inp = pcall( epnf.parsestring, g, s )
  if ok then
    epnf.dumpast( ast )
    print( select( 2, pcall( check_ast, ast, name, inp ) ) )
  else
    print( ast )
  end
  print( ("#"):rep( 80 ) )
end


test[[
directory "/etc/" {
  owner "root"
  group "wheel"
  mode "0755"
  action "create"
}
file "/etc/passwd" {
  owner "root"
  group "wheel"
  mode "075"
  action "create"
}
]]

test[[
directory "" {}
file ""
]]

test[[
directory "/etc/" {
  owner "root"
  gruop "wheel"
  mode "0755"
  action "create"
}
]]


