fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'phils-posters'
version '1.0.2'
ui_page 'html/index.html'
Author 'Phil and rex'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/client.lua',
    'client/placeprop.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
}

files {
    'html/index.html',
    'locales/*.json'
}

lua54 'yes'
