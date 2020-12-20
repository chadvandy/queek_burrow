-- local headtaking = core:get_static_object("headtaking")
-- local faction_key = headtaking.faction_key

return {
    {   -- capture or destroy targeted settlement
        key = "squeak_1a",
        constructor = function(headtaking, mission)
            local faction_obj = cm:get_faction(headtaking.faction_key)

            local valid_regions = {}

            local queek = faction_obj:faction_leader()
            if queek:has_region() then
                local region = queek:region()
                local adjacent_regions = region:adjacent_region_list()

                for i = 0, adjacent_regions:num_items()-1 do
                    local adjacent_region = adjacent_regions:item_at(i)
                    if adjacent_region:is_abandoned() or adjacent_region:owning_faction():name() ~= headtaking.faction_key then
                        valid_regions[#valid_regions+1] = adjacent_region:name()

                        if #valid_regions > 10 then
                            break
                        end
                    end
                end
            end
            
            local factions_at_war = faction_obj:factions_at_war_with()
            for i = 0, factions_at_war:num_items() -1 do
                local faction = factions_at_war:item_at(i)
                local region_list = faction:region_list()
                for j = 0, region_list:num_items() -1 do
                    local region = region_list:item_at(j)

                    valid_regions[#valid_regions+1] = region:name()
                    if #valid_regions > 10 then
                        break
                    end
                end
            end

            local region_key = valid_regions[cm:random_number(#valid_regions)]

            mission.condition = "region "..region_key
            return mission
        end,
        objective = "RAZE_OR_OWN_SETTLEMENTS",
        condition = "",
        payload = "money 1000",
    },
    {   -- kill x number of enemies
        key = "squeak_1b",
        objective = "KILL_X_ENTITIES",
        condition = "total [500]",
        payload = "money 1000",
    },
    {   -- own x number of units
        key = "squeak_1c",
        objective = "OWN_N_UNITS",
        condition = "total [40]",
        payload = "money 1000",
    },
    {   -- capture x number of heads
        key = "squeak_1d",
        objective = "SCRIPTED",
        condition = {"script_key obtain_heads", "override_text obtain_heads"},
        payload = "money 1000",
        start_func = function(headtaking)
            cm:set_saved_value("squeak_1d_num_heads", headtaking.total_heads)
        end,
        -- TODO figure out how to pass this a data table to do stuff like dynamic total heads or whatever
        listener = function()
            core:add_listener(
                "my_listener",
                "HeadtakingCollectedHead",
                function(context)
                    -- you've gotten two heads!
                    return context:headtaking().total_heads >= 2 + cm:get_saved_value("squeak_1d_num_heads")
                end,
                function(context)
                    cm:complete_scripted_mission_objective("squeak_1d", "obtain_heads", true)
                end,
                true
            )
        end,
        
    }

    -- capture nearby settlement
    -- collect X heads
    -- defeat X armies
    -- recruit X units
    -- earn X income
    -- give X money (lose money after mission to pay Squeak)
    -- earn x gold from raidin

    -- stage 4, demand Sword of Khaine
}