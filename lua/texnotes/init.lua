-- TODO: reduce to only one usercommand: Note.

-- External dependencies
local plenary = require("plenary")
local job = plenary.job
local pick = require("mini.pick")

local texnotes = {} -- all related functions to the module
local H = {}        -- helper functions to setup the plugin

--- texnotes module setup
texnotes.setup = function(config)
  _G.texnotes = texnotes

  config = H.setup_config(config)

  H.apply_config(config)

  H.create_autocommands(config)
end

--- texnotes module config
texnotes.config = {
  path = "~/texnotes",
  compile_on_write = true,
  render_format = "pdf",
}

texnotes.options = {
  "render",
  "new",
  "rename",
  "rename reference",
  "delete",
  "graph",
  "new project",
  "open menu",
  "render updates",
  "manage",
  "viewer",
}

texnotes.get_references = function(filepath)
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

texnotes.render_note = function(dir)
  local tex = H.get_path("tex", dir .. "/notes/slipbox", false, true)

  pick.start({
    mappings = H.menu_mappings(),
    source = {
      items = tex,
      name = "TeXNotes",
      choose = function(item)
        H.notify(item)
        H.notify("renaming " .. item)
        vim.ui.input({ prompt = "rename: " }, function(input)
          input = H.uppercase(input)
          texnotes.manage("rename_reference", item, input)
        end)
      end,
    },
    window = H.win_config(),
  })
end

texnotes.delete_at_point = function(file)
  if not file then
    return
  end
  local name = file:sub(1, -5)
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

texnotes.new_note = function(dir)
  vim.ui.input({ prompt = "new note: " }, function(input)
    if input then
      input = H.lowercase(input)
      H.notify("creating " .. input .. ".tex")
      texnotes.manage("newnote", input, "", true)
      input = input .. ".tex"
      H.open_file("tex", input, dir)
    end
  end)
end

texnotes.new_project = function(dir)
  vim.ui.input({ prompt = "new project: " }, function(input)
    if input then
      input = H.lowercase(input)
      H.notify("creating " .. input)
      texnotes.manage("newproject", input, "", true)
      local filename = input .. ".tex"
      input = input .. "/"
      H.open_file("tex", filename, dir .. input)
    end
  end)
end

texnotes.rename_reference = function(dir)
  local refs = texnotes.get_references(dir .. "/notes/documents.tex")

  pick.start({
    mappings = H.menu_mappings(),
    source = {
      items = refs,
      name = "TeXNotes",
      choose = function(item)
        H.notify(item)
        H.notify("renaming " .. item)
        vim.ui.input({ prompt = "rename: " }, function(input)
          input = H.uppercase(input)
          texnotes.manage("rename_reference", item, input)
        end)
      end,
    },
    window = H.win_config(),
  })
end

texnotes.rename_note_at_point = function(file)
  local refs = plenary.path:new("notes/documents.tex"):readlines()

  vim.ui.input({ prompt = "rename: " }, function(input)
    if not input then
      return
    end
    local rename = input
    local name = file:sub(1, -5)
    rename = H.lowercase(rename)

    for _, str in ipairs(refs) do
      local startIdx, endIdx = str:find("{.*}")
      if startIdx and endIdx then
        local innerStr = str:sub(startIdx + 1, endIdx - 1)
        if innerStr == name then
          local reference = str:match("%[(.-)%]"):gsub("-", "")
          texnotes.manage("rename_reference", reference, H.uppercase(rename))
          break
        end
      end
    end

    H.notify("renaming " .. name .. " to " .. rename)
    texnotes.manage("rename_file", name, rename)
  end)
end

texnotes.open_graph = function()
  texnotes.manage("synchronize", "", "", true)
  vim.fn.jobstart({ "python", "network.py" })
end

texnotes.render_updates = function()
  texnotes.manage("render_updates")
end

texnotes.viewer = function(dir)
  -- TODO: support for html, maybe check compiled files in pdf/html related to the buf_name
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  local filename = H.get_filename(path):sub(1, -5)
  H.open_file("pdf", filename .. ".pdf", dir)
end

texnotes.user_manage = function()
  vim.ui.input({ prompt = "manage.py: " }, function(input)
    texnotes.manage(input)
  end)
end

