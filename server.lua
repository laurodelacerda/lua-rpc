
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

luarpc = require("luarpc")

idl = "lua.idl"

local ip, port = luarpc.createServant(myobj1, idl)
local ip2, port2 = luarpc.createServant(myobj2, idl)
local ip3, port3 = luarpc.createServant(myobj1, idl)

print("Serviço 1 na porta " .. port)

print("Serviço 2 na porta " .. port2)

luarpc.waitIncoming()