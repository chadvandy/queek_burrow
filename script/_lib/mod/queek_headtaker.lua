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
        turns_since_last_mission = false,
        num_missions = 0,
        current_mission = "",
    },

    -- saves the stages of each legendary head mission
    legendary_mission_info = {},

    -- data-ified missions for legendary heads and squeak stages
    legendary_missions = require("script/headtaking/legendary_missions"),
    squeak_missions = require("script/headtaking/squeak_missions"),

    chance = 100,
    queek_subtype = "wh2_main_skv_queek_headtaker",
    faction_key = "wh2_main_skv_clan_mors",

    -- table matching subcultures to their head reward
    valid_heads = require("script/headtaking/valid_heads"),

    -- TODO, should it be indexed like this, or just read valid_heads in a slightly expensive loop? I'm okay with either, don't want to hold too much memory
    -- built from valid_heads, makes a quick index'd table to pull valid heads based on subculture or subtype
    subculture_to_heads = {},
    subtype_to_heads = {},

    -- table of legendary heads attached to their various related missions, ultra static
    legendary_heads = require("script/headtaking/legendary_heads"),
}

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

    core:trigger_custom_event("HeadtakingCollectedHead", {["headtaking"] = self, ["head"] = self.heads[head_key], ["faction_key"] = details.faction_key})
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

function headtaking:get_mission_with_key(key)
    if not is_string(key) then
        -- errmsg
        return false
    end

    local missions = self.squeak_missions
    for i = 1, #missions do
        local mission = missions[i]
        if mission.key == key then
            return mission
        end
    end

    -- errmsg, none found! :(
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

function headtaking:squeak_trigger_event()

end

-- this is where Squeak's random incessant requests are generated
function headtaking:squeak_random_shit()
    -- local stage = self.squeak_stage
    
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

    -- if there's a mission already active, check if it's a scripted one and start the listener, else do naught
    if self.squeak_mission_info.current_mission ~= "" then
        local mission_data = self:get_mission_with_key(self.squeak_mission_info.current_mission)

        -- start the listener for this mission, if there is one!
        if mission_data and mission_data.listener then
            mission_data.listener()
        end

        return
    end

    core:add_listener(
        "SqueakRandomEvent",
        "FactionTurnStart",
        function(context)
            return context:faction():name() == self.faction_key
        end,
        function(context)
            -- there's not a mission already and it's not the first mission; check if there should be a mission triggered
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
            end
        end,
        true
    )
end

-- this tracks the current LL missions (initialized through Squeak Init if it's over stage 1)
function headtaking:track_legendary_heads()
    local legendary_heads = self.legendary_heads
    local legendary_mission_info = self.legendary_mission_info

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

            -- TODO make this work with the auto-gen'd missions
            -- can do that by, say, looping through all the mission infos, checking mission keys
            -- try to make it so there's no way to double up on mission keys between different heads

            -- cut off the "_1" or w/e ending
            local head_key = string.sub(mission_key, 1, -3)

            -- grab just the number, ie. "1"
            local stage = tonumber(string.sub(mission_key, -1, -1))

            local legendary_obj = self.legendary_heads[head_key]

            local mission_chain = legendary_obj.mission_chain
            local mission_obj = mission_chain[stage]

            -- trigger any end-function if any are set
            if mission_obj.end_func then
                local f = loadstring(mission_obj.end_func)
                setfenv(f, core:get_env())
                f(self, head_key)

                -- mission_obj.end_func(self, head_key)
            end

            -- reward the head if it's the last mission of this chain
            if stage == #mission_chain then
                -- TODO add details! (somehow???)
                -- TODO permakill the lord
                self:add_head_with_key(head_key)

                core:trigger_custom_event("HeadtakingLegendaryHeadRetrieved", {headtaking=self, head_key=head_key})
                return
            end
            -- trigger the next mission
            local next_stage = stage+1

            self.legendary_mission_info[head_key].mission_key = ""
            self.legendary_mission_info[head_key].tracker = nil
            self.legendary_mission_info[head_key].stage = next_stage

            self:trigger_legendary_head_mission(head_key, next_stage)
        end,
        true
    )

    -- check stages of each legendary head - if it's stage 0, check the prereq; if it's beyond that, trigger any necessary listeners
    for head_key,obj in pairs(legendary_heads) do

        -- initalize the mission_info table if it hasn't been yet
        if not legendary_mission_info[head_key] then legendary_mission_info[head_key] = {stage=0, mission_key = "", tracker = nil} end

        local mission_info = legendary_mission_info[head_key]

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
                        self:trigger_legendary_head_mission(head_key, 1)
                    end,
                    false
                )
            else
                -- trigger first stage right away
                self:trigger_legendary_head_mission(head_key, 1)
            end
        else
            -- trigger any necessary listeners for this stage
            local mission_chain = obj.mission_chain
            local mission = mission_chain[mission_info.stage]

            self:initialize_legendary_head_listener(mission, head_key)
        end
    end