texnotes.file_menu = function(dir)
  -- TODO: handle multiple marked deletions?
  local add_items = function(target, source, prefix)
    for _, v in pairs(source) do
      table.insert(target, { text = prefix .. H.remove_path(v), path = v })
    end
  end

  local notes_dir = dir .. "/notes/slipbox"
  local projects_dir = dir .. "/projects"
  local pdfs_dir = dir .. "/pdf"

  local pdfs = H.get_path("pdf", pdfs_dir)
  local notes = H.get_path("tex", notes_dir)
  local projects = H.get_path("tex", projects_dir)

  local items = {}

  add_items(items, notes, " ")
  add_items(items, projects, " ")
  add_items(items, pdfs, " ")

  pick.start({
    mappings = H.menu_mappings({
      rename = {
        char = "<C-r>",
        func = function()
          local selection = pick.get_picker_matches().current.text
          texnotes.rename_note_at_point(selection:sub(5))
          MiniPick.refresh()
        end,
      },
      delete = {
        char = "<C-d>",
        func = function()
          local selection = pick.get_picker_matches().current.text
          texnotes.delete_at_point(selection:sub(5))
          MiniPick.refresh()
        end,
      },
    }),
    source = {
      items = items,
      name = "TeXNotes",
      choose = function(item)
        if plenary.filetype.detect(item.text) == "pdf" then
          H.open_file("pdf", item.text:sub(5), dir)
          MiniPick.stop()
          return
        end
        MiniPick.default_choose(item)
        MiniPick.stop()
      end,

      choose_marked = function(item_marked)
        for _, v in pairs(item_marked) do
          local ftp = plenary.filepath.detect(v.text)
          if ftp == "pdf" then
            H.open_file("pdf", v.text:sub(5), dir)
          else
            MiniPick.default_choose(v)
          end
        end
      end,
    },
    window = H.win_config(),
  })
end

texnotes.manage = function(command, arg1, arg2, sync)
  local args = { "manage.py", command }

  if arg1 and arg1 ~= "" then
    table.insert(args, arg1)
  end
  if arg2 and arg2 ~= "" then
    table.insert(args, arg2)
  end

  local Job_spec = {
    command = "python",
    args = args,
  }

  if sync then
    job:new(Job_spec):sync()
  else
    job:new(Job_spec):start()
  end
end

-- Helper functions and utilities
-- We setup the whole plugin down here
-- TODO: refactor all "render" functions, add table of parameters?

H.default_config = vim.deepcopy(texnotes.config)

H.setup_config = function(config)
  vim.validate({ config = { config, "table", true } })
  config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})

  return config
end

H.apply_config = function(config)
  texnotes.config = config
end

-- Utilities
-- MiniPick configuration
H.menu_mappings = function(...)
  local mappings = {

    choose = "<CR>",
    choose_in_split = "",
    choose_in_vsplit = "",
    choose_marked = "<C-o>",

    delete_left = "",
    delete_word = "<C-u>",

    mark = "<C-x>",
    mark_all = "",

    move_up = "<C-k>",
    move_down = "<C-j>",
    move_start = "",

    paste = "",

    refine = "",
    refine_marked = "",

    scroll_up = "<C-f>",
    scroll_down = "<C-b>",
    scroll_left = "<C-h>",
    scroll_right = "<C-l>",

    toggle_info = "",
    toggle_preview = "<Tab>",
  }

  for _, param in ipairs({ ... }) do
    for key, value in pairs(param) do
      mappings[key] = value
    end
  end

  return mappings
end

H.win_config = function()
  local height = 10
  local width = 70
  return {
    config = {
      anchor = "NW",
      height = height,
      width = width,
      row = math.floor(0.5 * vim.o.lines - (height / 2)),
      col = math.floor(0.5 * (vim.o.columns - width)),
    },
    prompt_prefix = " : ",
  }
end

