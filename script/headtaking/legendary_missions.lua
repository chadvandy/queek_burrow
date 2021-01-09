-- these are the predetermined-ish missions for each stage of a legendary head chain
-- some factions will have specified missions at different points in their chain, and they all culminate in a specified end battle with Queek v. the Baddie, but sometimes they can pick from this list which will generate a mission for that faction
-- assumes that the chain will be querying for missions between 1-3, so only those are defined here; 4 is usually the Queek v Baddie stage

return {
    -- first chain missions!
    [1] = {
        {   -- raid their land
            key = "legendary_head_1_raid",
            objective = "SCRIPTED",
            condition = {"script_key legendary_head_1_raid", "override_text legendary_head_1_raid"},
            payload = "money 500",
            listener = function(headtaking, head_key)
                local head_obj = headtaking.legendary_heads[head_key]
                local faction_key = head_obj.faction_key

                if not is_string(faction_key) then
                    -- errmsg!
                    return nil
                end

                return {
                    name = "legendary_head_1_raid",
                    event_name = "CharacterTurnStart",
                    conditional = function(context)
                        local char = context:character()
                        if char:faction():name() == "wh2_main_skv_clan_mors" and char:has_military_force() and char:military_force():active_stance() == "MILITARY_FORCE_ACTIVE_STANCE_TYPE_LAND_RAID" then
                            local region = char:region()
                            if not region:is_null_interface() and not region:is_abandoned() then
                                if region:owning_faction():name() == faction_key then
                                    return true
                                end
                            end
                        end

                        return false
                    end,
                    callback = function(context)
                        cm:complete_scripted_mission_objective("legendary_head_1_raid", "legendary_head_1_raid", true)
                    end,
                }
            end,
            start_func = nil,
            end_func = nil,
            constructor = nil,
        },
        {   -- raze one specified settlement TODO specify
            key = "legendary_head_1_raze",
            objective = "SCRIPTED",
            condition = {"script_key legendary_head_1_raze", "override_text legendary_head_1_raze"},
            payload = "money 500",
            listener = function(headtaking, head_key)
                local head_obj = headtaking.legendary_heads[head_key]
                local faction_key = head_obj.faction_key

                if not is_string(faction_key) then
                    -- errmsg!
                    return nil
                end

                return {
                    name = "legendary_head_1_raze",
                    event_name = "CharacterRazedSettlement",
                    conditional = function(context)
                        local char = context:character()
                        -- local region = context:garrison_residence():region()

                        -- check if Queek faction
                        if char:faction():name() == headtaking.faction_key then
                            -- check if the defenders were the targeted faction
                            local _,_,defending_faction_key = cm:pending_battle_cache_get_defender(1)
                            if defending_faction_key == faction_key then
                                return true
                            end
                        end

                        return false
                    end,
                    callback = function(context)
                        cm:complete_scripted_mission_objective("legendary_head_1_raze", "legendary_head_1_raze", true)
                    end,
                }
            end,
            start_func = nil,
            end_func = nil,
            constructor = nil,
        },
    },
    -- second chain missions!
    [2] = {
        {   -- get a trophy head from this faction
            key = "legendary_head_2_trophy",
            objective = "SCRIPTED",
            condition = {"script_key legendary_head_2_trophy", "override_text legendary_head_2_trophy"},
            payload = "money 2000",
            listener = function(headtaking, head_key)
                local head_obj = headtaking.legendary_heads[head_key]
                local faction_key = head_obj.faction_key

                if not is_string(faction_key) then
                    -- errmsg!
                    return nil
                end
                
                return {
                    name = "legendary_head_2_trophy",
                    event_name = "HeadtakingCollectedHead",
                    conditional = function(context)
                        return context:faction_key() == faction_key
                    end,
                    callback = function(context)
                        cm:complete_scripted_mission_objective("legendary_head_2_trophy", "legendary_head_2_trophy", true)
                    end,
                }
            end,
            start_func = nil,
            end_func = nil,
            constructor = nil,
        },
        {   -- occupy three of their settlements
            key = "legendary_head_2_occupy",
            objective = "SCRIPTED",
            condition = {"script_key legendary_head_2_occupy", "override_text legendary_head_2_occupy"},
            payload = "money 2000",
            listener = function(headtaking, head_key)
                local head_obj = headtaking.legendary_heads[head_key]
                local faction_key = head_obj.faction_key

                if not is_string(faction_key) then
                    -- errmsg!
                    return nil
                end

                return {
                    name = "legendary_head_2_occupy",
                    event_name = "RegionFactionChangeEvent",
                    conditional = function(context)
                        -- see that the targeted faction lost a region + that Queek took it
                        return context:previous_faction():name() == faction_key and not context:region():is_abandoned() and context:region():owning_faction():name() == headtaking.faction_key
                    end,
                    callback = function(context)
                        local headtaking = core:get_static_object("headtaking")
                        local mission_info = headtaking.legendary_mission_info[head_key]

                        mission_info.tracker = mission_info.tracker + 1

                        if mission_info.tracker == 3 then
                            cm:complete_scripted_mission_objective("legendary_head_2_trophy", "legendary_head_2_trophy", true)
                            -- core:remove_listener("legendary_head_2_occupy") TODO, figure out unique keys for the listeners so they can be propa removed
                        end
                    end,
                }
            end,
            start_func = function(headtaking, head_key)
                headtaking.legendary_mission_info[head_key].tracker = 0
            end,
            end_func = function(headtaking, head_key)
                
            end,
            constructor = nil,
        },
        {   -- defeat three armies
            key = "legendary_head_2_fight",
            objective = "DEFEAT_N_ARMIES_OF_FACTION",
            condition = nil,
            payload = "money 2000",
            listener = nil,
            start_func = nil,
            end_func = nil,
            constructor = function(mission, headtaking, head_key)
                local head_obj = headtaking.legendary_heads[head_key]
                local faction_key = head_obj.faction_key

                if not is_string(faction_key) then
                    -- errmsg!
                    return nil
                end

                -- defeat 3 armies of faction "faction_key"
                mission.condition = {
                    "total 3",
                    "faction "..faction_key,
                }

                return mission
            end,
        },
    },
    -- third chain missions!
    [3] = {
        {   -- sack their capital
            key = "legendary_head_3_capital",
            objective = "RAZE_OR_SACK_N_DIFFERENT_SETTLEMENTS_INCLUDING",
            condition = nil,
            payload = "money 5000",
            listener = nil,
            start_func = nil,
            end_func = nil,
            constructor = function(mission, headtaking, head_key)
                local head_obj = headtaking.legendary_heads[head_key]
                local faction_key = head_obj.faction_key

                if not is_string(faction_key) then
                    -- errmsg!
                    return nil
                end

                local faction_obj = cm:get_faction(faction_key)
                local capital = faction_obj:home_region()
                if capital:is_null_interface() then
                    -- what do????
                    return nil
                end

                -- raze capital
                mission.condition = {
                    "total 1",
                    "region "..capital:name(),
                }

                return mission
            end,
        },
    },
}



        -- this was a chain 1, fuck it tho tbh
        -- {   -- perform agent action against these fools
        --     key = "legendary_head_1_action",
        --     objective = "",
        --     condition = "",
        --     payload = "",
        --     listener = {
        --         name = "",
        --         event_name = "",
        --         conditional = function(context)

        --         end,
        --         callback = function(context)

        --         end,
        --     },
        --     start_func = function(mission)

        --     end,
        --     end_func = function(mission)
                
        --     end,
        --     constructor = function(mission)
                
        --     end,
        -- },