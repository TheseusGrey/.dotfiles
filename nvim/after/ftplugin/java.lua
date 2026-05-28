local home = os.getenv("HOME")
local jdtls_path = home .. "/.local/share/nvim/mason/packages/jdtls"
local lombok_path = jdtls_path .. "/lombok.jar"

-- Auto-download lombok if missing
if vim.fn.filereadable(lombok_path) == 0 then
  vim.fn.system({ "curl", "-sL", "https://projectlombok.org/downloads/lombok.jar", "-o", lombok_path })
end

-- Spring Boot language server extensions
local spring_boot_path = home .. "/.local/share/nvim/spring-boot-ls"
local spring_boot_jars_pattern = spring_boot_path .. "/jars/*.jar"

-- Auto-download Spring Boot LS jars if directory is missing
if vim.fn.isdirectory(spring_boot_path .. "/jars") == 0 then
  vim.fn.mkdir(spring_boot_path .. "/jars", "p")
  local vsix_path = spring_boot_path .. "/spring-boot.vsix"
  vim.fn.system({
    "curl",
    "-sL",
    "https://open-vsx.org/api/VMware/vscode-spring-boot/latest/file/VMware.vscode-spring-boot-latest.vsix",
    "-o",
    vsix_path,
  })
  vim.fn.system({ "unzip", "-o", vsix_path, "extension/jars/*", "-d", spring_boot_path })
  -- Move jars up from extension/jars/ to jars/
  vim.fn.system({ "sh", "-c", "mv " .. spring_boot_path .. "/extension/jars/*.jar " .. spring_boot_path .. "/jars/" })
  vim.fn.system({ "rm", "-rf", spring_boot_path .. "/extension", vsix_path })
end

local workspace_path = home .. "/.local/share/nvim/jdtls-workspace/"
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = workspace_path .. project_name

local status, jdtls = pcall(require, "jdtls")
if not status then
  return
end
local extendedClientCapabilities = jdtls.extendedClientCapabilities

-- Determine OS-specific config dir
local os_config = "config_linux"
if vim.fn.has("mac") == 1 then
  os_config = "config_mac"
elseif vim.fn.has("win32") == 1 then
  os_config = "config_win"
end

-- Use SDKMAN's current Java
local sdkman_dir = os.getenv("SDKMAN_DIR") or (home .. "/.sdkman")
local java_home = sdkman_dir .. "/candidates/java/current"
local java_cmd = java_home .. "/bin/java"

local config = {
  cmd = {
    java_cmd,
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dlog.protocol=true",
    "-Dlog.level=ALL",
    "-Xmx1g",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-javaagent:" .. lombok_path,
    "-jar",
    vim.fn.glob(home .. "/.local/share/nvim/mason/packages/jdtls/plugins/org.eclipse.equinox.launcher_*.jar"),
    "-configuration",
    home .. "/.local/share/nvim/mason/packages/jdtls/" .. os_config,
    "-data",
    workspace_dir,
  },
  root_dir = require("jdtls.setup").find_root({ ".git", "mvnw", "gradlew", "pom.xml", "build.gradle" }),

  settings = {
    java = {
      signatureHelp = { enabled = true },
      extendedClientCapabilities = extendedClientCapabilities,
      maven = {
        downloadSources = true,
      },
      eclipse = {
        downloadSources = true,
      },
      configuration = {
        updateBuildConfiguration = "interactive",
      },
      import = {
        gradle = {
          enabled = true,
          wrapper = { enabled = true },
          java = { home = java_home },
        },
        maven = { enabled = true },
      },
      referencesCodeLens = {
        enabled = true,
      },
      references = {
        includeDecompiledSources = true,
      },
      inlayHints = {
        parameterNames = {
          enabled = "all",
        },
      },
      format = {
        enabled = false,
      },
    },
  },

  init_options = {
    bundles = (function()
      local bundles = {
        vim.fn.glob(
          home
            .. "/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
        ),
      }
      vim.list_extend(bundles, vim.split(vim.fn.glob(spring_boot_jars_pattern), "\n"))
      return bundles
    end)(),
  },
}

require("jdtls").start_or_attach(config)
