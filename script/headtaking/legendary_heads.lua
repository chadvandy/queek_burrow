return {
    legendary_head_belegar = {
        faction_key = "wh_main_dwf_karak_izor",
        backup_faction_key = "wh_main_dwf_dwarfs_qb1",
        subtype_key = "dlc06_dwf_belegar",
        forename_key = "names_name_2147358029",
        surname_key = "names_name_2147358036",
        eb_key = "",
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
                key = "legendary_head_belegar_encounter",
                objective = "SCRIPTED",
                condition = {"script_key legendary_head_belegar_encounter", "override_text mission_text_text_legendary_head_belegar_encounter"},
                payload = "money 5000",
            },
        },
    },
    legendary_head_skarsnik = {
        faction_key = "wh_main_grn_crooked_moon",
        backup_faction_key = "wh_main_grn_greenskins_qb1",
        subtype_key = "dlc06_grn_skarsnik",
        forename_key = "names_name_2147358016",
        surname_key = "names_name_2147358924",
        eb_key = "",
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
                key = "legendary_head_skarsnik_encounter",
                objective = "SCRIPTED",
                condition = {"script_key legendary_head_skarsnik_encounter", "override_text mission_text_text_legendary_head_skarsnik_encounter"},
                payload = "money 5000",
            },
        },
    },
    legendary_head_tretch = {
        faction_key = "wh2_dlc09_skv_clan_rictus",
        backup_faction_key = "wh2_main_skv_skaven_qb1",
        subtype_key = "wh2_dlc09_skv_tretch_craventail",
        forename_key = "names_name_421856293",
        surname_key = "names_name_1843290975",
        eb_key = "",
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
                key = "legendary_head_tretch_encounter",
                objective = "SCRIPTED",
                condition = {"script_key legendary_head_tretch_encounter", "override_text mission_text_text_legendary_head_tretch_encounter"},
                payload = "money 5000",
            },
        },
    },
    -- TODO temp disabled
    -- legendary_head_squeak = {
    --     faction_key = nil,
    --     backup_faction_key = "wh2_main_skv_skaven_qb1",
    --     prerequisite = {
    --         name = "SqueakUnlocked",
    --         event_name = "HeadtakingSqueakUpgrade",
    --         conditional = function(context) return context:stage() == 5 end,
    --     }
    -- },
}