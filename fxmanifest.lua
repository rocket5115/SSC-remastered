fx_version 'cerulean'
lua54        'yes'
game         'gta5'

ui_page 'html/index.html'

files {
    'configs/config.js',
    'html/webfonts/*',
    'html/online/*',
    'html/*.js',
    'html/css/*.css',
    'html/index.html',
}

client_scripts {
    'configs/config.lua',
    'client/camera.lua',
    'client/functions.lua',
    'client/global.lua',
    'client/nui.lua',
    'client/client.lua'
}

server_scripts {
    'session.lua',
    'attachments/*.lua',
    'configs/config.lua',
    'configs/config_s.lua',
    'server/functions.lua',
    'server/server.lua',
    'version.lua'
}