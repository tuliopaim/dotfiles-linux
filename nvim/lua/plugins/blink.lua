return {
    'saghen/blink.cmp',
    dependencies = {
        'rafamadriz/friendly-snippets',
        'Kaiser-Yang/blink-cmp-avante'
    },
    version = '*',
    opts = {
        keymap = { preset = 'default' },
        appearance = {
            use_nvim_cmp_as_default = true,
            nerd_font_variant = 'mono'
        },

        sources = {
            default = { 'lsp', 'path', 'snippets', 'buffer', 'dadbod', 'avante'},
            providers = {
                avante = { name = 'Avante',  module = 'blink-cmp-avante' },
                dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
            }
        },
    },
    opts_extend = { "sources.default" }
}
