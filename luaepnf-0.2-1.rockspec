package = "luaepnf"
version = "0.2-1"
source = {
  url = "git://github.com/siffiejoe/lua-luaepnf.git",
  tag = "v0.2",
}
description = {
  summary = "Extended PEG Notation Format (easy grammars for LPeg)",
  detailed = [[
    This Lua module provides sugar for writing grammars/parsers using
    the LPeg library. It simplifies error reporting and AST building.
  ]],
  homepage = "http://siffiejoe.github.com/lua-luaepnf/",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1, <= 5.2",
  "lpeg >= 0.8"
}
build = {
  type = "builtin",
  modules = {
    [ "epnf" ] = "src/epnf.lua",
  }
}

