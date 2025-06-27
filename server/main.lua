local Config = LoadResourceFile(GetCurrentResourceName(), "server/config.lua")
Config = assert(load(Config))()

local playerCooldowns = {}

local function printDebug(message)
    if Config.Plugin.Debug then
        print("^3[FiveM AI] ^7" .. message)
    end
end

local function hasPermission(playerId)
    return true
end

local function isOnCooldown(playerId)
    local identifier = GetPlayerIdentifier(playerId, 0)
    if not playerCooldowns[identifier] then return false end
    
    local currentTime = os.time()
    return (currentTime - playerCooldowns[identifier]) < Config.Plugin.Cooldown
end

local function setCooldown(playerId)
    local identifier = GetPlayerIdentifier(playerId, 0)
    playerCooldowns[identifier] = os.time()
end

local function isApiKeyValid()
    local apiKey = Config.AI.ApiKey
    return apiKey ~= "your_api_key_here" and apiKey ~= ""
end

local function sendAIRequest(prompt, callback)
    printDebug("发送AI请求: " .. prompt)
    
    local provider = Config.AI.Provider
    local apiUrl = Config.AI.ApiUrl[provider]
    local model = Config.AI.Model[provider]
    
    if not isApiKeyValid() then
        callback(false, "API密钥无效或未设置，请在server/config.lua中设置有效的API密钥")
        return
    end
    
    local headers = {
        ['Content-Type'] = 'application/json',
        ['Authorization'] = 'Bearer ' .. Config.AI.ApiKey
    }
    
    local requestData = {}
    local systemPrompt = "您是一个在GTA V的FiveM服务器中提供帮助的AI助手。请保持回答简洁、有帮助且符合游戏背景。"
    
    if provider == "openai" then
        requestData = json.encode({
            model = model,
            messages = {
                { role = "system", content = systemPrompt },
                { role = "user", content = prompt }
            },
            max_tokens = Config.AI.MaxTokens,
            temperature = Config.AI.Temperature
        })
    elseif provider == "volces" then
        requestData = json.encode({
            model = model,
            messages = {
                { role = "system", content = systemPrompt },
                { role = "user", content = prompt }
            }
        })
    else
        callback(false, "不支持的API提供商: " .. provider)
        return
    end
    
    PerformHttpRequest(apiUrl, function(statusCode, responseText, headers)
        if statusCode == 200 then
            local response = json.decode(responseText)
            if provider == "openai" then
                if response and response.choices and response.choices[1] and response.choices[1].message then
                    callback(true, response.choices[1].message.content)
                else
                    callback(false, "API返回了无效的响应格式")
                end
            elseif provider == "volces" then
                printDebug("火山引擎API响应: " .. responseText)
                if response and response.choices then
                    if response.choices[1] and response.choices[1].message then
                        callback(true, response.choices[1].message.content)
                    elseif response.choices[0] and response.choices[0].message then
                        callback(true, response.choices[0].message.content)
                    else
                        callback(false, "API返回了无效的响应格式：choices数组结构异常")
                    end
                else
                    callback(false, "API返回了无效的响应格式：缺少choices字段")
                end
            end
        else
            printDebug("API请求失败，状态码: " .. tostring(statusCode) .. ", 响应: " .. (responseText or "无响应"))
            callback(false, "API请求失败: " .. tostring(statusCode))
        end
    end, 'POST', requestData, headers)
end

RegisterCommand(Config.Plugin.CommandPrefix:sub(2), function(playerId, args, rawCommand)
    if playerId > 0 then
        if not hasPermission(playerId) then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 0, 0},
                multiline = true,
                args = {"系统", "您没有使用AI命令的权限"}
            })
            return
        end
        
        if isOnCooldown(playerId) then
            local timeLeft = Config.Plugin.Cooldown - (os.time() - playerCooldowns[GetPlayerIdentifier(playerId, 0)])
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 165, 0},
                multiline = true,
                args = {"系统", "请等待 " .. timeLeft .. " 秒后再次使用AI命令"}
            })
            return
        end
    end

    if #args == 0 then
        if playerId > 0 then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 255, 0},
                multiline = true,
                args = {"AI助手", "请提供一个问题或指令"}
            })
        else
            print("请提供一个问题或指令")
        end
        return
    end
    
    local userPrompt = table.concat(args, " ")
    printDebug("玩家 " .. GetPlayerName(playerId) .. " 请求AI: " .. userPrompt)
    
    if playerId > 0 then
        setCooldown(playerId)
        
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {0, 191, 255},
            multiline = true,
            args = {"AI助手", "正在思考您的问题..."}
        })
    end
    
    sendAIRequest(userPrompt, function(success, response)
        if success then
            if playerId > 0 then
                TriggerClientEvent('chat:addMessage', playerId, {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {"AI助手", response}
                })
            else
                print("AI响应: " .. response)
            end
        else
            if playerId > 0 then
                TriggerClientEvent('chat:addMessage', playerId, {
                    color = {255, 0, 0},
                    multiline = true,
                    args = {"AI助手", "发生错误: " .. response}
                })
            else
                print("AI错误: " .. response)
            end
        end
    end)
