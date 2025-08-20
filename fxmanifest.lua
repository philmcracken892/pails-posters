fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'phils-posters
version '1.0.2'
ui_page 'html /index.html'
Author 'Phil and rex'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
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

escrow_ignore {
    'locales',
    'config.lua',
    'README.md',
    'rex-notes.sql'
}

files {
    'html/index.html'
}

lua54 'yes'
