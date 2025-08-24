-- ~/.config/nvim/lua/util/dap.lua

local M = {}

function M.setup()
  local dap = require("dap")
  local saved_keymaps = {}

  local dap_keys = {
    ["<F5>"] = function()
      dap.continue()
    end,
    ["<F10>"] = function()
      dap.step_over()
    end,
    ["<F11>"] = function()
      dap.step_into()
    end,
    ["<F12>"] = function()
      dap.step_out()
    end,
    ["<F9>"] = function()
      dap.toggle_breakpoint()
    end,
  }

  local function set_dap_keymaps()
    saved_keymaps = {}
    for key, action in pairs(dap_keys) do
      local existing = vim.fn.maparg(key, "n", false, true)
      if existing and existing.rhs then
        saved_keymaps[key] = existing
      end
      vim.keymap.set("n", key, action, { silent = true, noremap = true, desc = "DAP " .. key })
    end
  end

  local function restore_keymaps()
    for key in pairs(dap_keys) do
      vim.keymap.del("n", key)
      local saved = saved_keymaps[key]
      if saved then
        vim.keymap.set("n", key, saved.rhs, {
          silent = saved.silent == 1,
          noremap = saved.noremap == 1,
          expr = saved.expr == 1,
        })
      end
    end
    saved_keymaps = {}
  end

  dap.listeners.before.attach["keymap_setup"] = set_dap_keymaps
  dap.listeners.before.launch["keymap_setup"] = set_dap_keymaps
  dap.listeners.after.event_terminated["keymap_restore"] = restore_keymaps
  dap.listeners.after.event_exited["keymap_restore"] = restore_keymaps
end

function M.clone_and_extend(base, overrides)
  local result = {}
  for k, v in pairs(base) do
    result[k] = v
  end
  for k, v in pairs(overrides) do
    result[k] = v
  end
  return result
end

--- Find the index of a DAP config with the given name
-- @param configs table - The dap.configurations.[lang] array
-- @param name string - The name to search for
-- @return integer|nil - The index (1-based) or nil if not found
function M.config_index(configs, name)
  for i, config in ipairs(configs) do
    if config.name == name then
      return i
    end
  end
  return nil
end

-- Helper to get vite-node binary path via `pnpm bin`
function M.get_vite_node_path()
  local handle = io.popen("pnpm bin")
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  if not result then
    return nil
  end
  local vite_node = vim.fn.trim(result) .. "/vite-node"
  if vim.fn.filereadable(vite_node) == 1 then
    return vite_node
  else
    vim.notify("vite-node not found in pnpm bin", vim.log.levels.ERROR)
    return nil
  end
end

--- Derive a .env file name from a given path
-- @param path string - The file path (with or without extension)
-- @return string - The derived env filename
function M.cli_env_debug_file(program_path)
  if program_path == "" then
    return ".env.node-cli.debug"
  end

  local trimmed = program_path:match("^(.*)%.") or program_path

  if trimmed == "" then
    return ".env.node-cli.debug"
  end

  return ".env.node-cli.debug." .. trimmed
end

return M
