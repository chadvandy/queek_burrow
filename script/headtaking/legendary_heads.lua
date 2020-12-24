return {
    legendary_head_belegar = {
        faction_key = "wh_main_dwf_karak_izor",
        prerequisite = {
            name = "BelegarUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {
            {   -- raid Angrund
                key = "legendary_head_belegar_1",
                objective = "SCRIPTED",
                condition = {"script_key legendary_head_belegar_1", "override_text legendary_head_belegar_1"},
                payload = "money 500",
                listener = {
                    name = "bloop",
                    event_name = "CharacterTurnStart",
                    conditional = function(context)
                        local char = context:character()
                        if char:faction():name() == "wh2_main_skv_clan_mors" and char:has_military_force() and char:military_force():active_stance() == "MILITARY_FORCE_ACTIVE_STANCE_TYPE_LAND_RAID" then
                            local region = char:region()
                            if not region:is_null_interface() and not region:is_abandoned() then
                                if region:owning_faction():name() == "wh_main_dwf_karak_izor" then
                                    return true
                                end
                            end
                        end
                        return false
                    end,
                    callback = function(context)
                        cm:complete_scripted_mission_objective("legendary_head_belegar_1", "legendary_head_belegar_1", true)
                    end,
                },
                start_func = nil,
                end_func = nil,
                constructor = nil,
            },
            {   -- defeat 3 armies of Belegar's (or fewer, if there are fewer on the map!)
                key = "legendary_head_belegar_2",
                objective = "SCRIPTED",
                condition = {"script_key legendary_head_belegar_2", "override_text legendary_head_belegar_2"},
                payload = "money 500",
                listener = {
                    name = "legendary_head_belegar_2",
                    event_name = "BattleCompleted",
                    conditional = function(context)
                        local pb = cm:model():pending_battle()
                        if cm:pending_battle_cache_faction_is_involved("wh2_main_skv_clan_mors") and cm:pending_battle_cache_faction_is_involved("wh_main_dwf_karak_izor") then
                            if cm:pending_battle_cache_faction_is_attacker("wh2_main_skv_clan_mors") and string.find(pb:attacker_battle_result(), "victory") then
                                return true
                            end
                        end
                        return false
                    end,
                    callback = function(context)
                        local headtaking = core:get_static_object("headtaking")
                        local mission_info = headtaking.legendary_mission_info["legendary_head_belegar"]

                        mission_info.tracker = (mission_info.tracker and mission_info.tracker + 1) or 1
                        
                        if mission_info.tracker >= 3 then
                            cm:complete_scripted_mission_objective("legendary_head_belegar_2", "legendary_head_belegar_2", true)
                            core:remove_listener("legendary_head_belegar_2")
                        end
                    end,
                    persistence = true,
                },
                start_func = function(mission)
                    local headtaking = core:get_static_object("headtaking")
                    local mission_info = headtaking.legendary_mission_info["legendary_head_belegar"]
                    mission_info.tracker = 0
                end,
                end_func = function(mission)
                    local headtaking = core:get_static_object("headtaking")
                    local mission_info = headtaking.legendary_mission_info["legendary_head_belegar"]
                    mission_info.tracker = 0
                end,
                constructor = nil,
            },
            {
                key = "legendary_head_belegar_3",
                objective = "RAZE_OR_OWN_SETTLEMENTS",
                condition = nil,
                payload = "money 500",
                listener = nil,
                start_func = nil,
                end_func = nil,
                constructor = function(mission)
                    local karak_izor = cm:get_faction("wh_main_dwf_karak_izor")
                    if not karak_izor then
                        -- errmsg, big issue
                        return false
                    end

                    if karak_izor:has_home_region() then
                        mission.condition = "region "..karak_izor:home_region():name()
                    else
                        -- fallback condition????
                        return false
                    end
                   
                    return mission
                end,
            },
            {
                key = "legendary_head_belegar_4",
                objective = "SCRIPTED",
                condition = {"script_key legendary_head_belegar_4", "override_text legendary_head_belegar_4"},
                payload = "money 500",
                listener = nil, -- listen for the interactible marker being touched by Queek only, and then spawn the army & attack
                -- TOOD ^^^^^^ have two listeners for one mission?
                start_func = function(mission)
                    -- spawn the Belegar interactible marker!
                end,
                end_func = nil,
                constructor = nil,
            },
        },
    },
    legendary_head_skarsnik = {
        faction_key = "wh_main_grn_crooked_moon",
        prerequisite = {
            name = "SkarsnikUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {

        },
    },
    legendary_head_tretch = {
        faction_key = "wh2_dlc09_skv_clan_rictus",
        prerequisite = {
            name = "TretchUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {

        },
    },
    legendary_head_squeak = {

        prerequisite = {
            name = "SqueakUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 5 end,
        }
    },
}