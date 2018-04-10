local luarpc = require("luarpc")

local idl = "simple.idl"

client = luarpc.createProxy("localhost", arg[1], idl)

print("\ncall foo")
local resultFoo = client.foo("teste\nteste")
print(type(resultFoo).." -> "..resultFoo)

print("\ncall cast")
local resultCast = client.cast(123)
print(type(resultCast).." -> "..resultCast)

print("\ncall boo")
local resultboo1, resultboo2 = client.boo(1, 2, 'function boo')   
print(type(resultboo1)..": "..resultboo1)
print(type(resultboo2)..": "..resultboo2)

print("\ncall voidFunc")
local result = client.voidFunc('a')
print(type(result))
print(result)
