
local luarpc = {}
local socketsOccupied = {}

local function parser(idl)
	local prototypes = {}
	function interface(idl)
      for name,sig in pairs(idl.methods) do
         local func = {}
         func.output = {}
         func.input = {}
         table.insert(func.output, sig.resulttype)
         local args = sig.args 
         for i=1, #args do
            if string.match(args[i].direction, 'out') then
               table.insert(func.output, args[i].type)
            end

            if string.match(args[i].direction, 'in') then
               table.insert(func.input, args[i].type)
            end
         end
         prototypes[name] = func
      end
	end
   dofile(idl)
	return prototypes
end

function luarpc.dumpParser(idl)
   t =  parser(idl)
   require 'pl.pretty'.dump(t)
end

local function validateArgs(args, sig)
   local input = sig.input
   for i=1, #input do
      if #args < i then
         return false
      end
      local t = type(args[i])
   end
end

local function packArgs(args, sig)
end

function luarpc.createServant(servantObject, idl)
	-- lendo a interface
	io.input(idl)
	local input = io.read("*all")
	--input = string.gsub(input, "^interface", "return")
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
   -- inicializa uma tabela vazia que será o stub do objeto remoto
   local proxy = {}

   -- extrai as funções da interface
	local prototypes = parser(idl)

   -- cria a implementacao do stub para as funções da idl
	for name, sig in pairs(prototypes) do
      proxy[name] = function(...)
         local args = {...}

--[[
         if ~validateArgs(args, sig) then
            return '___ERRORPC: metodo invalido'
         end
]]--
         local request = name..'\n'
         request = request .. args[1]..'\n'

--         print(request)

         -- chamada remota
         local server = socket.connect(hostname, port)
         
         server:send(request)

         local ans, err = server:receive()
         
         if err then
            return '___ERRORPC'
         end
         return ans
      end
	end

   return proxy
end

return luarpc
