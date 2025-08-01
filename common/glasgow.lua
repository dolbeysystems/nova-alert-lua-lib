---@diagnostic disable-next-line:name-style-check
return function(Account)
    local module = {}
    local discrete = require("libs.common.discrete_values")(Account)
    local codes = require("libs.common.codes")(Account)
    local dates = require "libs.common.dates"
    local site_discretes = require("libs.common.site_discretes")
    local log = require("cdi.log")
    local cdi_alert_link = require "cdi.link"
    ---------------------------------------------------------------------------------------------
    --- Abstract link args class
    ---------------------------------------------------------------------------------------------
    --- @class (exact) GetGlasgowLinksArgs
    --- @field not_consecutive boolean? Determines if we are looking for consecutive values or not.
    --- @field glasgow_calculation number? The custom calculation for the Glasgow Coma Score.
    --- @field permanent boolean? If true, the link will be permanent
    ---------------------------------------------------------------------------------------------


    --- @param args GetGlasgowLinksArgs
    --- @return CdiAlertLink[]
    function module.glasgow_linked_values(args)
        local not_consecutive = args.not_consecutive or true
        local glasgow_calculation = args.glasgow_calculation or 0
        local permanent = args.permanent or false

        local code_link_g30 = codes.make_code_prefix_link("G30.", "Alzheimers Disease")
        local abs_link_ch_baseline_mental_status = codes.make_abstraction_link("CHANGE_IN_BASELINE_MENTAL_STATUS", "Change in Baseline Mental Status")
        local code_link_dementia_2 = codes.make_code_prefix_link("F02.", "Dementia")
        local code_link_dementia_1 = codes.make_code_prefix_link("F01.", "Dementia")
        local code_link_dementia_3 = codes.make_code_prefix_link("F03.", "Dementia")
        if (
                (code_link_dementia_1 or
                    code_link_dementia_2 or
                    code_link_dementia_3 or
                    code_link_g30) and
                abs_link_ch_baseline_mental_status == nil
            ) and glasgow_calculation == 0
        then
            glasgow_calculation = 12
        elseif glasgow_calculation == 0 then
            glasgow_calculation = 14
        end

        local dvs_score = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_glasgow_coma_scale,
            -- the annotations on predicate suggest that this is always true
            predicate = function(dv_, num) return num ~= nil end
        }
        local dvs_eye = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_glasgow_eye_opening,
            predicate = function(dv, num_) return dv.result ~= nil end
        }
        local dvs_verbal = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_glasgow_verbal,
            predicate = function(dv, num_) return dv.result ~= nil end
        }
        local dvs_motor = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_glasgow_motor,
            predicate = function(dv, num_) return dv.result ~= nil end
        }
        local dvs_oxygen = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_oxygen_therapy,
            predicate = function(dv, num_)
                return dv.result ~= nil and dv.result ~= "" and
                    (string.find(dv.result, "vent") ~= nil or
                        string.find(dv.result, "Vent") ~= nil or
                        string.find(dv.result, "Mechanical Ventilation") ~= nil)
            end
        }

        local matched_list = {}
        local a = #dvs_score
        local b = #dvs_eye
        local c = #dvs_verbal
        local d = #dvs_motor
        local w = #dvs_score - 1
        local x = #dvs_eye - 1
        local y = #dvs_verbal - 1
        local z = #dvs_motor - 1

        local twelve_hour_check = function(date, oxygen_dvs_)
            for _, dv in ipairs(oxygen_dvs_) do
                local dv_date_int = dv.result_date
                local start_date = dv_date_int - (12 * 3600)
                local end_date = dv_date_int + (12 * 3600)
                if start_date <= date and date <= end_date then
                    return false
                end
            end
            return true
        end
        local function get_first_link()
            if
                a > 0 and b > 0 and c > 0 and d > 0 and
                dvs_eye[b].result ~= 'Oriented' and
                tonumber(dvs_score[a].result) <= glasgow_calculation and
                dvs_score[a].result_date == dvs_eye[b].result_date and
                dvs_score[a].result_date == dvs_verbal[c].result_date and
                dvs_score[a].result_date == dvs_motor[d].result_date and
                twelve_hour_check(dvs_score[a].result_date, dvs_oxygen)
            then
                
                local matching_date = dvs_score[a].result_date
                local link = cdi_alert_link()
                link.discrete_value_id = dvs_score[a].unique_id
                link.link_text =
                    dates.date_int_to_string(matching_date, "%m/%d/%Y %H:%M") ..
                    " Total GCS = " .. dvs_score[a].result ..
                    " (Eye Opening: " .. dvs_eye[b].result ..
                    ", Verbal Response: " .. dvs_verbal[c].result ..
                    ", Motor Response: " .. dvs_motor[d].result .. ")"
                link.sequence = 1
                link.permanent = permanent
                link.discrete_value_name = dvs_score[a].name
                return link
            end
            return nil
        end

        local function get_second_link()
            if
                w > 0 and x > 0 and y > 0 and z > 0 and
                dvs_eye[x].result ~= 'Oriented' and
                tonumber(dvs_score[w].result) <= glasgow_calculation and
                dvs_score[w].result_date == dvs_eye[x].result_date and
                dvs_score[w].result_date == dvs_verbal[y].result_date and
                dvs_score[w].result_date == dvs_motor[z].result_date and
                twelve_hour_check(dvs_score[w].result_date, dvs_oxygen) and
                permanent == false
            then
                local matching_date = dvs_score[w].result_date
                local link = cdi_alert_link()
                link.discrete_value_id = dvs_score[w].unique_id
                link.link_text =
                    dates.date_int_to_string(matching_date, "%m/%d/%Y %H:%M") ..
                    " Total GCS = " .. dvs_score[w].result ..
                    " (Eye Opening: " .. dvs_eye[x].result ..
                    ", Verbal Response: " .. dvs_verbal[y].result ..
                    ", Motor Response: " .. dvs_motor[z].result .. ")"
                link.sequence = 1
                link.permanent = permanent
                link.discrete_value_name = dvs_score[w].name
                return link
            end
            return nil
        end

        if not_consecutive == false then
            if a >= 1 then
                for _ = 1, #dvs_score do
                    local first_link = get_first_link()
                    local second_link = get_second_link()

                    if first_link ~= nil and second_link ~= nil then
                        table.insert(matched_list, first_link)
                        table.insert(matched_list, second_link)
                        return matched_list
                    else
                        a = a - 1; b = b - 1; c = c - 1; d = d - 1;
                        w = w - 1; x = x - 1; y = y - 1; z = z - 1;
                    end
                end
            else
                for _ = 1, #dvs_score do
                    local first_link = get_first_link()

                    if first_link ~= nil then
                        table.insert(matched_list, first_link)
                        return matched_list
                    else
                        a = a - 1; b = b - 1; c = c - 1; d = d - 1;
                    end
                end
            end
        else
            for _ = 1, #dvs_score do
                local first_link = get_first_link()

                if first_link ~= nil then
                    table.insert(matched_list, first_link)
                    return matched_list
                else
                    a = a - 1; b = b - 1; c = c - 1; d = d - 1;
                end
            end
        end
        return matched_list
    end

    return module
end
