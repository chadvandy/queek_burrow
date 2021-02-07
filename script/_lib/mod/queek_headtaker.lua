if __game_mode ~= __lib_type_campaign then
    -- camp only!
    return
end

local headtaking = {
    -- keep track of all the head objects

    -- links head keys to the amount of hedz
    heads = {},

    -- saves the current state of each slot - ordered 1-4 from left to right
    slots = {
        "locked",
        "open",
        "open",
        "locked",
    },

    -- count the total number of heads ever, including all current and all previously spent heads
    total_heads = 0,

    -- count the current total number of heads
    current_heads = 0,

    legendary_heads_max = 0,
    legendary_heads_num = 0,

    squeak_stage = 0,
    squeak_mission_info = {
        turns_since_last_event = 1,
        turns_since_last_mission = false,
        num_missions = 0,
        current_mission = "",
    },

    -- saves the stages of each legendary head mission
    legendary_mission_info = {},

    -- data-ified missions for legendary heads and squeak stages
    legendary_missions = require("script/headtaking/legendary_missions"),
    legendary_encounters =require("script/headtaking/legendary_encounters"),
    squeak_missions = require("script/headtaking/squeak_missions"),

    chance = 100, -- chance defaults to 60%
    queek_subtype = "wh2_main_skv_queek_headtaker",
    faction_key = "wh2_main_skv_clan_mors",

    -- table matching subcultures to their head reward
    valid_heads = require("script/headtaking/valid_heads"),

    -- built from valid_heads, makes a quick index'd table to pull valid heads based on subculture or subtype
    subculture_to_heads = {},
    subtype_to_heads = {},

    -- table of legendary heads attached to their various related missions, ultra static
    legendary_heads = require("script/headtaking/legendary_heads"),
}

local prefix = "[QUEEK] "

local function log_init()
    local file_name = "!vandy_lib.txt"
    local file = io.open(file_name, "w+")

    file:write("[VLIB] " .. get_timestamp() .. " New Vandy Lib Initialized\n")
    file:close()
end

local function log(text)
    text = tostring(text)

    local time = get_timestamp()
    text = prefix .. time .. "\t" .. text .. "\n"

    local file_name = "!vandy_lib.txt"
    local file = io.open(file_name, "a+")

    file:write(text)

    file:close()

    ModLog(text)
end

local function err(text)
    local pre = prefix .. "[SCRIPT ERROR] "
    
    text = tostring(text)

    local time = get_timestamp()
    text = pre .. time .. "\t" .. text .. "\n"

    local file_name = "!vandy_lib.txt"
    local file = io.open(file_name, "a+")

    file:write(text)

    file:close()

    ModLog(text)
end

local function timed_callback(key, condition, callback, time)
    if not is_string(key) then
        log("timed_callback called, key isn't a string: ".. tostring(key))
        return false
    end

    if not is_function(condition) and condition ~= true then
        log("timed_callback called, condition isn't a function or true: "..tostring(condition))
        return false
    end

    if not is_function(callback) then
        log("timed_callback called, callback isn't a function: "..tostring(callback))
        return false
    end

    if not is_number(time) then
        log("timed_callback called, time isn't a number: "..tostring(time))
        return false
    end

    local function trigger_and_listener()
        core:add_listener(
            key,
            "RealTimeTrigger",
            function(context)
                return context.string == key --and (condition == true or condition(context) == true)
            end,
            function(context)
                if condition == true or condition(context) == true then
                    callback(context)
                else
                    trigger_and_listener()
                end
            end,
            false
        )

        real_timer.register_singleshot(key, time)
    end

    trigger_and_listener()
end

local function repeat_callback(key, condition, callback, time)
    if not is_string(key) then
        err("repeat_callback() called, but the key provided is not a string!")
        return false
    end

    if not is_function(condition) or not condition == true then
        err("repeat_callback() called, but the condition provided is not a function or true!")
        return false
    end

    if not is_function(callback) then
        err("repeat_callback() called, but the callback provided is not a function!")
        return false
    end

    if not is_number(time) then
        err("repeat_callback() called, but the time provided is not a number!")
        return false
    end

    real_timer.register_repeating(key, time)

    core:add_listener(
        key,
        "RealTimeTrigger",
        function(context)
            return context.string == key and condition(context)
        end,
        function(context)
                callback(context)
        end,
        true
    )
end

function headtaking:has_squeak()
    local stage = self:get_squeak_stage()
    return stage >= 1 and stage < 5
end

function headtaking:get_squeak_stage()
    return self.squeak_stage
end

function headtaking:get_queek()
    local faction_obj = cm:get_faction(self.faction_key)
    local queek = faction_obj:faction_leader()

    if not queek:character_subtype(self.queek_subtype) then
        err("headtaking:get_queek() called, but Queek is not found in the faction! Big issue!")
        return false
    end

    return queek
end

function headtaking:queek_has_ancillary(ancillary_key)
    local queek = self:get_queek()
    if not queek then return false end

    return queek:has_ancillary(ancillary_key)
end

function headtaking:queek_has_skill(skill_key)
    local queek = self:get_queek()
    if not queek then return false end

    return queek:has_skill(skill_key)
end

function headtaking:queek_has_trait(trait_key)
    local queek = self:get_queek()
    if not queek then return false end

    return queek:has_trait(trait_key)
end

function headtaking:queek_has_access_to_head(head_key)
    if not is_string(head_key) then
        err("queek_has_access_to_head() called, but the head_key ["..tostring(head_key).."] provided is not a string!")
        return false
    end

    if not self.valid_heads[head_key] and not self.legendary_heads[head_key] then
        err("queek_has_access_to_head() called, but the head_key ["..tostring(head_key).."] provided is not a valid head!")
        return false
    end

    local faction_key = self.faction_key
    local faction_obj = cm:get_faction(faction_key)
    local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)

    return faction_cooking_info:is_ingredient_unlocked(head_key)
end

