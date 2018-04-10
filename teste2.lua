local luarpc = require("luarpc")


local client1 = luarpc.createProxy("localhost", arg[1], "simple.idl")
local client2 = luarpc.createProxy("localhost", arg[2], "lua.idl")

print("\ncall foo - client1")
local resultFoo = client1.foo("teste\nteste")
print(type(resultFoo).." -> "..resultFoo)

print("\ncall foo - client2")
local resultDouble, resultStr = client2.foo(1, 2, "teste\nteste")
print(type(resultDouble).." -> "..resultDouble)
print(type(resultStr).." -> "..resultStr)