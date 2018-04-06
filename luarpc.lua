
local luarpc = {}

local socketsOccupied = {}

function luarpc.createServant(servantObject, idl)

	-- lendo a interface
	io.input(idl)
	local input = io.read("*all")
	input = string.gsub(input, "^interface", "return")
	local f = loadstring(input)
	local interface = f()

	-- reservando socket
	socket = require("socket")
	server = assert(socket.bind("*", 0))
	local ip, port = server:getsockname()

	-- guardando o (socket, objeto) utilizado na tabela
	table.insert(socketsOccupied, port)
	
	return ip, port ;

end

function luarpc.waitIncoming()
-- TODO Tratar envio de mensagens fora do padrão do protocolo acordado.
	while 1 do

	    local client = server:accept()

	    local line, err = client:receive()

	    if err then 
		    client:close()
	    end
	end

end 

function luarpc.createProxy(hostname, port, idl)

		-- lendo a interface
	io.input(idl)
	local input = io.read("*all")
	input = string.gsub(input, "^interface", "return")
	local f = loadstring(input)
	local interface = f()

	local functions = {}
	local prototypes = parser(interface)

	print(prototypes)

	for name, sig in pairs(prototypes) do
		
		--[[
		functions[name] = function (...)
		-- validar parâmetros
		local params = {...}
		--]]

		local values = {name}

		local types = sig.input

		for i = 1, #types do
			if (#params >= i ) then
				values[#values+1] = params[i]
			end
			if (type(params[i]) ~= "number") then
				values[#values] = "\"" .. values[#values] .. "\""
			end
		end

		-- creating request
		local request = pack(values)

		-- creating socket 
		local client = socket.tcp()



	end

end

return luarpc
