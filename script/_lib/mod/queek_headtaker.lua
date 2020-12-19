if __game_mode ~= __lib_type_campaign then
    -- camp only!
    return
end

local headtaking = {
    -- keep track of all the head objects

    -- links head keys to the amount of hedz
    heads = {},

    -- count the total number of heads ever, including all current and all previously spent heads
    total_heads = 0,

    -- count the current total number of heads
    current_heads = 0,



    legendary_heads_max = 0,
    legendary_heads_num = 0,

    squeak_stage = 0,
    squeak_mission_info = {
        num_missions = 0,
        current_mission = "",
    },

    chance = 100,
    queek_subtype = "wh2_main_skv_queek_headtaker",
    faction_key = "wh2_main_skv_clan_mors",

    -- table matching subcultures to their head reward
    valid_heads = require("script/headtaking/valid_heads"),
    legendary_heads = require("script/headtaking/legendary_heads"),
    subculture_to_heads = {},
    subtype_to_heads = {},

    special_heads = {
        dlc06_dwf_belegar = "legendary_head_belegar",
        dlc06_grn_skarsnik = "legendary_head_skarsnik",
    },
}

local queek_subtype = "wh2_main_skv_queek_headtaker"



function headtaking:add_head_with_key(head_key, details)
    if not is_string(head_key) then
        -- errmsg
        return false
    end

    ModLog("adding head with key "..head_key)

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

    -- iter the head total trackers
    self.total_heads = self.total_heads + 1
    self.current_heads = self.current_heads + 1

    ModLog("New total heads counter is: "..tostring(self.total_heads))
    ModLog("New current heads counter is: "..tostring(self.current_heads))
    
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

    core:trigger_custom_event("HeadtakingCollectedHead", {["headtaking"] = self, ["head"] = self.heads[head_key]})
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

function headtaking:get_head_for_subculture(sc_key)
    if not is_string(sc_key) then
        -- errmsg
        return false
    end

    local sc_table = self.subculture_to_heads[sc_key]
    if not is_table(sc_table) then
        -- errmsg
        return false
    end

    local max = #sc_table
    local ran = cm:random_number(max, 1)

    return sc_table[ran]
end


