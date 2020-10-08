if __game_mode ~= __lib_type_campaign then
    -- camp only!
    return
end

local headtaking = {
    heads = nil,


    chance = 20,
    queek_subtype = "wh2_main_skv_queek_headtaker",
    faction_key = "wh2_main_skv_clan_mors",

    -- table matching subcultures to their head reward
    valid_heads = {
        wh_main_sc_chs_chaos = "generic_head_chaos",
        wh_main_sc_dwf_dwarfs = "generic_head_dwarf",
        wh_main_sc_emp_empire = "generic_head_empire",
        wh_main_sc_grn_greenskins = "generic_head_greenskins",
        wh_main_sc_nor_norsca = "generic_head_norsca",
        wh_main_sc_vmp_vampire_counts = "generic_head_vampire_counts",
        wh_dlc03_sc_bst_beastmen = "generic_head_beastmen",
        wh2_main_sc_lzd_lizardmen = "generic_head_lizardmen",
        wh2_main_sc_hef_high_elves = "generic_head_high_elf",
        wh2_main_sc_def_dark_elves = "generic_head_dark_elf",
        wh2_dlc11_sc_cst_vampire_coast = "generic_head_vampire_coast",
        wh_dlc05_sc_wef_wood_elves = "generic_head_wood_elves",
        wh_main_sc_brt_bretonnia = "generic_head_bretonnia",
        wh2_main_sc_skv_skaven = "generic_head_skaven",
        wh2_dlc09_sc_tmb_tomb_kings = "generic_head_tomb_kings",

        -- doubles
        --[[
            wh_main_sc_grn_savage_orcs = "generic_head_greenskins",
            wh_main_sc_ksl_kislev = "generic_head_empire",
            wh_main_sc_teb_teb = "generic_head_empire",
        ]]
    },

    special_heads = {
        dlc06_dwf_belegar = "legendary_head_belegar",
        dlc06_grn_skarsnik = "legendary_head_skarsnik",
    },
}

