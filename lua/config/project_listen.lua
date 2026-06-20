--- Deterministic per-cwd RPC listen socket under stdpath('run'). First nvim binds; others
--- become followers. Stale UNIX sockets after crash: probe fails + kind socket → unlink once.
--- Slug: split abs path on '/', reverse segments (deepest dir first), join with '-'.
--- Long slug (>64): keep first 64 chars + '-' + first 36 of sha256(abs cwd).
--- If the resulting path exceeds the OS unix-socket limit, serverstart may fail (handled below).


local abs_cwd = vim.fs.abspath(vim.uv.cwd() or vim.fn.getcwd(-1))

--- Reversed path segments (leaf dirname first); safe-ish for filenames in each segment.
--- @param abs_path string
--- @return string
local function cwd_slug(abs_path)
  local norm = vim.fs.normalize(abs_path, { expand_env = false })
  local segments = {}
  for seg in norm:gmatch("[^/]+") do
    segments[#segments + 1] = seg:gsub("[:\\]", "-")
  end
  local rev = {}
  for i = #segments, 1, -1 do
    rev[#rev + 1] = segments[i]
  end
  return table.concat(rev, "-")
end

--- @param path string
--- @return boolean
local function rpc_peer_alive(path)
  local ok, cid = pcall(vim.fn.sockconnect, "pipe", path, { rpc = true })
  if ok and type(cid) == "number" and cid > 0 then
    pcall(vim.fn.chanclose, cid)
    return true
  end
  return false
end

local slug_from_cwd = cwd_slug(abs_cwd)
local rundir = vim.fn.stdpath("run") .. "/nvf-rpc"
vim.fn.mkdir(rundir, "p")

local slug = slug_from_cwd
if #slug > 64 then
  slug = slug:sub(1, 64) .. "-" .. vim.fn.sha256(abs_cwd):sub(1, 36)
end

local socket_path = string.format("%s/%s.sock", rundir, slug)

vim.g.nvf_rpc_path = socket_path

local stat = vim.uv.fs_stat(socket_path)
if stat then
  if stat.type ~= "socket" then
    vim.g.nvf_rpc_state = "error"
    vim.notify(
      "nvf-rpc: socket path occupied by non-socket: " .. socket_path,
      vim.log.levels.WARN,
      { title = "nvf-rpc" }
    )
    return
  end
  if rpc_peer_alive(socket_path) then
    vim.g.nvf_rpc_state = "follower"
    return
  end
  local ok_rm, err_rm = pcall(vim.fn.delete, socket_path)
  if not ok_rm then
    vim.g.nvf_rpc_state = "error"
    vim.notify(
      "nvf-rpc: stale socket but delete failed (" .. (err_rm or "?") .. "):\n" .. socket_path,
      vim.log.levels.WARN,
      { title = "nvf-rpc" }
    )
    return
  end
end

local addr = vim.fn.serverstart(socket_path)
if type(addr) == "string" and addr ~= "" then
  vim.g.nvf_rpc_state = "listening"
  vim.g.nvf_rpc_socket = socket_path
else
  vim.g.nvf_rpc_state = "error"
  vim.notify(
    "nvf-rpc: serverstart failed for:\n" .. socket_path,
    vim.log.levels.WARN,
    { title = "nvf-rpc" }
  )
end