function headtaking:get_valid_head_for_character(subculture_key, subtype_key)
    if not is_string(subculture_key) or not is_string(subtype_key) then
        -- errmsg
        return false
    end

    local valid_heads = {}
    local sc_table = self.subculture_to_heads[subculture_key]
    local st_table = self.subtype_to_heads[subtype_key]

    if is_table(sc_table) then
        for i = 1, #sc_table do
            local head = sc_table[i]
            valid_heads[#valid_heads+1] = head
        end
    end

    if is_table(st_table) then
        for i = 1, #st_table do
            local head = st_table[i]
            valid_heads[#valid_heads+1] = head
        end
    end

    local max = #valid_heads

    if max == 0 then
        -- issue, a head wasn't constructed; what do?
        return ""
    end

    -- randomly select a head from the table
    local ran_num = cm:random_number(max, 1)
    return valid_heads[ran_num]
end

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

    head_key = self:get_valid_head_for_character(subculture_key, subtype_key)

    -- no head found for this char
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

function headtaking:squeak_random_shit()

end

function headtaking:squeak_upgrade(new_level)

end

function headtaking:squeak_init(new_stage)
    if is_number(new_stage) then
        self.squeak_stage = new_stage
    end

    ModLog("Squeak init!")
    local stage = self.squeak_stage
    ModLog("Stage is "..tostring(stage))

    -- first stage, Squeak is unacquired - guarantee his aquisition the next head taken
    if stage == 0 then
        core:add_listener(
            "AddSqueakPls",
            "HeadtakingCollectedHead",
            function(context)
                ModLog("Checking if Squeak add do")
                local total_heads = self.total_heads
                local chance = 0
                ModLog("Current total heads: "..tostring(total_heads))
                
                -- chance is 50% on the first head collected (2, since Queek starts with one)
                if total_heads == 2 then
                    return true
                elseif total_heads == 3 then
                    chance = 50
                elseif total_heads == 4 then
                    chance = 75
                elseif total_heads >= 5 then
                    return true
                end

                -- if chance is 50, then the random_number returning 1-50 will pass, so on.
                local ran = cm:random_number(100,1)

                ModLog("ran calc'd is: "..tostring(ran))

                return ran <= chance
            end,
            function(context)
                local total_heads = self.total_heads

                -- if this is the first head caught, then simply trigger an incident
                if total_heads == 2 then
                    cm:trigger_incident(self.faction_key, "squeak_scurry", true)

                    return
                end

                -- add Squeak
                local faction = cm:get_faction(self.faction_key)
                local queek = faction:faction_leader()
                cm:force_add_ancillary(
                    queek,
                    "squeak_stage_1",
                    true,
                    false
                )

                -- trigger incident for "hey, you got this fucker"

                -- set stage to next
                self:squeak_init(1)

                core:remove_listener("AddSqueakPls")
            end,
            true
        )
    elseif stage == 1 then
        -- Squeak acquired, and begins asking for inane shit
        self:squeak_random_shit()

        -- after a mission or two, go up
    elseif stage == 2 then
        -- Squeak informs about Legendary Heads (name pending!), and continues asking for inane shit
        self:squeak_random_shit()

        -- add in missions for each LL here
    elseif stage == 3 then
        -- Squeak upgrades 
        -- Squeak asks of you to conquer K8P finally and settle down, papa
        self:squeak_random_shit()

        -- add in mission to reconquista K8P
    elseif stage == 4 then
        -- After K8P conquer, Squeak demands of wildly wild shit
        self:squeak_random_shit()

        -- eventually, Squeak gets caught speaking to Queek's heads secretly, resulting in his fucking death, fuck that guy.
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

        if faction_cooking_info:is_ingredient_unlocked(key) then
            self.legendary_heads_num = self.legendary_heads_num + 1
        end
    end

    self.legendary_heads_max = #legendary_heads

    -- grab the current number of heads for internal tracking
    local heads = self.heads

    local num = 0

    -- add the total of all current heads
    for _, head_obj in pairs(heads) do
        local num_heads = head_obj.num_heads

        -- ignore 0 and -1
        if num_heads > 0 then
            num = num + num_heads
        end
    end

    self.current_heads = num
end


function headtaking:init_valid_heads()
    local valid_heads = self.valid_heads

    for head_key, validity_table in pairs(valid_heads) do
        local valid_subcultures = validity_table.subculture
        local valid_subtypes = validity_table.subtype

        if is_string(valid_subcultures) then
            valid_subcultures = {valid_subcultures}
        end

        if is_string(valid_subtypes) then
            valid_subtypes = {valid_subtypes}
        end

        if is_table(valid_subcultures) then
            for i = 1, #valid_subcultures do
                local sc_key = valid_subcultures[i]

                if not self.subculture_to_heads[sc_key] then
                    self.subculture_to_heads[sc_key] = {}
                end

                local internal_table = self.subculture_to_heads[sc_key]
                internal_table[#internal_table+1] = head_key
            end
        end

        if is_table(valid_subtypes) then
            for i = 1, #valid_subtypes do
                local st_key = valid_subtypes[i]

                if not self.subtype_to_heads[st_key] then
                    self.subtype_to_heads[st_key] = {}
                end

                local internal_table = self.subtype_to_heads[st_key]
                internal_table[#internal_table+1] = head_key
            end
        end
    end
end

-- initialize the mod stuff!
function headtaking:init()
    local faction_obj = cm:get_faction(self.faction_key)

    if not faction_obj or faction_obj:is_null_interface() then
        -- Queek unfound, returning false
        return false
    end

    self:init_valid_heads()

    -- set up the self.heads table - it tracks the number of heads available, or if a head is locked
    if cm:is_new_game() or self.heads == {} then
        ModLog("setting up fresh heads")

        local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)
        for key, _ in pairs(self.valid_heads) do

            self.heads[key] = {
                num_heads = 0,
                history = {},
            }

            if faction_cooking_info:is_ingredient_unlocked(key) then
                self.heads[key]["num_heads"] = 1
            else
                self.heads[key]["num_heads"] = -1 -- -1 is locked
            end
        end

        -- TODO add details manually
        self:add_head_with_key("generic_head_skaven")

        -- first thing's first, enable using 4 ingredients for a recipe for queeky
        -- TODO temp disabled secondaries until the unlock mechanic is introduced
        cm:set_faction_max_primary_cooking_ingredients(faction_obj, 2)
        cm:set_faction_max_secondary_cooking_ingredients(faction_obj, 0)
    end

    ModLog("Heads table: "..tostring(self.heads))

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

            -- refresh the UI for any necessary changes
            self:ui_refresh()
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
    if is_uicomponent(find_uicomponent("queek_cauldron")) then
        self:set_head_counters()
    end
end

-- this sets the UI for the number of heads and their respective states and opacities
function headtaking:set_head_counters()
    local category_list = find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "ingredient_category_list")

    if not is_uicomponent(category_list) then
        -- errmsg
        return false
    end

    local list_box = find_uicomponent(category_list, "list_view", "list_clip", "list_box")

    for i = 0, list_box:ChildCount() -1 do
        local category = UIComponent(list_box:Find(i))
        local ingredient_list = UIComponent(category:Find("ingredient_list"))

        -- only count heads on non-Nemeses heads
        if not string.find(category:Id(), "nemesis") then
            for j = 0, ingredient_list:ChildCount() -1 do
                local ingredient = UIComponent(ingredient_list:Find(j))
                local id = ingredient:Id()

                -- skip the default ingredient UIC, "template_ingredient"
                if id ~= "template_ingredient" then

                    -- create the number-of-heads label
                    local num_label = core:get_or_create_component("num_heads", "ui/vandy_lib/number_label", ingredient)
                    num_label:SetStateText("0")
                    num_label:SetTooltipText("Number of Heads", true)
                    num_label:SetDockingPoint(3)
                    num_label:SetDockOffset(0, 0)
    
                    num_label:SetCanResizeWidth(true) num_label:SetCanResizeHeight(true)
                    num_label:Resize(num_label:Width() /2, num_label:Height() /2)
                    num_label:SetCanResizeWidth(false) num_label:SetCanResizeHeight(false)
    
                    num_label:SetVisible(false)

                    local ingredient_key = string.gsub(id, "CcoCookingIngredientRecord", "")

                    local head_obj = self.heads[ingredient_key]

                    if head_obj then
                        local num_heads = head_obj["num_heads"]
                        if num_heads and is_number(num_heads) and num_heads ~= -1 then -- only continue if this head is tracked in the heads data table
                            local slot_item = UIComponent(ingredient:Find("slot_item"))

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
        local p = effect_list:DockingPoint()
        --local px, py = core:get_screen_resolution()
        local fx = x --(px * 0.67) + x

        effect_list:SetDockOffset(fx, y * 1.25)
        effect_list:SetCanResizeHeight(true)
        effect_list:Resize(effect_list:Width(), effect_list:Height() *1.45)
        effect_list:SetCanResizeHeight(false)
        
        local tt = find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "component_tooltip2")
        tt:SetDockingPoint(p)
        tt:SetDockOffset(fx + tt:Width(), y * 1.25)
        tt:SetCanResizeHeight(true)
        tt:Resize(tt:Width(), tt:Height() *1.45)
        tt:SetCanResizeHeight(false)

        -- hide for now :(
        tt:SetVisible(false)
        -- remove_component(tt)

        -- change the text on Collected Heads / Collected Legendary Heads
        local heads_num = find_uicomponent("queek_cauldron", "left_colum", "progress_display_holder", "ingredients_progress_holder", "ingredients_progress_number")

        -- TODO decide if this should be X / Total Heads or X / (Total Heads - Legendaries)

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

        local ok, err = pcall(function()
            ModLog("starting add list view")
            -- add in the listview, bluh
            local list_view = UIComponent(category_list:CreateComponent("list_view", "ui/vandy_lib/vlist"))

            local list_clip = UIComponent(list_view:Find("list_clip"))
            local list_box = UIComponent(list_clip:Find("list_box"))
            local vslider = UIComponent(list_view:Find("vslider"))

            local cw,ch = category_list:Dimensions()

            list_view:SetCanResizeHeight(true)
            list_view:SetCanResizeWidth(true)

            list_clip:SetCanResizeHeight(true)
            list_clip:SetCanResizeWidth(true)

            list_box:SetCanResizeHeight(true)
            list_box:SetCanResizeWidth(true)

            list_view:Resize(cw, ch)
            list_clip:Resize(cw, ch-50)

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

            local addresses = {}

            -- the order in which the categories are displayed
            local id_to_order = {
                nemeses = 1,
                underlings = 2,
                beasts = 3,
                human = 4,
                elves = 5,
                chaos = 6,
                undead = 7,
            }
            
            for i = 0, category_list:ChildCount() -1 do
                local child = UIComponent(category_list:Find(i))
                local id = child:Id()
                if id ~= "list_view" and id ~= "template_category" then
                    local key = string.gsub(id, "CcoCookingIngredientGroupRecord", "")
                    local ind = id_to_order[key]

                    addresses[ind] = child:Address()
                end
            end

            for i = 1, #addresses do
                list_box:Adopt(addresses[i])
            end

            -- ModLog("farlg")

            list_box:Layout()
            vslider:SetVisible(true)

            list_box:Resize(cw, ch+150)
            list_box:SetCanResizeHeight(false)
            list_box:SetCanResizeWidth(false)
            
            -- ModLog("awefawef")

        end) if not ok then ModLog(err) end

        self:ui_refresh()

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
                real_timer.unregister("queek_cauldron_test_open")

                opened_up() 
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
    local ok, err = pcall(function()
        headtaking:init() 

        if cm:get_local_faction_name(true) == headtaking.faction_key then
            headtaking:ui_init()
        end 
    end) if not ok then ModLog(err) end
end)

cm:add_loading_game_callback(
    function(context)
        headtaking.heads = cm:load_named_value("headtaking_heads", headtaking.heads, context)
        headtaking.total_heads = cm:load_named_value("headtaking_total_heads", headtaking.total_heads, context)
        headtaking.squeak_stage = cm:load_named_value("headtaking_squeak_stage", headtaking.squeak_stage, context)
        headtaking.squeak_mission_info = cm:load_named_value("headtaking_squeak_mission_info", headtaking.squeak_mission_info, context)
    end
)

cm:add_saving_game_callback(
    function(context)
        cm:save_named_value("headtaking_heads", headtaking.heads, context)
        cm:save_named_value("headtaking_total_heads", headtaking.total_heads, context)
        cm:save_named_value("headtaking_squeak_stage", headtaking.squeak_stage, context)
        cm:save_named_value("headtaking_squeak_mission_info", headtaking.squeak_mission_info, context)
    end
)