local parse_notes = require("cmp-texnotes.parse_notes")
local plenary = require("plenary")

local remove_path = function(path)
	path = plenary.path:new(path):_split()
	return path[#path]
end


return function(_, params, callback)
	local items = {}

	-- NOTE: plenary version, some issues with how it handles paths made it unstable

	-- local plenary = require("plenary")
	-- local file = plenary.path:new("notes/documents.tex"):readlines()

	-- for _, str in ipairs(file) do
	-- 	if str ~= "" then
	-- 		local reference = str:match("%[(.-)%]"):gsub("-", "")
	-- 		table.insert(items, {
	-- 			documentation = { kind = "markdown", value = " " .. str },
	-- 			label = reference,
	-- 		})
	-- 	end
	-- end

	local insert_refs = function(where, label, ref, filename, details)
		-- local doc = "- Filename: " .. filename .. "\n- Reference: " .. ref
		table.insert(where, {
			labelDetails = { description = details },
			label = label,
			-- documentation = { kind = "markdown", value = doc },
		})
	end

	local insert_texlabels = function(where, info_label, info_file_path, info_environment)
		local doc = string.format(
			"- label: %s\n- found in: %s\n- env:\n%s",
			info_label,
			remove_path(info_file_path),
			info_environment
		)

		table.insert(where, {
			labelDetails = { description = " Label" },
			label = info_label,
			documentation = { kind = "markdown", value = doc },
		})
	end

	local path = require("cmp-texnotes.options").validate(params).path
	local notes_path = require("cmp-texnotes.options").validate(params).notes

	local file = io.open(vim.fn.expand(path), "r")
	local note_data = parse_notes.get_labels(notes_path)

	if not file and not note_data then
		return
	end

	if file then
		for line in file:lines() do
			local reference = line:match("%[(.-)%]")
			local filename = line:match("%{(.-)%}")
			if reference and filename then
				reference = reference:gsub("-", "")
				insert_refs(items, reference, reference, filename, " refs")
				insert_refs(items, filename, reference, filename, " file")
			end
		end
		file:close()
	end

	if #note_data > 0 then
		for _, info in ipairs(note_data) do
			insert_texlabels(items, info.label, info.file_path, info.environment)
		end
	end

	-- Send data to cmp
	callback({
		items = items,
		isIncomplete = true,
	})
end
