local PLUGIN_NAME = "logo.nvim"

local autocmd_group = vim.api.nvim_create_augroup(PLUGIN_NAME, {})
local highlight_ns_id = vim.api.nvim_create_namespace(PLUGIN_NAME)
local logo_buff = -1
local cache_dir = vim.fn.stdpath("cache")
local img_api = require("image")

local vimimage = require("image").from_file(vim.fn.expand("~/.config/nvim/VIMTRANS.png"), {
	id = "vimstart",
})

local function get_geometry(image)
	local term_size   = require("image/utils").term.get_size()
	local cellwidth   = term_size.cell_width
	local cellheight  = term_size.cell_height
	local winwidth    = term_size.screen_cols
	local winheight   = term_size.screen_rows

	local imagewidth  = image.image_width
	local imageheight = image.image_height

	local geometry    = {
		x = math.floor((((cellwidth * winwidth) - imagewidth) / 2) / cellwidth),
		y = math.floor((((cellheight * winheight) - imageheight) / 2) / cellheight),
	}
	return geometry
end


local function draw_logo(buf, image)
	local window = vim.fn.bufwinid(buf)
	local geometry = get_geometry(image)
	local options = {
		x = geometry.x,
		y = geometry.y
	}
	image:render(options)
end

local function create_and_set_minintro_buf(default_buff)
	local intro_buff = vim.api.nvim_create_buf("nobuflisted", "unlisted")
	vim.api.nvim_buf_set_name(intro_buff, PLUGIN_NAME)
	vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = intro_buff })
	vim.api.nvim_set_option_value("buftype", "nofile", { buf = intro_buff })
	vim.api.nvim_set_option_value("filetype", "vim_gang", { buf = intro_buff })
	vim.api.nvim_set_option_value("swapfile", false, { buf = intro_buff })

	vim.api.nvim_set_current_buf(intro_buff)
	vim.api.nvim_buf_delete(default_buff, { force = true })

	return intro_buff
end

local function set_options()
	vim.opt_local.number = false           -- disable line numbers
	vim.opt_local.relativenumber = false   -- disable relative line numbers
	vim.opt_local.list = false             -- disable displaying whitespace
	vim.opt_local.fillchars = { eob = ' ' } -- do not display "~" on each new line
	vim.opt_local.colorcolumn = "0"        -- disable colorcolumn
end

local function display_logo()
	local default_buff = vim.api.nvim_get_current_buf()

	logo_buff = create_and_set_minintro_buf(default_buff)
	set_options()
	draw_logo(logo_buff, vimimage)

	-- TODO support resize
	-- vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
	--  callback = redraw
	-- })
end
local function setup(options)
	options = options or {}
	vim.api.nvim_set_hl(highlight_ns_id, "Default", { fg = options.color })
	vim.api.nvim_set_hl_ns(highlight_ns_id)

	vim.api.nvim_create_autocmd("VimEnter", {
		group = autocmd_group,
		callback = function()
			-- Execute a command if there are no open files
			if vim.api.nvim_buf_get_name(0) == "" then
				display_logo()
			end
		end,
		once = true
	})

	vim.api.nvim_create_autocmd("BufRead", {
		callback = function()
			img_api.clear("vimstart")
		end,
	})

	vim.api.nvim_create_autocmd("BufNewFile", {
		callback = function()
			img_api.clear("vimstart")
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "StartupScreen",
		callback = function()
			vim.opt.laststatus = 0
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function()
					vim.opt.laststatus = 2
				end,
			})
		end,
	})
end

return {
	setup = setup
}
