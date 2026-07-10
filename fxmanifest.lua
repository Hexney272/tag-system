fx_version 'cerulean'
game 'gta5'

author 'RealRP'
description 'RealRP - NUI headtag rendszer (név, frakció/rang, ikonok, halott-időzítő, jármű rendszámtábla típusok)'
version '1.1.0'

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/plate-types.css',
    'html/plate-types.js',
    'html/plates/*.svg'
}

shared_scripts {
    'config.lua',
    'plate_config.lua'
}

client_scripts {
    'client.lua',
    'client_plate_types.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua',
    'esx.lua'
}

dependencies {
    'es_extended',
    'oxmysql'
}
