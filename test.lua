local luarpc = require('luarpc')

local idl = 'test.idl'

luarpc.dumpParser(idl)

local args = { 'aa', 'a', 2, nil }
print(luarpc.testValidateInputArgs('foo', args, idl))

print(luarpc.testValidateInputArgs('string', args, idl))