
local luarpc = {}
local servers = {}
local objects = {}

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

	-- reservando socket
	socket = require("socket")
	server = assert(socket.bind("*", 0))
	local ip, port = server:getsockname()

	-- guardando o (socket, objeto) utilizado na tabela
	table.insert(servers, server)

	objects[server] = servantObject
	
	return server ;

end

function luarpc.waitIncoming()
-- TODO Tratar envio de mensagens fora do padrão do protocolo acordado.
	while 1 do
		local canRead = socket.select(servers, nil)

		for _, server in ipairs(canRead) do

			local object = objects[server]
	
			local client = server:accept()

			local name, err = client:receive()

			print(name)

			local params = {}

			local param1, err = client:receive()

			table.insert(params, param1)	

			local result = object[name](table.unpack(params))

			client:send(result .. "\n")

--			if err then 

--			end

			client:close()
		end		
	end

end 

-- valida os argumentos de entrada na proxy, retorna nil se não houver erros, ou o primeiro erro encontrado
local function validateArgsProxy(args, expectedArgs) 
      for i=1, #expectedArgs do
            if (#args < i) then
                  return nil
            end

            local t = type(args[i])
            if (expectedArgs[i] == 'double' and t ~= 'number') then
                  return "Expected double and received "..tostring(t)
            elseif (expectedArgs[i] == 'char' and (t ~= 'string' or string.len(args[i]) > 1)) then
                  if (t == 'string') then
                        return "Expected char and received string with more than 1 character"
                  else
                        return "Expected char and received "..tostring(t)
                  end
            elseif (expectedArgs[i] == 'string' and t ~= 'string') then
                  return "Expected string and received "..tostring(t)
            end
      end

      return nil
end

function luarpc.testValidateInputArgs(method, args, idl)
      local prototypes = parser(idl)
      local sig = prototypes[method]
      return validateArgsProxy(args, sig.input)
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

         local inputError = validateArgsProxy(args, sig.input)
         if inputError  then
            return '___ERRORPC: '..inputError
         end

         local request = name..'\n'
         request = request .. args[1]..'\n'

         -- chamada remota
	   local socket = require("socket")

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
