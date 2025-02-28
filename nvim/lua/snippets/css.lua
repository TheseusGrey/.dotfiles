local ls = require("luasnip")
-- some shorthands...
local snippet = ls.snippet
local snip_node = ls.snippet_node
local text = ls.text_node
local insert = ls.insert_node
local func = ls.function_node
local choose = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local conds = require("luasnip.extras.conditions")
local conds_expand = require("luasnip.extras.conditions.expand")

return {
  snippet("layout-column-breakout", {
    text({
      ".column-with-breakouts {",
      "/* Edit/override these properties to customise the layout */",
      "\t--padding-inline: ",
    }),
    insert(1, "1rem"),
    text({ ";", "\t--content-max-width: " }),
    insert(2, "80ch"),
    text({ ";", "\t--popout-max-width: " }),
    insert(3, "90ch"),
    text({ ";", "\t--breakout-max-width: " }),
    insert(4, "120ch"),
    text({ ";", "\t/* Column size calculations */" }),
    text({ "\t--popout-size: calc(", "\t\t(var(--popout-max-width) - var(--content-max-width)) / 2", "\t);" }),
    text({ "\t--breakout-size: calc(", "\t\t(var(--breakout-max-width) - var(--popout-max-width)) / 2", "\t);" }),
    text({
      "",
      "\t/* Adds in some responsiveness */",
      "\t--full: minmax(var(--padding-inline), 1fr);",
      "\t--content: min(var(--content-max-width), 100% - var(--gap) * 2);",
      "\t--popout: minmax(0, var(--breakout-size));",
      "\t--breakout: minmax(0, var(--popout-size));",
    }),
    text({
      "",
      "\t/* Defining the grid layout */",
      "\tdisplay: grid;",
      "\tgrid-template-columns:",
      "\t\t[full-start] var(--full)",
      "\t\t[breakout-start] var(--breakout)",
      "\t\t[popout-start] var(--popout)",
      "\t\t[content-start] var(--content) [content-end]",
      "\t\tvar(--popout) [popout-end]",
      "\t\tvar(--breakout) [breakout-end]",
      "\t\tvar(--full) [full-end];",
      "}",
    }),
    text({
      "",
      ".content > :not(.popoout, .breakout, .full-width),",
      ".full-width > :not(.popout, .breakout, .full-width) {",
      "\tgrid-column: content;",
      "}",
    }),
    text({ ".content > .popout {", "\tgrid-column: popout;", "}" }),
    text({ ".content > .breakout {", "\tgrid-column: breakout;", "}" }),
    text({ ".full-width {", "\tgrid-column: full;", "}" }),
    text({
      "",
      "img.full-width {",
      "\twidth: 100%;",
      "\tmax-height: 45vh;",
      "\tobject-fit: cover;",
      "}",
    }),
  }),

  snippet("layout-column-breakout-overrides", {
    text("\t--padding-inline: "),
    insert(1, "1rem"),
    text({ ";", "\t--content-max-width: " }),
    insert(2, "80ch"),
    text({ ";", "\t--popout-max-width: " }),
    insert(3, "90ch"),
    text({ ";", "\t--breakout-max-width: " }),
    insert(4, "120ch"),
  }),

  snippet("grid-dynamic-columns", {
    text({ "\tdisplay: grid;", "\tgrid-template-columns: repeat(" }),
    choose(1, {
      text("auto-fill"),
      text("auto-fit"),
    }),
    text(", minmax("),
    insert(2, "250px"),
    text(", 1fr));"),
  }),
}
