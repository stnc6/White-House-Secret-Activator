_G.VIT_Events_BLT = _G.VIT_Events_BLT or {}
local M = _G.VIT_Events_BLT

if M._loaded then
    return M
end
M._loaded = true

M.only_level_id = "vit"
M.only_host = true
M.chat_prefix = "[WHSA]"

M._order = {
    enable_painting = 1,
    enable_elevator = 2,
    open_puzzle_vault = 3
}
M._order_names = {
    [1] = "Enable painting",
    [2] = "Enable elevator",
    [3] = "Open puzzle vault"
}

local function in_chat()
    local hud_chat = managers.hud and managers.hud:chat_focus()
    local comp_chat = managers.menu_component
        and managers.menu_component.input_focus_game_chat_gui
        and managers.menu_component:input_focus_game_chat_gui()
end

local function is_host()
    return not Network:is_client()
end

local function notify(msg)
    if managers.chat and managers.chat.feed_system_message then
        managers.chat:feed_system_message(ChatManager.GAME, string.format("%s %s", M.chat_prefix, tostring(msg)))
    end
end

local function get_level_id()
    if managers.job and managers.job.current_level_id then
        return managers.job:current_level_id()
    end
    if Global and Global.level_data and Global.level_data.level_id then
        return Global.level_data.level_id
    end
    return nil
end

local function on_wrong_level()
    notify("Works only on the White House heist.")
end

local function trigger_elements(editor_names)
    if not managers.mission or not managers.mission.scripts then
        return 0
    end

    local player = managers.player and managers.player:player_unit()
    if not alive(player) then
        return 0
    end

    local fired = 0
    for _, script in pairs(managers.mission:scripts()) do
        for __, element in pairs(script:elements()) do
            local en = element and element.editor_name and element:editor_name()
            if en and editor_names[en] then
                fired = fired + 1
                pcall(element.on_executed, element, player)
            end
        end
    end

    return fired
end

local function ensure_state()
    local lvl = get_level_id()
    local scripts_ref = (managers.mission and managers.mission.scripts and managers.mission:scripts()) or nil

    if not M._state
        or M._state.level_id ~= lvl
        or M._state.scripts_ref ~= scripts_ref
    then
        M._state = {
            level_id = lvl,
            scripts_ref = scripts_ref,
            step = 1
        }
    end
end

function M.trigger(action_name, editor_names)
    if in_chat() then return end

    if M.only_level_id and get_level_id() ~= M.only_level_id then
        on_wrong_level()
        return
    end

    if M.only_host and not is_host() then
        notify("You must be a host for the trigger.")
        return
    end

    local fired = trigger_elements(editor_names)
    notify(string.format("%s: triggered.", tostring(action_name), fired))
end

function M.trigger_ordered(action_key, action_name, editor_names)
    if in_chat() then return end

    if M.only_level_id and get_level_id() ~= M.only_level_id then
        on_wrong_level()
        return
    end

    if M.only_host and not is_host() then
        notify("You must be a host for the trigger.")
        return
    end

    ensure_state()

    local required = M._order[action_key] or 1
    local step = M._state.step or 1
	
	if step > 3 then
        notify("All steps done.")
        return
    end

    if required ~= step then
        local next_name = M._order_names[step] or ("step " .. tostring(step))
        notify(string.format(
            "Softlock protection: now you can only %s (step %d/3).",
            tostring(next_name),
            step
        ))
        return
    end

    local fired = trigger_elements(editor_names)
    notify(string.format("%s: triggered.", tostring(action_name), fired))
	
	if fired > 0 then
        M._state.step = step + 1
    end
end

return M