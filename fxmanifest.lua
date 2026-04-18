fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Gaby.silva'
description 'Emprego profissional de entregador iFood para bases vRP e vRPex'
version '1.0.0'

shared_scripts {
    '@vrp/lib/utils.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua'
}

files {
    'README.md',
    'vrp_ifood_job.sql'
}
