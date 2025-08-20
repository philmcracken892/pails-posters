local Translations = {

    client = {
        lang_1 = 'Open Moneybox',
    },

    server = {
        lang_1 = 'loading ',
        lang_2 = ' prop with ID: ',
    },

}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

-- Lang:t('client.lang_1')
-- Lang:t('server.lang_1')