end

function headtaking:initialize_legendary_head_listener(mission_obj, head_key)
    local mission_info = self.legendary_mission_info[head_key]

    -- grab the mission obj for the generated mission
    if mission_obj.key == "GENERATED" then
        local mission_key = mission_info.mission_key

        if not is_string(mission_key) then
            -- errmsg generated mission key wasn't saved???
            
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
            -- errmsg couldn't find the mission used, wtf?

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
    ModLog("Constructing mission from data, for head ["..head_key.."] during stage ["..tostring(stage_num).."].")
    ModLog("Mission key is "..data.key)
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
        ModLog("Constructing!")
        data = data.constructor(data, self, head_key)

        if not data then
            ModLog("Constructor failed D:")
            return false
        end
    end

    -- use the mission_manager to do all the heavy lifting of constructing the mission string
    local mission = mission_manager:new(self.faction_key, data.key)

    mission:add_new_objective(data.objective)
    ModLog("Objective added "..data.objective)
    
    mission:set_mission_issuer("squeak")

    if not is_table(data.condition) then data.condition = {data.condition} end
    for i = 1, #data.condition do
        local condition = data.condition[i]
        mission:add_condition(condition)
        ModLog("Condition added "..condition)
    end

    mission:add_payload(data.payload)
    ModLog("Payload added "..data.payload)

    mission:trigger()

    ModLog("trigger'd")

    -- if there's a start func for whatever reason, call it!
    if data.start_func then
        local f = loadstring(data.start_func)
        setfenv(f, core:get_env())

        f(self, head_key)
        ModLog("Start func'd")

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
        ModLog("Listener func'd")
    end

    if is_table(listener) then
        ModLog("Listener'd")
        core:add_listener(
            listener.name,
            listener.event_name,
            listener.conditional,
            listener.callback,
            listener.persistence or false
        )
    end
end) if not ok then ModLog(err) end
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

