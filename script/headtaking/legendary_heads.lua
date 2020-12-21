

return {
    legendary_head_belegar = {
        prerequisite = {
            name = "BelegarUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {
            {
                key = "legendary_head_belegar_1",
                objective = "",
                condition = "",
                payload = "",
                listener = nil,
                start_func = nil,
                constructor = nil,
            }
        },
    },
    legendary_head_skarsnik = {
        prerequisite = {
            name = "SkarsnikUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {

        },
    },
    legendary_head_tretch = {
        prerequisite = {
            name = "TretchUnlocked",
            event_name = "HeadtakingSqueakUpgrade",
            conditional = function(context) return context:stage() == 2 end,
        },
        mission_chain = {

        },
    },
    legendary_head_squeak = {

    },
}