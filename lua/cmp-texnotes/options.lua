local main = {}

main.default = {
	path = "~/texnotes/notes/documents.tex",
	notes = "~/texnotes/notes/slipbox",
}

main.validate = function(params)
	local options = vim.tbl_deep_extend("keep", params.option, main.default)
	vim.validate({
		path = { options.path, "string" },
		notes = { options.path, "string" },
	})
	return options
end

return main
