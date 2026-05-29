-- hl.window_rule({ match = { focus = false, class = "negative:kitty" }, opacity = "0.8" })

-- Blener File browser
hl.window_rule({ match = { initial_title = "File Browser" }, size = { "(monitor_w*0.75)", "(monitor_h*0.75)" }, center = true })
hl.window_rule({
    match = { initial_title = "WolframNB", initial_class = "wolfram-Wolfram14" },
    float = true,
    border_size = 0,
    tag =
    "+hyprglass_disabled",
    no_shadow = true,
    size = { "(window_w*0.5)", "(window_w*0.5)" }
})
hl.window_rule({
    match = { class = "wolfram-Wolfram14" },

})
