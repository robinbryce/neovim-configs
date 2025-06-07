-- ~/.config/nvim/lua/util/dap.lua

local M = {}

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
