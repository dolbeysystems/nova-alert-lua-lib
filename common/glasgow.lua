---@diagnostic disable-next-line:name-style-check
return function(Account)
    local module = {}
    local discrete = require("libs.common.discrete_values")(Account)
    local links = require("libs.common.basic_links")(Account)
    local dates = require("libs.common.dates")
    local log = require("cdi.log")
    local cdi_alert_link = require "cdi.link"


    --- @param value number
    --- @param consecutive boolean
    --- @return CdiAlertLink[]
    local function glasgow_linked_values(value, consecutive)
        local score_dvs = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_glasgow_coma_scale,
            -- the annotations on predicate suggest that this is always true
            predicate = function(dv_, num) return num ~= nil end
        }
        local eye_dvs = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_glasgow_eye_opening,
            predicate = function(dv, num_) return dv.result ~= nil end
        }
        local verbal_dvs = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_glasgow_verbal,
            predicate = function(dv, num_) return dv.result ~= nil end
        }
        local motor_dvs = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_glasgow_motor,
            predicate = function(dv, num_) return dv.result ~= nil end
        }
        local oxygen_dvs = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_oxygen_therapy,
            predicate = function(dv, num_)
                return string.find(dv.result, "vent") ~= nil or
                    string.find(dv.result, "Vent") ~= nil
            end
        }

        local matched_list = {}
        local a = #score_dvs
        local b = #eye_dvs
        local c = #verbal_dvs
        local d = #motor_dvs
        local w = #score_dvs - 1
        local x = #eye_dvs - 1
        local y = #verbal_dvs - 1
        local z = #motor_dvs - 1

        local clean_numbers = function(num) return tonumber(string.gsub(num, "[<>]", "")) end
        local twelve_hour_check = function(date, oxygen_dvs_)
            for _, dv in ipairs(oxygen_dvs_) do
                local dv_date_int = dv.result_date
                local start_date = dv_date_int - (12 * 3600)
                local end_date = dv_date_int - (12 * 3600)
                if start_date <= date and date <= end_date then
                    return false
                end
            end
            return true
        end
        local function get_start_link()
            if
                a > 0 and b > 0 and c > 0 and d > 0 and
                eye_dvs[b].result ~= 'Oriented' and
                clean_numbers(score_dvs[a].result) <= value and
                score_dvs[a].result_date == eye_dvs[b].result_date and
                score_dvs[a].result_date == verbal_dvs[c].result_date and
                score_dvs[a].result_date == motor_dvs[d].result_date and
                twelve_hour_check(score_dvs[a].result_date, oxygen_dvs)
            then
                local matching_date = score_dvs[a].result_date
                local link = cdi_alert_link()
                link.discrete_value_id = score_dvs[a].unique_id
                link.link_text =
                    matching_date ..
                    " Total GCS = " .. score_dvs[a].result ..
                    " (Eye Opening: " .. eye_dvs[b].result ..
                    ", Verbal Response: " .. verbal_dvs[c].result ..
                    ", Motor Response: " .. motor_dvs[d].result .. ")"
                return link
            end
            return nil
        end

        local function get_last_link()
            if
                w > 0 and x > 0 and y > 0 and z > 0 and
                eye_dvs[x].result ~= 'Oriented' and
                clean_numbers(score_dvs[w].result) <= value and
                score_dvs[w].result_date == eye_dvs[x].result_date and
                score_dvs[w].result_date == verbal_dvs[y].result_date and
                score_dvs[w].result_date == motor_dvs[z].result_date and
                twelve_hour_check(score_dvs[w].result_date, oxygen_dvs)
            then
                local matching_date = score_dvs[w].result_date
                local link = cdi_alert_link()
                link.discrete_value_id = score_dvs[w].unique_id
                link.link_text =
                    matching_date ..
                    " Total GCS = " .. score_dvs[w].result ..
                    " (Eye Opening: " .. eye_dvs[x].result ..
                    ", Verbal Response: " .. verbal_dvs[y].result ..
                    ", Motor Response: " .. motor_dvs[z].result .. ")"
                return link
            end
            return nil
        end

        if consecutive then
            if a >= 1 then
                for _ = 1, #score_dvs do
                    local start_link = get_start_link()
                    local last_link = get_last_link()

                    if start_link ~= nil and last_link ~= nil then
                        table.insert(matched_list, start_link)
                        table.insert(matched_list, last_link)
                        return matched_list
                    else
                        a = a - 1; b = b - 1; c = c - 1; d = d - 1;
                        w = w - 1; x = x - 1; y = y - 1; z = z - 1;
                    end
                end
            else
                for _ = 1, #score_dvs do
                    local start_link = get_start_link()

                    if start_link ~= nil then
                        table.insert(matched_list, start_link)
                        return matched_list
                    else
                        a = a - 1; b = b - 1; c = c - 1; d = d - 1;
                    end
                end
            end
        else
            for _ = 1, #score_dvs do
                local start_link = get_start_link()

                if start_link ~= nil then
                    table.insert(matched_list, start_link)
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
