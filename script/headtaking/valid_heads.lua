-- this file defines all the valid head types and links them to the resulting subculture or agent subtypes

return {
    ["generic_head_greenskins"] = {
        subculture = {"wh_main_sc_grn_greenskins", "wh_main_sc_grn_savage_orcs"},
    },
    ["generic_head_troll_hag"] = {
        -- subculture = {"wh_main_sc_grn_greenskins", "wh_main_sc_grn_savage_orcs"},
        subtype = "wh2_dlc15_grn_river_troll_hag",
    },
    ["generic_head_goblin"] = {
        -- subculture = {"wh_main_sc_grn_greenskins", "wh_main_sc_grn_savage_orcs"},
        subtype = {"dlc06_grn_night_goblin_warboss", "grn_goblin_big_boss", "grn_goblin_great_shaman", "grn_night_goblin_shaman", "wh2_dlc15_grn_goblin_great_shaman_raknik"},
    },


    ["generic_head_lizardmen"] = {
        subculture = "wh2_main_sc_lzd_lizardmen",
    },
    ["generic_head_skink"] = { -- why are there so many fucking skinks
        -- subculture = "wh2_main_sc_lzd_lizardmen",
        subtype = {"wh2_main_lzd_skink_chief", "wh2_main_lzd_skink_priest_beasts", "wh2_main_lzd_skink_priest_heavens", "wh2_dlc13_lzd_skink_chief_horde", "wh2_dlc13_lzd_red_crested_skink_chief_horde", "wh2_dlc12_lzd_tlaqua_skink_priest_heavens", "wh2_dlc12_lzd_tlaqua_skink_priest_beasts", "wh2_dlc12_lzd_tlaqua_skink_chief", "wh2_dlc12_lzd_red_crested_skink_chief_legendary", "wh2_dlc12_lzd_red_crested_skink_chief"},
    },


    ["generic_head_beastmen"] = {
        subculture = "wh_dlc03_sc_bst_beastmen",
    },

    ["generic_head_chaos"] = {
        subculture = "wh_main_sc_chs_chaos",
    },
    
    ["generic_head_norsca"] = {
        subculture = "wh_main_sc_nor_norsca",
    },

    ["generic_head_dark_elf"] = {
        subculture = "wh2_main_sc_def_dark_elves",
    },

    ["generic_head_high_elf"] = {
        subculture = "wh2_main_sc_hef_high_elves",
    },

    ["generic_head_wood_elf"] = {
        subculture = "wh_dlc05_sc_wef_wood_elves",
    },

    ["generic_head_empire"] = {
        subculture = "wh_main_sc_emp_empire",
    },

    ["generic_head_bretonnia"] = {
        subculture = "wh_main_sc_brt_bretonnia",
    },
    ["generic_head_damsel"] = {
        -- subculture = "wh_main_sc_brt_bretonnia",
        subtype = {"brt_damsel", "brt_damsel_beasts", "brt_damsel_life"},
    },

    ["generic_head_dwarf"] = {
        subculture = "wh_main_sc_dwf_dwarfs",
    },
    ["generic_head_dwarf_beard"] = {
        subculture = "wh_main_sc_dwf_dwarfs",
    },

    ["generic_head_skaven"] = {
        subculture = "wh2_main_sc_skv_skaven",
    },
    ["generic_head_skaven_rat"] = {
        subculture = "wh2_main_sc_skv_skaven",
    },

    ["generic_head_vampire_coast"] = {
        subculture = "wh2_dlc11_sc_cst_vampire_coast",
    },

    ["generic_head_vampire"] = {
        subculture = "wh_main_sc_vmp_vampire_counts",
    },
    ["generic_head_necromancer"] = {
        -- subculture = "wh_main_sc_vmp_vampire_counts",
        subtype = {"vmp_necromancer", "vmp_master_necromancer"}
    },
    ["generic_head_strigoi"] = {
        -- subculture = "wh_main_sc_vmp_vampire_counts",
        subtype = {"dlc04_vmp_strigoi_ghoul_king", "wh2_dlc11_vmp_bloodline_strigoi"}
    },

    ["generic_head_tomb_kings"] = {
        subculture = "wh2_dlc09_sc_tmb_tomb_kings",
    },
}