fx_version 'cerulean'
game 'gta5'

lua54 'yes'

author 'NPCcxc'
description 'FiveM AI助手插件'
version '1.0.0'

server_scripts {
    'server/config.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}

shared_scripts {
    'shared/utils.lua'
}

ui_page 'client/html/index.html'

files {
    'client/html/index.html',
    'client/html/style.css',
    'client/html/script.js',
    'client/html/default_avatar.png',
    'client/html/avatars/avatar1.png',
    'client/html/avatars/avatar2.png',
    'client/html/avatars/avatar3.png',
    'client/html/avatars/avatar4.png',
    'client/html/avatars/user_avatar.png'
}

dependency '/assetpacks'

provide 'fivem_ai'
name 'fivem_ai' 