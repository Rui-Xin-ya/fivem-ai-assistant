# fivem-ai-assistant

fivem的AI助手可以让你的服务器接入deepseek或者其他AI,支持用户绑定QQ头像

![游戏截图](https://i.ibb.co/V083PBWX/2d92fe97-a439-479c-ad51-d03e5330ed84.png)

## 🚀插件安装步骤

1.**下载插件**

```bash
https://github.com/Rui-Xin-ya/fivem-ai-assistant.git
```

或者点击仓库右上角选择Download ZIP

2.**放置文件** 将插件文件夹复制到你的FiveM服务器 `resources` 目录下

3.**配置文件** 编辑 `config.lua` 文件，设置你的AI API密钥和其他配置选项

4.**启动插件** 输入ensure fivem-ai-assistant

## ⚙️ 必要配置说明

**必要配置**，必须配置这些才能正常运行

```
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
```

## 🎯 使用方法

游戏内输入/ai或者F10都可以打开AI界面，界面支持绑定QQ头像

## 📝 更新日志

### v1.0.0 (2024-06-27)

- 🎉 初始版本发布
- ✅ 基础AI对话功能
- ✅ 游戏帮助系统

## 📞 支持与反馈

**GitHub Issues**: [报告问题](https://github.com/Rui-Xin-ya/fivem-ai-assistant/issues)

Discord:1200074512536965180

QQ:3438341186

本项目采用 [Creative Commons Attribution-NonCommercial 4.0 International License](https://creativecommons.org/licenses/by-nc/4.0/) 许可证。  

### 许可证说明
✅ 允许个人使用  
✅ 允许修改  
✅ 允许分发  
❗ 禁止商业使用  
❗ 必须保留原始版权声明  

### 商业使用许可
如需商业使用，请联系项目维护者获取单独许可。
