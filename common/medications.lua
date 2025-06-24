---@diagnostic disable-next-line:name-style-check
return function(Account)
    local module = {}
    local links = require "libs.common.basic_links" (Account)
    local lists = require "libs.common.lists"

    --------------------------------------------------------------------------------
    --- Make a medication link
    ---
    --- @param cat string The medication category (name)
    --- @param text string? The text for the link
    --- @param predicate (fun(med: Medication):boolean?)? A predicate to filter the medications
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink? - a link to the medication or nil if not found
    --------------------------------------------------------------------------------
    function module.make_medication_link(cat, text, predicate, sequence)
        text = text or ""
        return links.get_medication_link {
            cat = cat,
            text = text,
            predicate = predicate,
            seq = sequence
        }
    end

    --------------------------------------------------------------------------------
    --- Make a medication link
    ---
    --- @param cat string The medication category (name)
    --- @param text string? The text for the link
    --- @param predicate (fun(med: Medication):boolean?)? A predicate to filter the medications
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink? - a link to the medication or nil if not found
    --------------------------------------------------------------------------------
    function module.make_medication_link_by_cdi_category(cat, text, predicate, sequence)
        text = text or ""
        return links.get_medication_link {
            cat = cat,
            text = text,
            predicate = predicate,
            useCdiAlertCategoryField = true,
            seq = sequence
        }
    end

    --------------------------------------------------------------------------------
    --- Make a medication link
    ---
    --- @param cat string The medication category (name)
    --- @param text string? The text for the link
    --- @param predicate (fun(med: Medication):boolean?)? A predicate to filter the medications
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink? - a link to the medication or nil if not found
    --------------------------------------------------------------------------------
    function module.make_medication_links_by_cdi_category(cat, text, predicate, sequence)
        text = text or ""
        return links.get_medication_links {
            cat = cat,
            text = text,
            predicate = predicate,
            useCdiAlertCategoryField = true,
            seq = sequence
        }
    end

    --------------------------------------------------------------------------------
    --- Make a predicate to check that a medication route matches any of a list of patterns
    ---
    --- @param ... string The patterns to compare against
    --- @return fun(med: Medication):boolean - the predicate function
    --------------------------------------------------------------------------------
    function module.make_route_match_predicate(...)
        local patterns = { ... }
        return function(med)
            return lists.any(patterns, function(pattern)
                return string.match(med.route, pattern)
            end)
        end
    end

    --------------------------------------------------------------------------------
    --- Make a predicate to check that a medication route matches any of a list of patterns
    ---
    --- @param ... string The patterns to compare against
    --- @return fun(med: Medication):boolean - the predicate function
    --------------------------------------------------------------------------------
    function module.make_route_no_match_predicate(...)
        local patterns = { ... }
        return function(med)
            for _, pattern in ipairs(patterns) do
                if med.route and string.match(med.route, pattern) then
                    return false
                end
            end
            return true
        end
    end

    return module
end
