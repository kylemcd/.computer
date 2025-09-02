-- import mason plugin safely
local mason_status, mason = pcall(require, "mason")
if not mason_status then
	return
end

-- import mason-lspconfig plugin safely
local mason_lspconfig_status, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mason_lspconfig_status then
	return
end

-- mason setup
mason.setup()

local servers = {
  "ts_ls",
  "html",
  "cssls",
  "tailwindcss",
  "lua_ls",
  "emmet_ls",
}

mason_lspconfig.setup({
  automatic_installation = false,
})

local function setup_server(server_name)
  -- Back-compat alias: tsserver -> ts_ls
  if server_name == "tsserver" then
    server_name = "ts_ls"
  end
  local ok_lspconfig, lspconfig = pcall(require, "lspconfig")
  if not ok_lspconfig then return end
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok_cmp, cmp_caps = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then
    capabilities = cmp_caps.default_capabilities(capabilities)
  end
  lspconfig[server_name].setup({
    capabilities = capabilities,
  })
end

if type(mason_lspconfig.setup_handlers) == "function" then
  mason_lspconfig.setup_handlers({ setup_server })
else
  for _, server in ipairs(servers) do
    setup_server(server)
  end
end
