-- construct — parte de Hyprland del shell. duran la enlaza en ~/.config/hypr/shell.lua
-- al hacer `duran switch construct`. theme = colores y ajustes que lee scheme/active.lua.

-- Paneles del shell sin animación de Hyprland (el shell los anima)
hl.layer_rule({ match = { namespace = "construct-.*" }, no_anim = true })

local theme = {
    accent   = "39ff88",  -- fósforo (borde ventana activa)
    accent2  = "19e6f0",  -- cian
    accent3  = "ff2e88",  -- magenta (urgente)
    onAccent = "020403",  -- texto sobre acento
    inactive = "0b1a12",  -- borde ventana inactiva
    outline  = "1f5c3a",  -- acento atenuado
    bg       = "020403",
    gapsIn = 6, gapsOut = 12,
    animations = true,
    blur = false,         -- paneles opacos tipo CRT
    vrr = 0,
}

-- Modo juego (lo escribe construct): sin huecos ni efectos, VRR a pantalla completa
local f = io.open(os.getenv("HOME") .. "/.local/state/construct/game", "r")
if f then
    if f:read("l") == "1" then
        theme.gapsIn, theme.gapsOut = 0, 0
        theme.animations = false
        theme.blur = false
        theme.vrr = 2
    end
    f:close()
end

return { theme = theme }