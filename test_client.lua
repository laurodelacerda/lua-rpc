local luarpc = require("luarpc")

local idl = "simple.idl"

client = luarpc.createProxy("localhost", arg[1], idl)

local resultFoo = client.foo("teste\nteste")
print(type(resultFoo).." -> "..resultFoo)

local resultCast = client.cast(123, 456)
print(type(resultCast).." -> "..resultCast)
