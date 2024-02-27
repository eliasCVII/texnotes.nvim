local cmp = require("cmp")

local source = {}

function source.new()
	return setmetatable({}, { __index = source })
end

source.complete = require("cmp-texnotes.complete")

source.get_trigger_characters = function()
	return { "{" }
end

source.get_keyword_pattern = function()
	return [[\k\+]]
end

source.is_available = function()
	return vim.bo.filetype == "tex"
end

cmp.register_source("texnotes", source.new())

return source
