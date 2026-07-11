-- Shell / ex-command output in a scratch buffer when native hit-enter is easy to miss.
-- Note: <leader>cs is Aerial (lazyvim aerial extra); use <leader>cy here.
return {
  "folke/snacks.nvim",
  keys = {
    {
      "<leader>cy",
      function()
        local cmd = vim.fn.input("Shell: ")
        if cmd == "" then
          return
        end
        local out = vim.fn.system(cmd)
        local lines = vim.split(out, "\n", { trimempty = false })
        if lines[#lines] == "" then
          lines[#lines] = nil
        end
        if vim.v.shell_error ~= 0 then
          table.insert(lines, 1, "[exit " .. vim.v.shell_error .. "]")
        end
        if #lines == 0 then
          lines = { "(no output)" }
        end
        Snacks.scratch({
          name = "Shell",
          icon = " ",
          ft = "log",
          template = table.concat(lines, "\n"),
          filekey = { id = "shell", cwd = false, branch = false, count = false },
          win = { position = "bottom", height = 0.4, title = " Shell: " .. cmd .. " " },
        })
      end,
      desc = "Shell command output (scratch)",
    },
  },
}
