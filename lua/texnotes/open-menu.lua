local Menu = require("nui.menu")
local filetype = require("plenary.filetype")
local utils = require("texnotes.utils")
local NuiText = require("nui.text")

local function remove_path(path) -- returns the filename only, i.e index.tex
	return path:match(".+/([^/]+)$")
end

local function get_path(pattern, dir, get_file)
	local files
	if get_file then
		files = vim.fs.find(pattern, { path = dir })
	else
		files = vim.fs.find(function(name)
			return name:match(".*%." .. pattern .. "$")
		end, { limit = math.huge, type = "file", path = dir })
		for i, v in ipairs(files) do
			files[i] = remove_path(v)
		end
	end
	return files
end

local function send_to_lines(separator, list, target, prefix)
	if separator then
		table.insert(target, Menu.separator(separator))
	end
	for _, v in ipairs(list) do
		if prefix then
			table.insert(target, Menu.item(prefix .. v))
		else
			table.insert(target, Menu.item(v))
		end
	end
end

local M = {}

M.open_menu = function(dir)
	local notes_dir = dir .. "/notes/slipbox"
	local projects_dir = dir .. "/projects"
	local pdfs_dir = dir .. "/pdf"

	local notes = get_path("tex", notes_dir)
	local projects = get_path("tex", projects_dir)
	local pdfs = get_path("pdf", pdfs_dir)

	local to_lines = {}

	send_to_lines(NuiText(" notes/"), notes, to_lines, " ")
	send_to_lines(NuiText(" projects/"), projects, to_lines, " ")
	send_to_lines(NuiText(" pdf/"), pdfs, to_lines, " ")

	local menu = Menu({
		position = "50%",
		size = {
			width = 50,
			height = 15,
		},
		border = {
			style = "rounded",
			text = {
				top = "[choose to open]",
				top_align = "center",
				bottom = "q <quit>",
				bottom_align = "right",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
		},
	}, {

		lines = to_lines,
		max_width = 20,
		keymap = {
			focus_next = { "j", "<Down>", "<Tab>" },
			focus_prev = { "k", "<Up>", "<S-Tab>" },
			close = { "<Esc>", "<C-c>", "q" },
			submit = { "<CR>", "<Space>", "L" },
		},
		on_submit = function(item)
			utils.open_file(filetype.detect(item.text), item.text:sub(5), dir)
		end,
	})

	-- mount the component
	menu:mount()
end
return M
