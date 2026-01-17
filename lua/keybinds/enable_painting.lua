_G.VIT_Events_BLT = _G.VIT_Events_BLT or {}
local M = _G.VIT_Events_BLT

if not M.trigger_ordered then
    dofile(ModPath .. "lua/vit_events.lua")
    M = _G.VIT_Events_BLT
end

if not (M and M.trigger_ordered) then
    return
end

M.trigger_ordered("enable_painting", "Enable painting", {
    seq_painting_glow = true,
    enable_painting_interaction = true
})
