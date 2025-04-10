---@diagnostic disable-next-line:name-style-check
return function(Account)
    local module = {}
    local links = require("libs.common.basic_links")(Account)

    --------------------------------------------------------------------------------
    --- Get account codes matching a prefix
    ---
    --- @param prefix string The prefix to search for
    ---
    --- @return string[] - a list of codes that match the prefix
    --------------------------------------------------------------------------------
    function module.get_account_codes_by_prefix(prefix)
        --- @type Account
        local account = Account
        local codes = {}
        for _, code in ipairs(account:get_unique_code_references()) do
            if code:sub(1, #prefix) == prefix then
                table.insert(codes, code)
            end
        end
        return codes
    end

    --- @class (exact) GetCodeLinkWithPrefixArgs : GetCodeLinksArgs
    --- @field prefix string The prefix to search for

    --------------------------------------------------------------------------------
    --- Get the first code link for a prefix
    ---
    --- @param arguments GetCodeLinkWithPrefixArgs a table of arguments
    ---
    --- @return CdiAlertLink? - the link to the first code or nil if not found
    --------------------------------------------------------------------------------
    function module.get_code_prefix_link(arguments)
        local codes = module.get_account_codes_by_prefix(arguments.prefix)
        if #codes == 0 then
            return nil
        end
        arguments.code = codes[1]
        local code_links = links.get_code_links(arguments)
        if type(code_links) == "table" then
            return code_links[1]
        else
            return code_links
        end
    end

    --------------------------------------------------------------------------------
    --- Get all code links for a prefix
    ---
    --- @param arguments GetCodeLinkWithPrefixArgs The arguments for the link
    ---
    --- @return CdiAlertLink[]? - a list of links to the codes or nil if not found
    --------------------------------------------------------------------------------
    function module.get_code_prefix_links(arguments)
        local codes = module.get_account_codes_by_prefix(arguments.prefix)
        if #codes == 0 then
            return nil
        end
        arguments.codes = codes
        return links.get_code_links(arguments)
    end

    --------------------------------------------------------------------------------
    --- Make a code link
    ---
    --- @param code string The code to search for
    --- @param text string The text for the link
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink? - a link to the codes or nil if not found
    --------------------------------------------------------------------------------
    function module.make_code_link(code, text, sequence)
        return links.get_code_link {
            code = code,
            text = text,
            seq = sequence,
        }
    end

    --------------------------------------------------------------------------------
    --- Make code links from the codes provided
    ---
    --- @param codes string[] The codes to search for
    --- @param text string The text for the link
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink[] - a list of links to the codes or nil if not found
    --------------------------------------------------------------------------------
    function module.make_code_links(codes, text, sequence)
        return links.get_code_links {
            codes = codes,
            text = text,
            seq = sequence,
        }
    end

    --------------------------------------------------------------------------------
    --- Make a code link from the first found code from a list
    ---
    --- @param codes string[] The codes to search for
    --- @param text string The text for the link
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink? - a link to the codes or nil if not found
    --------------------------------------------------------------------------------
    function module.make_code_one_of_link(codes, text, sequence)
        return links.get_code_link {
            codes = codes,
            text = text,
            seq = sequence,
        }
    end

    --------------------------------------------------------------------------------
    --- Make an abstraction link
    ---
    --- @param abs string The abstraction to search for
    --- @param text string The text for the link
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink? - a link to the codes or nil if not found
    --------------------------------------------------------------------------------
    function module.make_abstraction_link(abs, text, sequence)
        return links.get_abstraction_link {
            code = abs,
            text = text,
            seq = sequence,
        }
    end

    --------------------------------------------------------------------------------
    --- Make an abstraction link with a value part on the suffix
    ---
    --- @param abs string The abstraction to search for
    --- @param text string The text for the link
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink? - a link to the codes or nil if not found
    --------------------------------------------------------------------------------
    function module.make_abstraction_link_with_value(abs, text, sequence)
        return links.get_abstraction_value_link {
            code = abs,
            text = text,
            seq = sequence,
        }
    end

    --------------------------------------------------------------------------------
    --- Make an code link from a prefix
    ---
    --- @param prefix string The code prefix to search for
    --- @param text string The text for the link
    --- @param sequence number? The sequence number of the link
    ---
    --- @return CdiAlertLink? - a link to the code or nil if not found
    --------------------------------------------------------------------------------
    function module.make_code_prefix_link(prefix, text, sequence)
        return module.get_code_prefix_link {
            prefix = prefix,
            text = text,
            seq = sequence,
        }
    end

    --------------------------------------------------------------------------------
    --- Make many code links from a prefix
    ---
    --- @param prefix string The code prefix to search for
    --- @param text string The text for the links
    --- @param sequence number? The sequence number of the links
    ---
    --- @return CdiAlertLink[]? - a list of links to the codes or nil if not found
    --------------------------------------------------------------------------------
    function module.make_code_prefix_links(prefix, text, sequence)
        return module.get_code_prefix_links {
            prefix = prefix,
            text = text,
            seq = sequence,
        }
    end

    --------------------------------------------------------------------------------
    --- Get the account codes that are present as keys in the provided dictionary
    ---
    --- @param account Account The account to get the codes from
    --- @param dictionary table<string, string> The dictionary of codes to check against
    ---
    --- @return string[] - List of codes in dependecy map that are present on the account (codes only)
    --------------------------------------------------------------------------------
    function module.get_account_codes_in_dictionary(account, dictionary)
        local codes = {}

        for key, _ in pairs(dictionary) do
            if account:has_code_references(key) then table.insert(codes, key) end
        end
        return codes
    end

    --- Check for a diagnosis code in the active working history (first element)
    --- @param code string The code to search for
    --- @return boolean? - nil if the working history is empty.
    function module.is_diagnosis_code_in_working_history(code)
        if Account.working_history[1] then
            for _, diagnosis in ipairs(Account.working_history[1].diagnoses) do
                if diagnosis.code == code then return true end
            end
            return false
        end
    end

    --- Check for a procedure code in the active working history (first element)
    --- @param code string The code to search for
    --- @return boolean? - nil if the working history is empty.
    function module.is_procedure_code_in_working_history(code)
        if Account.working_history[1] then
            for _, procedure in ipairs(Account.working_history[1].procedures) do
                if procedure.code == code then return true end
            end
            return false
        end
    end

    return module
end
