local async = require("plenary.async")

local M = {}

local function extract_labels_and_env_from_file(file_path)
	local file = assert(io.open(file_path, "r"))
	local in_environment = false
	local current_environment = ""
	local current_lines = {}
	local current_label = nil
	local label_info = {}

	for line in file:lines() do
		if in_environment then
			table.insert(current_lines, line)
			if line:find("\\end{" .. current_environment .. "}") then
				in_environment = false
				table.insert(label_info, {
					label = current_label,
					file_path = file_path,
					environment = table.concat(current_lines, "\n"),
				})
				current_lines = {}
			end
		else
			local label = line:match("\\label%{(.-)%}")
			if label then
				current_label = label
				current_environment = line:match("\\begin%{(.-)%}")
				if current_environment then
					in_environment = true
					table.insert(current_lines, line)
				end
			end
		end
	end

	file:close()

	return label_info
end

local function process_tex_files_async(folder_path)
	local files = {}
	for file in io.popen("find " .. folder_path .. ' -name "*.tex"'):lines() do
		table.insert(files, file)
	end

	local results = {}
	local async_func = function()
		for _, file in ipairs(files) do
			local labels_envs = extract_labels_and_env_from_file(file)
			for _, info in ipairs(labels_envs) do
				table.insert(results, info)
			end
		end
	end

	async.run(async_func)
	return results
end

M.get_labels = function(dir)
	return process_tex_files_async(dir)
end

return M