function headtaking:can_get_head_from_event(context)
    local character = context:character()
    local faction = character:faction()

    log("Character killed, checking stuff.")
    log("is null interface: "..tostring(character:is_null_interface()))
    log("has mf force:" .. tostring(character:has_military_force()))
    log("is embedded: "..tostring(character:is_embedded_in_military_force()))
    log("has garri: "..tostring(character:has_garrison_residence()))

    log("queek is in: "..tostring(cm:pending_battle_cache_char_is_involved(cm:get_faction(self.faction_key):faction_leader())))
    log("faction name: "..faction:name())
    log("is quest battle faction: "..tostring(faction:is_quest_battle_faction()))

    return
        character:is_null_interface() == false                              -- character that died actually exists
        -- and character:character_type("general")                          -- temp disbabled -- generals only
        and (character:has_military_force() or character:is_embedded_in_military_force() or character:has_garrison_residence()) -- needs to be in an army (leading, hero in it, or a garrison friend)
        and cm:pending_battle_cache_char_is_involved(cm:get_faction(self.faction_key):faction_leader())     -- Queek was involved in the battle
        and faction:name() ~= self.faction_key                  -- the character that died isn't in Clan Mors, lol
        and faction:name() ~= "wh2_main_skv_skaven_rebels"  -- not Skaven Rebels (prevent cheesing (: )
        and not faction:is_quest_battle_faction()               -- not a QB faction
end

function headtaking:get_headtaking_chance(target_character_obj)
    local chance = self.chance

    -- +20% if Trophy Heads skill is had'd
    if self:queek_has_skill("wh2_main_skill_skv_trophy_heads_queek") then
        chance = chance + 20
    end

    if is_character(target_character_obj) then
        local faction_obj = target_character_obj:faction()
        local faction_key = faction_obj:name()
        local subculture_key = faction_obj:subculture()

        if string.find(subculture_key, "dwf") then
            -- auto +10% against dwf
            chance = chance + 10

            -- +15% if Dwarf-Gouger is equipped
            if self:queek_has_ancillary("wh2_main_anc_weapon_dwarf_gouger") then
                chance = chance + 15
            end
        elseif string.find(subculture_key, "grn") then
            -- auto +10% against grn
            chance = chance + 10
        elseif string.find(subculture_key, "skv") then
            -- +15% if Make Examples!
            if self:queek_has_skill("wh2_main_skill_skv_queek_unique_melee_4") then
                chance = chance + 15
            end
        end
    end

    return chance
end

function headtaking:increase_headtaking_chance(plus)
    if not is_number(plus) then
        err("increase_headtaking_chance() called, but the value ["..tostring(plus).."] provided is not a number!")
        return false
    end

    local new_val = self.chance + plus

    -- TODO? max ceiling
    -- for now clamp to 100 max, because lul
    if new_val >= 100 then new_val = 100 end

    self.chance = new_val
end

-- debug to add every head!
function headtaking:add_all_heads()
    for head_key,_ in pairs(self.valid_heads) do
        self:add_head_with_key(head_key)
    end

    for head_key,_ in pairs(self.legendary_heads) do
        self:add_head_with_key(head_key)
    end
end

-- add a random head, starting with any that the faction doesn't currently have
-- if all heads are had, just a perfectly random one
function headtaking:add_random_head()
    local heads = self.heads
    local unhad = {}
    local all = {}

    for head_key, head_obj in pairs(heads) do
        local count = head_obj.num_heads

        if count < 1 then
            unhad[#unhad+1] = head_key
        end

        all[#all+1] = head_key
    end

    local my_head
    -- if there's no unhads, pick a perfectly random one
    if #unhad == 0 then
        my_head = all[cm:random_number(#all)]
    else
        my_head = unhad[cm:random_number(#unhad)]
    end

    self:add_head_with_key(my_head)
end

-- adds a number of random heads (defaults to 3) from a subculture
-- can be that culture - any variety of heads they have - or a few heads from within that faction's ingredient group
function headtaking:add_free_heads_from_subculture(subculture_key, num_heads)
    if not is_string(subculture_key) then
        -- errmsg
        return false
    end

    if not num_heads then num_heads = 3 end

    if not is_number(num_heads) then
        -- errmsg
        return false
    end

    local added = {}
    local heads = self:get_valid_heads_from_subculture(subculture_key)

    -- local group_heads = self:get_valid_heads_from_group()


    -- add one random head from the "heads" table for each head added above
    for _ = 1, num_heads do
        added[#added+1] = heads[cm:random_number(#heads)]
    end

    for i = 1, #added do
        self:add_head_with_key(added[i], nil, true)
    end

    -- inform the player of the free many heads
    cm:trigger_incident(self.faction_key, "yummy_heads_destroyed_faction", true)
end

-- lose a head randomly from your stash
function headtaking:lose_random_head()
    local heads = self.heads
    local had_heads = {}

    for head_key, head_obj in pairs(heads) do
        local count = head_obj.num_heads
        for _ = 1, count do
            had_heads[#had_heads] = head_key
        end
    end

    local ran = cm:random_number(#had_heads)
    local lost_head = had_heads[ran]

    -- remove it from your stash
    self.heads[lost_head].num_heads = self.heads[lost_head].num_heads - 1
end

function headtaking:add_head_with_key(head_key, details, skip_event)
    if not is_string(head_key) then
        err("add_head_with_key() called, but the head_key ["..tostring(head_key).."] provided is not a string!")
        return false
    end

    -- test that it's a valid head!
    if not self.valid_heads[head_key] and not self.legendary_heads[head_key] then
        err("add_head_with_key() called, but the head_key ["..tostring(head_key).."] provided is not a valid head!")
        return false
    end

    log("adding head with key "..head_key)

    local faction_obj = cm:get_faction(self.faction_key)
    local queek_obj = faction_obj:faction_leader()

    local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)

    if not self.heads[head_key] then
        self.heads[head_key] = {
            num_heads = 0,
            history = {},
        }
    end

    -- prevent any breaking here
    if not details then details = {} end

    -- if we're passing in a "details" table, save it to the table for this head
    -- if details and is_table(details) then
    self.heads[head_key]["history"][#self.heads[head_key]["history"]+1] = details
    -- end

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

    log("New total heads counter is: "..tostring(self.total_heads))
    log("New current heads counter is: "..tostring(self.current_heads))
    
    if not skip_event then
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

    core:trigger_custom_event("HeadtakingCollectedHead", {["headtaking"] = self, ["head"] = self.heads[head_key], ["head_key"] = head_key, ["faction_key"] = details.faction_key})
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
        err("get_head_for_subculture() called, but the subculture key ["..tostring(sc_key).."] provided is not a string!")
        return false
    end

    local sc_table = self.subculture_to_heads[sc_key]
    if not is_table(sc_table) then
        err("get_head_for_subculture() called, but the subculture key ["..tostring(sc_key).."] provided is not valid! No heads found for this one.")
        return false
    end

    local max = #sc_table
    local ran = cm:random_number(max, 1)

    return sc_table[ran]
end

function headtaking:get_valid_heads_for_group(group_key)
    if not is_string(group_key) then
        -- errmsg
        return false
    end

    local retval = {}
    local valid_heads = self.valid_heads

    for head_key, head_data in pairs(valid_heads) do
        local group = head_data.group
        if group == group_key then
            retval[#retval+1] = head_key
        end
    end

    return retval
end

function headtaking:get_valid_heads_for_subculture(subculture_key)
    if not is_string(subculture_key) then
        -- errmsg
        return false
    end

    local valid_heads = {}

    local heads_table = self.subtype_to_heads[subculture_key]

    if is_table(heads_table) then
        for i = 1, #heads_table do
            valid_heads[#valid_heads+1] = heads_table[i]
        end
    end

    return valid_heads
end

function headtaking:get_valid_heads_for_subtype(subtype_key)
    if not is_string(subtype_key) then
        -- errmsg
        return false
    end

    local valid_heads = {}

    local heads_table = self.subtype_to_heads[subtype_key]

    if is_table(heads_table) then
        for i = 1, #heads_table do
            valid_heads[#valid_heads+1] = heads_table[i]
        end
    end

    return valid_heads
end

function headtaking:get_valid_head_for_character(subculture_key, subtype_key)
    if not is_string(subculture_key) or not is_string(subtype_key) then
        err("get_valid_head_for_character() called, but the subtype or subculture key ["..tostring(subtype_key).."] / ["..tostring(subculture_key).."] provided is not a string!")
        return false
    end

    local valid_heads = {}

    local sc_table = self:get_valid_heads_for_subculture(subculture_key)
    local st_table = self:get_valid_heads_for_subtype(subtype_key)

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

    --log("adding head with key ["..head_key.."]")

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

function headtaking:get_mission_with_key(key)
    if not is_string(key) then
        err("get_mission_with_key() called, but the key ["..tostring(key).."] provided is not a string!")
        return false
    end

    local missions = self.squeak_missions
    for i = 1, #missions do
        local mission = missions[i]
        if mission.key == key then
            return mission
        end
    end

    err("get_mission_with_key() called, but no mission with ["..tostring(key).."] was found!")
    return false
end

function headtaking:squeak_trigger_mission()
    local missions = self.squeak_missions
    local stage = self.squeak_stage

    -- first 4 missions are valid for stage 1, and it goes up from there
    local last_valid = 4
    if stage == 2 then
        last_valid = 4
    elseif stage == 3 then
        last_valid = 4
    elseif stage == 4 then
        last_valid = 4
    end

    -- update last mission time
    self.squeak_mission_info.turns_since_last_mission = cm:model():turn_number()

    -- pick a random mission from the list
    local ran = cm:random_number(last_valid)

    local mission = missions[ran]

    if mission.constructor then mission = mission.constructor(self, mission) end

    local objective = mission.objective

    local mm = mission_manager:new(self.faction_key, mission.key)
    mm:set_mission_issuer("squeak") -- TODO set this more dynamically, for the different versions
    mm:add_new_objective(objective)

    if is_string(mission.condition) then mission.condition = {mission.condition} end
    for i = 1, #mission.condition do
        -- this is the condition string; it comes as "total [500]" by default
        -- this little constructor here changes up the value in the brackets, if valid, and concatenates it to the beginning. for instance, finding a region_key.
        local str = mission.condition[i]

        local condition = str

        local x = string.find(str, "[%[]")
        local y = string.find(str, "[%]]")

        -- if there's some [%%%] string within, test it and change it; else, just apply the condition
        if x and y then
            local my_str = str:sub(x,y)
            local condition_type = str:sub(1, x-2)

            local condition_value = my_str:gsub("[%[%]]", "")
            
            if objective == "KILL_X_ENTITIES" then
                local val = tonumber(condition_value)
                local floor = val * 0.75
                local ceil = val * 2.25

                condition_value = tostring(cm:random_number(ceil, floor))
            elseif objective == "OWN_N_UNITS" then
                local val = tonumber(condition_value)
                local floor = val * 0.8
                local ceil = val * 1.2

                condition_value = tostring(cm:random_number(ceil, floor))
            end

            condition = condition_type .. " " .. condition_value
        end

        mm:add_new_condition(condition)
    end

    mm:add_payload(mission.payload)

    mm:trigger()

    if mission.start_func then mission.start_func(self) end
    if mission.listener then mission.listener() end
end

-- gets every deployed general in the faction with 6 or under loyalty
function headtaking:get_generals_in_faction_with_low_loyalty()
    local retval = false
    local faction = cm:get_faction(self.faction_key)

    if not faction then
        err("get_generals_in_faction_with_low_loyalty() called, but Queek's faction isn't found! Big issue!")
        return false
    end

    local char_list = faction:character_list()

    local saddies = {}

    for i = 0, char_list:num_items() -1 do
        local char = char_list:item_at(i)

        if char:character_type("general") and not char:character_subtype(self.queek_subtype) and char:has_military_force() and char:loyalty() <= 6 then
            retval = true
            saddies[#saddies+1] = char:command_queue_index()
        end
    end

    if retval then
        return saddies
    end

    return false
end

-- trigger a random squeak event from a list and listen for the result
function headtaking:squeak_trigger_event()
    local ok, errmsg = pcall(function()
    log("event 1")
    local events = {
        "squeak_found_this",        -- incident, free head
        "squeak_has_this",          -- dilemma, pick from 4 heads
        "squeak_stole_this",        -- dilemma, Squeak stole your head, caught him. choose to take the head and reprimand him, or send him to get another       
    }

    local generals = self:get_generals_in_faction_with_low_loyalty()
    local general_cqi

    -- lock this event unless there are any valid generals
    if generals then
        events[#events+1] = "squeak_took_this" -- dilemma, Squeak took a head from a general, choose to accept, return, return a fake, or destroy the evidence
        general_cqi = generals[cm:random_number(#generals)]
    end

    log("event 2")

    local ran = cm:random_number(#events)

    local head_event = events[ran]

    if ran <= 1 then -- it's an incident
        cm:trigger_incident(
            self.faction_key,
            head_event,
            true
        )

        -- add a single head that isn't already in the collection; if you have all heads, just add a random one
        self:add_random_head()
    else             -- it's a derlermer
        if head_event == "squeak_took_this" then
            -- special dilemma with this special dilemma
            local faction_cqi = cm:get_faction(self.faction_key):command_queue_index()

            cm:trigger_dilemma_with_targets(
                faction_cqi,
                head_event,
                0,
                0,
                general_cqi,
                0,
                0,
                0,
                nil
            )
        else
            cm:trigger_dilemma(
                self.faction_key,
                head_event
            )
        end

        -- listen for the result, change it based on the dilemmer
        core:add_listener(
            "SqueakDilemma",
            "DilemmaChoiceMadeEvent",
            function(context)
                return context:dilemma() == head_event
            end,
            function(context)
                local choice = context:choice() + 1 -- +1 because this is passed as 0-1-2-3, instead of 1-2-3-4
                local key = context:dilemma()

                -- 25% chance of a head + an effect bundle, 25% chance of a dudd (negative bundle on Queek), 50% chance of a head you already have + an okay effect bundle
                if key == "squeak_has_this" then
                    local options = {"best", "dud", "okay", "okay"}
                    options = cm:random_sort(options) -- randomize these options

                    local result = options[choice]

                    -- TODO eb's
                    if result == "best" then
                        -- head + great EB
                        self:add_random_head()
                    elseif result == "dud" then
                        -- negative EB
                    elseif result == "okay" then
                        -- head + okay EB
                        self:add_random_head()
                    end
                elseif key == "squeak_stole_this" then
                    -- Squeak stole your head

                    -- Choice 1: Take it back, get a negative EB for Squeak's sneakiness
                    if choice == 1 then
                        -- the EB is applied through the DB, boi
                    end

                    -- Choice 2: Lose it, get a different head but no EB
                    if choice == 2 then
                        self:lose_random_head()
                        self:add_random_head()
                    end
                elseif key == "squeak_took_this" then
                    -- Squeak took a head from a general, the rascal
                    local general = cm:get_character_by_cqi(general_cqi)

                    -- Choice 1: Thanks dog, free head + lost loyalty
                    if choice == 1 then
                        self:add_random_head()
                        cm:modify_character_personal_loyalty_factor("character_cqi:"..general_cqi, cm:random_number(-1, -2))
                    
                    -- Choice 2: Free loyalty for returning it
                    elseif choice == 2 then
                        cm:modify_character_personal_loyalty_factor("character_cqi:"..general_cqi, cm:random_number(2, 1))
                    
                    -- Choice 3: Free head, 50% chance to gain loyalty, 50% chance to lose more loyalty
                    elseif choice == 3 then
                        self:add_random_head()
                        if cm:random_number() >= 50 then
                            -- free loyalty
                            cm:modify_character_personal_loyalty_factor("character_cqi:"..general_cqi, cm:random_number(2, 1))
                        else
                            -- much lost loyalty
                            cm:modify_character_personal_loyalty_factor("character_cqi:"..general_cqi, cm:random_number(-1, -4))
                        end

                    -- Choice 4: No head, no loyalty change
                    elseif choice ==4 then
                        -- nada, maybe an EB in DB
                    end
                end
            end,
            false
        )
    end
end) if not ok then err(errmsg) end
end

-- check to see if we should trigger an event; if yes, trigger an event, lol
function headtaking:squeak_trigger_event_test()
    local turn = cm:model():turn_number()
    local last_turn = self.squeak_mission_info.turns_since_last_event

    -- 100% chance at 20 turns since, 5% at 1 turns since, so on
    local turns_since = turn - last_turn
    local chance = (turns_since / 20) * 100

    if cm:random_number(100) <= chance then
        self:squeak_trigger_event()
    end
end

-- called each faction turn start - checks if there's a mission available to trigger, or if the first mission needs to be triggered, or if there's an available random event
function headtaking:squeak_random_shit_check()
    -- first time Squeak is having a mission!
    if self.squeak_mission_info.turns_since_last_mission == false then
        local found_factions = {}

        local queek_faction = cm:get_faction(self.faction_key)
        local known_factions = queek_faction:factions_met()
        for i = 0, known_factions:num_items() -1 do
            local known_faction = known_factions:item_at(i)
            if not queek_faction:at_war_with(known_faction) and not queek_faction:is_ally_vassal_or_client_state_of(known_faction) then
                -- don't add allies or current enemies to this list
                found_factions[#found_factions+1] = known_faction:name()
            end
        end

        if #found_factions > 0 then
            local mm = mission_manager:new(self.faction_key, "squeak_start")
            mm:set_mission_issuer("squeak")
            mm:add_new_objective("DECLARE_WAR")
            local faction_key = found_factions[cm:random_number(#found_factions)]
            mm:add_condition("faction "..faction_key)
            mm:add_payload("money 500")

            mm:trigger()

            self.squeak_mission_info.turns_since_last_mission = cm:model():turn_number()
            self.squeak_mission_info.current_mission = "squeak_start"
        else
            -- TODO trigger some backup mission?
        end

        return
    end

    -- if there's not a mission active, check if we should trigger one
    if self.squeak_mission_info.current_mission == "" then
        local this_turn = cm:model():turn_number()
        local that_turn = self.squeak_mission_info.turns_since_last_mission

        local turns_since = this_turn - that_turn

        local do_it = false

        -- 20;40;60;80;100% chance every turn since last mission completed
        if turns_since >= 5 then
            do_it = true
        else
            local chance = 20 * turns_since

            if cm:random_number(100) <= chance then
                do_it = true
            end
        end

        if do_it then
            self:squeak_trigger_mission()
        else
            -- if we're not triggering a mish this turn, check if we should do a random event
            self:squeak_trigger_event_test()
        end
    else -- if there's currently a mission, do a check to see if we should do a random event!
        self:squeak_trigger_event_test()
    end
end

-- this is where Squeak's random incessant requests are generated
function headtaking:squeak_random_shit()
    -- if there's a mission already active, check if it's a scripted one and start the listener, else do naught
    if self.squeak_mission_info.current_mission ~= "" then
        local mission_data = self:get_mission_with_key(self.squeak_mission_info.current_mission)

        -- start the listener for this mission, if there is one!
        if mission_data and mission_data.listener then
            mission_data.listener()
        end
    end

    -- there's not a mission already and it's not the first mission; check if there should be a mission triggered
    core:add_listener(
        "SqueakRandomEvent",
        "FactionTurnStart",
        function(context)
            return context:faction():name() == self.faction_key
        end,
        function(context)
            self:squeak_random_shit_check()
        end,
        true
    )
end

function headtaking:kill_char_with_cqi(cqi)
    if not is_number(cqi) then
        err("kill_char_with_cqi() called, but the cqi provided ["..tostring(cqi).."] is not a number!")
        return false
    end

    core:add_listener(
        "killed_charrie",
        "CharacterConvalescedOrKilled",
        function(context)
            return cqi == context:character():command_queue_index()
        end,
        function(context)
            cm:stop_character_convalescing(cqi)
        end,
        false
    )

    cm:kill_character(cqi, false, true)
end

function headtaking:set_legendary_head_mission_info_to_new_stage(head_key, stage_num, trigger_encounter)
    if not is_string(head_key) then
        err("set_legendary_head_mission_info_to_new_stage() called but the head_key provided ["..tostring(head_key).."] is not a string!")
        return false
    end

    if not is_number(stage_num) then
        err("set_legendary_head_mission_info_to_new_stage() called but the stage_num provided ["..tostring(stage_num).."] is not a number!")
        return false
    end

    local mission_info = self.legendary_mission_info[head_key]
    if not mission_info then
        err("set_legendary_head_mission_info_to_new_stage() called but the head_key provided ["..tostring(head_key).."] does not have any mission info saved!")
        return false
    end

    local head_obj = self.legendary_heads[head_key]
    if not head_obj then
        err("set_legendary_head_mission_info_to_new_stage() called but the head_key provided ["..tostring(head_key).."] does not have any legendary information!")
        return false
    end

    -- if this is a QB faction, we have to set the stage to the end of the chain 
    local _, is_qb = self:get_faction_key_for_legendary_head(head_key)
    if is_qb then
        -- push this to the final step in the mission chain
        stage_num = #head_obj.mission_chain
    end

    mission_info.mission_key = ""
    mission_info.tracker = nil
    mission_info.stage = stage_num

    self:trigger_legendary_head_mission(head_key, stage_num, trigger_encounter)
end

function headtaking:get_faction_key_for_legendary_head(head_key)
    if not is_string(head_key) then
        err("get_faction_key_for_legendary_head() called, but the head_key provided ["..tostring(head_key).."] is not a string!")
        return false, false
    end
    
    local legendary_obj = self.legendary_heads[head_key]
    if not legendary_obj then
        err("get_faction_key_for_legendary_head() called, but the head_key provided ["..tostring(head_key).."] is not a valid legendary head!")
        return false, false
    end

    local is_qb = false
    
    local faction_key = legendary_obj.faction_key
    local faction_obj = cm:get_faction(faction_key)
    if not faction_obj or faction_obj:is_dead() then
        faction_key = legendary_obj.backup_faction_key
        faction_obj = cm:get_faction(faction_key)
        is_qb = true
        if not faction_obj then
            err("get_faction_key_for_legendary_head() called, but the head_key provided ["..tostring(head_key).."] does not have a valid faction saved! Tried ["..tostring(legendary_obj.faction_key).."] and ["..tostring(legendary_obj.backup_faction_key).."].")
            return false, false
        end
    end

    return faction_key, is_qb
end

function headtaking:generate_leghead_force(head_key)
    if not is_string(head_key) then
        err("generate_leghead_force() called, but the head_key provided ["..tostring(head_key).."] is not a valid string!")
        return false
    end

    local encounter_tab = self.legendary_encounters[head_key]
    if not encounter_tab then
        err("generate_leghead_force() called, but the head_key provided ["..tostring(head_key).."] does not have an encounter attached!")
        return false
    end

    -- TODO, in the future use better and more personalized armies. For now, just fucking take the vanilla templates from the random army manager
    -- local force = random_army_manager:new_force(head_key)

    -- local mandatory = encounter_tab["mandatory"]
    -- local random = encounter_tab["random"]

    local template_key = "wh_main_sc_dwf_dwarfs"

    if head_key == "legendary_head_skarsnik" then
        template_key = "wh_main_sc_grn_greenskins"
    elseif head_key == "legendary_head_tretch" then
        template_key = "wh2_main_sc_skv_skaven"
    end

    local num_units = self:get_queek():military_force():unit_list():num_items()
    num_units = cm:random_number(num_units+5, num_units-5)

    if num_units > 20 then num_units = 20 end
    if num_units < 10 then num_units = 10 end

    -- take the turn number and change it into a value between 1-10 (for the "power" bit in the random army manager)
    -- assumes 1 is turn 1 and assumes 10 is turn >140
    -- turn 140 is taken from the chaos invasion full inv
    local function normalize_power_for_turn_number()
        local val = cm:model():turn_number()

        -- the OG values to clamp between (ie. scale numbers equally between 1-140 for the normalization)
        local pre_min = 1
        local pre_max = 140

        -- the printed values to clamp between (ie. result is between 1-10)
        local new_min = 1
        local new_max = 10

        local new_val = math.ceil(new_min + (val - pre_min) * (new_max - new_min) / (pre_max - pre_min))

        -- clamp, in case the turn number is greater than 140
        if new_val > new_max then new_val = new_max end
        if new_val < new_min then new_val = new_min end

        return new_val
    end

    local power = normalize_power_for_turn_number()

    log("Generating force for "..head_key..", with template_key ["..template_key.."], num_units ["
    ..num_units.."], and power ["..power.."].")

    local force_list = WH_Random_Army_Generator:generate_random_army(head_key.."_encounter", template_key, num_units, power, false, false)

    return force_list
end

-- this tracks the current LL missions (initialized through Squeak Init if it's over stage 1)
function headtaking:track_legendary_heads()
    local legendary_heads = self.legendary_heads

    -- check for completion of any legendary head missions
    core:add_listener(
        "LegendaryHeadMissionCompleted",
        "MissionCompleted",
        function(context)
            return string.find(context:mission():mission_record_key(), "legendary_head_")
        end,
        function(context)
            local mission = context:mission()
            local mission_key = mission:mission_record_key()

            local head_key
            local stage

            -- check all the mission infos to determine which head this mission is attached to
            local legendary_mission_infos = self.legendary_mission_info
            for mission_head_key, mission_info in pairs(legendary_mission_infos) do
                if mission_info.mission_key == mission_key then
                    head_key = mission_head_key
                    stage = mission_info.stage
                end
            end

            if not head_key then
                err("LegendaryHeadMissionCompleted triggered, but no head_key was found for the mission with key ["..mission_key.."]")
                return false
            end

            local legendary_obj = self.legendary_heads[head_key]

            local mission_chain = legendary_obj.mission_chain
            local mission_obj = mission_chain[stage]

            -- trigger any end-function if any are set
            if mission_obj.end_func then
                local f = loadstring(mission_obj.end_func)
                setfenv(f, core:get_env())
                f(self, head_key)
            end

            -- reward the head if it's the last mission of this chain
            if stage == #mission_chain then
                -- TODO add details! (somehow???)
                local details = {}
                details.faction_key = legendary_obj.faction_key
                details.subtype = legendary_obj.subtype_key
                details.turn_number = cm:model():turn_number()

                -- local details = {
                --     subtype = subtype_key,
                --     forename = forename,
                --     surname = surname,
                --     flag_path = flag_path,
                --     faction_key = faction_key,
                --     level = level,
                --     region_key = region_key,
                --     turn_number = turn_number,
                -- }

                -- permakill the lord
                do
                        
                    local faction_key = self:get_faction_key_for_legendary_head(head_key)
                    if faction_key then
                        local faction = cm:get_faction(faction_key)

                        local faction_leader = faction:faction_leader()
                        if faction_leader:character_subtype(legendary_obj.subtype_key) then
                            self:kill_char_with_cqi(faction_leader:command_queue_index())
                        end
                    end
                end

                -- add the ancillary to Queek
                local queek = self:get_queek()
                cm:force_add_ancillary(
                    queek,
                    head_key,
                    true,
                    false
                )

                -- -- add the perma effect to Queek
                -- local eb = legendary_obj.eb_key
                -- if is_string(eb) and eb ~= "" then
                --     -- grab the Queeker character and give him the free EB
                --     local queek = self:get_queek()

                --     cm:apply_effect_bundle_to_character(eb, queek, -1)
                -- end

                self:add_head_with_key(head_key, details)

                core:trigger_custom_event("HeadtakingLegendaryHeadRetrieved", {headtaking=self, head_key=head_key})

                -- clear out legendary mish info?
                self.legendary_mission_info = {}

                return
            end

            -- trigger the next mission
            local next_stage = stage+1

            self:set_legendary_head_mission_info_to_new_stage(head_key, next_stage)
        end,
        true
    )

    local function get_head_key_from_encounter_key(encounter_key)
        if not is_string(encounter_key) then
            return ""
        end

        -- remove the "_encounter" suffix on the marker keys, to return the head key
        return string.gsub(encounter_key, "_encounter", "")
    end

    -- check interaction with any Legendary Head encounters
    core:add_listener(
        "HeadtakingLegendaryEncounterInteracted",
        "HeadtakingLegendaryEncounterInteracted",
        function(context)
            return context:character():character_subtype(self.queek_subtype)
        end,
        function(context)
            log("Queek interacted with the leghead encounter")
            local head_key = get_head_key_from_encounter_key(context:table_data().marker_ref)
            log("Head key: "..head_key)
            local head_info = self.legendary_heads[head_key]

            cm:callback(function()
                -- grab the faction key (backup for factions that don't exist on Vor)
                local faction_key = self:get_faction_key_for_legendary_head(head_key)
                if not faction_key then
                    log("no faction found, in real or backup!")
                    return false
                end

                log("Spawning force for faction: " .. faction_key)

                local ok, err = pcall(function()

                -- grab the subtype key of the lord
                local subtype_key = head_info.subtype_key
                local forename_key = head_info.forename_key
                local surname_key = head_info.surname_key
                
                -- spawn the general at Queek's level!
                local queek = context:character()
                local level = queek:rank()

                -- we know that queek has a military force since queek is the character who is here
                local mf_cqi = queek:military_force():command_queue_index()

                local force_key = head_key.."_encounter"
                local force_list = self:generate_leghead_force(head_key)

                -- spawn a force for this faction (Forced_Battle_Manager)
                local fb = Forced_Battle_Manager:setup_new_battle(force_key)
                fb:add_new_force(force_key, force_list, faction_key, true, nil, subtype_key, level)
                fb:set_names_for_force(force_key, forename_key, surname_key)

                -- set a couple events to trigger, if Queeker wins or Queeker loses
                fb:set_post_battle_script_event("HeadtakingLegendaryHeadBattleWon", "defender_victory")
                fb:set_post_battle_script_event("HeadtakingLegendaryHeadBattleLost", "attacker_victory")

                local x,y = queek:logical_position_x(), queek:logical_position_y()
                local ox,oy = x,y

                -- local num_done = 0

                -- local function find_location()
                --     num_done = num_done + 1
                --     log("finding location, loop "..num_done)

                --     if num_done >= 15 then
                --         log("max loop, returning "..ox.." "..oy)
                --         return ox,oy
                --     end

                --     local ix,iy = x,y

                --     x,y = cm:find_valid_spawn_location_for_character_from_position(
                --         faction_key,
                --         x,
                --         y,
                --         true
                --     )

                --     log("Found ("..x..", "..y..")")

                --     if x == -1 then
                --         log("Invalid, trying again")
                --         x = ix + cm:random_number(2, -2)
                --         y = iy + cm:random_number(2, -2)
                --         log("Passing forward ("..x..", "..y..")")
                --         return find_location()
                --     end

                --     return x,y
                -- end

                -- local new_x,new_y = find_location()
            
                -- spawn above force to attack Queek
                fb:trigger_battle(force_key, mf_cqi, ox, oy, false, true)

                end) if not ok then log(err) end
            end, 0.5)
        end,
        true
    )

    -- triggered if the encounter is timed out or if the encounter battle is lost
    -- lose the active mission; allow the vanilla LL to respawn; return to the first mission in the chain
    local function you_failed(head_key, is_timeout)
        local head_obj = self.legendary_heads[head_key]
        if not head_obj then
            err("Mission failure triggered for ["..tostring(head_key).."], but there's no head_obj attached to that head key?")
            return false
        end
        
        local mission_info = self.legendary_mission_info[head_key]
        local mission_key = mission_info.mission_key

        -- fail the mission
        cm:complete_scripted_mission_objective(mission_key, mission_key, false)

        -- respawn the vanilla lord, if there be one
        local faction_key, is_qb = self:get_faction_key_for_legendary_head(head_key)
        if faction_key and not is_qb then
            local faction_obj = cm:get_faction(faction_key)
            local faction_leader = faction_obj:faction_leader()

            if not faction_leader:is_null_interface() then
                cm:stop_character_convalescing(faction_leader:command_queue_index())
            end
        end

        -- trigger a message event to inform the player of their absolute fuck up
        local event_feed_string = "event_feed_strings_text_legendary_head_encounter_failed"
        if is_timeout then
            event_feed_string = "event_feed_strings_text_legendary_head_encounter_timeout"
        end

        cm:show_message_event(
            self.faction_key,
            event_feed_string.."_title",
            event_feed_string.."_primary_detail",
            event_feed_string.."_secondary_detail",
            true,
            667
        )

        -- start the first mission once more
        self:set_legendary_head_mission_info_to_new_stage(head_key, 1)
    end

    -- check if a Leghead encounter has timed out - if it has, return to square 1 for this chain
    core:add_listener(
        "HeadtakingLegendaryEncounterTimeout",
        "HeadtakingLegendaryEncounterTimeout",
        true,
        function(context)
            local head_key = get_head_key_from_encounter_key(context:table_data().area_key)

            -- cancel the active mission here and return to the first step!
            you_failed(head_key, true)
        end,
        true
    )

    -- check if a Leghead encounter was lost - ditto, return to square 0
    core:add_listener(
        "HeadtakingLegendaryHeadBattleLost",
        "HeadtakingLegendaryHeadBattleLost",
        true,
        function(context)
            log("Headtaking Legendary Head Battle Lost")
            local encounter_key = context:forced_battle_key()
            local head_key = get_head_key_from_encounter_key(encounter_key)

            -- cancel the active mission here and return to the first step
            you_failed(head_key)

            -- destroy the invasion
            local inv = invasion_manager:get_invasion(encounter_key)
            if inv then
                log("Inv found")
                inv:kill()
                log("Killed")
                invasion_manager:remove_invasion(encounter_key)
                log("Removed")
            end  
        end,
        true
    )

    -- check if the battle was won! Win the mission and do other stuff.
    core:add_listener(
        "HeadtakingLegendaryHeadBattleWon",
        "HeadtakingLegendaryHeadBattleWon",
        true,
        function(context)
            log("HeadtakingLegendaryHeadBattleWon")
            local encounter_key = context:forced_battle_key(0)
            -- local head_key = get_head_key_from_encounter_key(encounter_key)

            -- win the mission! The rest of the stuff is handled elsewhere
            cm:complete_scripted_mission_objective(encounter_key, encounter_key, true)
        end,
        true
    )

    -- check if the HeadtakingEncounterTrigger event is called, to delay the encounters on Vortex to space them out a bit
    core:add_listener(
        "HeadtakingEncounterTrigger",
        "HeadtakingEncounterTrigger",
        true,
        function(context)
            local head_key = context.string

            -- this is automatically set to the encounter within this function
            self:set_legendary_head_mission_info_to_new_stage(head_key, 1, true)
        end,
        true
    )

    -- check stages of each legendary head - if it's stage 0, check the prereq; if it's beyond that, trigger any necessary listeners
    for head_key,obj in pairs(legendary_heads) do

        -- initalize the mission_info table if it hasn't been yet
        if not self.legendary_mission_info[head_key] then self.legendary_mission_info[head_key] = {stage=0, mission_key = "", tracker = nil} end

        -- if the relevant targeted faction is a human, cancel this shit
        local faction_key = self:get_faction_key_for_legendary_head(head_key)
        if faction_key then
            local faction_obj = cm:get_faction(faction_key)

            -- only against targeted AI faction
            if not faction_obj:is_human() then
                local mission_info = self.legendary_mission_info[head_key]

                -- if it's the pre-stage (0), then initialize the pre-requisite listener
                if mission_info.stage == 0 then
                    -- the "prerequisite" field in script/headtaking/legendary_heads.lua
                    local prereq = obj.prerequisite
        
                    if prereq then
                        core:add_listener(
                            prereq.name,
                            prereq.event_name,
                            prereq.conditional,
                            function(context)
                                -- trigger first stage (1)
                                self:set_legendary_head_mission_info_to_new_stage(head_key, 1)
                            end,
                            false
                        )
                    else
                        -- trigger first stage right away
                        self:set_legendary_head_mission_info_to_new_stage(head_key, 1)
                    end
                else
                    -- trigger any necessary listeners for this stage
                    local mission_chain = obj.mission_chain
                    local mission = mission_chain[mission_info.stage]
        
                    self:initialize_legendary_head_listener(mission, head_key)
                end
            end
        end
    end
end

function headtaking:initialize_legendary_head_listener(mission_obj, head_key)
    local mission_info = self.legendary_mission_info[head_key]

    -- grab the mission obj for the generated mission
    if mission_obj.key == "GENERATED" then
        local mission_key = mission_info.mission_key

        if not is_string(mission_key) then
            err("initialize_legendary_head_listener() called for a generated mission, but the mission key was not saved in the mission info! Returning early.")            
            return false
        end

        -- grab the mission from the default legendary_missions table (for the current stage)
        local legendary_missions = self.legendary_missions[mission_info.stage]

        for i = 1, legendary_missions do
            local mish = legendary_missions[i]
            if mish.key == mission_key then
                mission_obj = mish
            end
        end

        if mission_obj.key == "GENERATED" then
            err("initialize_legendary_head_listener() called for a generated mission, but no mission was found in the legendary missions file? Returning early.")
            return false
        end
    end

    local listener = mission_obj.listener

    if is_string(listener) then
        listener = loadstring(listener)
        setfenv(listener, core:get_env())
    end

    if is_function(listener) then
        listener = listener(self, head_key)
    end

    if is_table(listener) then
        core:add_listener(
            listener.name,
            listener.event_name,
            listener.conditional,
            listener.callback,
            listener.persistence or false
        )
    end
end

function headtaking:construct_mission_from_data(data, head_key, stage_num)
    log("Constructing mission from data, for head ["..head_key.."] during stage ["..tostring(stage_num).."].")
    log("Mission key is "..data.key)
    -- save the current stage in storage
    local legendary_mission_info = self.legendary_mission_info[head_key]

    -- save the stage num and mission key to grab them later on
    legendary_mission_info.stage = stage_num
    legendary_mission_info.mission_key = data.key

    -- nil out the tracker (used for counting objectives like "defeat 3 armies") so there's no false positives
    legendary_mission_info.tracker = nil

    -- trigger the constructor if there is one
    if is_string(data.constructor) then
        data.constructor = loadstring(data.constructor)
        setfenv(data.constructor, core:get_env())
    end

    if is_function(data.constructor) then
        log("Constructing!")
        data = data.constructor(data, self, head_key)

        if not data then
            log("Constructor failed D:")
            return false
        end
    end

    -- use the mission_manager to do all the heavy lifting of constructing the mission string
    local mission = mission_manager:new(self.faction_key, data.key)

    mission:add_new_objective(data.objective)
    log("Objective added "..data.objective)
    
    mission:set_mission_issuer("squeak")

    if not is_table(data.condition) then data.condition = {data.condition} end
    for i = 1, #data.condition do
        local condition = data.condition[i]
        mission:add_condition(condition)
        log("Condition added "..condition)
    end

    mission:add_payload(data.payload)
    log("Payload added "..data.payload)

    mission:trigger()

    log("trigger'd")

    -- if there's a start func for whatever reason, call it!
    if data.start_func then
        local f = loadstring(data.start_func)
        setfenv(f, core:get_env())

        f(self, head_key)
        log("Start func'd")

        -- data.start_func(self, head_key)
    end

    -- trigger any listener releated
    local listener = data.listener

    local ok, err = pcall(function()

    if is_string(listener) then
        listener = loadstring(listener)
        setfenv(listener, core:get_env())
    end

    if is_function(listener) then
        listener = listener(self, head_key)
        log("Listener func'd")
    end

    if is_table(listener) then
        log("Listener'd")
        core:add_listener(
            listener.name,
            listener.event_name,
            listener.conditional,
            listener.callback,
            listener.persistence or false
        )
    end
end) if not ok then log(err) end
end

local function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- subloop is increased through the inner call of trigger_random - will only go up subloop_max times.
-- subloop reduced to 0 on a successful call or on the end of the loop
local subloop = 0
local subloop_max = 5

function headtaking:trigger_random_legendary_head_mission_at_stage(head_key, stage_num)
    if subloop >= 5 then
        err("trigger_random_legendary_head_mission_at_stage() called, but the loop to find a valid mission has failed. Called for ["..head_key.."] at stage ["..tostring(stage_num).."].")

        -- refresh the stage and mission info?
        self:set_legendary_head_mission_info_to_new_stage(head_key, stage_num)
        subloop = 0
        return
    end

    local legendary_missions = self.legendary_missions

    local stage_missions = legendary_missions[stage_num]

    if not is_table(stage_missions) or #stage_missions < 1 then
        err("trigger_random_legendary_head_mission_at_stage() called for head ["..tostring(head_key).."] at stage ["..tostring(stage_num).."] - there's no mission available at this stage! Returning early.")
        return false
    end

    -- TODO maybe later on have this be a weighted random, to prevent the same mission being picked several times

    -- randomly pick one of the missions at this stage
    local mission = stage_missions[cm:random_number(#stage_missions)]

    -- copy the reference (so we don't override the table in self.legendary_missions)
    local data = deepcopy(mission)

    -- check if there's already a mission (or more) with this key active, and then iterate the key suffix one more (max of 3)
    local highest_append = self:is_legendary_head_mission_active(data.key)
    if highest_append then
        if highest_append == 3 then
            -- find another mission?
            -- prevent infi loop
            subloop = subloop + 1
            self:trigger_random_legendary_head_mission_at_stage(head_key, stage_num)
            return
        else
            -- append +1
            data.key = data.key .. "_" .. tostring(highest_append + 1)
        end
    else
        -- append "_1" to the end
        data.key = data.key .. "_1"
    end

    subloop = 0

    log("relevant mission key: "..mission.key)
    log("copied mission key: "..data.key)

    -- change the override_text field to be override_text..head_key, for proper localisation
    if is_table(data.condition) then
        for i = 1, #data.condition do
            local condition = data.condition[i]
            if string.find(condition, "override_text") then
                -- changes "legendary_head_1_raid" to "legendary_head_1_raid_legendary_head_belegar", wow that sucks. TODO make this suck less prolly?
                data.condition[i] = condition .. "_" .. head_key
            end
        end
    end

    -- construct and trigger that shit
    self:construct_mission_from_data(data, head_key, stage_num)
end

-- check if there is any random-gen'd mission with this key active; return false, or the highest number appended if any are found
function headtaking:is_legendary_head_mission_active(mission_key)
    local mission_infos = self.legendary_mission_info

    local highest_append = 0

    for _, mission_info in pairs(mission_infos) do
        local key = mission_info.mission_key

        if string.find(key, mission_key) then
            -- grab the end of the mission key (ie. "legendary_head_1_raid_1" will return "1")
            local append = tonumber(string.sub(key, -1, -1))
            if append > highest_append then
                highest_append = append
            end
        end
    end

    if highest_append == 0 then return false else return highest_append end
end

-- this is tracked automagically through the interactive marker stuff
-- spawn the interactable marker, start the mission, and begin the backend tracking for shit
function headtaking:trigger_legendary_head_encounter(head_key, mission_obj, stage_num)
    if not is_string(head_key) then
        err("trigger_legendary_head_encounter() called, but the head_key provided ["..tostring(head_key).."] is not a valid string!")
        return false
    end

    if not is_table(mission_obj) then
        err("trigger_legendary_head_encounter() called, but the mission_obj provided ["..tostring(mission_obj).."] is not a valid table!")
        return false
    end

    local encounter_key = mission_obj.key

    if not is_string(encounter_key) then
        err("trigger_legendary_head_encounter() called, but the mission_obj provided doesn't have a valid key ["..tostring(encounter_key).."].")
        return false
    end

    local legendary_obj = self.legendary_heads[head_key]
    if not legendary_obj then
        err("trigger_legendary_head_encounter() called, but the head_key provided ["..head_key.."] isn't a valid legendary head!")
        return false
    end

    -- grab the relevant faction object (wrapper validates that it exists, and checks the QB backup faction)
    local faction_key, is_qb = self:get_faction_key_for_legendary_head(head_key)
    if not faction_key then
        return err("trigger_legendary_head_encounter() called for head ["..head_key.."], but there's no faction found for this legendary head!")
    end

    -- grab Queek and find a suitable spawn location for him
    local queek = self:get_queek()

    -- find the spawn coordinates for the interactable marker (10 hex from Queek, or Queek's Capital as fallback)
    local x,y

    -- grab the enemy faction and remove their faction leader from the map
    if not is_qb then
        local faction_obj = cm:get_faction(faction_key)
        local faction_leader = faction_obj:faction_leader()

        if not faction_leader:is_null_interface() then
            -- if they're wounded, unwound them and rewound them?
            if faction_leader:is_wounded() then
                cm:stop_character_convalescing(faction_leader:command_queue_index())
            end

            cm:callback(function()
                -- wound for 100 turns. Revived or killed after the Encounter battle
                cm:wound_character("character_cqi:"..faction_leader:command_queue_index(), 100, false)
            end, 0.1)
        end
    else
        if not trigger_encounter then
            -- delay the encounter by 5-10 turns
            cm:add_turn_countdown_event(self.faction_key, cm:random_number(10, 5), "HeadtakingEncounterTrigger", head_key)
            return
        end
    end

    -- if there's no Queek, or Queek is at sea, spawn the encounter by the capital
    if not queek or not queek:has_military_force() or queek:is_at_sea() then
        local capital = cm:get_faction(self.faction_key):home_region()
        if capital:is_null_interface() then
            -- I literally don't know what to do here
            err("trigger_legendary_head_encounter() called, but Queek isn't found and neither is Queek's capital! Dunno at all what to do here, so we're just stopping.")
            return
        end

        local region_key = capital:name()

        x,y = cm:find_valid_spawn_location_for_character_from_settlement(
            faction_key,
            region_key,
            false,
            true,
            10
        )
    else
        x,y = cm:find_valid_spawn_location_for_character_from_character(
            faction_key,
            "character_cqi:"..queek:command_queue_index(),
            true,
            10
        )
    end

    if not x or x == -1 then
        err("trigger_legendary_head_encounter() called, but no valid spawn location found for the encounter!")
        return false
    end

    -- create an interactive marker obj
    local encounter_marker = Interactive_Marker_Manager:new_marker_type(
        encounter_key,
        encounter_key,
        5,
        1,
        self.faction_key,
        "",
        true
    )

    -- trigger this script event if the marker is not encountered within its duration
    encounter_marker:add_timeout_event("HeadtakingLegendaryEncounterTimeout")

    -- trigger this script event when the marker is encountered
    encounter_marker:add_interaction_event("HeadtakingLegendaryEncounterInteracted")
    
    encounter_marker:is_persistent(false)

    local event_feed_prefix = "event_feed_strings_text_"
    local spawn_event_prefix = event_feed_prefix .. encounter_key
    local timeout_event_prefix = event_feed_prefix .. "legendary_head_encounter_timeout"

    -- add the event feed stuff for the marker being triggered and for the marker being lost
    encounter_marker:add_spawn_event_feed_event(
        spawn_event_prefix.. "_title",
        spawn_event_prefix .. "_primary_detail",
        spawn_event_prefix .. "_secondary_detail",
        668,
        self.faction_key
    )

    encounter_marker:add_despawn_event_feed_event(
        timeout_event_prefix.. "_title",
        timeout_event_prefix .. "_primary_detail",
        timeout_event_prefix .. "_secondary_detail",
        668,
        self.faction_key
    )

    -- spawn the marker on the map (at the previously determined location)
    encounter_marker:spawn_at_location(
        x,
        y,
        false,
        true,
        0
    )

    -- trigger the mission itself
    self:construct_mission_from_data(mission_obj, head_key, stage_num)

    -- set the zoom-to location onto the encounter!
    cm:set_scripted_mission_position(encounter_key, encounter_key, x, y)
end

-- trigger individual missions in each legendary head chain
-- if no stage is provided, it defaults to 1 to start it off
function headtaking:trigger_legendary_head_mission(head_key, stage_num, trigger_encounter)
    if not is_string(head_key) then
        err("trigger_legendary_head_mission() called, but the head_key provided ["..tostring(head_key).."] is not a valid string!")
        return false
    end

    if not is_number(stage_num) then stage_num = 1 end

    -- check if there's already a mission active for this leghead; if there is, skip
    local current_key = self.legendary_mission_info[head_key].mission_key

    if is_string(current_key) and current_key ~= "" then
        err("trigger_legendary_head_mission() called for head ["..head_key.."], but there's already a mission active ["..current_key.."].")
        return
    end
    
    local legendary_obj = self.legendary_heads[head_key]
    local mission_chain = legendary_obj.mission_chain
    local mission_obj = mission_chain[stage_num]
    
    if not mission_obj then
        err("trigger_legendary_head_mission() called for head ["..head_key.."] at stage ["..tostring(stage_num).."], but there's no mission available at that stage!")
        return false
    end
    
    -- pick a mission for this stage from a list, if it's a generated mission
    if mission_obj.key == "GENERATED" then
        -- construct this mission elsewhere
        return self:trigger_random_legendary_head_mission_at_stage(head_key, stage_num)
    end

    -- check if it's an encounter and handle that elsewhere
    if string.find(mission_obj.key, "_encounter") then
        return self:trigger_legendary_head_encounter(head_key, mission_obj, stage_num, trigger_encounter)
    end

    self:construct_mission_from_data(mission_obj, head_key, stage_num)
end

-- this is called when Squeak is propa upgraded
-- only triggered once per level, obvo
function headtaking:squeak_upgrade(new_level)
    local faction = cm:get_faction(self.faction_key)
    local queek = faction:faction_leader()

    if new_level > 1 then
        -- remove the old fuck
        cm:force_remove_ancillary(
            queek,
            "squeak_stage_"..tostring(self.squeak_stage),
            false,
            true
        )
    end

    self.squeak_stage = new_level

    cm:force_add_ancillary(
        queek,
        "squeak_stage_"..tostring(new_level),
        true,
        false
    )

    -- trigger incident for "hey, you got this fucker" / upgrade
    cm:trigger_incident(self.faction_key, "squeak_stage_"..tostring(new_level), true)

    self:squeak_init()

    core:trigger_custom_event("HeadtakingSqueakUpgrade", {headtaking=self, stage=self.squeak_stage})
end

function headtaking:squeak_init(new_stage)
    if is_number(new_stage) then
        self.squeak_stage = new_stage
    end

    log("Squeak init!")
    local stage = self.squeak_stage
    log("Stage is "..tostring(stage))

    if stage >= 1  then
        -- check whenever a Squeak mish is completed
        core:add_listener(
            "QueekSqueakCompleaked",
            "MissionSucceeded",
            function(context)
                return context:mission():mission_record_key():find("squeak") and context:faction():is_human() and context:faction():name() == self.faction_key
            end,
            function(context)
                local completed_mission = context:mission():mission_record_key()

                self.squeak_mission_info.current_mission = ""
                self.squeak_mission_info.turns_since_last_mission = cm:model():turn_number() 
                self.squeak_mission_info.num_missions = self.squeak_mission_info.num_missions + 1

                core:trigger_custom_event("HeadtakingSqueakMissionCompleted", {headtaking = self, mission=completed_mission, num_missions = self.squeak_mission_info.num_missions})
            end,
            true
        )
    end

    -- first stage, Squeak is unacquired - guarantee his aquisition the next head taken
    if stage == 0 then
        core:add_listener(
            "AddSqueakPls",
            "HeadtakingCollectedHead",
            function(context)
                log("Checking if Squeak add do")
                local total_heads = self.total_heads
                local chance = 0
                log("Current total heads: "..tostring(total_heads))
                
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

                log("ran calc'd is: "..tostring(ran))

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
                self:squeak_upgrade(1)

                core:remove_listener("AddSqueakPls")
            end,
            true
        )
    elseif stage == 1 then
        -- Squeak acquired, and begins asking for inane shit
        self:squeak_random_shit()

        -- after a mission or two, go up
        core:add_listener(
            "SqueakStage2",
            "HeadtakingSqueakMissionCompleted",
            function(context)
                return context:num_missions() == 2
            end,
            function(context)
                -- local completed_mission = context:mission()

                self:squeak_upgrade(2)
            end,
            false
        )
    elseif stage == 2 then
        -- Squeak informs about Legendary Heads (name pending!), and continues asking for inane shit
        self:squeak_random_shit()

        -- LL missions are triggered within the LL mission setup, actually, so nothing else needs doing here
    elseif stage == 3 then
        -- Squeak upgrades
        self:squeak_random_shit()
        
        -- Squeak asks of you to conquer K8P finally and settle down, papa
        -- TODO add in mission to reconquista K8P / whatever the Vortex requirement should be
    elseif stage == 4 then
        -- After K8P conquer, Squeak demands of wildly wild shit
        self:squeak_random_shit()

        -- eventually, Squeak gets caught speaking to Queek's heads secretly, resulting in his fucking death, fuck that guy.
    elseif stage == 5 then
        -- dead
    end
end

-- count & save the number of legendary heads thusfar obtained
function headtaking:init_count_heads()
    local faction_obj = cm:get_faction(self.faction_key)

    -- self.legendary_heads_num = 0

    local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)

    local legendary_heads = self.legendary_heads

    -- first, weirdly, we have to loop through the leghead table here and check if any faction within is human played
    -- if they are, remove them
    -- if they aren't, add up the legendary head num total and amount

    local total = 0
    for key,_ in pairs(legendary_heads) do
        local cont = true
        local faction_key = self:get_faction_key_for_legendary_head(key)

        if not faction_key then
            -- remove it
            self.legendary_heads[key] = nil
            cont = false
        end

        local inner_faction_obj = cm:get_faction(faction_key)
        if not inner_faction_obj or inner_faction_obj:is_human() then
            -- remove it
            self.legendary_heads[key] = nil
            cont = false
        end

        if cont then
            total = total + 1

            if faction_cooking_info:is_ingredient_unlocked(key) then
                self.legendary_heads_num = self.legendary_heads_num + 1
            end
        end
    end

    self.legendary_heads_max = total

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

function headtaking:initialize_listeners()
    -- faction start for checking duration & refreshing UI
    core:add_listener(
        "queek_turn_start",
        "FactionTurnStart",
        function(context)
            return context:faction():name() == self.faction_key
        end,
        function(context)
            -- check & kill any recipes that are due for killing
            local duration = self:get_duration_of_current_dish()
            
            -- if the adjusted duration is all up, kill the current recipe
            if duration and duration <= 0 then
                cm:clear_active_cooking_recipe(cm:get_faction(self.faction_key))
            end

            -- refresh the header UI
            self:ui_refresh()
        end,
        true
    )

    -- next up, enable some 'eads to be gitted through battles
    core:add_listener(
        "queek_killed_someone",
        "CharacterConvalescedOrKilled",
        function(context)
            return self:can_get_head_from_event(context)
        end,
        function(context)
            log("queek killed someone")
            local killed_character = context:character()
            local queek_faction = cm:get_faction(self.faction_key)
            if not queek_faction or queek_faction:is_null_interface() then
                return false
            end

            local queek = queek_faction:faction_leader()

            local rand = cm:random_number(100, 1)

            local chance = self:get_headtaking_chance(killed_character)

            local killed_faction = killed_character:faction()

            -- grant an extra set of free heads if Queek has destroyed an entire faction
            if killed_faction:is_dead() and self:has_squeak() then
                self:add_free_heads_from_subculture(killed_faction:subculture(), 3)
                return
            end

            if rand <= chance then
                self:add_head(killed_character, queek)
            end
        end,
        true
    )


    local queek_queests = {
        ["wh2_main_great_vortex_skv_queek_headtaker_warp_shard_armour_stage_6"] = true,
        ["wh2_main_great_vortex_skv_queek_headtaker_warp_shard_armour_stage_6_mpc"] = true,
        ["wh2_main_skv_queek_headtaker_warp_shard_armour_stage_6"] = true,
        ["wh2_main_skv_queek_headtaker_warp_shard_armour_stage_6_mpc"] = true,
        ["wh2_main_great_vortex_skv_queek_headtaker_dwarfgouger_stage_4"] = true,
        ["wh2_main_great_vortex_skv_queek_headtaker_dwarfgouger_stage_4_mpc"] = true,
        ["wh2_main_skv_queek_headtaker_dwarfgouger_stage_4"] = true,
        ["wh2_main_skv_queek_headtaker_dwarfgouger_stage_4_mpc"] = true,
    }

    -- listeners for the Queek Quests
    core:add_listener(
        "queek_quest_qompleted",
        "MissionSucceeded",
        function(context)
            -- check if it belongs in the list above
            local mission = context:mission()
            return queek_queests[mission:mission_record_key()]
        end,
        function(context)
            local key = context:mission():mission_record_key()

            local details = {}
            local head_key = ""

            details.turn_number = cm:model():turn_number()

            if string.find(key, "dwarfgouger") then
                details.subtype = "dwf_lord"
                details.forename = "names_name_2147345846"
                details.surname = "names_name_2147358994"

                head_key = "generic_head_dwarf_beard"
            else
                details.subtype = "wh2_main_skv_warlord"
                details.forename = "names_name_2147360678"
                details.surname = "names_name_2147360732"

                head_key = "generic_head_skaven"
            end

            self:add_head_with_key(head_key, details)
        end,
        true
    )
end

function headtaking:unlock_slot_at_index(index)
    if not is_number(index) then
        err("unlock_slot_at_index() called, but the index provided ["..tostring(index).."] is not a number!")
        return false
    end

    local slot = self.slots[index]

    if not slot then
        err("unlock_slot_at_index() called at index ["..tostring(index).."], but there's no slot at that index! Highest index is: "..tostring(#self.slots))
        return false
    end

    if slot == "open" then
        err("unlock_slot_at_index() called at index ["..tostring(index).."], but that slot is already opened!")
        return false
    end

    -- unlock
    self.slots[index] = "open"

    local faction = cm:get_faction(self.faction_key)

    local cooking_interface = cm:model():world():cooking_system():faction_cooking_info(faction);
    local current_slots = cooking_interface:max_secondary_ingredients();
    
    -- add one more secondary ingredient (on the code side of shit)
    cm:set_faction_max_secondary_cooking_ingredients(faction, current_slots+1)
end

function headtaking:initialize_slot_unlocks()
    -- listen for 1 Leghead being obtained for the first slot unlock
    if self.slots[1] == "locked" then
        core:add_listener(
            "headtaking_slot_one",
            "HeadtakingLegendaryHeadRetrieved",
            true,
            function()
                self:unlock_slot_at_index(1)
            end,
            false
        )
    end

    if self.slots[4] == "locked" then
        -- listen for K8P being occupied in ME for the second slot unlock
        if cm:get_campaign_name() == "main_warhammer" then
            core:add_listener(
                "headtaking_slot_two",
                "RegionFactionChangeEvent",
                function(context)
                    local region = context:region()

                    return region:name() == "wh_main_eastern_badlands_karak_eight_peaks" and region:owning_faction():name() == self.faction_key
                end,
                function(context)
                    self:unlock_slot_at_index(4)
                end,
                false
            )
        else -- listen for Belegar & Skarsnik being trophy head'd for the second slot unlock
            core:add_listener(
                "headtaking_slot_two",
                "HeadtakingCollectedHead",
                function(context)
                    local head_key = context:head_key()
                    return string.find(head_key, "belegar") or string.find(head_key, "skarsnik")
                end,
                function()
                    local faction_obj = cm:get_faction(self.faction_key)

                    local belly = "legendary_head_belegar"
                    local skars = "legendary_head_skarsnik"
                    
                    local faction_cooking_info = cm:model():world():cooking_system():faction_cooking_info(faction_obj)
                    
                    -- if both belly and skars were obtained previously, unlock this SLOT
                    if faction_cooking_info:is_ingredient_unlocked(belly) and
                    faction_cooking_info:is_ingredient_unlocked(skars) then
                        self:unlock_slot_at_index(1)

                        core:remove_listener("headtaking_slot_two")
                    end
                end,
                true
            )
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
        log("setting up fresh heads")

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
        self:add_head_with_key("generic_head_high_elf", {}, true)

        local loc_prefix = "event_feed_strings_text_headtaking_intro_"

        -- trigger message about this shit ("hi, this is the mechanic, you have a rat head, enjoy")
        cm:show_message_event(
            self.faction_key,
            loc_prefix.."title",
            loc_prefix.."primary_detail",
            loc_prefix.."secondary_detail",
            true,
            667
        )

        -- setup the slots - 2 primary, and 0 secondary (until they're unlocked through play)
        cm:set_faction_max_primary_cooking_ingredients(faction_obj, 2)
        cm:set_faction_max_secondary_cooking_ingredients(faction_obj, 0)
    end

    log("Heads table: "..tostring(self.heads))

    self:init_count_heads()
    self:squeak_init()
    self:track_legendary_heads()

    self:initialize_listeners()
    self:initialize_slot_unlocks()
    
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

            -- do this 50ms later, for new states and what not
            -- refresh the UI for any necessary changes
            timed_callback(
                "ui_refresh",
                true,
                function()
                    self:ui_refresh()
                end,
                50
            )
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

function headtaking:get_duration_of_current_dish()
    local info = cm:model():world():cooking_system():faction_cooking_info(cm:get_faction(self.faction_key))

    if info:is_null_interface() then
        err("get_duration_of_current_dish() called, but there's no cooking info available? Big issue!")
        return false
    end

    local active_dish = info:active_dish()
    if not string.find(tostring(active_dish), "COOKING_DISH_SCRIPT_INTERFACE") then
        log("get_duration_of_current_dish() called, but there's no active dish right now!")
        return false
    end

    local key = active_dish:recipe()
    local duration = active_dish:remaining_duration()

    -- legendary recipes are 10 turns, regs are 5
    if string.find(key, "legendary_") then
        duration = duration - 5
    else
        duration = duration - 10
    end

    return tostring(duration)
end

-- this is called to refresh things like num_heads and the Collected Heads counter and what not
function headtaking:ui_refresh()
    if not cm:get_local_faction_name(true) == self.faction_key then
        return
    end

    self:ui_refresh_header()

    if is_uicomponent(find_uicomponent("queek_cauldron")) then
        local ok, err = pcall(function()
            self:set_head_counters()

            self:check_duration_in_ui()

        end) if not ok then log(err) end
    end
end

-- this refreshes the header, queek_headtaking, instead of the actual panel
function headtaking:ui_refresh_header()
    -- check & change the duration

    local header = find_uicomponent("layout", "resources_bar", "topbar_list_parent", "queek_headtaking")

    if not is_uicomponent(header) then
        log("Headtaking Header doesn't exist rn, yo!")
        return false
    end

    local duration_banner = find_uicomponent(header, "grom_dish_effect", "grom_dish_effect_number_holder", "grom_dish_effect_number")

    local duration = self:get_duration_of_current_dish()

    if not duration then
        -- no active dish rn, yo
        return false
    end

    duration_banner:SetStateText(tostring(duration))

    -- remove old listener and add new one for hover of current_dish
    core:remove_listener("headtaking_duration_header")

    core:add_listener(
        "headtaking_duration_header",
        "ComponentMouseOn",
        function(context)
            return (context.string == "grom_dish_effect" or context.string == "grom_dish_effect_number") and cm:get_local_faction_name(true) == self.faction_key
        end,
        function(context)
            repeat_callback(
                "check_tt_header", 
                function(context) 
                    return is_uicomponent(find_uicomponent("tooltip_trophy_rack"))
                end,
                function(context)
                    local tt = find_uicomponent("tooltip_trophy_rack")

                    local timer = find_uicomponent(tt, "active_dish", "timer_text")

                    local txt = string.format("Effects last for %d turns", duration)

                    timer:SetStateText(txt)

                    real_timer.unregister("check_tt_header")
                end,
                1
            )
        end,
        true
    )
end

-- check in the UI for the two "Effects last X turns" text blurbs being visible
function headtaking:poll_duration_in_ui()
    local function kill()
        real_timer.unregister("poll_in_ui")
        core:remove_listener("poll_in_ui")
    end

    -- make sure the polling isn't doubled up!
    kill()

    -- repeat these functions every 25ms
    local looper = 25

    repeat_callback(
        "poll_in_ui",
        function(context)
            local duration_uic_book = find_uicomponent("queek_cauldron", "recipe_book_holder", "recipe_book", "recipes_and_tooltip_holder", "recipes_and_tooltip_holder_beholder", "dish_tooltip", "tooltip_holder", "duration")
            local duration_uic_preview = find_uicomponent("queek_cauldron", "right_colum", "dish_effects_holder", "dish_effects", "duration")

            -- if both duration UIC's are off the screen, kill the polling
            if not is_uicomponent(duration_uic_book) and not is_uicomponent(duration_uic_preview) then
                kill()

                return false
            end

            if duration_uic_book:Visible() or duration_uic_preview:Visible() then
                return true
            end
        end,
        function(context)
            local duration_uic_book = find_uicomponent("queek_cauldron", "recipe_book_holder", "recipe_book", "recipes_and_tooltip_holder", "recipes_and_tooltip_holder_beholder", "dish_tooltip", "tooltip_holder", "duration")
            local duration_uic_preview = find_uicomponent("queek_cauldron", "right_colum", "dish_effects_holder", "dish_effects", "duration")

            if duration_uic_book:Visible() then
                -- check if the state text contains 15; if it does, change it
                local text = duration_uic_book:GetStateText()

                if string.find(text, "15") then
                    -- TODO vvvvv make sure this doesn't fuck up if Legendary recipes are unhidden later on!
                    -- assume that it's 5 turns, since Legendary recipes are hidden
                    text = string.gsub(text, "15", "5")

                    duration_uic_book:SetStateText(text)
                end
            end

            if duration_uic_preview:Visible() then
                local text = duration_uic_preview:GetStateText()

                if string.find(text, "15") then
                    -- TODO check the ingredient types to see if this is Legendary

                    -- for now, hard code that it's 5 turns, as well
                    text = string.gsub(text, "15", "5")

                    duration_uic_preview:SetStateText(text)
                end
            end
        end,
        looper
    )
end

-- change all duration references within the UI
function headtaking:check_duration_in_ui()
    -- establish polling within the UI for the "Effects last X turns" text blurbs
    self:poll_duration_in_ui()

    -- change all duration references within the UI, 
    local duration = self:get_duration_of_current_dish()

    if not duration then
        -- no current active dish
        return false
    end

    -- "Effects Duration" within the Recipe Book
    do
        local duration_uic = find_uicomponent("queek_cauldron", "recipe_book_holder", "recipe_book", "recipes_and_tooltip_holder", "recipes_and_tooltip_holder_beholder", "dish_tooltip", "tooltip_holder", "duration")
        
        local txt = duration_uic:GetStateText()
        txt = string.gsub(txt, "15", "5")

        duration_uic:SetStateText(txt)
    end

    -- "Effects Duration" within dish preview
    do
        local duration_uic = find_uicomponent("queek_cauldron", "right_colum", "dish_effects_holder", "dish_effects", "duration")

        local txt = duration_uic:GetStateText()
        txt = string.gsub(txt, "15", "5")

        duration_uic:SetStateText(txt)
    end

    -- duration banner in current_dish
    local timer = find_uicomponent("queek_cauldron", "right_colum", "dish_preview_holder", "current_dish_effect", "current_dish_effect_timer_holder", "grom_dish_effect_timer")
    timer:SetStateText(duration)

    -- "Effects last for" in current_dish tooltip
    core:remove_listener("headtaking_duration_panel")

    core:add_listener(
        "headtaking_duration_panel",
        "ComponentMouseOn",
        function(context)
            return context.string == "current_dish_effect" and cm:get_local_faction_name(true) == self.faction_key
        end,
        function(context)
            repeat_callback(
                "check_tt_header", 
                function(context)
                    return is_uicomponent(find_uicomponent("tooltip_trophy_rack")) 
                end,
                function(context)
                    local tt = find_uicomponent("tooltip_trophy_rack")

                    local timer = find_uicomponent(tt, "active_dish", "timer_text")

                    local txt = string.format("Effects last for %d turns", duration)

                    timer:SetStateText(txt)

                    real_timer.unregister("check_tt_header")
                end,
                1
            )
        end,
        true
    )
end

-- this sets the UI for the number of heads and their respective states and opacities
function headtaking:set_head_counters()
    local category_list = find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "ingredient_category_list")

    log("head 1")

    if not is_uicomponent(category_list) then
        err("set_head_counters() called, but the category list was not found!")
        return false
    end

    local list_box = find_uicomponent(category_list, "list_view", "list_clip", "list_box")

    for i = 0, list_box:ChildCount() -1 do
        local category = UIComponent(list_box:Find(i))
        local ingredient_list = UIComponent(category:Find("ingredient_list"))

        -- only count heads on non-Nemeses heads
        if not string.find(category:Id(), "nemeses") then
            for j = 0, ingredient_list:ChildCount() -1 do
                local ingredient = UIComponent(ingredient_list:Find(j))
                local id = ingredient:Id()

                -- skip the default ingredient UIC, "template_ingredient"
                if id ~= "template_ingredient" then
                    local num_label_address = ingredient:Find("num_heads")
                    local num_label

                    if not num_label_address then
                        -- create the number-of-heads label
                        num_label = core:get_or_create_component("num_heads", "ui/vandy_lib/number_label", ingredient)

                        -- resize them!
                        num_label:SetCanResizeWidth(true) num_label:SetCanResizeHeight(true)
                        num_label:Resize(num_label:Width() /2, num_label:Height() /2)
                        num_label:SetCanResizeWidth(false) num_label:SetCanResizeHeight(false)
                    else
                        num_label = UIComponent(num_label_address)
                    end

                    num_label:SetStateText("0")
                    num_label:SetTooltipText("Number of Heads", true)
                    num_label:SetDockingPoint(3)
                    num_label:SetDockOffset(0, 0)
    
                    num_label:SetVisible(false)
            

                    local ingredient_key = string.gsub(id, "CcoCookingIngredientRecord", "")
                    local head_obj = self.heads[ingredient_key]

                    if head_obj then
                        local num_heads = head_obj["num_heads"]
                        if num_heads and is_number(num_heads) and num_heads ~= -1 then -- only continue if this head is tracked in the heads data table (and isn't locked!)
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
        else 
            -- hide Nemesis heads if they're still locked, and include a template dummy if there's more hidden heads
            log("in nemeses heads")
            local any_hidden = false
            for j = 0, ingredient_list:ChildCount() -1 do
                local ingredient = UIComponent(ingredient_list:Find(j))
                local id = ingredient:Id()
                log("checking ingredient "..id)
                local head_key = string.gsub(id, "CcoCookingIngredientRecord", "")

                -- skip template_ingredient
                if head_key == "template_ingredient" then
                    -- skip
                else
                    -- check if the ingredient is already unlocked; if it is, don't do anything
                    if not self:queek_has_access_to_head(head_key) then

                        -- if the mission chain hasn't started to get this head (stage 0), hide the head entirely
                        local legendary_mission_info = self.legendary_mission_info[head_key]

                        if not legendary_mission_info then
                            log("no legendary mission info found for head with key: "..head_key)
                        else
                            local stage = legendary_mission_info.stage

                            local visible = true

                            log("current stage is: "..tostring(stage))

                            if not stage or stage == 0 then
                                -- this head is locked - hide it from the UI
                                visible = false
                                any_hidden = true
                            else
                                -- is anything needed here?
                            end

                            log("setting visibility: "..tostring(visible))

                            ingredient:SetVisible(visible)
                        end
                    end
                end
            end

            -- create a lil dummy ingredient!
            if any_hidden then
                local template = UIComponent(ingredient_list:Find("template_ingredient"))

                -- check if there's already a dummy - if there is, don't do shit
                local test = ingredient_list:Find("nemesis_dummy")
                if test then
                    -- there's already a dummy, don't do nothin
                    return
                end

                local dummy = UIComponent(template:CopyComponent("nemesis_dummy"))
                local slot_item = UIComponent(dummy:Find("slot_item"))

                dummy:SetVisible(true)
                
                local path = effect.get_skinned_image_path("icon_question_mark.png")

                -- greyed out ?
                slot_item:SetImagePath(path)
                slot_item:SetCurrentStateImageOpacity(1, 100)

                -- inactive
                slot_item:SetState("inactive")

                -- set the tooltip on hover
                slot_item:SetTooltipText("There are remaining Legendary Heads that Queek has yet to hear about - continue your adventures to obtain them.", true)
            end
        end
    end
end

-- getter for the number of legendary heads vs. total (ie. 0 / ? or 2 / 4)
function headtaking:ui_get_num_legendary_heads()
    -- if there's unknown heads yet, use "X / ?"
    local legendary_mission_info = self.legendary_mission_info
    local any_unknown = false

    for _,obj in pairs(legendary_mission_info) do
        if obj.stage == 0 then
            any_unknown = true
        end
    end

    local str = ""
    
    local current_heads = tostring(self.legendary_heads_num)
    if any_unknown then
        -- set the counter to "X Heads / ?"
        str = current_heads .. " / ?"
    else    -- set the legendary heads counter to "X Heads / Total Heads"
        str = current_heads .. " / " .. tostring(self.legendary_heads_max)
    end

    log("Got num legendary heads: "..str)
    log("Curr: "..self.legendary_heads_num)
    log("Max: "..self.legendary_heads_max)

    return str
end

function headtaking:get_queek_trait_tooltip_text()
    local str = effect.get_localised_string("yummy_heads_queek_trait_tooltip_text")
    return string.format(str, self:get_headtaking_chance())
end

function headtaking:ui_init()
    log("ui init")
    local topbar = find_uicomponent(core:get_ui_root(), "layout", "resources_bar", "topbar_list_parent")
    if is_uicomponent(topbar) then
        log("topbar found")
        local uic = UIComponent(topbar:CreateComponent("queek_headtaking", "ui/campaign ui/queek_headtaking"))

        if not is_uicomponent(uic) then
            log("uic not created?")
            return false
        end

        topbar:Layout()

        -- TODO set this to something more interesting later on
        -- set the tooltip for the Queek Trait icon
        local trait = find_uicomponent(uic, "trait")
        trait:SetTooltipText(self:get_queek_trait_tooltip_text(), true)

        -- set the total of heads to be "0 / ?" or "1 / 4" or whatever, depending on known heads
        local grom_goals = UIComponent(uic:Find("grom_goals"))

        do
            local txt = self:ui_get_num_legendary_heads()
            local start_state = grom_goals:CurrentState()

            for i = 0, grom_goals:NumStates() -1 do
                local state = grom_goals:GetStateByIndex(i)
                grom_goals:SetState(state)
                grom_goals:SetStateText(txt)
            end

            grom_goals:SetState(start_state)
        end

        log("Grom goals: "..grom_goals:GetStateText())

        -- print_all_uicomponent_children(uic)

        --uic:SetVisible(true)

        core:add_listener(
            "queek_goals",
            "ComponentMouseOn",
            function(context)
                return UIComponent(context.component) == grom_goals
            end,
            function(context)
                timed_callback("queek_goals", 
                function() return is_uicomponent(find_uicomponent("tooltip_queek_goals")) end,
                function()
                    -- find the tooltip (a child of root called tooltip_queek_goals)
                    local tt = find_uicomponent("tooltip_queek_goals")

                    local do_stuff = find_uicomponent(tt, "dy_recipes_eltharion_challenge")
                    local txt = do_stuff:GetStateText()

                    txt = string.format(txt, self.total_heads, self.legendary_heads_num)
                    do_stuff:SetStateText(txt)
                end, 5)

            end,
            true
        )

    else
        -- log("topbar unfound?")
    end

    core:add_listener(
        "queek_button_pressed",
        "ComponentLClickUp",
        function(context)
            return context.string == "queek_headtaking"
        end,
        function(context)
            self:open_panel()
        end,
        true
    )
end

function headtaking:close_panel()
    local panel = find_uicomponent("queek_cauldron")

    if not is_uicomponent(panel) then
        return false
    end

    remove_component(panel)

    -- refresh the header when it's closed!
    self:ui_refresh_header()

    -- reenable the esc key
    cm:steal_escape_key(false)

    core:remove_listener("queek_close_panel")
end

function headtaking:open_panel()
    local root = core:get_ui_root()
    local test = find_uicomponent("queek_cauldron")
    if not is_uicomponent(test) then
        root:CreateComponent("queek_cauldron", "ui/campaign ui/queek_cauldron_panel")

        repeat_callback(
            "queek_cauldron_test_open",
            function(context)
                return is_uicomponent(find_uicomponent("queek_cauldron")) and is_uicomponent(find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "component_tooltip"))
            end,
            function(context)
                real_timer.unregister("queek_cauldron_test_open")
                core:remove_listener("queek_cauldron_test_open")

                self:panel_opened()
            end,
            0
        )
    end
end


function headtaking:panel_opened()
    -- listen for close!
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
            self:close_panel()
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
            self:close_panel()
        end,
        false
    )

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

    -- TODO decide if this should be X / Total Heads or X / (Total Heads - Legendaries)
    -- for now it's just X / Total Heads
    local heads_num = find_uicomponent("queek_cauldron", "left_colum", "progress_display_holder", "ingredients_progress_holder", "ingredients_progress_number")

    local legendary_num = find_uicomponent("queek_cauldron", "left_colum", "progress_display_holder", "recipes_progress_holder", "recipes_progress_number")

    local str = self:ui_get_num_legendary_heads()

    legendary_num:SetStateText(str)

    -- TODO set this to the elaborate-ish tooltip that shows all perma-effects from Legheads
    -- TODO make this more interesting later on
    -- set a tooltip on the Queek Trait icon
    local trait = find_uicomponent("queek_cauldron", "left_colum", "progress_display_holder", "trait")
    trait:SetTooltipText(self:get_queek_trait_tooltip_text(), true)

    -- re-enable the recipe book, luh-mao
    local recipe_book = find_uicomponent("queek_cauldron", "recipe_book_holder", "recipe_button_group")
    recipe_book:SetVisible(true)

    -- replace the button icon
    local recipes_button = find_uicomponent(recipe_book, "recipes_button")
    recipes_button:SetImagePath("ui/skins/default/icon_queekcooking_cauldron.png")

    -- loop through all of the recipe book texts, and set the text to white instead of black
    local recipes_list = find_uicomponent("queek_cauldron", "recipe_book_holder", "recipe_book", "recipes_and_tooltip_holder", "recipes_and_tooltip_holder_beholder", "recipes_holder", "recipes_list")

    for i = 0, recipes_list:ChildCount() -1  do
        local child = UIComponent(recipes_list:Find(i))

        local id = child:Id()
        -- check if it's valid
        if string.find(id, "CcoCookingRecipeRecord") then
            -- if it's legendary, just hide the whole recipe
            if string.find(id, "legendary") then
                child:SetVisible(false)
            else
                local dish_name = UIComponent(child:Find("dish_name"))
                
                -- change the shader from set_greyscale bullshit to the normal_t0
                dish_name:TextShaderTechniqueSet("normal_t0", true)
            end
        end
    end

    local slot_holder = find_uicomponent("queek_cauldron", "mid_colum", "pot_holder", "ingredients_and_effects")
    local arch = find_uicomponent("queek_cauldron", "mid_colum", "pot_holder", "arch")

    -- if the fourth slot is locked, and we're in Vortex, change the tooltip text
    if self.slots[4] == "locked" and cm:get_campaign_name() == "wh2_main_great_vortex" then
        local fourth_slot = find_uicomponent(slot_holder, "main_ingredient_slot_4")

        fourth_slot:SetTooltipText("Unlock this slot by collecting the heads of the false claimants to Karak Eight Peaks.", true)
    end

    -- TODO move this into the UI file, fuck it

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
        local animated_frame = find_uicomponent(slot_holder, "main_ingredient_slot_"..tostring(i).."_animated_frame")

        local _, sloty = slot:Position()
        local w,_ = slot:Dimensions()

        local _,animy = animated_frame:Position()
        local animw,_ = animated_frame:Dimensions()

        -- this is the hard position on the screen where the middleish of the pike is (pike is 8px wide)
        local end_x = arx + (pike_pos + 4)

        -- grab the offset between the slot holder's position and the end result
        local slotx = end_x - (w/2)
        local animx = end_x - (animw/2)

        -- for some reason I'm 14 off, so
        slotx = slotx - 14
        animx = animx - 15

        -- move it
        slot:MoveTo(slotx, sloty)
        animated_frame:MoveTo(animx, animy)
    end

    -- move the rows into a predetermined order
    local category_list = find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "ingredient_category_list")

    local ok, err = pcall(function()
        log("starting add list view")
        -- add in the listview, bluh
        local list_view = UIComponent(category_list:CreateComponent("list_view", "ui/vandy_lib/vlist"))

        local list_clip = UIComponent(list_view:Find("list_clip"))
        local list_box = UIComponent(list_clip:Find("list_box"))
        local vslider = UIComponent(list_view:Find("vslider"))

        local cw,ch = category_list:Dimensions()
        cw = cw + 50

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

        list_box:Layout()
        vslider:SetVisible(true)

        do
            vslider:SetDockingPoint(6)
            
            local x,y = vslider:GetDockOffset()
            vslider:SetDockOffset(80,y)
        end

        list_box:Resize(cw, ch+150)
        list_box:SetCanResizeHeight(false)
        list_box:SetCanResizeWidth(false)

    end) if not ok then log(err) end

    self:ui_refresh()
end

log_init()
core:add_static_object("headtaking", headtaking)

cm:add_first_tick_callback(function()
    local ok, err = pcall(function()
        -- disable this whole thing if Queek is AI, for the time being
        local queek = cm:get_faction(headtaking.faction_key)
        if not queek:is_human() then
            return
        end

        headtaking:init()

        if cm:get_local_faction_name(true) == headtaking.faction_key then
            headtaking:ui_init()
        end
    end) if not ok then log(err) end
end)

cm:add_loading_game_callback(
    function(context)
        headtaking.heads = cm:load_named_value("headtaking_heads", headtaking.heads, context)
        headtaking.total_heads = cm:load_named_value("headtaking_total_heads", headtaking.total_heads, context)
        headtaking.slots = cm:load_named_value("headtaking_slots", headtaking.slots, context)

        headtaking.squeak_stage = cm:load_named_value("headtaking_squeak_stage", headtaking.squeak_stage, context)
        headtaking.squeak_mission_info = cm:load_named_value("headtaking_squeak_mission_info", headtaking.squeak_mission_info, context)

        headtaking.legendary_mission_info = cm:load_named_value("headtaking_legendary_mission_info", headtaking.legendary_mission_info, context)
    end
)

cm:add_saving_game_callback(
    function(context)
        cm:save_named_value("headtaking_heads", headtaking.heads, context)
        cm:save_named_value("headtaking_total_heads", headtaking.total_heads, context)
        cm:save_named_value("headtaking_slots", headtaking.slots, context)

        cm:save_named_value("headtaking_squeak_stage", headtaking.squeak_stage, context)
        cm:save_named_value("headtaking_squeak_mission_info", headtaking.squeak_mission_info, context)

        cm:save_named_value("headtaking_legendary_mission_info", headtaking.legendary_mission_info, context)
    end
)