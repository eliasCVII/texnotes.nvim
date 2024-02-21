local Menu = require("nui.menu")
local NuiText = require("nui.text")

local function remove_path(path) -- returns the filename only, i.e index.tex
	return path:match(".+/([^/]+)$")
end

local function get_OS()
	return package.config:sub(1, 1) == "\\" and "win" or "unix"
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

local function open_file(filetype, name, dir)
	local path = get_path(name, dir, true)
	if filetype == "pdf" then
		if get_OS() == "unix" then
			vim.fn.jobstart({ "handlr", "open", path[1] })
		elseif get_OS() == "win" then
			vim.fn.system("start " .. path[1])
		end
	elseif filetype == "tex" then
		vim.cmd("e " .. path[1])
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
			height = 10,
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
			submit = { "<CR>", "<Space>" },
		},
		on_close = function()
			print("Closing Menu!")
		end,
		on_submit = function(item)
			local filetype = item.text:sub(-3)
			open_file(filetype, item.text:sub(5), dir)
		end,
	})

	-- mount the component
	menu:mount()
end
return M
