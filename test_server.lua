myobj1 = { foo = 
             function (a, b, s)
               return a+b, "alo alo"
             end,
          boo = 
             function (n)
               return n
             end
        }
myobj2 = { foo = 
             function (a, b, s)
               return a-b, "tchau"
             end,
          boo = 
             function (n)
               return 1
             end
        }

myobj3 = {	
  foo = function(a)
    return a
  end,
  cast = function(a, b)
    return tonumber(a + b)
  end,
  boo = function (a, b, c)
    return c, a + b
  end ,
  voidFunc = function(a)
    print(a)
  end,
  voidFunc2 = function()
    print('voidFunc2')
  end
}

luarpc = require("luarpc")

local server1 = luarpc.createServant(myobj3, "simple.idl")
local ip, port1 = server1:getsockname()
print(port1)

local server2 = luarpc.createServant(myobj1, "lua.idl")
local ip, port2 = server2:getsockname()
print(port2)

luarpc.waitIncoming()