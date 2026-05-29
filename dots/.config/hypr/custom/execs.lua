hl.on("hyprland.start", function()
    -- Solaar
    hl.exec_cmd("solaar -w hide")

    -- Plugins
    hl.exec_cmd("hyprpm reload")
end)