function headtaking:trigger_random_legendary_head_mission_at_stage(head_key, stage_num)
    local legendary_missions = self.legendary_missions

    local stage_missions = legendary_missions[stage_num]

    if not is_table(stage_missions) or #stage_missions < 1 then
        -- errmsg no missions at this stage???
        return false
    end

    -- TODO maybe later on have this be a weighted random, to prevent the same mission being picked several times

    -- randomly pick one of the missions at this stage
    local mission = stage_missions[cm:random_number(#stage_missions)]

    -- TODO need to do a deep-copy
    -- copy the reference (so we don't override the table in self.legendary_missions)
    local data = deepcopy(mission)

    -- check if there's already a mission (or more) with this key active, and then iterate the key suffix one more (max of 3)
    local highest_append = self:is_legendary_head_mission_active(data.key)
    if highest_append then
        if highest_append == 3 then
            -- find another mission?
            -- TODO prevent infi loop
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

    ModLog("relevant mission key: "..mission.key)
    ModLog("copied mission key: "..data.key)

    -- change the override_text field to be override_text..head_key, for proper localisation
    if is_table(data.condition) then
        for i = 1, #data.condition do
            local condition = data.condition[i]
            if string.find(condition, "override_text") then
                -- changes "legendary_head_1_raid" to "legendary_head_1_raid_legendary_head_belegar", wow that sucks. TODO make this suck less prolly?
                local str = mission.condition[i]
                condition = condition .. "_" .. head_key

                ModLog("changed condition: " .. condition)

                
                -- this prevents the above from FOR SOME FUCKING REASON overwriting the mission table
                -- TODO this overwrites data.condition, what the FUCK
                mission.condition[i] = str

                data.condition[i] = condition
                
                ModLog("og condition: "..mission.condition[i])
                ModLog("copied condition: ".. data.condition[i])
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

    for head_key, mission_info in pairs(mission_infos) do
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

-- trigger individual missions in each legendary head chain
-- if no stage is provided, it defaults to 1 to start it off
function headtaking:trigger_legendary_head_mission(head_key, stage_num)
    if not is_string(head_key) then
        -- errmsg
        return false
    end

    if not is_number(stage_num) then stage_num = 1 end

    -- check if there's already a mission active for this leghead; if there is, skip
    local current_key = self.legendary_mission_info[head_key].mission_key

    if is_string(current_key) and current_key ~= "" then
        -- errmsg, mission already active
        return
    end
    
    local legendary_obj = self.legendary_heads[head_key]
    local mission_chain = legendary_obj.mission_chain
    local mission_obj = mission_chain[stage_num]
    
    if not mission_obj then
        -- errmsg
        return false
    end
    
    -- pick a mission for this stage from a list, if it's a generated mission
    if mission_obj.key == "GENERATED" then
        -- construct this mission elsewhere
        self:trigger_random_legendary_head_mission_at_stage(head_key, stage_num)
        return
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

    -- TODO vvvvv
    -- trigger incident for "hey, you got this fucker" / upgrade


    self:squeak_init()

    core:trigger_custom_event("HeadtakingSqueakUpgrade", {headtaking=self, stage=self.squeak_stage})
end

function headtaking:squeak_init(new_stage)
    if is_number(new_stage) then
        self.squeak_stage = new_stage
    end

    ModLog("Squeak init!")
    local stage = self.squeak_stage
    ModLog("Stage is "..tostring(stage))

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
                self.squeak_mission_info.turns_since_last_mission = -1
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

        -- LL missions are triggered by squeak_upgrade()'s internal listener
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

    local total = 0
    for key,_ in pairs(legendary_heads) do
        total = total + 1

        if faction_cooking_info:is_ingredient_unlocked(key) then
            self.legendary_heads_num = self.legendary_heads_num + 1
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
        -- TODO trigger incident with this
        self:add_head_with_key("generic_head_skaven")

        -- first thing's first, enable using 4 ingredients for a recipe for queeky
        -- TODO temp disabled secondaries until the unlock mechanic is introduced
        cm:set_faction_max_primary_cooking_ingredients(faction_obj, 2)
        cm:set_faction_max_secondary_cooking_ingredients(faction_obj, 0)
    end

    ModLog("Heads table: "..tostring(self.heads))

    self:init_count_heads()
    self:squeak_init()
    self:track_legendary_heads()

    --loyalty_listeners()

    -- next up, enable some 'eads to be gitted through battles
    core:add_listener(
        "queek_killed_someone",
        "CharacterConvalescedOrKilled",
        function(context)
            local character = context:character()
            local faction = character:faction()

            ModLog("Character killed, checking stuff.")
            ModLog("is null interface: "..tostring(character:is_null_interface()))
            ModLog("has mf force:" .. tostring(character:has_military_force()))
            ModLog("is embedded: "..tostring(character:is_embedded_in_military_force()))
            ModLog("has garri: "..tostring(character:has_garrison_residence()))

            ModLog("queek is in: "..tostring(cm:pending_battle_cache_char_is_involved(cm:get_faction(self.faction_key):faction_leader())))
            ModLog("faction name: "..faction:name())
            ModLog("is quest battle faction: "..tostring(faction:is_quest_battle_faction()))

            return 
                character:is_null_interface() == false                      -- character that died actually exists
                -- and character:character_type("general")                          -- temp disbabled -- generals only
                and (character:has_military_force() or character:is_embedded_in_military_force() or character:has_garrison_residence()) -- needs to be in an army (leading, hero in it, or a garrison friend)
                and cm:pending_battle_cache_char_is_involved(cm:get_faction(self.faction_key):faction_leader())     -- Queek was involved in the battle
                and faction:name() ~= self.faction_key                  -- the character that died isn't in Clan Mors, lol
                and faction:name() ~= "wh2_main_skv_skaven_rebels"  -- not Skaven Rebels (prevent cheesing (: )
                and not faction:is_quest_battle_faction()               -- not a QB faction
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
        local ok, err = pcall(function()
        self:set_head_counters()
        end) if not ok then ModLog(err) end
    end
end

-- this sets the UI for the number of heads and their respective states and opacities
function headtaking:set_head_counters()
    local category_list = find_uicomponent("queek_cauldron", "left_colum", "ingredients_holder", "ingredient_category_list")

    ModLog("head 1")

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
                    local num_label_address = ingredient:Find("num_heads")
                    local num_label

                    if not num_label_address then
                        -- create the number-of-heads label
                        num_label = core:get_or_create_component("num_heads", "ui/vandy_lib/number_label", ingredient)
                    else
                        num_label = UIComponent(num_label_address)
                    end

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
        else -- hide Nemesis heads if they're still locked, and include a template dummy if there's more hidden heads
            -- TODO don't hide them if they're locked, hide them if the MISSION isn't started
            local any_hidden = false
            for j = 0, ingredient_list:ChildCount() -1 do
                local ingredient = UIComponent(ingredient_list:Find(j))
                local id = ingredient:Id()
                local ingredient_key = string.gsub(id, "CcoCookingIngredientRecord", "")

                local num_heads = self.heads[ingredient_key]["num_heads"]

                if num_heads == -1 then
                    -- this head is locked - hide it from the UI
                    ingredient:SetVisible(false)
                    any_hidden = true
                else
                    -- is anything needed here?
                end
            end

            -- create a lil dummy ingredient!
            if any_hidden then
                local template = UIComponent(ingredient_list:Find("template_ingredient"))
                local dummy = UIComponent(template:CopyComponent("nemesis_dummy"))
                local slot_item = UIComponent(dummy:Find("slot_item"))

                dummy:SetVisible(true)
                -- set a tooltip and set a ??? image
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

        -- re-enable the recipe book, luh-mao
        local recipe_book = find_uicomponent("queek_cauldron", "recipe_book_holder", "recipe_button_group")
        recipe_book:SetVisible(true)

        -- hide specific recipe combos from the recipe book
        local hidden_recipe = find_uicomponent("queek_cauldron", "recipe_book_holder", "recipe_book", "recipes_and_tooltip_holder", "recipes_and_tooltip_holder_beholder", "recipes_holder", "recipes_list","CcoCookingRecipeRecordnemeses")

        hidden_recipe:SetVisible(false)

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

            do
                vslider:SetDockingPoint(6)
                
                local x,y = vslider:GetDockOffset()
                vslider:SetDockOffset(80,y)
            end

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
        -- disable this whole thing if Queek is AI, for the time being
        local queek = cm:get_faction(headtaking.faction_key)
        if not queek:is_human() then
            return
        end

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
        headtaking.legendary_mission_info = cm:load_named_value("headtaking_legendary_mission_info", headtaking.legendary_mission_info, context)
    end
)

cm:add_saving_game_callback(
    function(context)
        cm:save_named_value("headtaking_heads", headtaking.heads, context)
        cm:save_named_value("headtaking_total_heads", headtaking.total_heads, context)
        cm:save_named_value("headtaking_squeak_stage", headtaking.squeak_stage, context)
        cm:save_named_value("headtaking_squeak_mission_info", headtaking.squeak_mission_info, context)
        cm:save_named_value("headtaking_legendary_mission_info", headtaking.legendary_mission_info, context)
    end
)