-- straight up stolen from wh2_campaign_traits.lua, prevent LL's from being killed unless they're Skarsnik or Belegar
local excluded_legendary_lords = {
	["emp_karl_franz"] =						true, 					-- Karl Franz
	["emp_balthasar_gelt"] =					true,				-- Balthasar Gelt
	["dlc04_emp_volkmar"] =						true, 			-- Volkmar the Grim
	["dwf_thorgrim_grudgebearer"] =				true, 		-- Thorgrim Grudgebearer
	["dwf_ungrim_ironfist"] =					true, 				-- Ungrim Ironfist
	["pro01_dwf_grombrindal"] = 				true, 					-- Grombrindal
	--["dlc06_dwf_belegar"] =						"wh2_main_trait_defeated_belegar_ironhammer", 			-- Belegar Ironhammer
	["dlc05_wef_orion"] =						true, 						-- Orion
	["dlc05_wef_durthu"] =						true, 						-- Durthu
	["grn_grimgor_ironhide"] =					true, 			-- Grimgor Ironhide
	["grn_azhag_the_slaughterer"] =				true, 		-- Azhag the Slaughterer
	--["dlc06_grn_skarsnik"] =					"wh2_main_trait_defeated_skarsnik", 					-- Skarsnik
	["dlc06_grn_wurrzag_da_great_prophet"] =	true, 						-- Wurrzag
	["vmp_mannfred_von_carstein"] =				true, 		-- Mannfred von Carstein
	["vmp_heinrich_kemmler"] =					true, 			-- Heinrich Kemmler
	["dlc04_vmp_vlad_con_carstein"] =			true, 			-- Vlad von Carstein
	["dlc04_vmp_helman_ghorst"] =				true, 				-- Helman Ghorst
	["pro02_vmp_isabella_von_carstein"] =		true, 		-- Isabella von Carstein
	["chs_archaon"] =							true, 		-- Archaon the Everchosen
	["chs_kholek_suneater"] =					true, 				-- Kholek Suneater
	["chs_prince_sigvald"] =					true, 				-- Prince Sigvald
	["dlc03_bst_khazrak"] =						true, 				-- Khazrak One-Eye
	["dlc03_bst_malagor"] =						true, 		-- Malagor the Dark Omen
	["dlc05_bst_morghur"] =						true, 		-- Morghur the Shadowgave
	["brt_louen_leoncouer"] =					true, 				-- Louen Leoncouer
	["dlc07_brt_fay_enchantress"] =				true, 				-- Fay Enchantress
	["dlc07_brt_alberic"] =						true, 		-- Alberic de Bordeleaux
	["wh_dlc08_nor_wulfrik"] =					true,						-- Wulfrik the Wanderer
	["wh_dlc08_nor_throgg"] =					true,						-- Throgg
	["wh2_main_hef_tyrion"] =					true, 						-- Tyrion
	["wh2_main_hef_teclis"] =					true, 						-- Teclis
	["wh2_main_lzd_lord_mazdamundi"] =			true, 				-- Lord Mazdamundi
	["wh2_main_lzd_kroq_gar"] =					true, 					-- Kroq-Gar
	["wh2_main_def_malekith"] =					true, 					-- Malekith
	["wh2_main_def_morathi"] =					true, 						-- Morathi
	["wh2_main_skv_queek_headtaker"] =			true, 				-- Queen Headtaker
	["wh2_main_skv_lord_skrolk"] =				true, 					-- Lord Skrolk
	["wh2_dlc09_skv_tretch_craventail"] =		true,						-- Tretch Craventail
	["wh2_dlc09_tmb_settra"] =					true,						-- Settra the Imperishable
	["wh2_dlc09_tmb_arkhan"] =					true,						-- Arkhan the Black
	["wh2_dlc09_tmb_khalida"] =					true,						-- High Queen Khalida
	["wh2_dlc09_tmb_khatep"] =					true,						-- Grand Hierophant Khatep
	["wh2_dlc10_hef_alarielle"] =				true,					-- Alarielle the Radiant
	["wh2_dlc10_hef_alith_anar"] =				true,					-- Alith Anar
	["wh2_dlc10_def_crone_hellebron"] =			true,					-- Crone Hellebron
	["wh2_dlc11_cst_harkon"] =					true,				-- Luthor Harkon
	["wh2_dlc11_cst_noctilus"] =				true,				-- Count Noctilus
	["wh2_dlc11_cst_aranessa"] =				true,			-- Aranessa Saltspite
	["wh2_dlc11_cst_cylostra"] =				true,			-- Cylostra Direfin
	["wh2_dlc11_def_lokhir"] =					true,			-- Lokhir Fellheart
	["wh2_dlc12_lzd_tehenhauin"] =				true,					-- Tehenhauin
	["wh2_dlc12_skv_ikit_claw"] =				true,					-- Ikit Claw
	["wh2_dlc12_lzd_tiktaqto"] =				true,					-- Tiktaq'to
	["wh2_dlc13_emp_cha_markus_wulfhart_0"] = 	true,					-- Markus Wulfhart
	["wh2_dlc13_lzd_nakai"] = 					true,						-- Nakai
	["wh2_dlc13_lzd_gor_rok"] = 				true,						-- Gor-Rok
	["wh2_dlc14_brt_repanse"] = 				true,						-- Repanse de Lyonese
	["wh2_dlc14_def_malus_darkblade"] =			true,						-- Malus Darkblade
	["wh2_dlc14_skv_deathmaster_snikch"] =		true,						-- Deathmaster Snikch
	["wh2_pro08_neu_gotrek"] =					true,						-- Gotrek
	["wh2_dlc15_hef_imrik"] = 					true,						-- Imrik
	["wh2_dlc15_hef_eltharion"] = 				true,					-- Eltharion the Grim
	["wh2_dlc15_grn_grom_the_paunch"] = 		true							-- Grom the Paunch
};

