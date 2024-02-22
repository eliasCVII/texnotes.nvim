local utils = require("texnotes.utils")
local plenary = require("plenary")
local M = {}

local get_filename = function(path)
	-- local pathsep = package.config:sub(1, 1)
	-- path = path:gsub("[\\/]", pathsep)
	-- return path:match(".+" .. pathsep .. "([^" .. pathsep .. "]+)$")
	path = plenary.path:new(path):_split()
	return path[#path]
end

local render = function(filename)
	local file = filename:sub(1, -5)
	utils.notify("rendering ... " .. filename)
	utils.manage("render", file)
end

local render_on_save = function(filename)
	vim.api.nvim_create_autocmd("BufWritePost", {
		group = vim.api.nvim_create_augroup("watcher", { clear = true }),
		pattern = "*.tex",
		callback = function()
			render(filename)
		end,
	})
end

M.render = function(render_on_write)
	vim.api.nvim_create_user_command("Render", function()
		local buf = vim.api.nvim_get_current_buf()
		local path = vim.api.nvim_buf_get_name(buf)
		local filename = get_filename(path)
		if render_on_write then
			render_on_save(filename)
		else
			render(filename)
		end
	end, {})
end

M.viewer = function(dir)
	vim.api.nvim_create_user_command("Viewer", function()
		local buf = vim.api.nvim_get_current_buf()
		local path = vim.api.nvim_buf_get_name(buf)
		local filename = get_filename(path):sub(1, -5)
		utils.open_file("pdf", filename .. ".pdf", dir)
	end, {})
end

return M
