return {
    legendary_head_belegar = {
        faction_key = "wh_main_dwf_karak_izor",
        subtype_key = "dlc06_dwf_belegar",
        prerequisite = {
            name = "BelegarUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {
            {   -- Auto-Generated
                key = "GENERATED",
            },
            {   -- Auto_Generated
                key = "GENERATED",
            },
            {   -- Auto-Generated
                key = "GENERATED",
            },
            {
                --cm:set_scripted_mission_position
                key = "legendary_head_belegar_encounter",
                objective = "SCRIPTED",
                condition = {"script_key legendary_head_belegar_encounter", "override_text legendary_head_belegar_encounter"},
                payload = "money 5000", -- TODO effect bundle or summat

                -- listen for the interactible marker being touched by Queek only, and then spawn the army & attack
                listener = [[ 
                    function(headtaking, head_key)
                        -- local head_obj = headtaking.legendary_heads[head_key]
                        -- local faction_key = head_obj.faction_key
    
                        -- if not type(faction_key) == "string" then
                        --     -- errmsg!
                        --     return nil
                        -- end
    
                        return {
                            name = "legendary_head_belegar_encounter",
                            event_name = "AreaEntered",
                            conditional = function(context)
                                local area_key = context:area_key()
                                local character = context:character()

                                -- if it's the right area and it's Queek walking in ...
                                return area_key == "legendary_head_belegar_encounter" and character:character_subtype(headtaking.queek_subtype)
                            end,
                            callback = function(context)
                                -- spawn the army, have them attack the player
                                local headtaking = core:get_static_object("headtaking")
                                local mission_info = headtaking.legendary_mission_info[head_key]
    
                                mission_info.tracker = mission_info.tracker + 1
    
                                if mission_info.tracker == 3 then
                                    cm:complete_scripted_mission_objective("legendary_head_2_trophy", "legendary_head_2_trophy", true)
                                    -- core:remove_listener("legendary_head_2_occupy") TODO, figure out unique keys for the listeners so they can be propa removed
                                end
                            end,
                        }
                    end
                ]],
                -- TOOD ^^^^^^ have two listeners for one mission?
                start_func = [[
                    function(headtaking, head_key)
                        -- grab the x/y position
                        local x,y = 1,1

                        -- spawn the interactive marker on the world
                        cm:add_interactable_campaign_marker(
                            "legendary_head_belegar_encounter",
                            "legendary_head_belegar_encounter",
                            x,
                            y,
                            8,
                            "wh2_main_skv_clan_mors", -- only Mors can interact with this marker
                            ""
                        )  

                        -- set the mission location (for zoom-to stuff)
                        cm:set_scripted_mission_position("legendary_head_belegar_encounter", "legendary_head_belegar_encounter", x, y)
                    end
                ]],
                end_func = [[
                    function(headtaking, head_key)
                        -- remove the marker from the map
                        cm:remove_interactable_campaign_marker("legendary_head_belegar_encounter")
                    end
                ]],
                constructor = nil,
            },
        },
    },
    legendary_head_skarsnik = {
        faction_key = "wh_main_grn_crooked_moon",
        subtype_key = "dlc06_grn_skarsnik",
        prerequisite = {
            name = "SkarsnikUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {
            {   -- Auto-Generated
                key = "GENERATED",
            },
            {   -- Auto-Generated
                key = "GENERATED",
            },
            {   -- Auto-Generated
                key = "GENERATED",
            },
            {

            },
        },
    },
    legendary_head_tretch = {
        faction_key = "wh2_dlc09_skv_clan_rictus",
        subtype_key = "wh2_dlc09_skv_tretch_craventail",
        prerequisite = {
            name = "TretchUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {
            {   -- Auto-Generated
                key = "GENERATED",
            },
            {   -- Auto-Generated
                key = "GENERATED",
            },
            {   -- Auto-Generated
                key = "GENERATED",
            },
            {

            },
        },
    },
    legendary_head_squeak = {
        faction_key = nil,
        prerequisite = {
            name = "SqueakUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 5 end,
        }
    },
}