local queek_subtype = "wh2_main_skv_queek_headtaker"

function headtaking:add_head(character_obj, queek_obj)
    local faction_obj = cm:get_faction(self.faction_key)
    local head_key = ""

    local subtype_key = character_obj:character_subtype_key()
    local subculture_key = character_obj:faction():subculture()

    -- check if it was a special head first
    if self.special_heads[subtype_key] ~= nil then
        -- TODO disabling for now, no legendary heads!
        --head_key = special_heads[subtype_key]
        return false
    else
        head_key = self.valid_heads[subculture_key]
    end

    -- no head found for this subculture
    if head_key == "" then
        return false
    end

    --ModLog("adding head with key ["..head_key.."]")

    local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)

    -- we already have this head, add it to the heads table
    if faction_cooking_info:is_ingredient_unlocked(head_key) then
        self.heads[head_key] = self.heads[head_key] + 1
        return false
    end

    cm:unlock_cooking_ingredient(faction_obj, head_key)

    -- set the num of heads for this head type to 1
    self.heads[head_key] = 1
    
    if faction_obj:is_human() then
        local loc_prefix = "event_feed_strings_text_yummy_head_unlocked_"
        cm:show_message_event_located(
            self.faction_key,
            loc_prefix.."title",
            loc_prefix.."primary_detail",
            loc_prefix.."secondary_detail",
            queek_obj:logical_position_x(),
            queek_obj:logical_position_y(),
            true,
            666
        )
    end
end

-- TODO enable disable
function headtaking:loyalty_listeners(disable)
    if disable then
        core:remove_listener("queek_loyalty_stuff")
        cm:set_saved_value("yummy_heads_loyalty_increase", false)
        cm:set_saved_value("yummy_heads_loyalty_decrease", false)
    end

    local increase = cm:get_saved_value("yummy_heads_loyalty_increase")
    local decrease = cm:get_saved_value("yummy_heads_loyalty_decrease")

    if not increase and not decrease then
        return
    end

    core:add_listener(
        "queek_loyalty_stuff",
        "CharacterTurnStart",
        function(context)
            return context:character():faction():name() == self.faction_key
        end,
        function(context)
            local char_str = "character_cqi:"..tostring(context:character():command_queue_index())
            if increase then
                local rand = cm:random_number(2, 0)
                cm:modify_character_personal_loyalty_factor(char_str, rand)
            end

            if decrease then
                local rand = (cm:random_number(2, 0) *-1)
                cm:modify_character_personal_loyalty_factor(char_str, rand)
            end
        end,
        true
    )
end

