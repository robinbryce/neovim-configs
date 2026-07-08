return {
  {
    "sindrets/diffview.nvim",
    -- Lazy-load on its own commands + keys.
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewFileHistory",
      "DiffviewRefresh",
    },
    opts = {
      enhanced_diff_hl = true,
    },
    keys = {
      {
        "<leader>gvm",
        function()
          -- Resolve the remote default branch (origin/main, origin/master, …)
          -- then open the branch's cumulative diff via the merge-base ("...").
          -- Works whether the trunk is main or master, and ignores commits that
          -- landed on the trunk after this branch diverged.
          local function trunk()
            local head = vim.fn.systemlist({ "git", "rev-parse", "--abbrev-ref", "origin/HEAD" })[1]
            if vim.v.shell_error == 0 and head and head ~= "" and not head:find("fatal") then
              return head
            end
            for _, c in ipairs({ "origin/main", "origin/master", "main", "master" }) do
              vim.fn.system({ "git", "rev-parse", "--verify", "--quiet", c })
              if vim.v.shell_error == 0 then
                return c
              end
            end
            return "main"
          end
          vim.cmd("DiffviewOpen " .. trunk() .. "...HEAD")
        end,
        desc = "Diffview: branch vs default branch",
      },
      { "<leader>gvo", "<cmd>DiffviewOpen<cr>", desc = "Diffview: working tree" },
      { "<leader>gvc", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
      { "<leader>gvh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview: repo file history" },
      {
        "<leader>gvf",
        function()
          vim.cmd("DiffviewFileHistory " .. vim.fn.expand("%:p"))
        end,
        desc = "Diffview: current file history",
      },
    },
  },
  -- which-key group label for the diffview maps.
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>gv", group = "diffview" },
      },
    },
  },
}
