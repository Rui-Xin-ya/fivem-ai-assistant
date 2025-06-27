-- 作者: NPCcxc

function TruncateText(text, maxLength)
    if #text <= maxLength then
        return text
    end
    
    return string.sub(text, 1, maxLength) .. "..."
end

function FormatTime(seconds)
    if seconds < 60 then
        return seconds .. "秒"
    elseif seconds < 3600 then
        local mins = math.floor(seconds / 60)
        local secs = seconds % 60
        return mins .. "分" .. secs .. "秒"
    else
        local hours = math.floor(seconds / 3600)
        local mins = math.floor((seconds % 3600) / 60)
        return hours .. "小时" .. mins .. "分"
    end
end

function StripHtml(text)
    if not text then return "" end
    return text:gsub("<[^>]*>", "")
end

function GenerateUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

math.randomseed(os.time()) 