-- initialize the mod stuff!
function headtaking:init()
    local faction_obj = cm:get_faction(self.faction_key)

    if not faction_obj or faction_obj:is_null_interface() then
        -- Queek unfound, returning false
        return false
    end

    -- set up the self.heads table - it tracks the number of heads available, or if a head is locked
    if cm:is_new_game() or self.heads == nil then
        local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)
        for _, key in pairs(self.valid_heads) do
            if faction_cooking_info:is_ingredient_unlocked(key) then
                self.heads[key] = 1
            else
                self.heads[key] = "locked"
            end
        end
    end

    -- first thing's first, enable using 4 ingredients for a recipe for queeky
    -- TODO temp disabled secondaries until the unlock mechanic is introduced
    --
    cm:set_faction_max_primary_cooking_ingredients(faction_obj, 2)
    cm:set_faction_max_secondary_cooking_ingredients(faction_obj, 0)

    --loyalty_listeners()

    -- next up, enable some 'eads to be gitted through battles
    core:add_listener(
        "queek_killed_someone",
        "CharacterConvalescedOrKilled",
        function(context)
            local character = context:character()
            --ModLog("char convalesced or killed'd")

            return character:is_null_interface() == false and character:character_type("general") and character:has_military_force() and not character:military_force():is_armed_citizenry() and cm:pending_battle_cache_char_is_involved(cm:get_faction(self.faction_key):faction_leader()) and character:faction():name() ~= self.faction_key and not character:faction():is_quest_battle_faction()
        end,
        function(context)
            --ModLog("queek killed someone")
            local killed_character = context:character()
            local queek_faction = cm:get_faction(self.faction_key)
            if not queek_faction or queek_faction:is_null_interface() then
                return false
            end

            --ModLog("queek involved")

            local queek = queek_faction:faction_leader()
            --local pb = cm:model():pending_battle()

            --ModLog("add head")

            local rand = cm:random_number(100, 1)

            if rand <= self.chance then
                self:add_head(killed_character, queek)
            end
            --ModLog("head added")

            -- check what side peeps were on
            --[[if cm:pending_battle_cache_char_is_attacker(queek) then
                -- Queek attacked

            elseif cm:pending_battle_cache_char_is_defender(queek) then
                -- Queek defended
            end]]
            
        end,
        true
    )
    
    local scripted_dishes = {

    }

    local function skaven_loyalty_decrease()
        cm:set_saved_value("yummy_head_loyalty_decrease", true)

        self:loyalty_listeners()
    end

    local function skaven_loyalty_increase()
        cm:set_saved_value("yummy_head_loyalty_increase", true)

        self:loyalty_listeners()
    end

    local scripted_ingredients = {
        --["generic_head_skaven"] = skaven_loyalty_decrease
    }

    --[[local function teleport_dwarf()
        local faction_obj = cm:get_faction(faction_key)
        if faction_obj:is_human() then
            core:add_listener(
                "yummy_head_dwarf",
                ""
            )

        end
    end]]

    --[[local function tunneling()
        core:add_listener(
            "greenskins_tunneling",
            ""
        )
    end]]

    local scripted_effects = {
        --yummy_heads_empire_underempire = underempire,
        --yummy_heads_greenskins_tunnel = tunneling,
        --yummy_heads_dwarf_teleport = teleport_dwarf,
        --yummy_heads_angry_rats = skaven_loyalty_decrease,
        --yummy_heads_happy_rats = skaven_loyalty_increase
    }

    -- scripted effects from cooked dishes!
    core:add_listener(
        "queek_scripted_heads",
        "FactionCookedDish",
        function(context)
            return context:faction():name() == self.faction_key
        end,
        function(context)
            local cooked_dish = context:dish()
            local ingredients = cooked_dish:ingredients()
            local faction_effects = cooked_dish:faction_effects()

            -- subtract each ingredient used by 1 in the heads table
            for i = 1, #ingredients do
                local ingredient_key = ingredients[i]
                self.heads[ingredient_key] = self.heads[ingredient_key] -1
                --out("Ingredient used: "..ingredients[i])
            end

            if not faction_effects:is_empty() then
                for i = 0, faction_effects:num_items() -1 do
                    local effect = faction_effects:item_at(i)
                    local key = effect:key()
                    local func = scripted_effects[key]

                    -- check if there's a function attached to this effect key
                    if func ~= nil and is_function(func) then
                        func()
                    end
                end
            end

            local leader_effects = cooked_dish:faction_leader_effects()
            if not leader_effects:is_empty() then
                for i = 0, leader_effects:num_items() -1 do
                    local effect = leader_effects:item_at(i)
                    local key = effect:key()
                    local func = scripted_effects[key]

                    -- check if there's a function attached to this effect key
                    if func ~= nil and is_function(func) then
                        func()
                    end
                end
            end
        end,
        true
    )
end

core:add_static_object("headtaking", headtaking)

cm:add_first_tick_callback(function() headtaking:init() end)

cm:add_loading_game_callback(
    function(context)
        headtaking.heads = cm:load_named_value("headtaking_heads", {}, context)
    end
)

cm:add_saving_game_callback(
    function(context)
        cm:save_named_value("headtaking_heads", headtaking.heads, context)
    end
)