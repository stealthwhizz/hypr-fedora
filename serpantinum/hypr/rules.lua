-- ───────── Layer rules (OSD / overlays) ─────────
hl.layer_rule({ name = "lr1", match = { namespace = "^(volume_osd)$" },     no_anim = true })
hl.layer_rule({ name = "lr2", match = { namespace = "^(brightness_osd)$" }, no_anim = true })
hl.layer_rule({ name = "lr3", match = { namespace = "hyprpicker" },         no_anim = true })
hl.layer_rule({ name = "lr4", match = { namespace = "qsdock" },             no_anim = true })
hl.layer_rule({
    name         = "lr5",
    match        = { namespace = "ext-session-lock" },
    blur         = true,
    ignore_alpha = 0.2,
})

-- ───────── Window rules ─────────

-- CS2
hl.window_rule({ name = "cs2_immediate",    match = { class = "^(cs2)$" }, immediate = true })
hl.window_rule({ name = "cs2_aspectratio",  match = { class = "^(cs2)$" }, keep_aspect_ratio = true })

-- App Launcher
hl.window_rule({
    name      = "app_launcher",
    match     = { title = "^(app-launcher)$" },
    float     = true,
    center    = true,
    size      = "1200 600",
    animation = "slide",
})
