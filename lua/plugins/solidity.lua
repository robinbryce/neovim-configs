local uv = vim.uv or vim.loop

local function file_exists(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "file"
end

local function load_remappings_txt(root)
  local remaps = {}
  local path = root .. "/remappings.txt"
  local file = io.open(path, "r")
  if not file then
    return remaps
  end
  for line in file:lines() do
    local from, to = line:match("([^=]+)=(.+)")
    if from and to then
      table.insert(remaps, from .. "=" .. to)
    end
  end
  file:close()
  return remaps
end

local function load_foundry_remappings(root)
  local ok, toml = pcall(require, "toml")
  if not ok then
    return {}
  end
  local path = root .. "/foundry.toml"
  local file = io.open(path, "r")
  if not file then
    return {}
  end
  local contents = file:read("*a")
  file:close()

  local parsed = toml.parse(contents)
  local remappings = {}

  local profile = parsed and parsed.profile and parsed.profile.default
  if profile and profile.remappings then
    for _, entry in ipairs(profile.remappings) do
      table.insert(remappings, entry)
    end
  elseif parsed and parsed.remappings then
    for _, entry in ipairs(parsed.remappings) do
      table.insert(remappings, entry)
    end
  end

  return remappings
end

local function load_remappings(root)
  if file_exists(root .. "/remappings.txt") then
    return load_remappings_txt(root)
  else
    return load_foundry_remappings(root)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solidity = {
          cmd = { "solidity-language-server", "--stdio" },
          filetypes = { "solidity" },
          root_dir = require("lspconfig.util").root_pattern(
            "foundry.toml",
            "hardhat.config.js",
            "hardhat.config.ts",
            ".git"
          ),
          settings = {
            solidity = {
              includePath = "lib",
              remapping = {}, -- will be overridden per-project
            },
          },
          on_new_config = function(new_config, root_dir)
            new_config.settings.solidity.remapping = load_remappings(root_dir)
          end,
        },
      },
    },
  },
}
