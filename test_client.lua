local luarpc = require("luarpc")

local idl = "simple.idl"

client = luarpc.createProxy("localhost", arg[1], idl)

print(client.foo("teste"))

