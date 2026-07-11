local js_based_languages = {
  "typescript",
  "javascript",
  -- "typescriptreact",
  -- "javascriptreact",
  -- "vue",
}

return {
  { "nvim-neotest/nvim-nio" },
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")
      local util_dap = require("util.dap")
      util_dap.setup()

      dap.set_log_level("TRACE") -- Enables internal adapter debug logging
      dap.listeners.before.launch["run-prelaunch-task"] = function(config)
        if config.preLaunchCommand then
          -- Example: run a shell command like a build step
          vim.fn.system(config.preLaunchCommand)
        end
      end

      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      -- nvim-dap still uses sign_define for its own signs on 0.12 (only the
      -- diagnostic-sign path was removed). Guard against double-definition when
      -- LazyVim dap.core also runs.
      local function define_dap_signs()
        local icons = require("lazyvim.config").icons.dap
        for name, sign in pairs(icons) do
          sign = type(sign) == "table" and sign or { sign }
          local sign_name = "Dap" .. name
          if vim.tbl_isempty(vim.fn.sign_getdefined(sign_name)) then
            vim.fn.sign_define(sign_name, {
              text = sign[1],
              texthl = sign[2] or "DiagnosticInfo",
              linehl = sign[3],
              numhl = sign[3],
            })
          end
        end
      end
      define_dap_signs()

      dap.adapters["pwa-node"] = {
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = {
          command = "node",
          args = { "/Users/robin/.local/share/nvf/lazy/vscode-js-debug/out/src/vsDebugServer.js", "${port}" },
        },
      }

      dap.adapters["node2"] = {
        type = "executable",
        command = "node",
        args = { "/Users/robin/.local/share/nvf/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
      }
      dap.configurations.javascript = {}

      --- NOTICE:
      --- For node command line tool debugging the situation is odd
      --- * I could not get source debugging with the modern pwa-node  & vscode-js-debug at all
      --- * IT REQUIRES CAREFUL AND ACCURATE vite.config.ts and tsconfig.json configuration to use 'vite build'
      ---   for *both* cli tool build and debugger use
      --- Previously to getting this sorted out:
      --- * building with tsc is the only method that resulted in working source debug for the older depricated adpapter
      --- * building with vite, and outputing cjs is the only method that resulted in a single file executable that could be easily run by node (esm was just a tar pit)
      --- * if the results of vite build are present in dist, it breaks the debugging, so a clean is required before doing that
      table.insert(dap.configurations.javascript, {
        name = "node:index.ts",
        type = "node2",
        request = "launch",
        program = "${workspaceFolder}/bin/index.ts",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        -- trace = true, -- verbose telemetry in dap.log
        protocol = "inspector",
        outFiles = { "${workspaceFolder}/**/dist/**/*.js" },
        skipFiles = { "<node_internals>/**" },
        preLaunchCommand = "pnpm run build",
        -- runtimeExecutable = "/Users/robin/.config/nvm/versions/node/v22.14.0/bin/node",
      })

      table.insert(dap.configurations.javascript, {
        name = "node:file",
        type = "node2",
        request = "launch",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        -- trace = true, -- verbose telemetry in dap.log
        protocol = "inspector",
        outFiles = { "${workspaceFolder}/**/dist/**/*.js" },
        skipFiles = { "<node_internals>/**" },
        -- runtimeExecutable = "/Users/robin/.config/nvm/versions/node/v22.14.0/bin/node",
      })

      dap.configurations.typescript = dap.configurations.javascript
      local i = util_dap.config_index(dap.configurations.typescript, "node:index.ts")
      local base = dap.configurations.typescript[i] -- lua is one based
      local extend = util_dap.clone_and_extend(base, {
        name = "chreq freq [ETH, USD]" .. base.name,
        args = { "freq", "--source", "source.js", "ETH", "USD" },
      })
      table.insert(dap.configurations.typescript, extend)

      -- NOTICE: using ts-node promises to be the most convenient, as it doesn't require compiling the source,
      -- however I could not get the break points to catch. even when running node directly from the command line with hardcoded debugger; statements
      --
      -- dap.configurations.javascript = {
      --   {
      --     name = "Launch ts-node (esm)",
      --     type = "pwa-node",
      --     request = "launch",
      --     program = "/Users/robin/Desktop/personal/code/chainlink/tools/chreq/bin/aa.ts",
      --     cwd = "/Users/robin/Desktop/personal/code/chainlink/tools/chreq",
      --     runtimeExecutable = "/Users/robin/.config/nvm/versions/node/v22.14.0/bin/node",
      --     runtimeArgs = {
      --       "--loader",
      --       "ts-node/esm",
      --       "--no-warnings",
      --       "--enable-source-maps",
      --     },
      --     sourceMaps = true,
      --     protocol = "inspector",
      --     skipFiles = { "<node_internals>/**" },
      --     -- outFiles = { "/Users/robin/Desktop/personal/code/chainlink/tools/chreq/dist/**/*.js" },
      --     trace = true,
      --     -- 👇 required for in-memory maps from ts-node
      --     resolveSourceMapLocations = {
      --       "/Users/robin/Desktop/personal/code/chainlink/tools/chreq/**",
      --       "!**/node_modules/**",
      --     },
      --     -- sourceMapPathOverrides = {
      --     --   ["file:///*"] = "/Users/robin/Desktop/personal/code/chainlink/tools/chreq/*",
      --     -- },
      --     sourceMapPathOverrides = {
      --       ["file:///Users/robin/Desktop/personal/code/chainlink/tools/chreq/*"] = "${workspaceFolder}/*",
      --     },
      --     pauseForSourceMap = true,
      --   },
      -- }
      -- THIS ALSO DOES NOT WORK (using vite-node)
      -- table.insert(dap.configurations.javascript, {
      --   name = "pwa-node:index.ts",
      --   type = "pwa-node",
      --   request = "launch",
      --   -- console = "integratedTerminal",
      --   pauseForSourceMap = true,
      --   -- program = "${workspaceFolder}/bin/index.ts",
      --   cwd = "${workspaceFolder}",
      --   sourceMaps = true,
      --   resolveSourceMapLocations = {
      --     "${workspaceFolder}/**",
      --     "!**/node_modules/**",
      --   },
      --   -- trace = true, -- verbose telemetry in dap.log
      --   protocol = "inspector",
      --   outFiles = { "${workspaceFolder}/**/dist/**/*.js" },
      --   skipFiles = { "<node_internals>/**" },
      --   runtimeExecutable = "node",
      --   runtimeArgs = {
      --     "--inspect-brk",
      --     util_dap.get_vite_node_path(),
      --     "${workspaceFolder}/bin/index.ts",
      --   },
      --   -- runtimeExecutable = "/Users/robin/.config/nvm/versions/node/v20.19.0/bin/node",
      -- })
    end,
    keys = {
      {
        "<leader>dO",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>da",
        function()
          if vim.fn.filereadable(".vscode/launch.json") then
            local dap_vscode = require("dap.ext.vscode")
            dap_vscode.load_launchjs(nil, {
              ["pwa-node"] = js_based_languages,
              ["chrome"] = js_based_languages,
              ["node2"] = js_based_languages,
              ["pwa-chrome"] = js_based_languages,
            })
          end
          require("dap").continue()
        end,
        desc = "Run with Args",
      },
    },
    dependencies = {
      -- Install the vscode-js-debug adapter
      {
        "microsoft/vscode-js-debug",
        -- After install, build it and rename the dist directory to out
        build = "npm install --legacy-peer-deps --no-save && npx gulp vsDebugServerBundle && rm -rf out && mv dist out",
        version = "1.*",
      },
      {
        "mxsdev/nvim-dap-vscode-js",
        config = function()
          ---@diagnostic disable-next-line: missing-fields
          require("dap-vscode-js").setup({
            -- Path of node executable. Defaults to $NODE_PATH, and then "node"
            -- node_path = "node",

            -- Path to vscode-js-debug installation.
            debugger_path = vim.fn.resolve(vim.fn.stdpath("data") .. "/lazy/vscode-js-debug"),

            -- Command to use to launch the debug server. Takes precedence over "node_path" and "debugger_path"
            -- debugger_cmd = { "js-debug-adapter" },

            -- which adapters to register in nvim-dap
            adapters = {
              "node2",
              "chrome",
              "pwa-node",
              "pwa-chrome",
              "pwa-msedge",
              "pwa-extensionHost",
              "node-terminal",
            },

            -- Path for file logging
            -- log_file_path = "(stdpath cache)/dap_vscode_js.log",

            -- Logging level for output to file. Set to false to disable logging.
            -- log_file_level = false,

            -- Logging level for output to console. Set to false to disable console output.
            -- log_console_level = vim.log.levels.ERROR,
          })
        end,
      },
      {
        "Joakker/lua-json5",
        build = "./install.sh",
      },
    },
  },
}