end, false)

RegisterCommand("aiprovider", function(playerId, args, rawCommand)
    if playerId > 0 and not hasPermission(playerId) then
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {255, 0, 0},
            multiline = true,
            args = {"系统", "您没有使用此命令的权限"}
        })
        return
    end
    
    if #args ~= 1 then
        local message = "用法: /aiprovider [openai|volces]"
        if playerId > 0 then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 255, 0},
                multiline = true,
                args = {"系统", message}
            })
        else
            print(message)
        end
        return
    end
    
    local provider = args[1]:lower()
    
    if provider ~= "openai" and provider ~= "volces" then
        local message = "无效的提供商。可用选项: openai, volces"
        if playerId > 0 then
            TriggerClientEvent('chat:addMessage', playerId, {
                color = {255, 0, 0},
                multiline = true,
                args = {"系统", message}
            })
        else
            print(message)
        end
        return
    end
    
    Config.AI.Provider = provider
    
    local message = "已切换到 " .. provider .. " API"
    if playerId > 0 then
        TriggerClientEvent('chat:addMessage', playerId, {
            color = {0, 255, 0},
            multiline = true,
            args = {"系统", message}
        })
    else
        print(message)
    end
end, false)

RegisterServerEvent('fivem_ai:processAIRequest')
AddEventHandler('fivem_ai:processAIRequest', function(message)
    local playerId = source
    
    if not hasPermission(playerId) then
        TriggerClientEvent('fivem_ai:showResponse', playerId, false, "您没有使用AI功能的权限")
        return
    end
    
    if isOnCooldown(playerId) then
        local timeLeft = Config.Plugin.Cooldown - (os.time() - playerCooldowns[GetPlayerIdentifier(playerId, 0)])
        TriggerClientEvent('fivem_ai:showResponse', playerId, false, "请等待 " .. timeLeft .. " 秒后再次使用AI功能")
        return
    end
    
    setCooldown(playerId)
    TriggerClientEvent('fivem_ai:showProcessingNotification', playerId)
    printDebug("玩家 " .. GetPlayerName(playerId) .. " 通过聊天界面请求AI: " .. message)
    
    sendAIRequest(message, function(success, response)
        TriggerClientEvent('fivem_ai:showResponse', playerId, success, success and response or "发生错误: " .. response)
    end)
end)

RegisterServerEvent('fivem_ai:setProvider')
AddEventHandler('fivem_ai:setProvider', function(provider)
    local playerId = source
    
    if not hasPermission(playerId) then
        return
    end
    
    if provider ~= "openai" and provider ~= "volces" then
        return
    end
    
    printDebug("玩家 " .. GetPlayerName(playerId) .. " 设置API提供商为: " .. provider)
end)

TriggerEvent('chat:addSuggestion', Config.Plugin.CommandPrefix, '向AI助手提问', {
    { name = "问题", help = "您想问AI的问题" }
})

TriggerEvent('chat:addSuggestion', '/aiprovider', '切换AI API提供商', {
    { name = "provider", help = "API提供商 (openai 或 volces)" }
})

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        printDebug('FiveM AI助手插件已启动')
        printDebug('使用 ' .. Config.Plugin.CommandPrefix .. ' <问题> 来与AI交流')
        
        if not isApiKeyValid() then
            print("^1[FiveM AI] 警告: API密钥无效或未设置，请在server/config.lua中设置有效的API密钥^7")
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() == resourceName) then
        printDebug('FiveM AI助手插件已停止')
    end
end) 