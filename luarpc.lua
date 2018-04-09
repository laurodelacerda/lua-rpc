
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

local function packArgs(method, args, sig)
      local request = method..'\n'
      for i=1,#sig do
            if (sig[i] == 'string' or sig[i] == 'char') then
                  request = request..string.gsub(args[i], '\n', '\\:-)\\')
            else
                  request = request..tostring(args[i])
            end

            request = request..'\n'
      end
      return request
end

local function unpackArgs(method, args, sig)
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
	
	return server

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

                  require 'pl.pretty'.dump(params)

			local result = object[name](table.unpack(params))

                  client:send('\n') -- mensagem indicando sucesso no processamento da chamada pelo server

			client:send(result .. "\n") -- resultado da chamada

                  client:close()
		end		
	end

end 

-- valida os argumentos de entrada na proxy, retorna nil se não houver erros, ou o primeiro erro encontrado
local function validateLocalArgs(args, expectedArgs) 
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

local function validateResults(result, expectedArgs)
      for i=1, #expectedArgs do            
      end
end

local function validateRemoteArgs(args, expectedArgs)
      for i=1, #expectedArgs do
            if (#args < i) then
                  return nil
            end

            if (expectedArgs[i] == 'double') then
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
      return validateLocalArgs(args, sig.input)
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

                  local inputError = validateLocalArgs(args, sig.input)
                  if inputError  then
                        return '___ERRORPC: '..inputError
                  end
            
                  -- abre a conexão com o servidor
                  local socket = require("socket")
                  local server = socket.connect(hostname, port)

                  -- empacota os parametros
                  local request = packArgs(name, args, sig.input)

                  -- envia a faz a chamada remota
                  server:send(request)

                  -- aguarda a resposta do servidor
                  local ans, err = server:receive()

                  if err then 
                        return '___ERRORPC: '..err
                  end
                  -- o primeiro parametro retornado deve ser o status indicando se houve erro no processamento da chamada
                  if ans ~= '' then
                        return '___ERRORPC: '..ans
                  end

                  -- obtem tantas mensagens quantos forem os parâmetros de saída definidos na idl
                  local result = {}
                  for i=1, #sig.output do
                        ans, err = server:receive()
                        if err then
                              return '___ERRORPC: '..err
                        end

                        table.insert(result, ans)
                  end

                  -- TODO validar e converter os parâmetros de saída recebidos para ficar de acordo com a idl

                  return table.unpack(result)
            end
	end

   return proxy
end

return luarpc
