return {
    legendary_head_belegar = {
        faction_key = "wh_main_dwf_karak_izor",
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