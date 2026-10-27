-- construct — parte de Hyprland del shell. duran la enlaza en ~/.config/hypr/shell.lua
-- al hacer `duran switch construct`. theme = colores y ajustes que lee scheme/active.lua.

-- Paneles del shell sin animación de Hyprland (el shell los anima)
hl.layer_rule({ match = { namespace = "construct-.*" }, no_anim = true })

return {
    theme = {
        accent   = "39ff88",  -- fósforo (borde ventana activa)
        accent2  = "19e6f0",  -- cian
        accent3  = "ff2e88",  -- magenta (urgente)
        onAccent = "020403",  -- texto sobre acento
        inactive = "0b1a12",  -- borde ventana inactiva
        outline  = "1f5c3a",  -- acento atenuado
        bg       = "020403",
        gapsIn = 6, gapsOut = 12,
        animations = true,
        blur = false,         -- paneles opacos tipo CRT; el blur rompe la estética
        vrr = 0,
    },
}