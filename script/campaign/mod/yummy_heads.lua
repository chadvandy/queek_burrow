-- DONE remove Grom VO
-- DONE make 3 generic heads per race with icons
-- DONE rename "Start Cooking" & tooltip
-- DONE reorder the four ingredient groups to be Nemesis -> T3 (sceropted)
-- DONE reward heads for post-battle
-- DONE actual effects!



-- TODO resolve LL-head-collection mechanic (grant missions which guarantee death of LL)
-- TODO rename "Cauldron Dish"
-- TODO hide "Recipe Book"(?) // Rename
-- TODO fix slot tooltips



local faction_key = "wh2_main_skv_clan_mors"

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

    local killer = core:get_or_create_component("script_dummy", "ui/campaign ui/script_dummy")

    for i = 1, #uic_obj do
        local uic = uic_obj[i]
        if is_uicomponent(uic) then
            killer:Adopt(uic:Address())
        end
    end

    killer:DestroyChildren()
end 

local function ui_init()
    local topbar = find_uicomponent("layout", "resources_bar", "topbar_list_parent")
    if is_uicomponent(topbar) then
        local uic = UIComponent(topbar:CreateComponent("queek_headtaking", "ui/campaign ui/queek_headtaking"))

        find_uicomponent(uic, "grom_goals"):SetVisible(false)
        find_uicomponent(uic, "trait"):SetVisible(false)
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
                local dummy = core:get_or_create_component("script_dummy", "ui/campaign ui/script_dummy")
                dummy:Adopt(panel:Address())
                dummy:DestroyChildren()

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
                local dummy = core:get_or_create_component("script_dummy", "ui/campaign ui/script_dummy")
                dummy:Adopt(panel:Address())
                dummy:DestroyChildren()

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

        -- remove the scrap UI
        local scrap_crap = find_uicomponent("queek_cauldron", "mid_colum", "cook_button_holder", "scrap_cost")
        remove_component(scrap_crap)

        -- remove Grom's ugly gob
        local grom = find_uicomponent("queek_cauldron", "left_colum", "progress_display_holder", "trait")
        remove_component(grom)

        local slot_holder = find_uicomponent("queek_cauldron", "mid_colum", "pot_holder", "ingredients_and_effects")
        local arch = find_uicomponent("queek_cauldron", "mid_colum", "pot_holder", "arch")

        -- hide the animated circles around the 3/4 slots
        find_uicomponent(slot_holder, "main_ingredient_slot_1_animated_frame"):SetVisible(false)
        find_uicomponent(slot_holder, "main_ingredient_slot_4_animated_frame"):SetVisible(false)


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
            "CcoCookingIngredientGroupRecordnemesis_heads",
            "CcoCookingIngredientGroupRecordtier_one_heads",
            "CcoCookingIngredientGroupRecordtier_two_heads",
            "CcoCookingIngredientGroupRecordtier_three_heads",
        }
        
        for i = 1, #categories do
            --ModLog("in loop ["..categories[i].."]")
            local uic = find_uicomponent(category_list, categories[i])
            if is_uicomponent(uic) then
                local x,y = uic:Position()
                pos_x = x

                for j,pos_y in ipairs(pos) do
                    --local pos_y = pos[j]
                    if pos_y == 0 then
                        pos[j] = y

                        --ModLog("pos_y is 0 in num ["..tostring(j).."]. new pos_y is ["..tostring(y))

                        break
                    end

                    if y < pos_y then

                        --ModLog("pos_y ["..tostring(pos_y).."] is more than uic_y in num ["..tostring(j).."]. new pos_y is ["..tostring(y))
                        pos[j] = y
                        if j ~= 4 then
                            --ModLog("pushing pos_y ["..tostring(pos_y).."] to next index, ["..tostring(j+1).."]")
                            if pos[j+1] == 0 then
                                pos[j+1] = pos_y
                            else
                                -- TODO BAD CODE UGLY BAD BAD BAD BAD (written at midnight pls forgive me, future me)
                                local old_y = pos[j+1]
                                if pos[j+2] == 0 then
                                    pos[j+2] = old_y
                                    pos[j+1] = pos_y
                                else
                                    local oldest_y = pos[j+2]
                                    if pos[j+3] == 0 then
                                        pos[j+1] = pos_y
                                        pos[j+2] = old_y
                                        pos[j+3] = oldest_y
                                    end
                                end
                            end
                        end

                        break
                    end
                end
                --[[local data = {}
                data.x, data.y = uic:Position()
                pos[#pos+1] = data]]
            end
        end

        for i = 1, #categories do
            local uic = find_uicomponent(category_list, categories[i])
            if is_uicomponent(uic) then
                local pos_y = pos[i]
                uic:MoveTo(pos_x, pos_y)
            end
        end

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

-- table matching subcultures to their head reward
local valid_heads = {
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
}

local special_heads = {
    dlc06_dwf_belegar = "legendary_head_belegar",
    dlc06_grn_skarsnik = "legendary_head_skarsnik",
}

local queek_subtype = "wh2_main_skv_queek_headtaker"

local chance = 20

local function add_head(character_obj, queek_obj)
    local faction_obj = cm:get_faction(faction_key)
    local head_key = ""

    local subtype_key = character_obj:character_subtype_key()
    local subculture_key = character_obj:faction():subculture()

    -- check if it was a special head first
    if special_heads[subtype_key] ~= nil then
        -- TODO disabling for now, no legendary heads!
        --head_key = special_heads[subtype_key]
        return false
    else
        head_key = valid_heads[subculture_key]
    end

    -- no head found for this subculture
    if head_key == "" then
        return false
    end

    --ModLog("adding head with key ["..head_key.."]")

    local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)

    -- we already have this head, returning false!
    if faction_cooking_info:is_ingredient_unlocked(head_key) then
        return false
    end

    cm:unlock_cooking_ingredient(faction_obj, head_key)

    
    if faction_obj:is_human() then
        local loc_prefix = "event_feed_strings_text_yummy_head_unlocked_"
        cm:show_message_event_located(
            faction_key,
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
local function loyalty_listeners(disable)
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
            return context:character():faction():name() == faction_key
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
local function init()
    local faction_obj = cm:get_faction(faction_key)

    if not faction_obj or faction_obj:is_null_interface() then
        -- Queek unfound, returning false
        return false
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

            return character:is_null_interface() == false and character:character_type("general") and character:has_military_force() and not character:military_force():is_armed_citizenry() and cm:pending_battle_cache_char_is_involved(cm:get_faction(faction_key):faction_leader()) and character:faction():name() ~= faction_key and not character:faction():is_quest_battle_faction()
        end,
        function(context)
            --ModLog("queek killed someone")
            local killed_character = context:character()
            local queek_faction = cm:get_faction(faction_key)
            if not queek_faction or queek_faction:is_null_interface() then
                return false
            end

            --ModLog("queek involved")

            local queek = queek_faction:faction_leader()
            --local pb = cm:model():pending_battle()

            --ModLog("add head")

            local rand = cm:random_number(100, 1)

            if rand <= chance then
                add_head(killed_character, queek)
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

        loyalty_listeners()
    end

    local function skaven_loyalty_increase()
        cm:set_saved_value("yummy_head_loyalty_increase", true)

        loyalty_listeners()
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
            return context:faction():name() == faction_key
        end,
        function(context)
            local cooked_dish = context:dish()
            --local ingredients = cooked_dish:ingredients()
            local faction_effects = cooked_dish:faction_effects()

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

cm:add_first_tick_callback(function()
    if cm:get_local_faction(true) == faction_key then
        ui_init()
    end

    init()
end)

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