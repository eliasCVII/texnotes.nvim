local utils = require("texnotes.utils")
local menu = require("texnotes.open-menu")
local M = {}

local options = {
	"render",
	"new",
	"rename",
	"rename_ref",
	"delete",
	"graph",
	"new_project",
	"open_menu",
}

M.make_note = function(dir)
	-- Menu for Notes
	vim.api.nvim_create_user_command("Note", function(opts)
		selection = opts.fargs[1]

		-- Set a filewatcher on a .tex file
		if selection == options[1] then
			utils.render_note(dir)

		-- Adding notes to the slipbox
		elseif selection == options[2] then
			utils.new_note(dir)

		-- Rename a selected note
		elseif selection == options[3] then
			utils.rename_note(dir)

		-- Rename a reference
		elseif selection == options[4] then
			utils.rename_reference(dir)

		-- Removing notes
		elseif selection == options[5] then
			-- delete doesnt work right now
			utils.delete_note(dir)

		-- open network view
		elseif selection == options[6] then
			utils.open_graph()

		-- Create a new project
		elseif selection == options[7] then
			dir = dir .. "/projects/"
			utils.new_project(dir)

		-- Launch open menu
		elseif selection == options[8] then
			menu.open_menu(dir)
		end
	end, {
		nargs = 1,
		complete = function(ArgLead, CmdLine, CursorPos)
			-- return completion candidates as a list-like table
			return options
		end,
	})
end

return M
