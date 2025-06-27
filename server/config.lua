Config = {}

Config.AI = {
    Provider = "volces",

    --填写大模型的key
    ApiKey = "you_key",
    --大模型的API地址,如果使用别的大模型要修改API
    ApiUrl = {
        openai = "https://api.openai.com/v1/chat/completions",
        volces = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
    },
    --大模型的名称
    Model = {
        openai = "gpt-3.5-turbo",  
        volces = "doubao-seed-1-6-flash-250615"  
    },
    --回复间隔，防止滥用
    Timeout = 15000,  
    
    Temperature = 0.7,
    
    MaxTokens = 150
}

Config.Plugin = {
    CommandPrefix = "/ai",
    
    Debug = true,
    
    AllowedGroups = {
        "admin",
        "moderator"
    },
    
    Cooldown = 0
}

return Config 