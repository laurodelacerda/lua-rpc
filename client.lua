local socket = require("socket")
local luarpc = require("luarpc")

IP = "127.0.0.1"
porta1 = 44444
porta2 = 44445

idl = "lua.idl"

local p1 = luarpc.createProxy(IP, porta1, idl)
local p2 = luarpc.createProxy(IP, porta2, idl)

-- local r, s = p1:foo(3, 5)
-- local t = p2:boo(10)

-- print(r, s)
-- print(t)

