local luarpc = {}
local servers = {}
local objects = {}

local function parser(idl)
	local prototypes = {}
      
      -- função que lê a idl e cria uma tabela com subtabelas input e output
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

      -- carrega a idl
      dofile(idl)

	return prototypes
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

--[[
-- O código cliente deve tentar fazer a conversão dos argumentos que 
-- foram enviados para tipos especificados na interface (e gerar erros nos casos 
-- em que isso não é possível: por exemplo, se o programa fornece um string com 
-- letras onde se espera um parâmetro double). 

-- A função luarpc.waitIncoming pode ser executada depois de diversas chamadas a
-- luarpc.createServant, como indicado no exemplo, e deve fazer com que o processo
-- servidor entre em um loop onde ele espera pedidos de execução de chamadas a 
-- qualquer um dos objetos serventes criados anteriormente, atende esse pedido, 
-- e volta a esperar o próximo pedido (ou seja, não há concorrência no servidor!). 
-- Provavelmente você terá que usar a chamada select para programá-la.

         for param, sig in pairs(prototypes[name]) do

            local param, err = client:receive()

            table.insert(params, param)
            require 'pl.pretty'.dump(params)

            -- local inputError = validateValueArgs()

         end 
--]] 
			local object = objects[server]

			local client = server:accept()

			-- obtem o nome da função
			local name, err = client:receive()
			-- print(name)

			local params = {}

        		local prototypes = parser(idl)

			local sig = prototypes[name].input

--			local args = select("#", sig)
--[[				
      for i=1, #expectedArgs do
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
--]]
			for i=1, #sig do
				local param, err = client:receive()
				local t = type(param)
				--print(t)
				--print(sig[i])
				if(sig[i] == 'double' and t~= 'number') then
					param = tonumber(param)	
					if(param == nil) then
						client:send("ERRORLAURO: Expected double and received ".. tostring(t))
					end			
				elseif(sig[i] == 'string' and t~= 'string') then
					param = tostring(param)
				end

				table.insert(params, param)	
			end
         
--			local param1, err = client:receive()

--                  	table.insert(params, param1)

                  	require 'pl.pretty'.dump(params)
	                require 'pl.pretty'.dump(sig)			
         
			local result = object[name](table.unpack(params))

                  	client:send('\n') -- mensagem indicando sucesso no processamento da chamada pelo server

			client:send(result .. "\n") -- resultado da chamada

                  	client:close()
		end		
	end
end 

-- valida os argumentos de entrada na proxy, retorna nil se não houver erros, ou o primeiro erro encontrado
local function validateLocalArgs(args, expectedArgs) 
      if (#args < #expectedArgs) then
            return "Expected "..#expectedArgs.." arguments and received "..#args.." arguments"
      end
      for i=1, #expectedArgs do
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

-- converte os valores recebidos em 'args' para os tipos esperados descritos na tabela 'expectedArgs'
-- se houver erros retorna uma string indicando o erro encontrado, caso contrário retorna nil
-- obs: essa função altera os valores de args para os valores convertidos (typecast)
local function unpackArgs(args, expectedArgs)
      if (#args < #expectedArgs) then
            return "Expected "..#expectedArgs.." arguments and received "..#args.." arguments"
      end

      for i=1, #expectedArgs do
            local value = nil
            if (expectedArgs[i] == 'double') then
                  value = tonumber(args[i])
                  if not value then
                        return "Expected double and received "..args[i]
                  end
            elseif (expectedArgs[i] == 'char') then
                  value = string.gsub(args[i], '%\\%:%-%)%\\', '\n')
                  if (string.len(value) > 1) then
                        return "Expected char and received "..args[i]
                  end
            elseif (expectedArgs[i] == 'string') then
                  value = string.gsub(args[i], '%\\%:%-%)%\\', '\n')
            else
                  value = args[i]
            end
            args[i] = value
      end

      return nil
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

                  -- desempacota os parametros (cast de string para os tipos definidos na idl)
                  local outputError = unpackArgs(result, sig.output)
                  if outputError then
                        return '___ERRORPC: '..outputError
                  end

                  -- faz o unpack da tabela para retorno da função do lado do cliente
                  return table.unpack(result)
            end
	end

      return proxy
end

return luarpc
