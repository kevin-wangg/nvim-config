vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false
vim.opt.wrap = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.clipboard = "unnamedplus"

-- Text decorations in neorg files are concealed properly
vim.opt.conceallevel = 2

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Set cursor to last edit position when opening a file
vim.api.nvim_create_autocmd('BufReadPost', {
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 1 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})


-- Setup lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out,                            "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- LSP and tools
	{ "neovim/nvim-lspconfig" },
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
	-- Navigation
	{ "christoomey/vim-tmux-navigator" },
	-- File tree
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{
				"<leader>e",
				function() vim.cmd("Neotree toggle") end,
				desc = "Toggle Neo-tree",
			},
		},
		config = function()
			require("neo-tree").setup({
				window = {
					mappings = {
						["<C-v>"] = "open_vsplit", -- Open file in vertical split
						["<C-s>"] = "open_split", -- Open file in horizontal split (bonus)
						["<C-t>"] = "open_tabnew", -- Open file in new tab (bonus)
					},
				},
			})
		end,
	},
	-- Git signs
	{ "lewis6991/gitsigns.nvim" },
	-- Status line
	{ "nvim-lualine/lualine.nvim" },
	-- Colorscheme
	{ "rebelot/kanagawa.nvim" },
	-- Completion
	{
		"Saghen/blink.cmp",
		build = "cargo build --release",
	},
	-- Auto close brackets
	{
		"m4xshen/autoclose.nvim",
		event = "InsertEnter",
		config = function()
			require("autoclose").setup({
				options = {
					disabled_filetypes = { "text", "markdown", "norg" }
				}
			})
		end,
	},
	-- File picker
	{
		"dmtrKovalenko/fff.nvim",
		build = "cargo build --release",
		keys = {
			{
				"<leader>sf",
				function() require("fff").find_files() end,
				desc = "Find files with FFF",
			},
		},
		config = true,
	},
	-- Claude code plugin
	{
		"coder/claudecode.nvim",
		dependencies = { "folke/snacks.nvim" },
		config = true,
	},
	-- Treesitter plugin
	{
		"nvim-treesitter/nvim-treesitter",
		branch = 'master',
		lazy = false,
		build = ":TSUpdate",
	},
	-- Neorg for note taking
	{
		"nvim-neorg/neorg",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" },
		build = ":Neorg sync-parsers",
		lazy = false, -- Disable lazy loading as some `lazy.nvim` distributions set `lazy = true` by default
		version = "*", -- Pin Neorg to the latest stable release
		config = function()
			local neorg = require('neorg')
			neorg.setup {
				load = {
					["core.defaults"] = {},
					["core.concealer"] = {},
					["core.tempus"] = {},
					["core.keybinds"] = {
						config = {
							default_keybinds = true
						}
					},
					["core.dirman"] = {
						config = {
							workspaces = {
								notes = "~/neorg/notes",
								journal = "~/neorg"
							}
						}
					},
					["core.journal"] = {
						config = {
							workspace = "journal"
						}
					}
				}
			}
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
	}
})

require("nvim-treesitter.configs").setup({
	-- Enable highlight to proper text decorations rendering in neorg
	highlight = {
		enable = true,
	}
})
require('mason').setup()
require('mason-lspconfig').setup()
require('mason-tool-installer').setup({
	ensure_installed = {
		"lua_ls",
		"stylua",
		"clangd",
		"rust_analyzer",
	}
})
require('blink.cmp').setup()
require('gitsigns').setup()
-- lualine shows the full file path instead of just name
require('lualine').setup({
	sections = {
		lualine_c = {
			{
				'filename',
				path = 1,
			}
		}
	}
})

vim.lsp.config('lua_ls', {
	settings = {
		Lua = {
			runtime = {
				version = 'LuaJIT',
			},
			diagnostics = {
				globals = {
					'vim',
					'require'
				},
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = {
				enable = false,
			},
		},
	},
	on_attach = function(_, bufnr)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
		vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, { buffer = bufnr, desc = "Go to type definition" })
		vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, { buffer = bufnr, desc = "Go to implementation" })
		vim.keymap.set('n', 'gR', vim.lsp.buf.references, { buffer = bufnr, desc = "Go to references" })
		vim.keymap.set('n', 'g.', vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
		vim.keymap.set('n', 'gl', vim.diagnostic.open_float, { buffer = bufnr, desc = "Hover info" })
		vim.keymap.set('n', '<leader>q', function()
			vim.diagnostic.setqflist()
			vim.cmd('copen')
		end, { buffer = bufnr, desc = "Open quickfix list" })
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })
		vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { buffer = bufnr, desc = "Format" })
	end,
})

vim.lsp.config('rust_analyzer', {
	on_attach = function(client, bufnr)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
		vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, { buffer = bufnr, desc = "Go to type definition" })
		vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, { buffer = bufnr, desc = "Go to implementation" })
		vim.keymap.set('n', 'gR', vim.lsp.buf.references, { buffer = bufnr, desc = "Go to references" })
		vim.keymap.set('n', 'g.', vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
		vim.keymap.set('n', 'gl', vim.diagnostic.open_float, { buffer = bufnr, desc = "Hover info" })
		vim.keymap.set('n', '<leader>q', function()
			vim.diagnostic.setqflist()
			vim.cmd('copen')
		end, { buffer = bufnr, desc = "Open quickfix list" })
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })
		vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { buffer = bufnr, desc = "Format" })
	end,
})

vim.lsp.config('clangd', {
	on_attach = function(client, bufnr)
		vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
		vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
		vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, { buffer = bufnr, desc = "Go to type definition" })
		vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, { buffer = bufnr, desc = "Go to implementation" })
		vim.keymap.set('n', 'gR', vim.lsp.buf.references, { buffer = bufnr, desc = "Go to references" })
		vim.keymap.set('n', 'g.', vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
		vim.keymap.set('n', 'gl', vim.diagnostic.open_float, { buffer = bufnr, desc = "Hover info" })
		vim.keymap.set('n', '<leader>q', function()
			vim.diagnostic.setqflist()
			vim.cmd('copen')
		end, { buffer = bufnr, desc = "Open quickfix list" })
		vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })
		vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { buffer = bufnr, desc = "Format" })
	end,
})

vim.keymap.set('n', '<leader>x', ':q<CR>')
vim.keymap.set('n', '<leader>v', ':vsplit<CR>')
vim.keymap.set('n', '<leader>h', ':split<CR>')
vim.keymap.set('n', '<C-h>', '<CMD>TmuxNavigateLeft<CR>')
vim.keymap.set('n', '<C-j>', '<CMD>TmuxNavigateDown<CR>')
vim.keymap.set('n', '<C-k>', '<CMD>TmuxNavigateUp<CR>')
vim.keymap.set('n', '<C-l>', '<CMD>TmuxNavigateRight<CR>')
vim.keymap.set('n', 'H', ':tabprevious<CR>')
vim.keymap.set('n', 'L', ':tabnext<CR>')

vim.keymap.set('n', '<leader>nd', '<Plug>(neorg.tempus.insert-date)',
	{ buffer = true, desc = "Insert todays date at cursor position" }
)

-- Set the colorscheme
vim.cmd('colorscheme kanagawa')
