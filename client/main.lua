-- 客户端初始化脚本
local isProcessingAI = false
local chatOpen = false
local aiSettings = {
    aiName = "AI助手",
    aiAvatar = "https://i.imgur.com/YOJjZlW.png",
    userAvatar = "https://i.imgur.com/6MgCm6u.png",
    aiProvider = "volces", -- 默认使用火山引擎API
    qqNumber = "" -- QQ号码，用于显示QQ头像
}

function ShowGameNotification(message, notificationType)
    if not notificationType then notificationType = "info" end

    local notificationIcon = "CHAR_BLANK_ENTRY"
    local notificationTitle = "系统通知"
    local notificationSubtitle = ""
    local bgColor = 0
    
    if notificationType == "success" then
        notificationIcon = "CHAR_LIFEINVADER"
        notificationTitle = "成功"
        bgColor = 2
    elseif notificationType == "error" then
        notificationIcon = "CHAR_BLOCKED"
        notificationTitle = "错误"
        bgColor = 6
    elseif notificationType == "info" then
        notificationIcon = "CHAR_INFO_ICON"
        notificationTitle = "信息"
        bgColor = 0
    end

    SetNotificationTextEntry("STRING")
    AddTextComponentString(message)
    SetNotificationMessage(notificationIcon, notificationIcon, true, 4, notificationTitle, notificationSubtitle)
    DrawNotification(false, true)

    if chatOpen then
        SendNUIMessage({
            type = "systemMessage",
            message = message,
            messageType = notificationType
        })
    end
end

function SaveQQBinding()
    SetResourceKvp("fivem_ai_qq", aiSettings.qqNumber)
    print("已保存QQ绑定信息: " .. aiSettings.qqNumber)
end

function LoadQQBinding()
    local savedQQ = GetResourceKvpString("fivem_ai_qq")
    if savedQQ and savedQQ ~= "" then
        aiSettings.qqNumber = savedQQ
        print("已加载QQ绑定信息: " .. aiSettings.qqNumber)

        if aiSettings.qqNumber ~= "" then
            aiSettings.userAvatar = "https://q1.qlogo.cn/g?b=qq&nk=" .. aiSettings.qqNumber .. "&s=100"
            print("已设置QQ头像: " .. aiSettings.userAvatar)
        end
    end
end

function ToggleAIChat()
    chatOpen = not chatOpen
    
    if chatOpen then
        SendNUIMessage({
            type = 'open',
            aiAvatar = aiSettings.aiAvatar,
            userAvatar = aiSettings.userAvatar,
            aiName = aiSettings.aiName,
            qqNumber = aiSettings.qqNumber
        })
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    else
        SendNUIMessage({
            type = 'close'
        })
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SetPlayerControl(PlayerId(), true, 0)
    end
end

RegisterNetEvent('fivem_ai:showProcessingNotification')
AddEventHandler('fivem_ai:showProcessingNotification', function()
    isProcessingAI = true

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName('~b~AI助手~w~正在处理您的请求...')
    EndTextCommandThefeedPostTicker(false, true)

    Citizen.CreateThread(function()
        while isProcessingAI do
            Wait(500)
        end
    end)
end)

RegisterNetEvent('fivem_ai:showResponse')
AddEventHandler('fivem_ai:showResponse', function(success, message)
    isProcessingAI = false
    
    if success then
        if chatOpen then
            SendNUIMessage({
                type = "aiResponse",
                message = message,
                aiAvatar = aiSettings.aiAvatar,
                userAvatar = aiSettings.userAvatar
            })
        else
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName('~g~AI助手~w~: ' .. message)
            EndTextCommandThefeedPostTicker(false, true)
        end
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('~r~AI助手错误~w~: ' .. message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end)

RegisterCommand('aichat', function()
    ToggleAIChat()
end, false)

TriggerEvent('chat:addSuggestion', '/aichat', '打开AI聊天界面')

RegisterNUICallback('closeChat', function(data, cb)
    chatOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SetPlayerControl(PlayerId(), true, 0)
    cb('ok')

    Citizen.SetTimeout(100, function()
        if not chatOpen then
            SetNuiFocus(false, false)
            SetNuiFocusKeepInput(false)
        end
    end)
end)

RegisterNUICallback('sendMessage', function(data, cb)
    if data.message then
        TriggerServerEvent('fivem_ai:processAIRequest', data.message)
    end
    cb('ok')
end)

RegisterNUICallback('showNotification', function(data, cb)
    if data.message then
        ShowGameNotification(data.message, data.type)
    end
    cb('ok')
end)

RegisterNUICallback('saveQQBinding', function(data, cb)
    if data.qqNumber and string.len(data.qqNumber) >= 5 and string.len(data.qqNumber) <= 11 then
        aiSettings.qqNumber = data.qqNumber
        aiSettings.userAvatar = "https://q1.qlogo.cn/g?b=qq&nk=" .. data.qqNumber .. "&s=100"
        SaveQQBinding()

        cb({
            success = true,
            message = "QQ绑定成功",
            userAvatar = aiSettings.userAvatar
        })
    else
        cb({
            success = false,
            message = "QQ号码无效，必须是5-11位数字"
        })
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if(GetCurrentResourceName() == resourceName) then
        LoadQQBinding()
        TriggerServerEvent('fivem_ai:setProvider', aiSettings.aiProvider)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, 57) then
            ToggleAIChat()
        end
    end
end) 