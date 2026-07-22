hl.bind("CTRL+SUPER+ALT+KP_DIVIDE", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"),
    { description = "Edit user keybinds" })
hl.bind("SUPER + KP_DIVIDE", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Shell: Toggle cheatsheet" })


hl.bind("SUPER + mouse:272",
    hl.dsp.window.float({ action = "toggle" }),
    { release = true, click = true },
    { description = "Window: Float window" }
)
hl.bind("SUPER + mouse:272", hl.dsp.window.resize({ x = 900, y = 700, "exact" }), { release = true, click = true })

hl.bind("XF86Search", hl.dsp.global("quickshell:searchToggle"))

--#/# bind = CTRL+SUPER, ←/→,, -- Focus left/right
for i = 1, 4 do
    local key = { "SUPER + mouse_up", "SUPER + mouse_down" }
    local keycombos = { key[1], key[2], "CTRL + " .. key[1], "CTRL + " .. key[2] }
    hl.unbind(keycombos[i])
end

for i = 1, 4 do
    local key = { "SUPER + mouse_left", "SUPER + mouse_right" }
    local keycombos = { key[1], key[2], "CTRL + " .. key[1], "CTRL + " .. key[2] }
    local prefix = { "+", "-", "r+", "r-" }
    hl.bind(keycombos[i], function()
        hl.dispatch(hl.dsp.focus({ workspace = prefix[i] .. "1" }))
    end)
end

--#/# bind = CTRL+SUPER+SHIFT, ←/→,, -- Focus left/right

for i = 1, 2 do
    local key = { "CTRL + SUPER + SHIFT + " }
    local keycombos = { key[1] .. "mouse_left", key[1] .. "mouse_right" }
    local prefix = { "+", "-" }
    hl.bind(keycombos[i], hl.dsp.window.move({ workspace = prefix[i] .. "1" })) -- # [hidden]
end


-- Zoom

hl.bind("SUPER + KP_Subtract", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/zoom.sh decrease 0.3"))
hl.bind("SUPER + KP_Add", hl.dsp.exec_cmd("~/.config/hypr/hyprland/scripts/zoom.sh increase 0.3"))

-- Center

hl.bind("SUPER + ALT + C", hl.dsp.window.center())
-- hl.bind("SUPER + ALT + C", hl.dsp.window.resize({ x = 900, y = 700, "exact" }))
-- TODO: Game workspace


