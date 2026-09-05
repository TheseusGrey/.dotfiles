-- █▄░█ █░█ █ █▀▄ █ ▄▀█
-- █░▀█ ▀▄▀ █ █▄▀ █ █▀█

-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("__GL_VRR_ALLOWED", "1")
hl.env("WLR_DRM_NO_ATOMIC", "1")
hl.env("AQ_DRM_DEVICES", "/dev/dri/card1:/dev/dri/card0")

hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})
