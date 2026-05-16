hl.bind("CTRL+SUPER+ALT+KP_DIVIDE", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )
hl.bind("SUPER + KP_DIVIDE", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Shell: Toggle cheatsheet" })
hl.bind("SUPER + mouse:272",hl.dsp.window.float({ action = "toggle" }), { description = "Shell: Toggle cheatsheet" })
