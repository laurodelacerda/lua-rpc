--[[
local p1 = luarpc.createproxy (IP, porta1, arq_interface)
local p2 = luarpc.createproxy (IP, porta2, arq_interface)
local r, s = p1:foo(3, 5)
local t = p2:boo(10)


while true do

	local socket = require("socket")

	local client = socket.connect("localhost", 36287)

	local data = "\n"
	
	print(client)

	--local ans, err = client:receive()

end

--]]

local luarpc = require("luarpc")

local idl = "simple.idl"

client = luarpc.createProxy("localhost", 41131, idl)

-- client.foo("teste")

-- client:send("r\n")

-- local ans, err = client:receive()

print(client.foo("teste"))

