-- this file defines all the valid head types and links them to the resulting subculture or agent subtypes

return {
    -- Beasts
    ["generic_head_beastmen"] = {
        subculture = "wh_dlc03_sc_bst_beastmen",
        group = "beasts",
    },
    ["generic_head_troll_hag"] = {
        subculture = {"wh_main_sc_grn_greenskins", "wh_main_sc_grn_savage_orcs"},
        group = "beasts",
    },
    ["generic_head_lizardmen"] = {
        subculture = "wh2_main_sc_lzd_lizardmen",
        group = "beasts",
    },
    ["generic_head_skink"] = {
        subculture = "wh2_main_sc_lzd_lizardmen",
        group = "beasts",
    },

    -- Chaos
    ["generic_head_chaos"] = {
        subculture = "wh_main_sc_chs_chaos",
        group = "chaos",
    },
    
    ["generic_head_norsca"] = {
        subculture = "wh_main_sc_nor_norsca",
        group = "chaos",
    },

    -- Elves
    ["generic_head_dark_elf"] = {
        subculture = "wh2_main_sc_def_dark_elves",
        group = "elves",
    },
    ["generic_head_high_elf"] = {
        subculture = "wh2_main_sc_hef_high_elves",
        group = "elves",
    },
    ["generic_head_wood_elf"] = {
        subculture = "wh_dlc05_sc_wef_wood_elves",
        group = "elves",
    },

    -- Human
    ["generic_head_empire"] = {
        subculture = "wh_main_sc_emp_empire",
        group = "human",
    },
    ["generic_head_bretonnia"] = {
        subculture = "wh_main_sc_brt_bretonnia",
        group = "human",
    },
    ["generic_head_damsel"] = {
        subculture = "wh_main_sc_brt_bretonnia",
        group = "human",
    },

    -- Undead
    ["generic_head_vampire_coast"] = {
        subculture = "wh2_dlc11_sc_cst_vampire_coast",
        group = "undead",
    },
    ["generic_head_vampire"] = {
        subculture = "wh_main_sc_vmp_vampire_counts",
        group = "undead",
    },
    ["generic_head_necromancer"] = {
        subculture = "wh_main_sc_vmp_vampire_counts",
        group = "undead",
    },
    ["generic_head_strigoi"] = {
        subculture = "wh_main_sc_vmp_vampire_counts",
        group = "undead",
    },
    ["generic_head_tomb_kings"] = {
        subculture = "wh2_dlc09_sc_tmb_tomb_kings",
        group = "undead",
    },

    -- Underlings
    ["generic_head_greenskins"] = {
        subculture = {"wh_main_sc_grn_greenskins", "wh_main_sc_grn_savage_orcs"},
        group = "underlings",
    },
    ["generic_head_goblin"] = {
        subculture = {"wh_main_sc_grn_greenskins", "wh_main_sc_grn_savage_orcs"},
        group = "underlings",
    },
    ["generic_head_dwarf"] = {
        subculture = "wh_main_sc_dwf_dwarfs",
        group = "underlings",
    },
    ["generic_head_dwarf_beard"] = {
        subculture = "wh_main_sc_dwf_dwarfs",
        group = "underlings",
    },
    ["generic_head_skaven"] = {
        subculture = "wh2_main_sc_skv_skaven",
        group = "underlings",
    },
    ["generic_head_skaven_rat"] = {
        subculture = "wh2_main_sc_skv_skaven",
        group = "underlings",
    },
}