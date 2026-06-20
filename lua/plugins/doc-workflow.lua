-- Document workflow: numbered ARC/ADR in the *current buffer's git repo* docs/.
-- Interactive planning uses rail 2 (Cursor agent / :PlanNew), not in-repo plan files.
--
-- lazy-fullstack's own docs/ is only for Neovim tooling (e.g. cursor-agent ledger).

local valid_types = { arc = true, adr = true }

--- Find the git repository root for the current buffer.
---@return string|nil root Absolute path or nil
local function repo_root()
  local dot_git = vim.fn.finddir(".git", vim.fn.expand("%:p:h") .. ";")
  if dot_git ~= "" then
    return vim.fn.fnamemodify(dot_git, ":h")
  end
  return nil
end

--- Resolve the docs directory, creating it if necessary.
---@return string docs_dir Absolute path to the docs directory
local function resolve_docs_dir()
  local root = repo_root() or vim.fn.getcwd()
  local local_docs = root .. "/docs"

  if vim.fn.isdirectory(local_docs) == 1 then
    return local_docs
  end

  local shared = vim.env.SHARED_AGENT_DOCS
  if shared and shared ~= "" then
    if vim.fn.isdirectory(shared) == 1 then
      return shared
    end
    vim.notify("SHARED_AGENT_DOCS=" .. shared .. " is not a directory", vim.log.levels.WARN)
  end

  vim.fn.mkdir(local_docs, "p")
  local cat_path = local_docs .. "/DOCUMENT_CATEGORIES.md"
  local cat_content = [[# Documentation Categories

This project uses **ARC** and **ADR** under `docs/arc/` and `docs/adr/`.
Numbered filenames follow `arc-NNNN-slug.md` and `adr-NNNN-slug.md`.

**Interactive planning** (multi-session, agent-native persistence) is separate from
this tree; use Neovim `:PlanNew` / `<leader>Cp` (Cursor agent plan mode) for that.

---

## ARC — Architecture

**Location:** `docs/arc/`
**Prefix:** `arc-NNNN-*.md`

## ADR — Decisions

**Location:** `docs/adr/`
**Prefix:** `adr-NNNN-*.md`

## Numbering

Four-digit zero-padded sequence per type, increment from highest existing file.

## Cross-referencing

Use relative links, e.g. `See [ADR-0003](adr-0003-slug.md)`.
]]
  local f = io.open(cat_path, "w")
  if f then
    f:write(cat_content)
    f:close()
  end
  vim.notify("Created " .. local_docs .. "/ with DOCUMENT_CATEGORIES.md", vim.log.levels.INFO)
  return local_docs
end

---@param type_dir string
---@param prefix string "arc" | "adr"
---@return number
local function next_number(type_dir, prefix)
  local max_n = 0
  local pattern = "^" .. prefix .. "%-(%d+)%-"
  local handle = vim.loop.fs_scandir(type_dir)
  if handle then
    while true do
      local name, typ = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
      if typ == "file" then
        local n = name:match(pattern)
        if n then
          max_n = math.max(max_n, tonumber(n))
        end
      end
    end
  end
  return max_n + 1
end

---@param doc_type string "arc" | "adr"
---@param name string
local function create_doc(doc_type, name)
  local docs_dir = resolve_docs_dir()
  local type_dir = docs_dir .. "/" .. doc_type
  vim.fn.mkdir(type_dir, "p")

  local num = next_number(type_dir, doc_type)
  local filename = string.format("%s-%04d-%s.md", doc_type, num, name)
  local filepath = type_dir .. "/" .. filename
  local date = os.date("%Y-%m-%d")

  local title = string.upper(doc_type) .. "-" .. string.format("%04d", num) .. ": " .. name:gsub("%-", " ")

  local header = string.format(
    [[# %s

**Status:** DRAFT
**Date:** %s
**Related:**

---

]],
    title,
    date
  )

  local f = io.open(filepath, "w")
  if f then
    f:write(header)
    f:close()
  end
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  vim.notify("Created " .. doc_type .. "/" .. filename, vim.log.levels.INFO)
end

---@param args_str string
---@param doc_type string
local function new_from_args(args_str, doc_type)
  local name = vim.trim(args_str):lower():gsub("%s+", "-")
  if name == "" then
    vim.notify("Usage: :" .. (doc_type == "arc" and "ArcNew" or "AdrNew") .. " <kebab-name>", vim.log.levels.ERROR)
    return
  end
  create_doc(doc_type, name)
end

return {
  dir = vim.fn.stdpath("config"),
  name = "doc-workflow",
  virtual = true,
  lazy = false,
  config = function()
    vim.api.nvim_create_user_command("ArcNew", function(opts)
      new_from_args(opts.args, "arc")
    end, {
      nargs = "+",
      desc = "Create docs/arc/arc-NNNN-<name>.md in buffer git root",
    })

    vim.api.nvim_create_user_command("AdrNew", function(opts)
      new_from_args(opts.args, "adr")
    end, {
      nargs = "+",
      desc = "Create docs/adr/adr-NNNN-<name>.md in buffer git root",
    })

    vim.api.nvim_create_user_command("DocNew", function()
      vim.notify("Deprecated: use :ArcNew or :AdrNew", vim.log.levels.WARN, { title = "doc-workflow" })
    end, { desc = "Deprecated — use :ArcNew / :AdrNew" })

    vim.api.nvim_create_user_command("PlanNew", function(opts)
      local seed = vim.trim(opts.args or "")
      if seed ~= "" then
        vim.fn.setreg("+", seed)
        vim.notify("Plan seed yanked to + register — paste after agent opens", vim.log.levels.INFO, { title = "PlanNew" })
      end
      vim.cmd("CursorAgentPlan")
    end, {
      nargs = "?",
      desc = "Rail 2: Cursor agent plan mode; optional seed yanked to +",
    })

    vim.api.nvim_create_user_command("DocList", function()
      local docs_dir = resolve_docs_dir()
      local ok, fzf = pcall(require, "fzf-lua")
      if ok then
        fzf.files({
          cwd = docs_dir,
          prompt = "Docs> ",
        })
        return
      end

      local paths = vim.fn.globpath(docs_dir, "**/*.md", false, true)
      if type(paths) ~= "table" then
        paths = paths ~= "" and { paths } or {}
      end
      table.sort(paths)
      vim.ui.select(paths, { prompt = "Open doc:" }, function(choice)
        if choice then
          vim.cmd("edit " .. vim.fn.fnameescape(choice))
        end
      end)
    end, { desc = "Browse docs/**/*.md for buffer git root" })
  end,
  keys = {
    { "<leader>dna", ":ArcNew ", desc = "Doc: new ARC" },
    { "<leader>dnd", ":AdrNew ", desc = "Doc: new ADR" },
    { "<leader>dnp", ":PlanNew ", desc = "Rail 2: PlanNew (agent plan)" },
    { "<leader>dl", "<cmd>DocList<CR>", desc = "Doc: list / browse" },
  },
}
