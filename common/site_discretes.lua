---@diagnostic disable-next-line:name-style-check
return function(Account)

    local discrete = require("libs.common.discrete")
    local discrete_names_and_calculations = {}

    -- Blood Glucose
    discrete_names_and_calculations.dv_names = { "GLUCOSE (mg/dL)", "GLUCOSE" }
    discrete_names_and_calculations.predicate_high = discrete.make_gt_predicate(600)
    -- Glasgow 
    discrete_names_and_calculations.dv_names_glasgow_coma_scale = { "3.5 Neuro Glasgow Score" }
    discrete_names_and_calculations.calc_low_glasgow_coma_scale = 14
    discrete_names_and_calculations.calc_very_low_glasgow_coma_scale = 12
    discrete_names_and_calculations.predicate_glasgow_coma_score_low = discrete.make_lt_predicate(15)
    discrete_names_and_calculations.dv_names_glasgow_eye_opening = { "3.5 Neuro Glasgow Eyes (Adult)" }
    discrete_names_and_calculations.dv_names_glasgow_verbal = { "3.5 Neuro Glasgow Verbal (Adult)" }
    discrete_names_and_calculations.dv_names_glasgow_motor = { "3.5 Neuro Glasgow Motor" }
    discrete_names_and_calculations.dv_names_oxygen_therapy = { "DELIVERY", "Device Type" }

    return discrete_names_and_calculations
end