-- Handling paths
H.get_filename = function(path)
  path = plenary.path:new(path):_split()
  return path[#path]
end

H.remove_path = function(path)
  path = plenary.path:new(path):_split()
  return path[#path]
end

H.get_path = function(pattern, dir, get_file, rm_path)
  local files
  if get_file then
    files = vim.fs.find(pattern, { path = dir })
  else
    files = vim.fs.find(function(name)
      return name:match(".*%." .. pattern .. "$")
    end, { limit = math.huge, type = "file", path = dir })
    if rm_path then
      for i, v in ipairs(files) do
        files[i] = H.remove_path(v)
      end
    end
  end
  return files
end

H.get_OS = function()
  return package.config:sub(1, 1) == "\\" and "win" or "unix"
end

-- User input handling
H.uppercase = function(str)
  return string.gsub(" " .. str, "%W%l", string.upper):sub(2):gsub("[_ ]", "")
end

H.lowercase = function(str)
  return string.gsub(" " .. str, "%w%l", string.lower):sub(2):gsub("[ ]", "_")
end

-- Using vim.notify instead of print
H.notify = function(message)
  vim.notify(message, vim.log.levels.INFO, { title = "Note" })
end

-- Start async jobs
H.job = function(command, arg1, arg2)
  local args = { arg1 }
  if arg2 and arg2 ~= "" then
    table.insert(args, arg2)
  end
  local Job_spec = {
    command = command,
    args = args,
  }
  job:new(Job_spec):start()
end

-- Handling opening files based on system
H.open_file = function(filetype, name, dir)
  local path = H.get_path(name, dir, true)
  if filetype == "pdf" then
    if H.get_OS() == "unix" then
      H.job("handlr", "open", path[1]) -- NOTE: switch to xdg-open for all unix systems
      return
    elseif H.get_OS() == "win" then
      -- H.job("start", path[1]) FIX: This doesnt work on windows, use vim.fn.system for now
      vim.fn.system("start " .. path[1])
    end
  elseif filetype == "tex" then
    vim.cmd.edit(path[1])
  end
  return true
end

-- Autocommands & user commands
H.render_file = function(filename, render_format)
  local file = filename:sub(1, -5)
  H.notify("rendering ... " .. filename)
  if render_format == "pdf" then
    texnotes.manage("render", file)
  elseif render_format == "html" then
    texnotes.manage("render", file, render_format)
  end
end

H.render_on_save = function(filename, render_format)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("watcher", { clear = true }),
    pattern = "*.tex",
    callback = function()
      H.render_file(filename, render_format)
    end,
  })
end

H.render = function(config)
  vim.api.nvim_create_user_command("Render", function()
    local buf = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(buf)
    local filename = H.get_filename(path)
    if config.compile_on_write then
      H.render_on_save(filename, config.render_format)
    else
      H.render_file(filename, config.render_format)
    end
  end, {})
end

H.create_user_commands = function(config)
  -- Menu for Notes
  local options = texnotes.options
  local dir = config.path
  vim.api.nvim_create_user_command("Note", function(opts)
    local selection = opts.fargs[1]

    -- Set a filewatcher on a .tex file
    if selection == options[1] then
      texnotes.render_note(dir)

      -- Adding notes to the slipbox
    elseif selection == options[2] then
      texnotes.new_note(dir)

      -- Rename a selected note
    elseif selection == options[3] then
      texnotes.rename_note(dir)

      -- Rename a reference
    elseif selection == options[4] then
      texnotes.rename_reference(dir)

      -- Removing notes
    elseif selection == options[5] then
      -- delete doesnt work right now
      texnotes.delete_note(dir)

      -- open network view
    elseif selection == options[6] then
      texnotes.open_graph()

      -- Create a new project
    elseif selection == options[7] then
      dir = dir .. "/projects/"
      texnotes.new_project(dir)

      -- Launch open menu
    elseif selection == options[8] then
      texnotes.file_menu(dir)

      -- Render all updated files
    elseif selection == options[9] then
      texnotes.render_updates()

      -- Call your own commands
    elseif selection == options[10] then
      texnotes.user_manage()

      -- Open the compiled pdf
    elseif selection == options[11] then
      texnotes.viewer(dir)
    end
  end, {
    nargs = 1,
    complete = function()
      return options
    end,
  })

  H.render(config)
end

-- Autocommand behavior
H.create_autocommands = function(config)
  local augroup = vim.api.nvim_create_augroup("texnotes", { clear = true })

  local au = function(event, pattern, callback, desc)
    vim.api.nvim_create_autocmd(event, { group = augroup, pattern = pattern, callback = callback, desc = desc })
  end

  if vim.loop.cwd() ~= vim.fn.expand(config.path) then
    return
  end

  -- If we are inside texnotes folder, start everything
  au({ "BufEnter" }, "*", function()
    require("cmp-texnotes")
    H.create_user_commands(config)
  end, "Setup on default path only")

  if config.compile_on_write == true then
    au({ "BufEnter" }, "*.tex", function()
      vim.cmd("Render")
    end, "Start auto compiling")
  end
end

return texnotes
