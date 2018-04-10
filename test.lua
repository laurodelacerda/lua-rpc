local luarpc = require('luarpc')

local idl = 'test.idl'

-- luarpc.dumpParser(idl)

-- local args = { 'aa', 'a', 2  }

-- print("args:")
-- require 'pl.pretty'.dump(args)
  

-- print(luarpc.testValidateInputArgs('foo', args, idl))

-- print(luarpc.testValidateInputArgs('string', args, idl))

-- print(luarpc.testValidateInputArgs('too', args, idl))


local test = "teste\nteste"

print(test)
test = string.gsub(test, '\n', '\\:-)\\')
print(test)

test = string.gsub(test, '%\\%:%-%)%\\', '\n')
print(test)