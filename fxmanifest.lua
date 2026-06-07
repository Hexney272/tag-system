fx_version 'cerulean'
game 'gta5'

author 'RealRP'
description 'RealRP - NUI headtag rendszer (név, frakció/rang, ikonok, halott-időzítő, jármű rendszámtábla)'
version '1.0.0'

lua54 'yes'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js'
}

shared_script 'config.lua'

client_script 'client.lua'

server_script 'server.lua'
