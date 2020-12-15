if __game_mode ~= __lib_type_campaign then
    -- camp only!
    return
end

-- TODO get all the UI hooked in here

local headtaking = {
    heads = {},

    -- add to this whenever a new legendary head is crafted
    legendary_heads = {
        "belegar",
        "skarsnik",
        "tretch",
    },

    legendary_heads_max = 0,

    legendary_heads_num = 0,

    chance = 40,
    queek_subtype = "wh2_main_skv_queek_headtaker",
    faction_key = "wh2_main_skv_clan_mors",

    squeak_stage = 0,

    wall_of_skulls = {},

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



function headtaking:add_head_with_key(head_key, details)
    if not is_string(head_key) then
        -- errmsg
        return false
    end

    local faction_obj = cm:get_faction(self.faction_key)
    local queek_obj = faction_obj:faction_leader()

    -- TODO test that it's valid
    local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)

    if not self.heads[head_key] then
        self.heads[head_key] = {
            num_heads = 0,
            history = {},
        }
    end

    -- if we're passing in a "details" table, save it to the table for this head
    if details and is_table(details) then
        self.heads[head_key]["history"][#self.heads[head_key]["history"]+1] = details
    end

    -- we already have this head, add it to the heads table
    if faction_cooking_info:is_ingredient_unlocked(head_key) then
        self.heads[head_key]["num_heads"] = self.heads[head_key]["num_heads"] + 1
        -- return false
    else
        cm:unlock_cooking_ingredient(faction_obj, head_key)

        -- set the num of heads for this head type to 1
        self.heads[head_key]["num_heads"] = 1
    end
    
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

--[[
-- effects:
- 1-2 effects per head, avoid bloat ---- LOL
- make 'em interesting and potentially affect gameplay
- find a way to implement *some* form of bane
--]]

--[[ effect ideas:


-- TODO Greenskin tunnel movement range     - further movement range in tunnels -- TODO this
-- TODO Dwarf teleport army
-- TODO Beastmen make more interesting
-- TODO Bret impose chivalry
-- TODO Chaos make more interesting
-- TODO Dark Elf queek effect
-- TODO Skaveny skaven
-- TODO Empire free underempire \\ spawn witch hunters

- generic_head_skaven
Skaven - happy-frightened rats
    - slightly-randomized happiness effects for a few turns -- TODO this
        - general loyalty can jump up or down as a result
        - PO will vary between +/-5 or so
        - randomized LD effects
        - randomized diplo with other skavenz

    Bane:
    - food drain with angry bois

    - (TODO POTENTIALLY vary with multiple Clan heads!)

Belegar
    -
    -
    -

Skarsnik
    -
    -
    -


]]

function headtaking:add_head(character_obj, queek_obj)
    local faction_obj = cm:get_faction(self.faction_key)
    local head_key = ""

    local subtype_key = character_obj:character_subtype_key()
    local subculture_key = character_obj:faction():subculture()

    local forename = character_obj:get_forename()
    local surname = character_obj:get_surname()
    local flag_path = character_obj:flag_path()
    local faction_key = character_obj:faction():name()
    local level = character_obj:rank()
    local region_key = ""
    if character_obj:has_region() then
        region_key = character_obj:region():name()
    end

    local turn_number = cm:model():turn_number()

    local details = {
        subtype = subtype_key,
        forename = forename,
        surname = surname,
        flag_path = flag_path,
        faction_key = faction_key,
        level = level,
        region_key = region_key,
        turn_number = turn_number,
    }

    -- local str = string.format("Queek killed an enemy of faction %s with name %s %s, with subtype %s. Their flag is %s. Their level was %d. They were located in the region %s, and killed on turn number %d.", faction_key, forename, surname, subtype, flag_path, level, region_key, turn_number)

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

    self:add_head_with_key(head_key, details)
end

-- TODO enable the disable stuff
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

function headtaking:squeak_init()
    local stage = self.squeak_stage

    -- first stage, Squeak is unacquired - guarantee his aquisition the next head taken
    if stage == 0 then

    else

    end
end

-- count & save the number of legendary heads thusfar obtained
function headtaking:init_count_heads()
    local faction_obj = cm:get_faction(self.faction_key)

    -- self.legendary_heads_num = 0

    local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)

    local legendary_heads = self.legendary_heads

    for i = 1, #legendary_heads do
        local key = legendary_heads[i]
        local str = "legendary_head_"..key

        if faction_cooking_info:is_ingredient_unlocked(str) then
            self.legendary_heads_num = self.legendary_heads_num + 1
        end
    end

    self.legendary_heads_max = #legendary_heads
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
                self.heads[key]["num_heads"] = 1
            else
                self.heads[key]["num_heads"] = -1 -- -1 is locked
            end
        end

        -- first thing's first, enable using 4 ingredients for a recipe for queeky
        -- TODO temp disabled secondaries until the unlock mechanic is introduced
        cm:set_faction_max_primary_cooking_ingredients(faction_obj, 2)
        cm:set_faction_max_secondary_cooking_ingredients(faction_obj, 0)
    end

    self:init_count_heads()
    self:squeak_init()

    --loyalty_listeners()

    -- next up, enable some 'eads to be gitted through battles
    core:add_listener(
        "queek_killed_someone",
        "CharacterConvalescedOrKilled",
        function(context)
            local character = context:character()
            --ModLog("char convalesced or killed'd")

            return character:is_null_interface() == false and character:character_type("general") and character:has_military_force() --[[and not character:military_force():is_armed_citizenry()]] and cm:pending_battle_cache_char_is_involved(cm:get_faction(self.faction_key):faction_leader()) and character:faction():name() ~= self.faction_key and not character:faction():is_quest_battle_faction()
        end,
        function(context)
            ModLog("queek killed someone")
            local killed_character = context:character()
            local queek_faction = cm:get_faction(self.faction_key)
            if not queek_faction or queek_faction:is_null_interface() then
                return false
            end

            local queek = queek_faction:faction_leader()

            -- TODO variable chance here
            local rand = cm:random_number(100, 1)

            if rand <= self.chance then
                self:add_head(killed_character, queek)
            end            
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

            -- TODO edit the heads num_label fields and change the states, for each that were changed

            -- subtract each ingredient used by 1 in the heads table
            for i = 1, #ingredients do
                local ingredient_key = ingredients[i]
                self.heads[ingredient_key]["num_heads"] = self.heads[ingredient_key]["num_heads"] -1
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

local function remove_component(uic_obj)
    if is_uicomponent(uic_obj) then
        uic_obj = {uic_obj}
    end

    if not is_table(uic_obj) then
        -- issue
        script_error("remove_component() called, but the uic obj supplied wasn't a single UIC or a table of UIC's!")
        return false
    end

    if not is_uicomponent(uic_obj[1]) then
        -- issue
        script_error("remove_component() called, but the uic obj supplied wasn't a single UIC or a table of UIC's!")
        return false
    end

    local killer = core:get_or_create_component("killer", "ui/campaign ui/script_dummy")

    for i = 1, #uic_obj do
        local uic = uic_obj[i]
        if is_uicomponent(uic) then
            killer:Adopt(uic:Address())
        end
    end

    killer:DestroyChildren()
end

-- this is called to refresh things like num_heads and the Collected Heads counter and what not
function headtaking:ui_refresh()

end

function headtaking:ui_init()
    -- ModLog("ui init")
    local topbar = find_uicomponent(core:get_ui_root(), "layout", "resources_bar", "topbar_list_parent")
    if is_uicomponent(topbar) then
        -- ModLog("topbar found")
        local uic = UIComponent(topbar:CreateComponent("queek_headtaking", "ui/campaign ui/queek_headtaking"))

        if not is_uicomponent(uic) then
            -- ModLog("uic not created?")
            return false
        end

        local grom_goals = uic:SequentialFind("grom_goals")

        grom_goals:SetState("hover")
        grom_goals:SetStateText(tostring(self.legendary_heads_num) .. " / "..tostring(self.legendary_heads_max))

        grom_goals:SetState("NewState")
        grom_goals:SetStateText(tostring(self.legendary_heads_num) .. " / "..tostring(self.legendary_heads_max))

        -- print_all_uicomponent_children(uic)

        --uic:SetVisible(true)
        topbar:Layout()

        -- --find_uicomponent(uic, "grom_goals"):SetVisible(false)
        -- local trait = find_uicomponent(uic, "trait")
        -- trait:SetImagePath("ui/skins/default/queektrait_icon_large.png")
    else
        -- ModLog("topbar unfound?")
    end

    local function close_listener()
        core:add_listener(
            "queek_close_panel",
            "ComponentLClickUp",
            function(context)
                local uic = find_uicomponent("queek_cauldron", "right_colum", "exit_panel_button")
                if is_uicomponent(uic) then
                    return context.component == uic:Address()
                end
                return false
            end,
            function(context)
                local panel = find_uicomponent("queek_cauldron")

                remove_component(panel)

                -- reenable the esc key
                cm:steal_escape_key(false)

                core:remove_listener("queek_close_panel")
            end,
            false
        )

        core:add_listener(
            "queek_close_panel",
            "ShortcutTriggered",
            function(context) 
                return context.string == "escape_menu"
            end,
            function(context)
                local panel = find_uicomponent("queek_cauldron")
                remove_component(panel)

                -- reenable the esc key
                cm:steal_escape_key(false)

                core:remove_listener("queek_close_panel")
            end,
            false
        )
    end

    local function opened_up()
        -- prevent the esc key being used
        cm:steal_escape_key(true)

        -- move the effect list tt out of the way
        local effect_list = find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "component_tooltip")
        --[[local lview = find_uicomponent(effect_list, "ingredient_effects", "effects_listview")
        local lclip = find_uicomponent(lview, "list_clip")
        local lbox = find_uicomponent(lclip, "list_box")]]
        local x,y = effect_list:GetDockOffset()
        --local px, py = core:get_screen_resolution()
        local fx = x --(px * 0.67) + x

        effect_list:SetDockOffset(fx, y * 1.25)
        effect_list:SetCanResizeHeight(true)
        effect_list:Resize(effect_list:Width(), effect_list:Height() *1.45)
        effect_list:SetCanResizeHeight(false)
        
        -- double made for no reason --TODO make it for a reason?
        local tt = find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "component_tooltip2")
        --tt:SetVisible(false)
        remove_component(tt)

        -- change the text on Collected Heads / Collected Legendary Heads
        local heads_num = find_uicomponent("queek_cauldron", "left_colum", "progress_display_holder", "ingredients_progress_holder", "ingredients_progress_number")

        local legendary_num = find_uicomponent("queek_cauldron", "left_colum", "progress_display_holder", "recipes_progress_holder", "recipes_progress_number")
        legendary_num:SetStateText(tostring(self.legendary_heads_num) .. " / " .. tostring(self.legendary_heads_max))

        local slot_holder = find_uicomponent("queek_cauldron", "mid_colum", "pot_holder", "ingredients_and_effects")
        local arch = find_uicomponent("queek_cauldron", "mid_colum", "pot_holder", "arch")

        -- move the four slots to line up with the pikes
        local pikes = {
            [1] = 167,
            [2] = 251,
            [3] = 369,
            [4] = 450
        }

        local shx, _ = slot_holder:Position()
        local arx, _ = arch:Position()

        for i,v in ipairs(pikes) do
            local pike_pos = v
            local slot = find_uicomponent(slot_holder, "main_ingredient_slot_"..tostring(i))

            local _, sloty = slot:Position()
            local w,_ = slot:Dimensions()

            -- this is the hard position on the screen where the middleish of the pike is (pike is 8px wide)
            local end_x = arx + (pike_pos + 4)

            -- grab the offset between the slot holder's position and the end result
            local slotx = end_x - (w/2)

            -- for some reason I'm 14 off, so
            slotx = slotx - 14

            -- move it
            slot:MoveTo(slotx, sloty)
        end

        -- move the four rows so it goes Nemesis -> T1 -> T2 -> T3
        local category_list = find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "ingredient_category_list")

        local pos = {
            [1] = 0, -- nemesis
            [2] = 0, -- tier one
            [3] = 0, -- tier two
            [4] = 0 -- tier three
        }

        local pos_x = 0

        local categories = {
            "CcoCookingIngredientGroupRecordzzz_nemesis_heads",
            "CcoCookingIngredientGroupRecordaaa_tier_one_heads",
            "CcoCookingIngredientGroupRecordfff_tier_two_heads",
            "CcoCookingIngredientGroupRecordmmm_tier_three_heads",
        }

        local ok, err = pcall(function()
            ModLog("starting add list view")
            -- add in the listview, bluh
            local list_view = UIComponent(category_list:CreateComponent("list_view", "ui/vandy_lib/vlist"))

            local list_clip = UIComponent(list_view:Find("list_clip"))
            local list_box = UIComponent(list_clip:Find("list_box"))
            local vslider = UIComponent(list_view:Find("vslider"))

            local cw,ch = category_list:Dimensions()
            ModLog("Dimensions are: ("..tostring(cw)..", "..tostring(ch)..")")
            list_view:SetCanResizeHeight(true)
            list_view:SetCanResizeWidth(true)

            list_clip:SetCanResizeHeight(true)
            list_clip:SetCanResizeWidth(true)

            ModLog("Bloop a doop")

            list_box:SetCanResizeHeight(true)
            list_box:SetCanResizeWidth(true)

            list_view:Resize(cw, ch)
            list_clip:Resize(cw, ch-50)

            ModLog("floorp a dorp")

            list_view:SetCanResizeHeight(false)
            list_view:SetCanResizeWidth(false)
            
            list_clip:SetCanResizeHeight(false)
            list_clip:SetCanResizeWidth(false)

            -- vslider:SetVisible(true)
            list_view:SetVisible(true)
            list_box:SetVisible(true)

            list_view:SetDockingPoint(2)
            list_clip:SetDockingPoint(0)
            list_box:SetDockingPoint(0)

            list_view:SetDockOffset(0, 0)
            list_clip:SetDockOffset(0, 0)
            list_box:SetDockOffset(0, 0)

            ModLog("shkorp")

            local addresses = {}

            ModLog("num children: "..tostring(category_list:ChildCount()))
            for i = 0, category_list:ChildCount() -1 do
                ModLog("loop "..tostring(i))
                local child = UIComponent(category_list:Find(i))
                ModLog("child gotten")
                ModLog("is uic: "..tostring(is_uicomponent(child)))
                ModLog("mah id: "..child:Id())
                if child:Id() ~= "list_view" and child:Id() ~= "template_category" then
                    addresses[#addresses+1] = child:Address()
                    ModLog("not list view and not template cat")
                end
            end

            for i = 1, #addresses do
                list_box:Adopt(addresses[i])
            end

            ModLog("farlg")

            list_box:Layout()
            vslider:SetVisible(true)

            list_box:Resize(cw, ch+150)
            list_box:SetCanResizeHeight(false)
            list_box:SetCanResizeWidth(false)
            
            ModLog("awefawef")
        
    --     for i = 1, #categories do
    --         ModLog("in loop ["..categories[i].."]")
    --         local uic = find_uicomponent(category_list, categories[i])
    --         if is_uicomponent(uic) then
    --             local x,y = uic:Position()
    --             pos_x = x

    --             for j,pos_y in ipairs(pos) do
    --                 --local pos_y = pos[j]
    --                 if pos_y == 0 then
    --                     pos[j] = y

    --                     ModLog("pos_y is 0 in num ["..tostring(j).."]. new pos_y is ["..tostring(y))

    --                     break
    --                 end

    --                 if y < pos_y then

    --                     ModLog("pos_y ["..tostring(pos_y).."] is more than uic_y in num ["..tostring(j).."]. new pos_y is ["..tostring(y))
    --                     pos[j] = y
    --                     if j ~= 4 then
    --                         ModLog("pushing pos_y ["..tostring(pos_y).."] to next index, ["..tostring(j+1).."]")
    --                         if pos[j+1] == 0 then
    --                             pos[j+1] = pos_y
    --                         else
    --                             -- TODO BAD CODE UGLY BAD BAD BAD BAD (written at midnight pls forgive me, future me)
    --                             local old_y = pos[j+1]
    --                             if pos[j+2] == 0 then
    --                                 pos[j+2] = old_y
    --                                 pos[j+1] = pos_y
    --                             else
    --                                 local oldest_y = pos[j+2]
    --                                 if pos[j+3] == 0 then
    --                                     pos[j+1] = pos_y
    --                                     pos[j+2] = old_y
    --                                     pos[j+3] = oldest_y
    --                                 end
    --                             end
    --                         end
    --                     end

    --                     break
    --                 end
    --             end

    --             -- loop through all ingredients, check their amounts in the headtaking table
    --             local ingredient_list = find_uicomponent(uic, "ingredient_list")

    --             -- no head counts for nemesis heads!
    --             if i ~= 1 then
    --                 for j = 0, ingredient_list:ChildCount() -1 do
    --                     -- skip the "template_ingredient" boi
    --                     local child = UIComponent(ingredient_list:Find(j))
    --                     local id = child:Id()
    --                     if id ~= "template_ingredient" then
    
    --                         local num_label = core:get_or_create_component("num_heads", "ui/vandy_lib/number_label", child)
    --                         num_label:SetStateText("0")
    --                         num_label:SetTooltipText("Number of Heads", true)
    --                         num_label:SetDockingPoint(3)
    --                         num_label:SetDockOffset(5, -5)
    
    --                         num_label:SetCanResizeWidth(true) num_label:SetCanResizeHeight(true)
    --                         num_label:Resize(num_label:Width() /2, num_label:Height() /2)
    --                         num_label:SetCanResizeWidth(false) num_label:SetCanResizeHeight(false)
    
    --                         num_label:SetVisible(false)
    
    --                         local ingredient_key = string.gsub(id, "CcoCookingIngredientRecord", "")

    --                         local head_obj = self.heads[ingredient_key]

    --                         if head_obj then
    --                             local num_heads = head_obj["num_heads"]
    --                             if num_heads and is_number(num_heads) then -- only continue if this head is tracked in the heads data table
    --                                 local slot_item = UIComponent(child:Find("slot_item"))

    --                                 num_label:SetStateText(tostring(num_heads))
    --                                 num_label:SetVisible(true)

    --                                 if num_heads == 0 then
    --                                     slot_item:SetState("inactive")
    --                                     slot_item:SetCurrentStateImageOpacity(1, 100)
    --                                 end
    --                             end
    --                         end
    --                     end
    --                 end
    --             end
    --         end
    --     end

    end) if not ok then ModLog(err) end

    --     for i = 1, #categories do
    --         local uic = find_uicomponent(category_list, categories[i])
    --         if is_uicomponent(uic) then
    --             local pos_y = pos[i]
    --             ModLog("Moving "..tostring(i).." to ("..tostring(pos_x)..", "..tostring(pos_y)..").")
    --             uic:MoveTo(pos_x, pos_y)
    --         end
    --     end

        --[[local adjusted_pos = {}
        for i = 1, #pos do
            local position = pos[i]
            
            if i == 1 then
                adjusted_pos[i] = position
            else
                local compare = pos[1]
                if position.y > compare.y then
                    adjusted_pos[1] = position
                    adjusted_pos[i] = compare
                end
            end
        end]]

        --[[local cook_button = find_uicomponent("queek_cauldron", "mid_colum", "cook_button_holder", "cook_button")
        cook_button:SetStateText("Assemble Trophy Rack")
        cook_button:SetTooltipText("Assign heads onto the trophy ")]]
    end

    local function test_open()
        -- check every UI tick if the queek cauldron is open - once it is, make the edits
        -- the following triggers an RealTimeTrigger event with the string "queek_cauldron_test_open" every single UI tick
        real_timer.register_repeating("queek_cauldron_test_open", 0)

        core:add_listener(
            "test_if_open",
            "RealTimeTrigger",
            function(context)
                --ModLog("test_if_open!")
                return context.string == "queek_cauldron_test_open" and is_uicomponent(find_uicomponent("queek_cauldron")) and is_uicomponent(find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "component_tooltip"))
            end,
            function(context)
                -- stop triggering!
                --ModLog("opened!")
                real_timer.unregister("queek_cauldron_test_open")
                --ModLog("testing!")
                --local ok, err = pcall(function()
                opened_up() --end) --if not ok then ModLog(err) end
                --ModLog("ended!")
            end,
            false
        )
    end

    core:add_listener(
        "queek_button_pressed",
        "ComponentLClickUp",
        function(context)
            return context.string == "queek_headtaking"
        end,
        function(context)
            local root = core:get_ui_root()
            local test = find_uicomponent("queek_cauldron")
            if not is_uicomponent(test) then
                root:CreateComponent("queek_cauldron", "ui/campaign ui/queek_cauldron_panel")

                test_open()
                
                close_listener()
            end
        end,
        true
    )
end

core:add_static_object("headtaking", headtaking)

cm:add_first_tick_callback(function() 
    headtaking:init() 

    if cm:get_local_faction_name(true) == headtaking.faction_key then
        headtaking:ui_init()
    end
end)

cm:add_loading_game_callback(
    function(context)
        headtaking.heads = cm:load_named_value("headtaking_heads", headtaking.heads, context)
        headtaking.squeak_stage = cm:load_named_value("headtaking_squeak_stage", headtaking.squeak_stage, context)
    end
)

cm:add_saving_game_callback(
    function(context)
        cm:save_named_value("headtaking_heads", headtaking.heads, context)
        cm:save_named_value("headtaking_squeak_stage", headtaking.squeak_stage, context)
    end
)