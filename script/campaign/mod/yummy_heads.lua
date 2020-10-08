local faction_key = "wh2_main_skv_clan_mors"

local headtaking = core:get_static_object("headtaking")

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

        --find_uicomponent(uic, "grom_goals"):SetVisible(false)
        find_uicomponent(uic, "trait"):SetImagePath("ui/skins/default/queektrait_icon_large.png")
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

        -- change* Grom's ugly gob
        local grom = find_uicomponent("queek_cauldron", "left_colum", "progress_display_holder", "trait")
        grom:SetImagePath("ui/skins/default/queektrait_icon_large.png")
        --remove_component(grom)

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

                -- loop through all ingredients, check their amounts in the headtaking table
                local ingredient_list = find_uicomponent(uic, "ingredient_list")

                -- no head counts for nemesis heads!
                if categories[i] ~= "CcoCookingIngredientGroupRecordnemesis_heads" then
                    for j = 0, ingredient_list:ChildCount() -1 do
                        -- skip the "template_ingredient" boi
                        if id ~= "template_ingredient" then
                            local child = UIComponent(ingredient_list:Find(j))
                            local id = child:Id()
    
                            local num_label = core:get_or_create_component("num_heads", "ui/vandy_lib/number_label", child)
                            num_label:SetStateText("0")
                            num_label:SetTooltipText("Number of Heads", true)
                            num_label:SetDockingPoint(3)
                            num_label:SetDockOffset(5, -5)
    
                            num_label:SetCanResizeWidth(true) num_label:SetCanResizeHeight(true)
                            num_label:Resize(num_label:Width() /2, num_label:Height() /2)
                            num_label:SetCanResizeWidth(false) num_label:SetCanResizeHeight(false)
    
                            num_label:SetVisible(false)
    
                            local ingredient_key = string.gsub(id, "CcoCookingIngredientRecord", "")

                            local num_heads = headtaking.heads[ingredient_key]
                            if num_heads and is_number(num_heads) then -- only continue if this head is tracked in the heads data table
                                local slot_item = UIComponent(child:Find("slot_item"))

                                num_label:SetStateText(tostring(num_heads))
                                num_label:SetVisible(true)

                                if num_heads == 0 then
                                    slot_item:SetState("inactive")
                                    slot_item:SetCurrentStateImageOpacity(1, 100)
                                end
                            end
                        end
                    end
                end
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


cm:add_first_tick_callback(function()
    if cm:get_local_faction(true) == faction_key then
        ui_init()
    end

    --init()
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