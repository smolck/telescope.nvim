-- TODO: Customize keymap
local a = vim.api

local actions = require('telescope.actions')
local state = require('telescope.state')

local mappings = {}
local keymap = {}

mappings.set_keymap = function(prompt_bufnr, results_bufnr)
  local function default_mapper(mode, map_key, table_key)
    a.nvim_buf_set_keymap(
      prompt_bufnr,
      mode,
      map_key,
      string.format(
        [[<C-O>:lua __TelescopeMapping(%s, %s, '%s')<CR>]],
        prompt_bufnr,
        results_bufnr,
        table_key
        ),
      {
        silent = true,
      }
    )
  end

  default_mapper('i', '<c-n>', 'control-n')
  default_mapper('i', '<c-p>', 'control-p')
  default_mapper('i', '<CR>', 'enter')

  default_mapper('n', '<esc>', 'escape')
end


function __TelescopeMapping(prompt_bufnr, results_bufnr, characters)
  if keymap[characters] then
    keymap[characters](prompt_bufnr, results_bufnr)
  end
end

-- TODO: Refactor this to use shared code.
-- TODO: Move from top to bottom, etc.
-- TODO: It seems like doing this brings us back to the beginning of the prompt, which is not great.
keymap["control-n"] = function(prompt_bufnr, _)
  actions.shift_current_selection(prompt_bufnr, 1)
end

keymap["control-p"] = function(prompt_bufnr, _)
  actions.shift_current_selection(prompt_bufnr, -1)
end

keymap["enter"] = function(prompt_bufnr, results_bufnr)
  local picker = actions.get_current_picker(prompt_bufnr)
  local entry = actions.get_selected_entry(prompt_bufnr)

  if not entry then
    print("[telescope] Nothing currently selected")
    return
  else
    local value = entry.value
    if not value then
      print("Could not do anything with blank line...")
      return
    end

    -- TODO: This is not great.
    if type(value) == "table" then
      value = entry.display
    end

    local sections = vim.split(value, ":")

    local filename = sections[1]
    local row = tonumber(sections[2])
    local col = tonumber(sections[3])

    vim.cmd(string.format([[bwipeout! %s]], prompt_bufnr))

    a.nvim_set_current_win(picker.original_win_id or 0)
    vim.cmd(string.format(":e %s", filename))

    local bufnr = vim.api.nvim_get_current_buf()
    a.nvim_buf_set_option(bufnr, 'buflisted', true)
    if row and col then
      a.nvim_win_set_cursor(0, {row, col})
    end

    vim.cmd [[stopinsert]]
  end
end

keymap["escape"] = function(prompt_bufnr)
  vim.cmd(string.format([[bwipeout! %s]], prompt_bufnr))
end

return mappings
