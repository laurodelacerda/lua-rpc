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

myobj3={	foo = 
	function(a)
		return a
	end
      }

luarpc = require("luarpc")

idl = "simple.idl"

local server = luarpc.createServant(myobj3, idl)

local ip, port = server:getsockname()

print(port)

luarpc.waitIncoming()


