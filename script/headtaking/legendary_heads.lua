return {
    legendary_head_belegar = {
        faction_key = "wh_main_dwf_karak_izor",
        backup_faction_key = "wh_main_dwf_dwarfs_qb1",
        subtype_key = "dlc06_dwf_belegar",
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
            },
        },
    },
    legendary_head_skarsnik = {
        faction_key = "wh_main_grn_crooked_moon",
        backup_faction_key = "wh_main_grn_greenskins_qb1",
        subtype_key = "dlc06_grn_skarsnik",
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
            },
        },
    },
    legendary_head_tretch = {
        faction_key = "wh2_dlc09_skv_clan_rictus",
        backup_faction_key = "wh2_main_skv_skaven_qb1",
        subtype_key = "wh2_dlc09_skv_tretch_craventail",
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
            },
        },
    },
    legendary_head_squeak = {
        faction_key = nil,
        backup_faction_key = "wh2_main_skv_skaven_qb1",
        prerequisite = {
            name = "SqueakUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 5 end,
        }
    },
}