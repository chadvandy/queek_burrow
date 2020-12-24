-- these are the predetermined-ish missions for each stage of a legendary head chain
-- some factions will have specified missions at different points in their chain, and they all culminate in a specified end battle with Queek v. the Baddie, but sometimes they can pick from this list which will generate a mission for that faction
-- assumes that the chain will be querying for missions between 1-3, so only those are defined here; 4 is usually the Queek v Baddie stage

return {
    -- first chain missions!
    [1] = {
        {   -- raid their land
            key = "",
            objective = "",
            condition = "",
            payload = "",
            listener = {
                name = "",
                event_name = "",
                conditional = function(context)

                end,
                callback = function(context)

                end,
            },
            start_func = function(mission)

            end,
            end_func = function(mission)
                
            end,
            constructor = function(mission)
                
            end,
        },
        {   -- perform agent action against these fools

        },
        {   -- raze one specified settlement

        },
    },
    -- second chain missions!
    [2] = {
        {   -- get a trophy head from this faction

        },
        {   -- occupy three of their settlements

        },
        {   -- defeat three armies

        },
    },
    -- third chain missions!
    [3] = {
        {   -- sack their capital

        },
    },
}