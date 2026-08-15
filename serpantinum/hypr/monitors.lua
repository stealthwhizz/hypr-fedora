-- Original was hardcoded to the author's own laptop panel (eDP-1 @144Hz).
-- Adapted to your actual hardware/refresh rates while keeping the same explicit-per-monitor approach.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.0 })
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1.0 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })
