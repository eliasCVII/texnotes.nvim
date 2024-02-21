local M = {}

local function uppercase(str)
	return string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("[_ ]", "")
end

local function lowercase(str)
	return string.gsub(" " .. str, "%w%l", string.lower):sub(2):gsub("[ ]", "_")
end

local function remove_path(path) -- returns the filename only, i.e index.tex
	return path:match(".+/([^/]+)$")
end

local function get_OS()
	return package.config:sub(1, 1) == "\\" and "win" or "unix"
end

local function get_path(pattern, dir, get_file) -- returns table with lists of files
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

M.open_file = function(filetype, name, dir)
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

local function get_references(filepath)
	local file = io.open(vim.fn.expand(filepath), "r")
	local lines = {}

	if file then
		for line in file:lines() do
			local match = line:match("%[(.-)%]")
			if match then
				match = match:gsub("-", "")
				table.insert(lines, match)
			end
		end
		file:close()
	end
	return lines
end

local function manage(command, par_one, par_two) -- control manage.py
	vim.fn.jobstart({ "python", "manage.py", command, par_one, par_two })
end

M.edit_note = function(dir) -- NOTE: unused
	local tex = get_path("tex", dir)
	vim.ui.select(tex, { prompt = "choose note to edit" }, function(choice)
		if choice ~= nil then
			local name = choice
			-- local name = remove_path(choice)
			local path = dir .. "/notes/slipbox/"
			M.open_file(name, path)
		end
		return choice
	end)
end

M.render_note = function(dir) -- render a specific note
	local tex = get_path("tex", dir .. "/notes/slipbox")
	vim.ui.select(tex, { prompt = "choose note to render" }, function(choice)
		if choice ~= nil then
			local name = choice:sub(1, -5)
			print("rendering", name)
			manage("render", name)
			vim.defer_fn(function()
				M.open_file("pdf", name .. ".pdf", dir)
			end, 500)
		end
		return choice
	end)
end

M.delete_note = function(dir)
	-- kind of a dangereous function
	local tex = get_path("tex", dir .. "/notes/slipbox")
	vim.ui.select(tex, { prompt = "choose note to delete" }, function(choice)
		if choice ~= nil then
			local name = choice:sub(1, -5)
			local command = "!bash auto_delete.sh " .. name
			vim.ui.input({ prompt = "Deleting " .. name .. ", you sure? (y/n) " }, function(input)
				if input == "y" then
					vim.cmd(command)
				else
					return
				end
				local delete_everything = vim.fn.input("Delete compiled files?: (y/n) ")
				if delete_everything == "y" then
					vim.cmd(command .. " y")
				end
			end)
		end
		return choice
	end)
end

M.new_note = function(dir)
	vim.ui.input({ prompt = "new note: " }, function(input)
		if input then
			input = lowercase(input) -- replace " " with "_"
			print("creating", input .. ".tex")
			manage("newnote", input)
			input = input .. ".tex"
			vim.defer_fn(function()
				M.open_file("tex", input, dir)
			end, 200)
		end
	end)
end

M.new_project = function(dir)
	vim.ui.input({ prompt = "new project: " }, function(input)
		if input then
			input = lowercase(input) -- replace " " with "_"
			print("creating", input)
			manage("newproject", input)
			local filename = input .. ".tex"
			input = input .. "/"
			vim.defer_fn(function()
				M.open_file("tex", filename, dir .. input)
			end, 200)
		end
	end)
end

M.view_note = function(dir) -- NOTE: unused
	local pdfs = get_path("pdf", dir)
	vim.ui.select(pdfs, { prompt = "choose compiled note to view" }, function(choice)
		if choice then
			local name = remove_path(choice)
			print("opening", name)
			vim.fn.jobstart({ "handlr", "open", choice })
		end
		return choice
	end)
end

M.rename_note = function(dir)
	local tex = get_path("tex", dir .. "/notes/slipbox")
	vim.ui.select(tex, { prompt = "choose a note to rename" }, function(choice)
		if choice then
			local rename = vim.fn.input("rename: ")
			local name = choice:sub(1, -5)
			print("renaming", name .. " to " .. rename)
			rename = lowercase(rename)
			manage("rename_file", name, rename)
		end
		return choice
	end)
end

M.rename_reference = function(dir)
	local refs = get_references(dir .. "/notes/documents.tex")

	vim.ui.select(refs, { prompt = "choose a reference to rename" }, function(choice)
		if choice then
			-- local name = uppercase(choice)
			print("renaming", choice)
			vim.ui.input({ prompt = "rename: " }, function(input)
				input = uppercase(input)
				manage("rename_reference", choice, input)
			end)
		end
		return choice
	end)
end

M.open_graph = function()
	manage("synchronize", "")
	vim.defer_fn(function()
		vim.fn.jobstart({ "python", "network.py" })
	end, 250)
end

return M
