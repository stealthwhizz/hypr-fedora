-- Codex desktop "pet" overlay (ChatGPT app). On Hyprland it is an ordinary floating XWayland window,
-- ~1138x2129 and transparent, so the compositor's blur/shadow/rounding/border/opacity made a dark frosted
-- rectangle over the Codex window, and the blur over such a large window is expensive.
-- Strip all decoration, keep it out of focus, pin it to every workspace, and tag it so alttab.sh skips it.
-- Matches ANY floating Codex window, so a manually floated main Codex window loses its styling too.
hl.window_rule({
    name        = "codex-pet-overlay",
    match       = { class = "Chatgpt", float = true },
    tag         = "+codex_pet",
    no_blur     = true,
    no_shadow   = true,
    no_anim     = true,
    no_focus    = true,
    border_size = 0,
    rounding    = 0,
    opacity     = "1.0 override",
    pin         = true,
})
