local watcher = require("texnotes.watcher")
local note = require("texnotes.note")
local M = {}

-- defaults go here
M.config = {
	path = "~/texnotes",
	render_on_write = true,
}

local function call_render()
	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*.tex",
		callback = function()
			vim.cmd("Render")
		end,
	})
end

M.setup = function(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})

	local expand = vim.fn.expand
	vim.api.nvim_create_autocmd("BufEnter", {
		callback = function()
			local dir = M.config.path
			if vim.loop.cwd() == expand(dir) then
				note.make_note(dir)
				watcher.render(M.config.render_on_write)
				watcher.viewer(dir)
				call_render()
			end
		end,
	})
end

return M
