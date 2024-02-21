local utils = require("texnotes.utils")
local M = {}

local render = function(filename)
	local file = filename:sub(1, -5)
	print("rendering ...", filename)
	vim.fn.jobstart({ "python", "manage.py", "render", file })
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
		local filename = path:match(".+/([^/]+)$")
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
		local name = path:match(".+/([^/]+)$"):sub(1, -5)
		utils.open_file("pdf", name .. ".pdf", dir)
	end, {})
end

return M
