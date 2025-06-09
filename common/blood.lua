---@diagnostic disable-next-line:name-style-check
return function(Account)
    local module = {}
    local discrete = require("libs.common.discrete_values")(Account)

    --- @class (exact) HematocritHemoglobinDiscreteValuePair
    --- @field hemoglobinLink CdiAlertLink
    --- @field hematocritLink CdiAlertLink

    --------------------------------------------------------------------------------
    --- Get Low Hemoglobin Discrete Value Pairs
    ---
    --- @param dv_names_hemoglobin string[] Names of the Hemoglobin discrete values
    --- @param dv_names_hematocrit string[] Names of the Hematocrit discrete values
    --- @param low_hemoglobin_value number Low value for hemoglobin
    ---
    --- @return HematocritHemoglobinDiscreteValuePair[]
    --------------------------------------------------------------------------------
    function module.get_low_hemoglobin_discrete_value_pairs(
        dv_names_hemoglobin,
        dv_names_hematocrit,
        low_hemoglobin_value
    )
        --- @type HematocritHemoglobinDiscreteValuePair[]
        local low_hemoglobin_pairs = {}

        local low_hemoglobin_values = discrete.get_ordered_discrete_values({
            discreteValueNames = dv_names_hemoglobin,
            predicate = function(dv)
                local value = discrete.get_dv_value_number(dv)
                return value ~= nil and value <= low_hemoglobin_value
            end
        })
        for i = 1, #low_hemoglobin_values do
            local dv_hemoglobin = low_hemoglobin_values[i]
            local dv_date = dv_hemoglobin.result_date
            local dv_hematocrit = dv_date and discrete.get_discrete_value_nearest_to_date({
                discreteValueNames = dv_names_hematocrit,
                date = dv_date
            })
            if dv_hematocrit then
                local hemoglobin_link = discrete.get_link_for_discrete_value(dv_hemoglobin, "Hemoglobin", 1, true)
                local hematocrit_link = discrete.get_link_for_discrete_value(dv_hematocrit, "Hematocrit", 2, true)
                --- @type HematocritHemoglobinDiscreteValuePair
                local pair = { hemoglobinLink = hemoglobin_link, hematocritLink = hematocrit_link }

                table.insert(low_hemoglobin_pairs, pair)
            end
        end

        return low_hemoglobin_pairs
    end

    --------------------------------------------------------------------------------
    --- Get Low Hematocrit Discrete Value Pairs
    ---
    --- @param dv_names_hematocrit string[] Names of the Hematocrit discrete values
    --- @param dv_names_hemoglobin string[] Names of the Hemoglobin discrete values
    --- @param low_hematocrit_value number Low value for hematocrit
    ---
    --- @return HematocritHemoglobinDiscreteValuePair[]
    --------------------------------------------------------------------------------
    function module.get_low_hematocrit_discrete_value_pairs(
        dv_names_hematocrit,
        dv_names_hemoglobin,
        low_hematocrit_value
    )
        --- @type HematocritHemoglobinDiscreteValuePair[]
        local low_hematocrit_pairs = {}

        local low_hematomocrit_values = discrete.get_ordered_discrete_values({
            discreteValueNames = dv_names_hematocrit,
            predicate = function(dv)
                local value = discrete.get_dv_value_number(dv)
                return value ~= nil and value <= low_hematocrit_value
            end,
            daysBack = 31
        })
        for i = 1, #low_hematomocrit_values do
            local dv_hematocrit = low_hematomocrit_values[i]
            local dv_date = dv_hematocrit.result_date
            local dv_hemoglobin = dv_date and discrete.get_discrete_value_nearest_to_date({
                discreteValueNames = dv_names_hemoglobin,
                date = dv_date
            })
            if dv_hemoglobin then
                local hematocrit_link = discrete.get_link_for_discrete_value(dv_hematocrit, "Hematocrit", 1, true)
                local hemoglobin_link = discrete.get_link_for_discrete_value(dv_hemoglobin, "Hemoglobin", 2, true)
                --- @type HematocritHemoglobinDiscreteValuePair
                local pair = { hemoglobinLink = hemoglobin_link, hematocritLink = hematocrit_link }
                table.insert(low_hematocrit_pairs, pair)
            end
        end
        return low_hematocrit_pairs
    end

    --- @class (exact) HematocritHemoglobinPeakDropLinks
    --- @field hemoglobinPeakLink CdiAlertLink
    --- @field hemoglobinDropLink CdiAlertLink
    --- @field hematocritPeakLink CdiAlertLink
    --- @field hematocritDropLink CdiAlertLink

    --------------------------------------------------------------------------------
    --- Get Hemoglobin and Hematocrit Links denoting a significant drop in hemoglobin
    ---
    --- @param dv_names_hemoglobin string[] Names of the Hemoglobin discrete values
    --- @param dv_names_hematocrit string[] Names of the Hematocrit discrete values
    --- @param low_hemoglobin_value number Low value for hemoglobin
    ---
    --- @return HematocritHemoglobinPeakDropLinks? - Peak and Drop links for Hemoglobin and Hematocrit if present
    --------------------------------------------------------------------------------
    function module.get_hemoglobin_drop_pairs(dv_names_hemoglobin, dv_names_hematocrit, low_hemoglobin_value)
        local hemoglobin_peak_link = nil
        local hemoglobin_drop_link = nil
        local hematocrit_peak_link = nil
        local hematocrit_drop_link = nil

        local highest_hemoglobin_in_past_week = discrete.get_highest_discrete_value({
            discreteValueNames = dv_names_hemoglobin,
        })

        if not highest_hemoglobin_in_past_week then return nil end

        local lowest_hemoglobin_in_past_week_after_highest = discrete.get_lowest_discrete_value({
            discreteValueNames = dv_names_hemoglobin,
            predicate = function(dv)
                return highest_hemoglobin_in_past_week ~= nil and
                    dv.result_date > highest_hemoglobin_in_past_week.result_date
            end
        })
        if not lowest_hemoglobin_in_past_week_after_highest then return nil end
        if lowest_hemoglobin_in_past_week_after_highest.result > low_hemoglobin_value then
            return nil
        end

        local hemoglobin_delta = 0

        if highest_hemoglobin_in_past_week and lowest_hemoglobin_in_past_week_after_highest then
            hemoglobin_delta = discrete.get_dv_value_number(highest_hemoglobin_in_past_week) -
                discrete.get_dv_value_number(lowest_hemoglobin_in_past_week_after_highest)
            if hemoglobin_delta >= 2 then
                hemoglobin_peak_link = discrete.get_link_for_discrete_value(highest_hemoglobin_in_past_week,
                    "Hemoglobin", 1, true)
                hemoglobin_drop_link = discrete.get_link_for_discrete_value(lowest_hemoglobin_in_past_week_after_highest,
                    "Hemoglobin", 2, true)
                local hemoglobin_peak_hemocrit = discrete.get_discrete_value_nearest_to_date({
                    discreteValueNames = dv_names_hematocrit,
                    date = highest_hemoglobin_in_past_week.result_date
                })
                local hemoglobin_drop_hemocrit = discrete.get_discrete_value_nearest_to_date({
                    discreteValueNames = dv_names_hematocrit,
                    date = lowest_hemoglobin_in_past_week_after_highest.result_date
                })
                if hemoglobin_peak_hemocrit then
                    hematocrit_peak_link = discrete.get_link_for_discrete_value(hemoglobin_peak_hemocrit,
                        "Hematocrit", 3, true)
                end
                if hemoglobin_drop_hemocrit then
                    hematocrit_drop_link = discrete.get_link_for_discrete_value(hemoglobin_drop_hemocrit,
                        "Hematocrit", 4, true)
                end
            end
        end

        if hemoglobin_peak_link and hemoglobin_drop_link and hematocrit_peak_link and hematocrit_drop_link then
            return {
                hemoglobinPeakLink = hemoglobin_peak_link,
                hemoglobinDropLink = hemoglobin_drop_link,
                hematocritPeakLink = hematocrit_peak_link,
                hematocritDropLink = hematocrit_drop_link
            }
        else
            return nil
        end
    end

    --------------------------------------------------------------------------------
    --- Get Hemoglobin and Hematocrit Links denoting a significant drop in hematocrit
    ---
    --- @param dv_names_hemoglobin string[] Names of the Hemoglobin discrete values
    --- @param dv_names_hematocrit string[] Names of the Hematocrit discrete values
    --- @param low_hematocrit_value number Low value for hematocrit
    ---
    --- @return HematocritHemoglobinPeakDropLinks? - Peak and Drop links for Hemoglobin and Hematocrit if present
    --------------------------------------------------------------------------------
    function module.get_hematocrit_drop_pairs(dv_names_hemoglobin, dv_names_hematocrit, low_hematocrit_value)
        local hemoglobin_peak_link = nil
        local hemoglobin_drop_link = nil
        local hematocrit_peak_link = nil
        local hematocrit_drop_link = nil

        -- If we didn't find the hemoglobin drop, look for a hematocrit drop
        local highest_hematocrit_in_past_week = discrete.get_highest_discrete_value({
            discreteValueNames = dv_names_hematocrit,
        })

        if not highest_hematocrit_in_past_week then return nil end

        local lowest_hematocrit_in_past_week_after_highest = discrete.get_lowest_discrete_value({
            discreteValueNames = dv_names_hematocrit,
            predicate = function(dv)
                return highest_hematocrit_in_past_week ~= nil and
                    dv.result_date > highest_hematocrit_in_past_week.result_date
            end
        })

        if not lowest_hematocrit_in_past_week_after_highest then return nil end

        local log = require("cdi.log")
        log.debug("lowest_hematocrit_in_past_week_after_highest.result: " .. 
            tostring(lowest_hematocrit_in_past_week_after_highest.result) .. ", low_hematocrit_value: " .. 
            tostring(low_hematocrit_value))

        if lowest_hematocrit_in_past_week_after_highest.result > low_hematocrit_value then
            return nil
        end

        local hematocrit_delta = 0

        if highest_hematocrit_in_past_week and lowest_hematocrit_in_past_week_after_highest then
            hematocrit_delta = discrete.get_dv_value_number(highest_hematocrit_in_past_week) -
                discrete.get_dv_value_number(lowest_hematocrit_in_past_week_after_highest)
            if hematocrit_delta >= 6 then
                hematocrit_peak_link = discrete.get_link_for_discrete_value(highest_hematocrit_in_past_week,
                    "Hematocrit", 5, true)
                hematocrit_drop_link = discrete.get_link_for_discrete_value(lowest_hematocrit_in_past_week_after_highest,
                    "Hematocrit", 6, true)
                local hemocrit_peak_hemoglobin = discrete.get_discrete_value_nearest_to_date({
                    discreteValueNames = dv_names_hemoglobin,
                    date = highest_hematocrit_in_past_week.result_date
                })
                local hemocrit_drop_hemoglobin = discrete.get_discrete_value_nearest_to_date({
                    discreteValueNames = dv_names_hemoglobin,
                    date = lowest_hematocrit_in_past_week_after_highest.result_date
                })
                if hemocrit_peak_hemoglobin then
                    hemoglobin_peak_link = discrete.get_link_for_discrete_value(hemocrit_peak_hemoglobin,
                        "Hemoglobin", 7, true)
                end
                if hemocrit_drop_hemoglobin then
                    hemoglobin_drop_link = discrete.get_link_for_discrete_value(hemocrit_drop_hemoglobin,
                        "Hemoglobin", 8, true)
                end
            end
        end

        if hemoglobin_peak_link and hemoglobin_drop_link and hematocrit_peak_link and hematocrit_drop_link then
            return {
                hemoglobinPeakLink = hemoglobin_peak_link,
                hemoglobinDropLink = hemoglobin_drop_link,
                hematocritPeakLink = hematocrit_peak_link,
                hematocritDropLink = hematocrit_drop_link
            }
        else
            return nil
        end
    end

    return module
end
