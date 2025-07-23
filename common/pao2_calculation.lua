---@diagnostic disable-next-line:name-style-check
return function(Account)
    local module = {}
    local discrete = require("libs.common.discrete_values")(Account)
    local links = require("libs.common.basic_links")(Account)
    local dates = require("libs.common.dates")
    local site_discretes = require("libs.common.site_discretes")
    local log = require("cdi.log")
    local cdi_alert_link = require "cdi.link"


    --- @class (exact) PaO2FiO2Links
    --- @class (exact) SpO2PaO2Links

    --------------------------------------------------------------------------------
    --- Get the links for PaO2/FiO2, through various attempts
    ---
    --- Links returned use the seq field to communicate other meaning:
    --- 2 - Ratio was calcluated by site
    --- 8 - Ratio was calculated by us and needs a warning added before it
    ---
    --- @param calc_pao2_fio2 number - The calculated PaO2/FiO2 ratio to compare against
    --- 
    --- @return PaO2FiO2Links[]
    --------------------------------------------------------------------------------
    function module.get_pao2_fio2_links(calc_pao2_fio2)

        --- Final links
        --- @type CdiAlertLink[]
        local pao2_fio2_ratio_links = {}

        --- Lookup table for converting spO2 to paO2
        local spo2_to_pao2_lookup = {
            [80] = 44,
            [81] = 45,
            [82] = 46,
            [83] = 47,
            [84] = 49,
            [85] = 50,
            [86] = 51,
            [87] = 52,
            [88] = 54,
            [89] = 56,
            [90] = 58,
            [91] = 60,
            [92] = 64,
            [93] = 68,
            [94] = 73,
            [95] = 80,
            [96] = 90
        }

        --- Lookup table for converting spO2 to paO2
        local oxgyen_therapy_to_fio2_lookup = {
            ["1L/min NC"] = 0.24,
            ["2L/min NC"] = 0.28,
            ["3L/min NC"] = 0.32,
            ["4L/min NC"] = 0.36,
            ["5L/min NC"] = 0.40,
            ["6L/min NC"] = 0.44
        }
        --- Lookup table for converting oxygen flow rate to FiO2
        local flow_rate_to_fi_o2_lookup = {
            [1] = 0.24, [2] = 0.28, [3] = 0.32, [4] = 0.36, [5] = 0.40, [6] = 0.44
        }
        --- All fio2 dvs from the last day
        local fio2_dvs = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_fio2,
            daysBack = 1
        }
        --- All resp rate dvs from the last day
        local resp_rate_dv = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_respiratory_rate,
            daysBack = 1
        }
        --- All oxygen therapy dvs from the last day
        local oxygen_therapy_dv = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_oxygen_therapy,
            daysBack = 1
        }
        --- All oxygen dv pairs from the last day
        local oxygen_pairs = discrete.get_discrete_value_pairs {
            discreteValueNames1 = site_discretes.dv_names_oxygen_flow_rate,
            discreteValueNames2 = site_discretes.dv_names_oxygen_therapy,
            predicate1 = function(dv)
                return
                    dates.date_is_less_than_x_days_ago(dv.result_date, 1) and
                    tonumber(dv.result) ~= nil
            end,
            predicate2 = function(dv)
                return
                    dates.date_is_less_than_x_days_ago(dv.result_date, 1) and
                    dv.result ~= nil
            end
        }

        -- Method #1 - Look for site calculated discrete values
        pao2_fio2_ratio_links = links.get_discrete_value_links {
            discreteValueNames = site_discretes.dv_names_pao2_fio2,
            text = "PaO2/FiO2",
            predicate = function(dv, num)
                return dates.date_is_less_than_x_days_ago(dv.result_date, 1) and tonumber(num) ~= nil and tonumber(num) < calc_pao2_fio2
            end,
            seq = 2
        }
        if #pao2_fio2_ratio_links > 0 then
            -- If we found links, return them
            return pao2_fio2_ratio_links
        end

        if #pao2_fio2_ratio_links == 0 then
            -- Method #2 - Look through FiO2 values for matching PaO2 values
            for _, fio2_dv in ipairs(fio2_dvs) do
                local pao2_dv = discrete.get_discrete_value_nearest_to_date {
                    discreteValueNames = site_discretes.dv_names_pao2,
                    date = fio2_dv.result_date,
                    predicate = function(dv)
                        return
                            dates.dates_are_less_than_x_minutes_apart(fio2_dv.result_date, dv.result_date, 5) and
                            tonumber(dv.result) ~= nil
                    end
                }
                if pao2_dv then
                    local fio2 = discrete.get_dv_value_number(fio2_dv)
                    local pao2 = discrete.get_dv_value_number(pao2_dv)
                    local resp_rate = "XX"
                    local percentage = tonumber(fio2) / 100
                    if percentage ~= nil and percentage > 0 then
                        local ratio = math.floor(pao2 / fio2)
                        if ratio <= 300 then
                            if #resp_rate_dv > 0 then
                                for _, resp_rate_item in ipairs(resp_rate_dv) do
                                    if resp_rate_item.result_date == pao2_dv.result_date then
                                        resp_rate = resp_rate_item.result
                                    end
                                end
                            end
                            -- Build links
                            local link = cdi_alert_link()
                            link.discrete_value_id = pao2_dv.unique_id
                            link.link_text =
                                dates.date_int_to_string(pao2_dv.result_date) ..
                                " - Respiratory Rate: " .. resp_rate ..
                                ", SpO2: " .. pao2 ..
                                ", FiO2: " .. fio2 ..
                                ", Estimated PF Ratio- " .. ratio
                            link.sequence = 8
                            table.insert(pao2_fio2_ratio_links, link)
                        end
                    end
                end
            end
        end

        if #pao2_fio2_ratio_links == 0 then
            -- Method #3 - Look through FiO2 values for matching SpO2 values
            for _, fio2_dv in ipairs(fio2_dvs) do
                local spo2_dv = discrete.get_discrete_value_nearest_to_date {
                    discreteValueNames = site_discretes.dv_names_spo2,
                    date = fio2_dv.result_date,
                    predicate = function(dv)
                        return
                            dates.dates_are_less_than_x_minutes_apart(fio2_dv.result_date, dv.result_date, 5) and
                            tonumber(dv.result) ~= nil
                    end
                }
                if spo2_dv then
                    local fio2 = discrete.get_dv_value_number(fio2_dv)
                    local spo2 = discrete.get_dv_value_number(spo2_dv)
                    local resp_rate = "XX"
                    local percentage = tonumber(fio2) / 100
                    local pao2 = spo2_to_pao2_lookup[spo2]
                    if pao2 ~= nil and pao2 > 0 and percentage ~= nil and percentage > 0 then
                        local ratio = math.floor(pao2 / fio2)
                        if ratio <= 300 then
                            if #resp_rate_dv > 0 then
                                for _, resp_rate_item in ipairs(resp_rate_dv) do
                                    if resp_rate_item.result_date == spo2_dv.result_date then
                                        resp_rate = resp_rate_item.result
                                    end
                                end
                            end
                            -- Build link
                            local link = cdi_alert_link()
                            link.discrete_value_id = spo2_dv.unique_id
                            link.link_text =
                                dates.date_int_to_string(spo2_dv.result_date) ..
                                " - Respiratory Rate: " .. resp_rate ..
                                ", SpO2: " .. spo2 ..
                                ", FiO2: " .. fio2 ..
                                ", Estimated PF Ratio- " .. ratio
                            link.sequence = 8
                            table.insert(pao2_fio2_ratio_links, link)
                        end
                    end
                end
            end
        end

        if #pao2_fio2_ratio_links == 0 then
            -- Method #4 - Look through Oxygen values for matching PaO2 values
            for _, oxygen_pair in ipairs(oxygen_pairs) do
                local oxygen_flow_rate_value = discrete.get_dv_value_number(oxygen_pair.first)
                local oxygen_therapy_value = oxygen_pair.second.result
                --- @type number?
                local fio2 = nil
                if oxygen_therapy_value == "Nasal Cannula" then
                    fio2 = flow_rate_to_fi_o2_lookup[oxygen_flow_rate_value]
                    if tonumber(fio2) ~= nil and tonumber(fio2) > 0 then
                        local pao2_dv = discrete.get_discrete_value_nearest_to_date {
                            discreteValueNames = site_discretes.dv_names_pao2,
                            date = oxygen_pair.first.result_date,
                            predicate = function(dv)
                                return
                                    dates.dates_are_less_than_x_minutes_apart(oxygen_pair.first.result_date, dv.result_date, 5) and
                                    tonumber(dv.result) ~= nil
                            end
                        }
                        if pao2_dv then
                            local pao2 = discrete.get_dv_value_number(pao2_dv)
                            local resp_rate = "XX"
                            local ratio = math.floor(pao2 / fio2)
                            if ratio <= 300 then
                                if #resp_rate_dv > 0 then
                                    for _, resp_rate_item in ipairs(resp_rate_dv) do
                                        if resp_rate_item.result_date == pao2_dv.result_date then
                                            resp_rate = resp_rate_item.result
                                        end
                                    end
                                end
                                -- Build link
                                local link = cdi_alert_link()
                                link.discrete_value_id = pao2_dv.unique_id
                                link.link_text =
                                    dates.date_int_to_string(pao2_dv.result_date) ..
                                    " - Respiratory Rate: " .. resp_rate ..
                                    ", PaO2: " .. pao2 ..
                                    ", Oxygen Flow Rate: " .. oxygen_flow_rate_value ..
                                    ", Oxygen Therapy: " .. oxygen_therapy_value ..
                                    ", Estimated PF Ratio- " .. ratio
                                link.sequence = 8
                                table.insert(pao2_fio2_ratio_links, link)
                            end
                        end
                    end
                end
            end
        end

        if #pao2_fio2_ratio_links == 0 then
            -- Method #5 - Look through Oxygen values for matching SpO2 values
            for _, oxygen_pair in ipairs(oxygen_pairs) do
                local oxygen_flow_rate_value = discrete.get_dv_value_number(oxygen_pair.first)
                local oxygen_therapy_value = oxygen_pair.second.result
                --- @type number?
                local fio2 = nil
                if oxygen_therapy_value == "Nasal Cannula" then
                    fio2 = flow_rate_to_fi_o2_lookup[oxygen_flow_rate_value]
                    if tonumber(fio2) ~= nil and tonumber(fio2) > 0 then
                        local spo2_dv = discrete.get_discrete_value_nearest_to_date {
                            discreteValueNames = site_discretes.dv_names_spo2,
                            date = oxygen_pair.first.result_date,
                            predicate = function(dv)
                                return
                                    dates.dates_are_less_than_x_minutes_apart(oxygen_pair.first.result_date, dv.result_date,
                                        5) and
                                    tonumber(dv.result) ~= nil
                            end
                        }

                        if spo2_dv then
                            local spo2 = discrete.get_dv_value_number(spo2_dv)
                            local resp_rate = "XX"
                            local pao2 = spo2_to_pao2_lookup[spo2]
                            if pao2 then
                                local ratio = math.floor(pao2 / fio2)
                                if ratio <= 300 then
                                    if #resp_rate_dv > 0 then
                                        for _, resp_rate_item in ipairs(resp_rate_dv) do
                                            if resp_rate_item.result_date == spo2_dv.result_date then
                                                resp_rate = resp_rate_item.result
                                            end
                                        end
                                    end
                                    -- Build link
                                    local link = cdi_alert_link()
                                    link.discrete_value_id = spo2_dv.unique_id
                                    link.link_text =
                                        dates.date_int_to_string(spo2_dv.result_date) ..
                                        " - Respiratory Rate: " .. resp_rate ..
                                        ", SpO2: " .. spo2 ..
                                        ", Oxygen Flow Rate: " .. oxygen_flow_rate_value ..
                                        ", Oxygen Therapy: " .. oxygen_therapy_value ..
                                        ", Estimated PF Ratio- " .. ratio
                                    link.sequence = 8
                                    table.insert(pao2_fio2_ratio_links, link)
                                end
                            end
                        end
                    end
                end
            end
        end

        if #pao2_fio2_ratio_links == 0 then
            -- Method #6 - Look through Oxygen therapy values for matching PaO2 values
            for _, oxygen_therapy_item in ipairs(oxygen_therapy_dv) do
                local oxygen_therapy_value = oxygen_therapy_item.result
                --- @type number?
                local fio2 = nil
                fio2 = oxgyen_therapy_to_fio2_lookup[oxygen_therapy_item.result]
                if fio2 then
                    if tonumber(fio2) ~= nil and tonumber(fio2) > 0 then
                        local pao2_dv = discrete.get_discrete_value_nearest_to_date {
                            discreteValueNames = site_discretes.dv_names_pao2,
                            date = oxygen_therapy_item.result_date,
                            predicate = function(dv)
                                return
                                    dates.dates_are_less_than_x_minutes_apart(oxygen_therapy_item.result_date, dv.result_date, 5) and
                                    tonumber(dv.result) ~= nil
                            end
                        }
                        if pao2_dv then
                            local pao2 = discrete.get_dv_value_number(pao2_dv)
                            local resp_rate = "XX"
                            if pao2 then
                                local ratio = math.floor(pao2 / fio2)
                                if ratio <= 300 then
                                    if #resp_rate_dv > 0 then
                                        for _, resp_rate_item in ipairs(resp_rate_dv) do
                                            if resp_rate_item.result_date == pao2_dv.result_date then
                                                resp_rate = resp_rate_item.result
                                            end
                                        end
                                    end
                                    -- Build link
                                    local link = cdi_alert_link()
                                    link.discrete_value_id = pao2_dv.unique_id
                                    link.link_text =
                                        dates.date_int_to_string(pao2_dv.result_date) ..
                                        " - Respiratory Rate: " .. resp_rate ..
                                        ", PaO2: " .. pao2 ..
                                        ", Oxygen Therapy: " .. oxygen_therapy_value ..
                                        ", Estimated PF Ratio- " .. ratio
                                    link.sequence = 8
                                    table.insert(pao2_fio2_ratio_links, link)
                                end
                            end
                        end
                    end
                end
            end
        end

        if #pao2_fio2_ratio_links == 0 then
            -- Method #7 - Look through Oxygen therapy values for matching SpO2 values
            for _, oxygen_therapy_item in ipairs(oxygen_therapy_dv) do
                local oxygen_therapy_value = oxygen_therapy_item.result
                --- @type number?
                local fio2 = nil
                fio2 = oxgyen_therapy_to_fio2_lookup[oxygen_therapy_item.result]
                if fio2 then
                    if tonumber(fio2) ~= nil and tonumber(fio2) > 0 then
                        local spo2_dv = discrete.get_discrete_value_nearest_to_date {
                            discreteValueNames = site_discretes.dv_names_spo2,
                            date = oxygen_therapy_item.result_date,
                            predicate = function(dv)
                                return
                                    dates.dates_are_less_than_x_minutes_apart(oxygen_therapy_item.result_date, dv.result_date, 5) and
                                    tonumber(dv.result) ~= nil
                            end
                        }
                        if spo2_dv then
                            local spo2 = discrete.get_dv_value_number(spo2_dv)
                            local resp_rate = "XX"
                            local pao2 = spo2_to_pao2_lookup[spo2]
                            if pao2 then
                                local ratio = math.floor(pao2 / fio2)
                                if ratio <= 300 then
                                    if #resp_rate_dv > 0 then
                                        for _, resp_rate_item in ipairs(resp_rate_dv) do
                                            if resp_rate_item.result_date == spo2_dv.result_date then
                                                resp_rate = resp_rate_item.result
                                            end
                                        end
                                    end
                                    -- Build link
                                    local link = cdi_alert_link()
                                    link.discrete_value_id = spo2_dv.unique_id
                                    link.link_text =
                                        dates.date_int_to_string(spo2_dv.result_date) ..
                                        " - Respiratory Rate: " .. resp_rate ..
                                        ", SpO2: " .. spo2 ..
                                        ", Oxygen Therapy: " .. oxygen_therapy_value ..
                                        ", Estimated PF Ratio- " .. ratio
                                    link.sequence = 8
                                    table.insert(pao2_fio2_ratio_links, link)
                                end
                            end
                        end
                    end
                end
            end
        end
        return pao2_fio2_ratio_links
    end



    --------------------------------------------------------------------------------
    --- Get fallback links for PaO2 and SpO2
    --- These are gathered if the PaO2/FiO2 collection fails
    --- 
    --- @return SpO2PaO2Links[]
    --------------------------------------------------------------------------------
    function module.get_pao2_spo2_links()
        --- @param link_text string
        --- @param discrete_value DiscreteValue
        --- @param seq number
        ---
        --- @return CdiAlertLink
        local function create_link(link_text, discrete_value, seq)
            local link = cdi_alert_link()
            link.link_text = links.replace_link_place_holders(link_text, nil, nil, discrete_value, nil)
            link.discrete_value_id = discrete_value.unique_id
            link.discrete_value_name = discrete_value.name
            link.sequence = seq
            return link
        end

        local sp_o2_discrete_values = {}
        local pa_o2_discrete_values = {}
        local o2_therapy_discrete_values = {}
        local respiratory_rate_discrete_values = {}
        local sp_o2_link_text = "SpO2: [VALUE] (Result Date: [RESULTDATE])"
        local pao2_link_text = "PaO2: [VALUE] (Result Date: [RESULTDATE])"
        local o2_therapy_link_text = "Oxygen Therapy '[VALUE]' (Result Date: [RESULTDATE])"
        local respiratory_rate_link_text = "Respiratory Rate: [VALUE] (Result Date: [RESULTDATE])"
        local date_limit = dates.days_ago(1)
        local pa_dv_idx = nil
        local sp_dv_idx = nil
        local ot_dv_idx = nil
        local rr_dv_idx = nil
        local matching_date = nil
        local oxygen_value = "XX"
        local resp_rate_str = "XX"
        local matched_list = {}

        sp_o2_discrete_values = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_spo2,
            predicate = function(dv_, num)
                return dv_.result_date >= date_limit and tonumber(num) ~= nil and tonumber(num) < 91
            end
        }

        pa_o2_discrete_values = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_pao2,
            predicate = function(dv_, num)
                return dv_.result_date >= date_limit and tonumber(num) ~= nil and tonumber(num) <= 60
            end
        }

        o2_therapy_discrete_values = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_oxygen_therapy,
            predicate = function(dv_, num)
                return dv_.result_date >= date_limit and tonumber(num) ~= nil
            end
        }

        respiratory_rate_discrete_values = discrete.get_ordered_discrete_values {
            discreteValueNames = site_discretes.dv_names_respiratory_rate,
            predicate = function(dv_, num)
                return dv_.result_date >= date_limit and tonumber(num) ~= nil
            end
        }

        if #pa_o2_discrete_values > 0 then
            for idx, item in ipairs(pa_o2_discrete_values) do
                matching_date = item.result_date
                pa_dv_idx = idx
                if #o2_therapy_discrete_values > 0 then
                    for idx2, item2 in ipairs(o2_therapy_discrete_values) do
                        if item.result_date == item2.result_date then
                            matching_date = item.result_date
                            ot_dv_idx = idx2
                            oxygen_value = item2.result
                            break
                        end
                    end
                end
                if #respiratory_rate_discrete_values > 0 then
                    for idx3, item3 in ipairs(respiratory_rate_discrete_values) do
                        if item3.result_date == matching_date then
                            rr_dv_idx = idx3
                            resp_rate_str = item3.result
                            break
                        end
                    end
                end
                if matching_date then
                    matching_date = dates.date_int_to_string(matching_date)
                end
                table.insert(
                    matched_list,
                    create_link(
                        matching_date .. " Respiratory Rate: " .. resp_rate_str .. ", Oxygen Therapy: " .. oxygen_value ..
                        ", PaO2: " .. pa_o2_discrete_values[pa_dv_idx].result,
                        pa_o2_discrete_values[pa_dv_idx],
                        0
                    )
                )
                table.insert(
                    matched_list,
                    create_link(
                        pao2_link_text,
                        pa_o2_discrete_values[pa_dv_idx],
                        2
                    )
                )
                if ot_dv_idx then
                    table.insert(
                        matched_list,
                        create_link(
                            o2_therapy_link_text,
                            o2_therapy_discrete_values[ot_dv_idx],
                            3
                        )
                    )
                end
                if rr_dv_idx then
                    table.insert(
                        matched_list,
                        create_link(
                            respiratory_rate_link_text,
                            respiratory_rate_discrete_values[rr_dv_idx],
                            4
                        )
                    )
                end
            end
            return matched_list
        elseif #sp_o2_discrete_values > 0 then
            for idx, item in ipairs(sp_o2_discrete_values) do
                matching_date = item.result_date
                sp_dv_idx = idx

                if #o2_therapy_discrete_values > 0 then
                    for idx2, item2 in ipairs(o2_therapy_discrete_values) do
                        if item.result_date == item2.result_date then
                            matching_date = item.result_date
                            ot_dv_idx = idx2
                            oxygen_value = item2.result
                            break
                        end
                    end
                end
                if oxygen_value == nil then
                    oxygen_value = "XX"
                end
                if #respiratory_rate_discrete_values > 0 then
                    for idx3, item3 in ipairs(respiratory_rate_discrete_values) do
                        if item3.result_date == matching_date then
                            rr_dv_idx = idx3
                            resp_rate_str = item3.result
                            break
                        end
                    end
                end
                if resp_rate_str == nil then
                    resp_rate_str = "XX"
                end
                if matching_date then
                    matching_date = dates.date_int_to_string(matching_date)
                end
                table.insert(
                    matched_list,
                    create_link(
                        matching_date .. " Respiratory Rate: " .. resp_rate_str .. ", Oxygen Therapy: " .. oxygen_value ..
                        ", SpO2: " .. sp_o2_discrete_values[sp_dv_idx].result,
                        sp_o2_discrete_values[sp_dv_idx],
                        0
                    )
                )
                table.insert(
                    matched_list,
                    create_link(
                        sp_o2_link_text,
                        sp_o2_discrete_values[sp_dv_idx],
                        1
                    )
                )
                if ot_dv_idx then
                    table.insert(
                        matched_list,
                        create_link(
                            o2_therapy_link_text,
                            o2_therapy_discrete_values[ot_dv_idx],
                            5
                        )
                    )
                end
                if rr_dv_idx then
                    table.insert(
                        matched_list,
                        create_link(
                            respiratory_rate_link_text,
                            respiratory_rate_discrete_values[rr_dv_idx],
                            7
                        )
                    )
                end
            end
            return matched_list
        else
            return {}
        end
    end

    return module
end
