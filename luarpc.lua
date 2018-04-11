local luarpc = {}
local servers = {}
local objects = {}

local socket = require("socket")

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

local function compareArrays(table1, table2)

      if #table1 ~= #table2 then
            return false
      end

      local i = 1
      local j = 1

      local count = 0

      while i <= #table1 do
            if j > #table2 then
                  return false
            elseif string.match(table1[i], table2[j]) then               
                  count = count + 1
                  i = i + 1
                  j = 1
            else
                  j = j + 1
            end
      end

      if #table1 == count then
            return true
      else
            return false
      end
end   

local function validateIdl(object, idl)

      local idlMethods = {}
      local objMethods = {}

      local i = parser(idl)      

      for k in pairs(i) do 
            table.insert(idlMethods, k)            
      end

      for j in pairs(object) do 
            table.insert(objMethods, j)            
      end

      if compareArrays(idlMethods, objMethods) then
            return nil
      else
            return 'The object is not IDL compliant.'
      end
end

-- valida os argumentos de entrada na proxy, retorna nil se não houver erros, ou o primeiro erro encontrado
local function validateLocalArgs(args, expectedArgs) 
      for i=1, #expectedArgs do         
            if (#args >= i) then  
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
      end

      return nil
end

local function packArgs(method, args, sig)
      local request = method..'\n'
      for i=1,#sig do
            if (#args >= i) then
                  if (sig[i] == 'string' or sig[i] == 'char') then
                        request = request..string.gsub(args[i], '\n', '\\:-)\\')
                  else
                        request = request..tostring(args[i])
                  end
            else
                  if (sig[i] == 'double') then
                        request = request..'0'  -- se for double completa com 0
                  else
                        request = request..'\n' -- se for char ou string ou void envia \n
                  end
            end

            request = request..'\n'
      end
      return request
end

-- converte os valores recebidos em 'args' para os tipos esperados descritos na tabela 'expectedArgs'
-- se houver erros retorna uma string indicando o erro encontrado, caso contrário retorna nil
-- obs: essa função altera os valores de args para os valores convertidos (typecast)
local function unpackArgs(args, expectedArgs)
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

function luarpc.createServant(servantObject, idl)
      
      local errorIdl = validateIdl(servantObject, idl)

      -- reservando socket
      local server = assert(socket.bind("*", 0))

      -- guardando o (socket, objeto) utilizado na tabela
      table.insert(servers, server)

      -- guarda o objeto e a respectiva idl
      objects[server] = { servantObject, idl }

      if errorIdl then
            return '___ERRORPC: ' .. errorIdl, server
      else
            return '\n', server
      end
end

function luarpc.waitIncoming()

-- TODO Tratar envio de mensagens fora do padrão do protocolo acordado.
      while 1 do

            local canRead = socket.select(servers, nil)

            for _, server in ipairs(canRead) do

                  local object, idl = table.unpack(objects[server])

                  local client = server:accept()
                  
                  -- obtem o nome da função
                  local name, err = client:receive()

                  local prototypes = parser(idl)

                  local input = prototypes[name].input

                  local params = {}

                  for i=1, #input do
                        local param, err = client:receive()
                        table.insert(params, param)
                  end

                  local inputError = unpackArgs(params, input)
                  if inputError then
                        cliend:send(inputError)
                        client:close()
                  else
                        local result = table.pack(object[name](table.unpack(params)))

                        client:send('\n') -- mensagem indicando sucesso no processamento da chamada pelo server

                        for i=1, #result do
                              client:send(string.gsub(result[i], "\n", "\\:-)\\").."\n") -- resultado da chamada
                        end

                        client:close()
                  end
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

                  local inputError = validateLocalArgs(args, sig.input)
                  if inputError  then
                        return '___ERRORPC: '..inputError
                  end
            
                  -- abre a conexão com o servidor
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

                        if err and sig.output[i] ~= 'void' and err ~= 'closed' then
                              return '___ERRORPC: '..err
                        end

                        print(ans)

                        table.insert(result, ans)
                  end

                  -- desempacota os parametros (cast de string para os tipos definidos na idl)
                  local outputError = unpackArgs(result, sig.output)
                  if outputError then
                        return '___ERRORPC: '..outputError
                  end

                  if (sig.output[i] == 'void') then
                        return
                  end

                  -- faz o unpack da tabela para retorno da função do lado do cliente
                  return table.unpack(result)
            end
      end

      return proxy
end

return luarpc
