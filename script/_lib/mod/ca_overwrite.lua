--- overwriting a couple functions that I need to have fixed up

-- overwrite pre-first-tick, so they're accessible on first tick and beyond
cm:add_pre_first_tick_callback(function()

    -- this is a new function
    -- add a script event that triggers after the forced battle
    function forced_battle:set_post_battle_script_event(script_event_name, victory_type)
        if not self.post_battle_script_events then
            self.post_battle_script_events = {}
        end

        if not is_string(script_event_name) then
            script_error("set_post_battle_script_event() called but the script event name provided ["..tostring(script_event_name).."] is not a string")
            return false
        end

        if not is_string(victory_type) or victory_type ~= "attacker_victory" and victory_type ~= "defender_victory" and victory_type ~= "both" then
            script_error("set_post_battle_script_event() called but the victory_type provided ["..tostring(victory_type).."] is not a string, or isn't 'attacker_victory', 'defender_victory', or 'both'.")
            return false
        end

        if victory_type == "both" then
            self.post_battle_script_events["attacker_victory"] = script_event_name
            self.post_battle_script_events["defender_victory"] = script_event_name
        else
            self.post_battle_script_events[victory_type] = script_event_name
        end
    end


    ---- new function
    -- add a forename and surname key override for a force key
    function forced_battle:set_names_for_force(force_key, forename_key,surname_key)
        if not is_string(force_key) then
            -- errmsg
            return false
        end

        local force = self.force_list[force_key]

        if not force then
            -- errmsg, none found
            return false
        end

        local names = {
            "",
            "",
            "",
            "",
        }

        if is_string(forename_key) then
            names[1] = forename_key
        end

        if is_string(surname_key) then
            names[3] = surname_key
        end

        self.general_names = names
    end

    -- this overwrites the vanilla function here
    -- trigger a custom script event after a forced battle is done.
    function forced_battle:trigger_post_battle_events(attacker_victory)

        local event_type = ""
        local event_key = ""

        ---- insert
        ModLog("trigger post battle events")
        local script_event_name
        if attacker_victory then
            ModLog("attacker victory")
            script_event_name = self.post_battle_script_events["attacker_victory"]
        else
            ModLog("defender victory")
            script_event_name = self.post_battle_script_events["defender_victory"]
        end

        if is_string(script_event_name) then
            ModLog("script event found, name is "..script_event_name)
            core:trigger_custom_event(
                script_event_name,
                {
                    ["forced_battle_key"] = self.key,
                    ["forced_battle"] = self
                }
            )
        end
        ---- end insert

        if attacker_victory and self.attacker_victory_event~= nil then
            event_type = self.attacker_victory_event.event_type
            event_key = self.attacker_victory_event.event_key
        elseif not attacker_victory and self.defender_victory_event ~= nil then
            event_type = self.defender_victory_event.event_type
            event_key = self.defender_victory_event.event_key
        else 
            return
        end

        local faction = cm:whose_turn_is_it()

        if event_type == "incident" then
            cm:trigger_incident(faction, event_key, true)
        elseif event_type == "dilemma" then
            cm:trigger_dilemma(faction,event_key,true)
        end
    end


    -- overwriting the assumption that it wants a new spawn location
    ---- added ignore_new_position param
    function forced_battle:spawn_generated_force(force_key, x, y, ignore_new_position)
        local force = self.force_list[force_key]
        
        local new_x,new_y = cm:find_valid_spawn_location_for_character_from_position(force.faction_key,x,y,true,7)

        ----- insert
        if ignore_new_position then
            new_x = x
            new_y = y
        end
        ----- insert end
    
        ---remove any invasions with the same key just in case
        invasion_manager:remove_invasion(force.key)
    
        self.invasion_key = force.key..new_x..new_y
    
        local forced_battle_force = invasion_manager:new_invasion(force.key,force.faction_key, force.unit_list,{new_x, new_y})
        if force.general_subtype ~= nil then
            local subculture = cm:get_faction(force.faction_key):subculture()
            local random_name = generate_character_name(subculture, force.general_subtype)

            ----- insert to add in predetermined names
            if self.general_names then
                random_name = self.general_names
            end
            ----- end insert

            forced_battle_force:create_general(false, force.general_subtype, random_name[1], random_name[2], random_name[3], random_name[4])
        end

        if force.general_level ~= nil then
            forced_battle_force:add_character_experience(force.general_level, true)
        end
    
        if force.effect_bundle ~=nil then
            local bundle_duration = -1
            forced_battle_force:apply_effect(force.effect_bundle, bundle_duration)
        end
    
        --- here we target the spawned invasion at the force they're attacking, if it already exists, otherwise it'll just mooch around post-battle
        local invasion_target_cqi
        local invasion_target_faction_key
    
        if self.target.is_existing then
            invasion_target_cqi = cm:get_character_by_mf_cqi(self.target.cqi):command_queue_index()
            invasion_target_faction_key = cm:get_character_by_mf_cqi(self.target.cqi):faction():name()
        end
    
        if self.attacker.is_existing then
            invasion_target_cqi = cm:get_character_by_mf_cqi(self.attacker.cqi):command_queue_index()
            invasion_target_faction_key = cm:get_character_by_mf_cqi(self.attacker.cqi):faction():name()
        end
    
        if self.target.existing or self.attacker.is_existing then
            forced_battle_force:set_target("CHARACTER", invasion_target_cqi, invasion_target_faction_key)
            forced_battle_force:add_aggro_radius(25, {invasion_target_faction_key}, 1)
        end
    
        forced_battle_force:start_invasion(
            function()
                self:forced_battle_stage_2(self)
            end,
            false,false,false)
        force.spawned = true
    end




    -- overwrite here needed for the overwrite above
    ----- adding the ignore_new_position param
    function forced_battle:trigger_battle(attacker_force, target_force, opt_target_x, opt_target_y, opt_is_ambush, ignore_new_position)

        self.target = {}
        self.attacker = {}
    
        --set up the defender first
        ---if a number is given, we assume it's a cqi
        if is_number(target_force) then
            local target_force_interface = cm:model():military_force_for_command_queue_index(target_force)
            if target_force_interface:is_null_interface() then
                script_error("ERROR: Force Battle Manager: trying to trigger forced battle "..self.key.." with an invalid attacker CQI!")
                return false
            end
            self.target.cqi = target_force
            self.target.interface = target_force_interface
            self.target.is_existing = true
            self.target.faction_interface = target_force_interface:faction()
        ---if a key is given, then we try and generate a force from the stored forces
        elseif is_string(target_force) then
            if self.force_list[target_force] == nil then
                script_error("ERROR: Force Battle Manager: trying to trigger forced battle with a generated force, but cannot find force with key "..target_force..". Has it been defined yet?")
                return false
            end
            
            if opt_target_x == nil or opt_target_y == nil then
                script_error("ERROR: Force Battle Manager: trying to trigger forced battle with generated defender "..target_force..", but we haven't been given x/y coords")
                return false
            end
    
            self.battle_location_x = opt_target_x
            self.battle_location_y = opt_target_y
            self.target.force_key = target_force
            self.target.is_existing = false
            self.target.destroy_after_battle = self.force_list[target_force].destroy_after_battle	
            self.target.faction_interface = cm:get_faction(self.force_list[target_force].faction_key)
        end
    
        ---now do all the same with the attacker
        if is_number(attacker_force) then
            local attacker_force_interface = cm:model():military_force_for_command_queue_index(attacker_force)
            if attacker_force_interface:is_null_interface() then
                script_error("ERROR: Force Battle Manager: trying to trigger forced battle "..self.key.." with an invalid attacker CQI!")
                return false
            end
            self.attacker.cqi = attacker_force
            self.attacker.interface = attacker_force_interface
            self.attacker.is_existing = true
            self.attacker.faction_interface = attacker_force_interface:faction()
        elseif is_string(attacker_force) then
            if self.force_list[attacker_force] == nil then
                script_error("ERROR: Force Battle Manager: trying to trigger forced battle with a generated force, but cannot find force with key "..attacker_force..". Has it been defined yet?")
                return false
            end
            
            if opt_target_x == nil or opt_target_y == nil then
                script_error("ERROR: Force Battle Manager: trying to trigger forced battle with generated attacker "..attacker_force..", but we haven't been given x/y coords")
                return false
            end

            ------- insert, why the fyuck isn't this in?
            self.battle_location_x = opt_target_x
            self.battle_location_y = opt_target_y
            ------- end insert

            self.attacker.force_key = attacker_force
            self.attacker.is_existing  = false
            self.attacker.destroy_after_battle = self.force_list[attacker_force].destroy_after_battle
            self.attacker.faction_interface = cm:get_faction(self.force_list[attacker_force].faction_key)
        end
    
        self.is_ambush = opt_is_ambush or false
    
    
        ------- insert the ignore_new_position bool into these commands
        if not self.attacker.is_existing then 
            self:spawn_generated_force(self.attacker.force_key, self.battle_location_x, self.battle_location_y, ignore_new_position )
        end
    
        if not self.target.is_existing then
            self:spawn_generated_force(self.target.force_key, self.battle_location_x, self.battle_location_y, ignore_new_position )
        end
        ------- end insert

        
        Forced_Battle_Manager.active_battle = self.key
        Forced_Battle_Manager:setup_battle_completion_listener()
    end


end)