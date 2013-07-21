#!/usr/bin/lua

package.path = "../src/?.lua;" .. package.path
local epnf = require( "epnf" )


local nan, inf = 0/0, 1/0

local pg = epnf.define( function(_ENV) -- begin of grammar definition
  -- some useful lexical patterns
  local any = P( 1 )
  local comment = ((P"//"+P"#") * (any-P"\n")^0) +
                  (P"/*" * (any-P"*/")^0 * P"*/") -- comments
  local _ = (WS + comment)^0  -- white space
  local sign = S"+-"
  local digit = R"09"
  local digit1 = R"19"
  local octdigit = R"07"
  local hexdigit = R( "09", "af", "AF" )
  local decimal = P"0" + (digit1 * digit^0)
  local int = C( sign^-1 * decimal ) / tonumber
  local oct = P"0" * (C( octdigit^1 ) * Cc( 8 )) / tonumber
  local hex = P"0" * S"xX" * (C( hexdigit^1 ) * Cc( 16 )) / tonumber
  local letter = R( "az", "AZ" ) + P"_"
  local charescape = P"\\" * C( S"abfnrtv\\'\"" ) / {
    [ "a" ] = "\a", [ "b" ] = "\b", [ "f" ] = "\f",
    [ "n" ] = "\n", [ "r" ] = "\r", [ "t" ] = "\t",
    [ "v" ] = "\v", [ "\\" ] = "\\", [ "'" ] = "'",
    [ '"' ] = '"'
  }
  local hexescape = P"\\" * S"xX" * C( hexdigit * hexdigit^-1 ) / function( s )
    return string.char( tonumber( s, 16 ) )
  end
  local octescape = P"\\" * C( P"0"^-1 * octdigit * octdigit^-2 ) / function( s )
    return string.char( tonumber( s, 8 ) )
  end
  local sliteral = (P'"' * Cs( (charescape + hexescape +
                     octescape + (any-P'"'))^0 ) * P'"') +
                   (P"'" * Cs( (charescape + hexescape +
                     octescape + (any-P"'"))^0 ) * P"'")
  local bool = C( W"true" + W"false" ) / { [ "true" ] = true,
                                           [ "false" ] = false }
  local integer = hex + oct + int
  local special_float = C( W"inf" + W"-inf" + W"nan" ) / {
    nan = nan, inf = inf, [ "-inf" ] = -inf
  }
  local float = C( sign^-1 * decimal * (P"." * digit^1)^-1 *
                   (S"Ee" * sign^-1 * digit^1)^-1 ) / tonumber
                + special_float
  local rawname = letter * (letter + digit)^0
  local rel_ref = rawname * (P"." * rawname)^0
  local abs_ref = P"." * rel_ref
  --local ref = C( abs_ref + rel_ref )
  local ref = C( P"."^-1 * rel_ref )
  local oref = ((P"(" * _ * ref * _ * (P")"+E()) * C( abs_ref )^-1)
                 / function( a, b ) return a .. (b or "") end) + ref
  local oval = bool + integer + float + sliteral + ID + V"msgoptionv"
  local empty_statement = P";" * _
  local syntax = W"syntax" * _ * (P"="+E()) * _ * (W"proto2"+E()) *
                 _ * (P";"+E()) * _
  local function csv( expr )
    return expr * (P"," * _ * expr)^0
  end


  START "protofile"
  protofile = _ * syntax^-1 * (V"message" + V"import" + V"package" +
              V"enum" + V"extend" + V"option" + V"service" +
              empty_statement)^0 * EOF()
  message = W"message" * _ * (ID+E()) * _ * (P"{"+E()) * _ *
            (V"messagefield" + V"enum" + V"message" + V"extensions" +
            V"extend" + V"option" + empty_statement)^0 * (P"}"+E()) * _
  import = W"import" * _ * (sliteral+E()) * _ * (P";"+E()) * _
  package = W"package" * _ * (ref+E()) * _ * (P";"+E()) * _
  enum = W"enum" * _ * (ID+E()) * _ * (P"{"+E()) * _ *
         (V"enumfield" + V"option" + empty_statement)^0 * (P"}"+E()) * _
  extend = W"extend" * _ * (ref+E()) * _ * (P"{"+E()) * _ *
           (V"messagefield" + empty_statement)^0 * (P"}"+E()) * _
  option = W"option" * _ * (oref+E()) * _ * (P"="+E()) * _ *
           (oval+E()) * _ * (P";"+E()) * _
  service = W"service" * _ * (ID+E()) * _ * (P"{"+E()) * _ *
            (V"option" + V"rpc" + empty_statement)^0 * (P"}"+E()) * _
  local fieldoptions = (P"[" * _ * csv( (V"fieldoption"+E()) * _ ) *
                         (P"]"+E()))^-1 * _
  messagefield = C( (W"required" + W"optional" + W"repeated") ) * _ *
                 (ref+E()) * _ * (ID+E()) * _ * (P"="+E()) * _ *
                 (integer+E()) * _ * fieldoptions * (P";"+E()) * _
  local ext_range = ((integer+E()) * _ * (W"to" * _ *
                      (integer+C( W"max" )+E()) * _)^-1) / function( s, e )
                        return s, e or s
                      end
  extensions = W"extensions" * _ * csv( ext_range ) * (P";"+E()) * _
  enumfield = ID * _ * (P"="+E()) * _ * (integer+E()) * _ *
              fieldoptions * (P";"+E()) * _
  fieldoption = oref * _ * (P"="+E()) * _ * (oval+E()) * _
  msgoptionv = P"{" * _ * (ID * _ * P":" * _ * oval * _)^1 * (P"}"+E())
  rpc = W"rpc" * _ * (ID+E()) * _ *
          (P"("+E()) * _ * (ref+E()) * _ * (P")"+E()) * _ *
          (W"returns"+E()) * _ *
          (P"("+E()) * _ * (ref+E()) * _ * (P")"+E()) * _ *
            ((P"{" * _ *
              (V"option" + empty_statement)^0 *
             (P"}"+E())) + (P";"+E())) * _
end ) -- end of grammar definition


local function test( s )
  local ok, ast = pcall( epnf.parsestring, pg, s )
  if ok then
    epnf.dumpast( ast )
  else
    print( ast )
  end
  print( ("#"):rep( 70 ) )
end


test[[
message Person {
  required string name = 1;
  required int32 id = 2;
  optional string email = 3;

  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }

  message PhoneNumber {
    required string number = 1;
    optional PhoneType type = 2;
  }

  repeated PhoneNumber phone = 4;
}

message Person2 {
  required string name = 1;
  required int32 id = 2;
  extensions 4 to max;
}

extend Person2 {
  repeated Person.PhoneNumber phone = 4;
}
]]


