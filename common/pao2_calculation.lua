---@diagnostic disable-next-line:name-style-check
return function(Account)
    local module = {}
    local discrete = require("libs.common.discrete_values")(Account)
    local links = require("libs.common.basic_links")(Account)
    local dates = require("libs.common.dates")
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
    --- @param dv_names_fi_o2 string[] - List of discrete value names for FiO2
    --- @param dv_names_pa_o2_fi_o2 string[] - List of discrete value names for PaO2/FiO2
    --- @param dv_names_pa_o2 string[] - List of discrete value names for PaO2
    --- @param dv_names_sp_o2 string[] - List of discrete value names for SpO2
    --- @param dv_names_oxygen_flow_rate string[] - List of discrete value names for Oxygen Flow Rate
    --- @param dv_names_oxygen_therapy string[] - List of discrete value names for Oxygen Therapy
    --- @param dv_names_respiratory_rate string[] - List of discrete value names for Respiratory Rate
    --- @param calc_pa_o2_fi_o2 number - The calculated PaO2/FiO2 ratio to compare against
    --- 
    --- @return PaO2FiO2Links[]
    --------------------------------------------------------------------------------
    function module.get_pa_o2_fi_o2_links(dv_names_fi_o2,
                                          dv_names_pa_o2,
                                          dv_names_sp_o2,
                                          dv_names_oxygen_flow_rate,
                                          dv_names_oxygen_therapy,
                                          dv_names_respiratory_rate,
                                          dv_names_pa_o2_fi_o2,
                                          calc_pa_o2_fi_o2)

        if Account.id == "1640042638" then
            for _, dv_name in ipairs(dv_names_fi_o2) do
                log.debug("pao2 fio2 calculation dv_names_fi_o2: " .. tostring(dv_name))
            end
            for _, dv_name in ipairs(dv_names_pa_o2) do
                log.debug("pao2 fio2 calculation dv_names_pa_o2: " .. tostring(dv_name))
            end
            for _, dv_name in ipairs(dv_names_sp_o2) do
                log.debug("pao2 fio2 calculation dv_names_sp_o2: " .. tostring(dv_name))
            end
            for _, dv_name in ipairs(dv_names_oxygen_flow_rate) do
                log.debug("pao2 fio2 calculation dv_names_oxygen_flow_rate: " .. tostring(dv_name))
            end
            for _, dv_name in ipairs(dv_names_oxygen_therapy) do
                log.debug("pao2 fio2 calculation dv_names_oxygen_therapy: " .. tostring(dv_name))
            end
            for _, dv_name in ipairs(dv_names_respiratory_rate) do
                log.debug("pao2 fio2 calculation dv_names_respiratory_rate: " .. tostring(dv_name))
            end
            for _, dv_name in ipairs(dv_names_pa_o2_fi_o2) do
                log.debug("pao2 fio2 calculation dv_names_pa_o2_fi_o2: " .. tostring(dv_name))
            end
            log.debug("pao2 fio2 calculation calc_pa_o2_fi_o2: " .. tostring(calc_pa_o2_fi_o2))
        end
        --- Final links
        --- @type CdiAlertLink[]
        local pa_o2_fi_o2_ratio_links = {}

        --- Lookup table for converting spO2 to paO2
        local sp_o2_to_pa_o2_lookup = {
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
        local oxgyen_therapy_to_fi_o2_lookup = {
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
        --- All fi_o2 dvs from the last day
        local fi_o2_dvs = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_fi_o2,
            predicate = function(dv)
                return
                    dates.date_is_less_than_x_days_ago(dv.result_date, 1) and
                    tonumber(dv.result) ~= nil
            end
        }
        --- All resp rate dvs from the last day
        local resp_rate_dv = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_respiratory_rate,
            predicate = function(dv)
                return
                    dates.date_is_less_than_x_days_ago(dv.result_date, 1) and
                    tonumber(dv.result) ~= nil
            end
        }
        --- All oxygen therapy dvs from the last day
        local oxygen_therapy_dv = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_oxygen_therapy,
            predicate = function(dv)
                return
                    dates.date_is_less_than_x_days_ago(dv.result_date, 1) and
                    dv.result ~= nil
            end
        }
        --- All oxygen dv pairs from the last day
        local oxygen_pairs = discrete.get_discrete_value_pairs {
            discreteValueNames1 = dv_names_oxygen_flow_rate,
            discreteValueNames2 = dv_names_oxygen_therapy,
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

        if #pa_o2_fi_o2_ratio_links == 0 then
            -- Method #1 - Look for site calculated discrete values
            pa_o2_fi_o2_ratio_links = links.get_discrete_value_links {
                discreteValueNames = dv_names_pa_o2_fi_o2,
                text = "PaO2/FiO2",
                predicate = function(dv, num)
                    return dates.date_is_less_than_x_days_ago(dv.result_date, 1) and tonumber(num) ~= nil and tonumber(num) < calc_pa_o2_fi_o2
                end,
                seq = 2
            }
            if Account.id == "1640042638" then
                log.debug("Checking Method #1 for PaO2/FiO2 links - " .. tostring(#pa_o2_fi_o2_ratio_links) .. " links found")
            end
            if #pa_o2_fi_o2_ratio_links > 0 then
                -- If we found links, return them
                return pa_o2_fi_o2_ratio_links
            end
        end

        if #pa_o2_fi_o2_ratio_links == 0 then
            if Account.id == "1640042638" then
                log.debug("Checking Method #2 - Look through FiO2 values for matching PaO2 values")
            end
            -- Method #2 - Look through FiO2 values for matching PaO2 values
            for _, fi_o2_dv in ipairs(fi_o2_dvs) do
                local pa_o2_dv = discrete.get_discrete_value_nearest_to_date {
                    discreteValueNames = dv_names_pa_o2,
                    date = fi_o2_dv.result_date,
                    predicate = function(dv)
                        return
                            dates.dates_are_less_than_x_minutes_apart(fi_o2_dv.result_date, dv.result_date, 5) and
                            tonumber(dv.result) ~= nil
                    end
                }
                if Account.id == "1640042638" then
                    log.debug("Checking Method #2 - fi_o2_dv: " .. tostring(fi_o2_dv) .. ", sp_o2_dv: " .. tostring(pa_o2_dv))
                end
                if pa_o2_dv then
                    if Account.id == "1640042638" then
                        log.debug("Checking Method #2 - fi_o2_dv: " .. tostring(fi_o2_dv) ..
                            ", pa_o2_dv: " .. tostring(pa_o2_dv))
                    end
                    local fi_o2 = discrete.get_dv_value_number(fi_o2_dv)
                    local pa_o2 = discrete.get_dv_value_number(pa_o2_dv)
                    local resp_rate = "XX"
                    local percentage = tonumber(fi_o2) / 100
                    if percentage ~= nil and percentage > 0 then
                        local ratio = pa_o2 / fi_o2
                        if ratio <= 300 then
                            if #resp_rate_dv > 0 then
                                for _, resp_rate_item in ipairs(resp_rate_dv) do
                                    if resp_rate_item.result_date == pa_o2_dv.result_date then
                                        resp_rate = resp_rate_item.result
                                    end
                                end
                            end
                            -- Build links
                            local link = cdi_alert_link()
                            link.discrete_value_id = pa_o2_dv.unique_id
                            link.link_text =
                                dates.date_int_to_string(pa_o2_dv.result_date) ..
                                " - Respiratory Rate: " .. resp_rate ..
                                ", SpO2: " .. pa_o2 ..
                                ", FiO2: " .. fi_o2 ..
                                ", Estimated PF Ratio- " .. ratio
                            link.sequence = 8
                            table.insert(pa_o2_fi_o2_ratio_links, link)
                        end
                    end
                end
            end
        end

        if #pa_o2_fi_o2_ratio_links == 0 then
            if Account.id == "1640042638" then
                log.debug("Checking Method #3 - Look through FiO2 values for matching SpO2 values")
            end
            -- Method #3 - Look through FiO2 values for matching SpO2 values
            for _, fi_o2_dv in ipairs(fi_o2_dvs) do
                local sp_o2_dv = discrete.get_discrete_value_nearest_to_date {
                    discreteValueNames = dv_names_sp_o2,
                    date = fi_o2_dv.result_date,
                    predicate = function(dv)
                        return
                            dates.dates_are_less_than_x_minutes_apart(fi_o2_dv.result_date, dv.result_date, 5) and
                            tonumber(dv.result) ~= nil
                    end
                }
                if Account.id == "1640042638" then
                    log.debug("Checking Method #3 - fi_o2_dv: " .. tostring(fi_o2_dv) .. ", sp_o2_dv: " .. tostring(sp_o2_dv))
                end
                if sp_o2_dv then
                    if Account.id == "1640042638" then
                        log.debug("Checking Method #3 - fi_o2_dv: " .. tostring(fi_o2_dv) ..
                            ", sp_o2_dv: " .. tostring(sp_o2_dv))
                    end
                    local fi_o2 = discrete.get_dv_value_number(fi_o2_dv)
                    local sp_o2 = discrete.get_dv_value_number(sp_o2_dv)
                    local resp_rate = "XX"
                    local percentage = tonumber(fi_o2) / 100
                    local pa_o2 = sp_o2_to_pa_o2_lookup[sp_o2]
                    if pa_o2 ~= nil and pa_o2 > 0 and percentage ~= nil and percentage > 0 then
                        local ratio = pa_o2 / fi_o2
                        if ratio <= 300 then
                            if #resp_rate_dv > 0 then
                                for _, resp_rate_item in ipairs(resp_rate_dv) do
                                    if resp_rate_item.result_date == sp_o2_dv.result_date then
                                        resp_rate = resp_rate_item.result
                                    end
                                end
                            end
                            -- Build link
                            local link = cdi_alert_link()
                            link.discrete_value_id = sp_o2_dv.unique_id
                            link.link_text =
                                dates.date_int_to_string(sp_o2_dv.result_date) ..
                                " - Respiratory Rate: " .. resp_rate ..
                                ", SpO2: " .. sp_o2 ..
                                ", FiO2: " .. fi_o2 ..
                                ", Estimated PF Ratio- " .. ratio
                            link.sequence = 8
                            table.insert(pa_o2_fi_o2_ratio_links, link)
                        end
                    end
                end
            end
        end

        if #pa_o2_fi_o2_ratio_links == 0 then
            if Account.id == "1640042638" then
                log.debug("Checking Method #4 - Look through Oxygen values for matching PaO2 values")
            end
            -- Method #4 - Look through Oxygen values for matching PaO2 values
            for _, oxygen_pair in ipairs(oxygen_pairs) do
                local oxygen_flow_rate_value = discrete.get_dv_value_number(oxygen_pair.first)
                local oxygen_therapy_value = oxygen_pair.second.result
                --- @type number?
                local fi_o2 = nil
                if Account.id == "1640042638" then
                    log.debug("Checking Method #4 - fi_o2: " .. tostring(fi_o2) .. ", oxygen_therapy_value: " .. tostring(oxygen_therapy_value))
                end
                if oxygen_therapy_value == "Nasal Cannula" then
                    fi_o2 = flow_rate_to_fi_o2_lookup[oxygen_flow_rate_value]
                    if tonumber(fi_o2) ~= nil and tonumber(fi_o2) > 0 then
                        local pa_o2_dv = discrete.get_discrete_value_nearest_to_date {
                            discreteValueNames = dv_names_pa_o2,
                            date = oxygen_pair.first.result_date,
                            predicate = function(dv)
                                return
                                    dates.dates_are_less_than_x_minutes_apart(oxygen_pair.first.result_date, dv.result_date, 5) and
                                    tonumber(dv.result) ~= nil
                            end
                        }
                        if pa_o2_dv then
                            if Account.id == "1640042638" then
                                log.debug("Checking Method #4 - fi_o2: " .. tostring(fi_o2) ..
                                    ", pa_o2_dv: " .. tostring(pa_o2_dv))
                            end
                            local pa_o2 = discrete.get_dv_value_number(pa_o2_dv)
                            local resp_rate = "XX"
                            local ratio = pa_o2 / fi_o2
                            if ratio <= 300 then
                                if #resp_rate_dv > 0 then
                                    for _, resp_rate_item in ipairs(resp_rate_dv) do
                                        if resp_rate_item.result_date == pa_o2_dv.result_date then
                                            resp_rate = resp_rate_item.result
                                        end
                                    end
                                end
                                -- Build link
                                local link = cdi_alert_link()
                                link.discrete_value_id = pa_o2_dv.unique_id
                                link.link_text =
                                    dates.date_int_to_string(pa_o2_dv.result_date) ..
                                    " - Respiratory Rate: " .. resp_rate ..
                                    ", PaO2: " .. pa_o2 ..
                                    ", Oxygen Flow Rate: " .. oxygen_flow_rate_value ..
                                    ", Oxygen Therapy: " .. oxygen_therapy_value ..
                                    ", Estimated PF Ratio- " .. ratio
                                link.sequence = 8
                                table.insert(pa_o2_fi_o2_ratio_links, link)
                            end
                        end
                    end
                end
            end
        end

        if #pa_o2_fi_o2_ratio_links == 0 then
            if Account.id == "1640042638" then
                log.debug("Checking Method #5 - Look through Oxygen values for matching SpO2 values")
            end
            -- Method #5 - Look through Oxygen values for matching SpO2 values
            for _, oxygen_pair in ipairs(oxygen_pairs) do
                local oxygen_flow_rate_value = discrete.get_dv_value_number(oxygen_pair.first)
                local oxygen_therapy_value = oxygen_pair.second.result
                --- @type number?
                local fi_o2 = nil
                if Account.id == "1640042638" then
                    log.debug("Checking Method #5 - fi_o2: " .. tostring(fi_o2) .. ", oxygen_therapy_value: " .. tostring(oxygen_therapy_value))
                end
                if oxygen_therapy_value == "Nasal Cannula" then
                    fi_o2 = flow_rate_to_fi_o2_lookup[oxygen_flow_rate_value]
                    if tonumber(fi_o2) ~= nil and tonumber(fi_o2) > 0 then
                        local sp_o2_dv = discrete.get_discrete_value_nearest_to_date {
                            discreteValueNames = dv_names_sp_o2,
                            date = oxygen_pair.first.result_date,
                            predicate = function(dv)
                                return
                                    dates.dates_are_less_than_x_minutes_apart(oxygen_pair.first.result_date, dv.result_date,
                                        5) and
                                    tonumber(dv.result) ~= nil
                            end
                        }

                        if sp_o2_dv then
                            if Account.id == "1640042638" then
                                log.debug("Checking Method #5 - fi_o2: " .. tostring(fi_o2) ..
                                    ", sp_o2_dv: " .. tostring(sp_o2_dv))
                            end
                            local sp_o2 = discrete.get_dv_value_number(sp_o2_dv)
                            local resp_rate = "XX"
                            local pa_o2 = sp_o2_to_pa_o2_lookup[sp_o2]
                            if pa_o2 then
                                local ratio = pa_o2 / fi_o2
                                if ratio <= 300 then
                                    if #resp_rate_dv > 0 then
                                        for _, resp_rate_item in ipairs(resp_rate_dv) do
                                            if resp_rate_item.result_date == sp_o2_dv.result_date then
                                                resp_rate = resp_rate_item.result
                                            end
                                        end
                                    end
                                    -- Build link
                                    local link = cdi_alert_link()
                                    link.discrete_value_id = sp_o2_dv.unique_id
                                    link.link_text =
                                        dates.date_int_to_string(sp_o2_dv.result_date) ..
                                        " - Respiratory Rate: " .. resp_rate ..
                                        ", SpO2: " .. sp_o2 ..
                                        ", Oxygen Flow Rate: " .. oxygen_flow_rate_value ..
                                        ", Oxygen Therapy: " .. oxygen_therapy_value ..
                                        ", Estimated PF Ratio- " .. ratio
                                    link.sequence = 8
                                    table.insert(pa_o2_fi_o2_ratio_links, link)
                                end
                            end
                        end
                    end
                end
            end
        end

        if #pa_o2_fi_o2_ratio_links == 0 then
            if Account.id == "1640042638" then
                log.debug("Checking Method #6 - Look through Oxygen therapy values for matching PaO2 values")
            end
            -- Method #6 - Look through Oxygen therapy values for matching PaO2 values
            for _, oxygen_therapy_item in ipairs(oxygen_therapy_dv) do
                local oxygen_therapy_value = oxygen_therapy_item.result
                --- @type number?
                local fi_o2 = nil
                fi_o2 = oxgyen_therapy_to_fi_o2_lookup[oxygen_therapy_item.result]
                if Account.id == "1640042638" then
                    log.debug("Checking Method #6 - fi_o2: " .. tostring(fi_o2) .. ", oxygen_therapy_value: " .. tostring(oxygen_therapy_value))
                end
                if fi_o2 then
                    if tonumber(fi_o2) ~= nil and tonumber(fi_o2) > 0 then
                        local pa_o2_dv = discrete.get_discrete_value_nearest_to_date {
                            discreteValueNames = dv_names_pa_o2,
                            date = oxygen_therapy_item.result_date,
                            predicate = function(dv)
                                return
                                    dates.dates_are_less_than_x_minutes_apart(oxygen_therapy_item.result_date, dv.result_date, 5) and
                                    tonumber(dv.result) ~= nil
                            end
                        }
                        if pa_o2_dv then
                            if Account.id == "1640042638" then
                                log.debug("Checking Method #6 - fi_o2: " .. tostring(fi_o2) ..
                                    ", pa_o2_dv: " .. tostring(pa_o2_dv))
                            end
                            local pa_o2 = discrete.get_dv_value_number(pa_o2_dv)
                            local resp_rate = "XX"
                            if pa_o2 then
                                local ratio = pa_o2 / fi_o2
                                if Account.id == "1640042638" then
                                    log.debug("Checking Method #6 - pa_o2: " .. tostring(pa_o2) .. ", ratio: " .. tostring(ratio))
                                end
                                if ratio <= 300 then
                                    if #resp_rate_dv > 0 then
                                        for _, resp_rate_item in ipairs(resp_rate_dv) do
                                            if resp_rate_item.result_date == pa_o2_dv.result_date then
                                                resp_rate = resp_rate_item.result
                                            end
                                        end
                                    end
                                    -- Build link
                                    local link = cdi_alert_link()
                                    link.discrete_value_id = pa_o2_dv.unique_id
                                    link.link_text =
                                        dates.date_int_to_string(pa_o2_dv.result_date) ..
                                        " - Respiratory Rate: " .. resp_rate ..
                                        ", PaO2: " .. pa_o2 ..
                                        ", Oxygen Therapy: " .. oxygen_therapy_value ..
                                        ", Estimated PF Ratio- " .. ratio
                                    link.sequence = 8
                                    table.insert(pa_o2_fi_o2_ratio_links, link)
                                end
                            end
                        end
                    end
                end
            end
        end

        if #pa_o2_fi_o2_ratio_links == 0 then
            if Account.id == "1640042638" then
                log.debug("Checking Method #7 - Look through Oxygen therapy values for matching SpO2 values")
            end
            -- Method #7 - Look through Oxygen therapy values for matching SpO2 values
            for _, oxygen_therapy_item in ipairs(oxygen_therapy_dv) do
                local oxygen_therapy_value = oxygen_therapy_item.result
                --- @type number?
                local fi_o2 = nil
                fi_o2 = oxgyen_therapy_to_fi_o2_lookup[oxygen_therapy_item.result]
                if Account.id == "1640042638" then
                    log.debug("Checking Method #7 - fi_o2: " .. tostring(fi_o2) .. ", oxygen_therapy_value: " .. tostring(oxygen_therapy_value))
                end
                if fi_o2 then
                    if tonumber(fi_o2) ~= nil and tonumber(fi_o2) > 0 then
                        local sp_o2_dv = discrete.get_discrete_value_nearest_to_date {
                            discreteValueNames = dv_names_sp_o2,
                            date = oxygen_therapy_item.result_date,
                            predicate = function(dv)
                                return
                                    dates.dates_are_less_than_x_minutes_apart(oxygen_therapy_item.result_date, dv.result_date, 5) and
                                    tonumber(dv.result) ~= nil
                            end
                        }
                        if sp_o2_dv then
                            if Account.id == "1640042638" then
                                log.debug("Checking Method #7 - fi_o2: " .. tostring(fi_o2) ..
                                    ", sp_o2_dv: " .. tostring(sp_o2_dv))
                            end
                            local sp_o2 = discrete.get_dv_value_number(sp_o2_dv)
                            local resp_rate = "XX"
                            local pa_o2 = sp_o2_to_pa_o2_lookup[sp_o2]

                            if pa_o2 then
                                if Account.id == "1640042638" then
                                    log.debug("Checking Method #7 - pa_o2: " .. tostring(pa_o2))
                                end
                                local ratio = pa_o2 / fi_o2
                                if Account.id == "1640042638" then
                                    log.debug("Checking Method #7 - pa_o2: " .. tostring(pa_o2) .. ", ratio: " .. tostring(ratio))
                                end
                                if ratio <= 300 then
                                    if #resp_rate_dv > 0 then
                                        for _, resp_rate_item in ipairs(resp_rate_dv) do
                                            if resp_rate_item.result_date == sp_o2_dv.result_date then
                                                resp_rate = resp_rate_item.result
                                            end
                                        end
                                    end
                                    -- Build link
                                    local link = cdi_alert_link()
                                    link.discrete_value_id = sp_o2_dv.unique_id
                                    link.link_text =
                                        dates.date_int_to_string(sp_o2_dv.result_date) ..
                                        " - Respiratory Rate: " .. resp_rate ..
                                        ", SpO2: " .. sp_o2 ..
                                        ", Oxygen Therapy: " .. oxygen_therapy_value ..
                                        ", Estimated PF Ratio- " .. ratio
                                    link.sequence = 8
                                    table.insert(pa_o2_fi_o2_ratio_links, link)
                                end
                            end
                        end
                    end
                end
            end
        end
        return pa_o2_fi_o2_ratio_links
    end



    --------------------------------------------------------------------------------
    --- Get fallback links for PaO2 and SpO2
    --- These are gathered if the PaO2/FiO2 collection fails
    ---
    --- @param dv_names_sp_o2 string[] - List of discrete value names for SpO2
    --- @param dv_names_pa_o2 string[] - List of discrete value names for PaO2
    --- @param dv_names_oxygen_therapy string[] - List of discrete value names for Oxygen Therapy
    --- @param dv_names_respiratory_rate string[] - List of discrete value names for Respiratory Rate
    --- 
    --- @return SpO2PaO2Links[]
    --------------------------------------------------------------------------------
    function module.get_pa_o2_sp_o2_links(dv_names_sp_o2,
                                          dv_names_pa_o2,
                                          dv_names_oxygen_therapy,
                                          dv_names_respiratory_rate)
        --- @param date_time integer?
        --- @param link_text string
        --- @param result string?
        --- @param id string?
        --- @param seq number
        ---
        --- @return CdiAlertLink
        local function create_link(date_time, link_text, result, id, seq)
            local link = cdi_alert_link()

            if date_time then
                link_text = link_text:gsub("[RESULTDATETIME]", os.date("%c", date_time))
            else
                link_text = link_text:gsub("[RESULTDATETIME]", "")
            end
            if result then
                link_text = link_text:gsub("[VALUE]", result)
            else
                link_text = link_text:gsub("[VALUE]", "")
            end
            link.link_text = link_text
            link.discrete_value_id = id
            link.sequence = seq
            return link
        end

        local sp_o2_discrete_values = {}
        local pa_o2_discrete_values = {}
        local o2_therapy_discrete_values = {}
        local respiratory_rate_discrete_values = {}
        local sp_o2_link_text = "SpO2: [VALUE] (Result Date: [RESULTDATETIME])"
        local pao2_link_text = "PaO2: [VALUE] (Result Date: [RESULTDATETIME])"
        local o2_therapy_link_text = "Oxygen Therapy '[VALUE]' (Result Date: [RESULTDATETIME])"
        local respiratory_rate_link_text = "Respiratory Rate: [VALUE] (Result Date: [RESULTDATETIME])"
        local date_limit = dates.days_ago(1)
        local pa_dv_idx = nil
        local sp_dv_idx = nil
        local ot_dv_idx = nil
        local rr_dv_idx = nil
        local matching_date = nil
        local oxygen_value = nil
        local resp_rate_str = nil
        local matched_list = {}

        sp_o2_discrete_values = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_sp_o2,
            predicate = function(dv)
                return dv.result_date >= date_limit and discrete.get_dv_value_number(dv) < 91
            end
        }

        pa_o2_discrete_values = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_pa_o2,
            predicate = function(dv)
                return dv.result_date >= date_limit and discrete.get_dv_value_number(dv) <= 60
            end
        }

        o2_therapy_discrete_values = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_oxygen_therapy,
            predicate = function(dv)
                return dv.result_date >= date_limit and dv.result ~= nil
            end
        }

        respiratory_rate_discrete_values = discrete.get_ordered_discrete_values {
            discreteValueNames = dv_names_respiratory_rate,
            predicate = function(dv)
                return dv.result_date >= date_limit and discrete.get_dv_value_number(dv) ~= nil
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
                else
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
                else
                    resp_rate_str = "XX"
                end

                if matching_date then
                    matching_date = dates.date_int_to_string(matching_date)
                end
                table.insert(
                    matched_list,
                    create_link(
                        nil,
                        matching_date .. " Respiratory Rate: " .. resp_rate_str .. ", Oxygen Therapy: " .. oxygen_value ..
                        ", PaO2: " .. pa_o2_discrete_values[pa_dv_idx].result,
                        nil,
                        pa_o2_discrete_values[pa_dv_idx].unique_id,
                        0
                    )
                )
                table.insert(
                    matched_list,
                    create_link(
                        pa_o2_discrete_values[pa_dv_idx].result_date,
                        pao2_link_text,
                        pa_o2_discrete_values[pa_dv_idx].result,
                        pa_o2_discrete_values[pa_dv_idx].unique_id,
                        2
                    )
                )
                if ot_dv_idx then
                    table.insert(
                        matched_list,
                        create_link(
                            o2_therapy_discrete_values[ot_dv_idx].result_date,
                            o2_therapy_link_text,
                            o2_therapy_discrete_values[ot_dv_idx].result,
                            o2_therapy_discrete_values[ot_dv_idx].unique_id,
                            3
                        )
                    )
                end
                if rr_dv_idx then
                    table.insert(
                        matched_list,
                        create_link(
                            respiratory_rate_discrete_values[rr_dv_idx].result_date,
                            respiratory_rate_link_text,
                            respiratory_rate_discrete_values[rr_dv_idx].result,
                            respiratory_rate_discrete_values[rr_dv_idx].unique_id,
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
                else
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
                else
                    resp_rate_str = "XX"
                end
                if matching_date then
                    matching_date = dates.date_int_to_string(matching_date)
                end
                table.insert(
                    matched_list,
                    create_link(
                        nil,
                        matching_date .. " Respiratory Rate: " .. resp_rate_str .. ", Oxygen Therapy: " .. oxygen_value ..
                        ", SpO2: " .. sp_o2_discrete_values[sp_dv_idx].result,
                        nil,
                        sp_o2_discrete_values[sp_dv_idx].unique_id,
                        0
                    )
                )
                table.insert(
                    matched_list,
                    create_link(
                        sp_o2_discrete_values[sp_dv_idx].result_date,
                        sp_o2_link_text,
                        sp_o2_discrete_values[sp_dv_idx].result,
                        sp_o2_discrete_values[sp_dv_idx].unique_id,
                        1
                    )
                )
                if ot_dv_idx then
                    table.insert(
                        matched_list,
                        create_link(
                            o2_therapy_discrete_values[ot_dv_idx].result_date,
                            o2_therapy_link_text,
                            o2_therapy_discrete_values[ot_dv_idx].result,
                            o2_therapy_discrete_values[ot_dv_idx].unique_id,
                            5
                        )
                    )
                end
                if rr_dv_idx then
                    table.insert(
                        matched_list,
                        create_link(
                            respiratory_rate_discrete_values[rr_dv_idx].result_date,
                            respiratory_rate_link_text,
                            respiratory_rate_discrete_values[rr_dv_idx].result,
                            respiratory_rate_discrete_values[rr_dv_idx].unique_id,
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
