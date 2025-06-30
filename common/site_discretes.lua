---@diagnostic disable-next-line:name-style-check
local discrete_names_and_calculations = {}

-- Blood Glucose
local dv_names_blood_glucose = { "GLUCOSE (mg/dL)", "GLUCOSE" }
local dv_names_glasgow_coma_scale = { "3.5 Neuro Glasgow Score" }
local calc_low_glasgow_coma_scale = 14
local calc_very_low_glasgow_coma_scale = 12
local dv_names_glasgow_eye_opening = { "3.5 Neuro Glasgow Eyes (Adult)" }
local dv_names_glasgow_verbal = { "3.5 Neuro Glasgow Verbal (Adult)" }
local dv_names_glasgow_motor = { "3.5 Neuro Glasgow Motor" }
local dv_names_oxygen_therapy = { "DELIVERY", "Device Type" }

return discrete_names_and_calculations
