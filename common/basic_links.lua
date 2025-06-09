local dates = require "libs.common.dates"


---@diagnostic disable-next-line:name-style-check
return function(Account)
    local module = {}
    local log = require("cdi.log")
    local cdi_alert_link = require "cdi.link"

    ---------------------------------------------------------------------------------------------
    --- Abstract link args class
    ---------------------------------------------------------------------------------------------
    --- @class (exact) LinkArgs
    --- @field account Account? Account object (uses global account if not provided)
    --- @field text string Link template
    --- @field max_per_value number? The maximum number of links to create for each matched value (default 1)
    --- @field seq number? Starting sequence number to use for the links
    --- @field fixed_seq boolean? If true, the sequence number will not be incremented for each link
    --- @field include_standard_suffix boolean? If true, the standard suffix will be appended to the link text
    --- @field hidden boolean? If true, the link will be hidden
    --- @field permanent boolean? If true, the link will be permanent

    --- @class (exact) GetCodeLinksArgs : LinkArgs
    --- @field codes string[]? List of codes to search for
    --- @field code string? Single code to search for
    --- @field document_types string[]? List of document types that the code must be found in
    --- @field predicate (fun(code_reference: CodeReferenceWithDocument): boolean)? Predicate function to filter code references
    --- @field sort(fun(l: CodeReferenceWithDocument, r: CodeReferenceWithDocument): boolean)? Sort function to sort the matched values before creating links

    --------------------------------------------------------------------------------
    --- Build links for all codes in the account that match some criteria
    ---
    --- @param args GetCodeLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink[] # a list of CdiAlertLink objects or a single CdiAlertLink object
    --------------------------------------------------------------------------------
    function module.get_code_links(args)
        local account = args.account or Account
        local codes = args.codes or { args.code }
        local link_template = args.text or ""
        local document_types = args.document_types or {}
        local predicate = args.predicate
        local sequence = args.seq or 0
        local fixed_sequence = args.fixed_seq or false
        local max_per_value = args.max_per_value or 9999
        local include_standard_suffix = args.include_standard_suffix
        local hidden = args.hidden or false
        local permanent = args.permanent or false
        local sort = args.sort or function(a, b)
            return a.code_reference.code > b.code_reference.code
        end

        if include_standard_suffix == nil or include_standard_suffix then
            link_template = link_template .. ": [CODE] '[PHRASE]' ([DOCUMENTTYPE], [DOCUMENTDATE])"
        end

        --- @type CdiAlertLink[]
        local links = {}

        --- @type CodeReferenceWithDocument[]
        local code_reference_pairs = {}
        for i = 1, #codes do
            local code = codes[i]
            local code_reference_pairs_for_code = account:find_code_references(code)
            for j = 1, #code_reference_pairs_for_code do
                local ref_pair = code_reference_pairs_for_code[j]

                if predicate == nil or predicate(ref_pair) then
                    table.insert(code_reference_pairs, ref_pair)
                    if max_per_value and #code_reference_pairs >= max_per_value then
                        break
                    end
                end
            end
        end

        table.sort(code_reference_pairs, sort)

        for i = 1, #code_reference_pairs do
            local ref = code_reference_pairs[i]
            local code_reference = ref.code_reference
            local document = ref.document

            if document_types == nil or #document_types == 0 then
                --- @type CdiAlertLink
                local link = cdi_alert_link()
                link.code = code_reference.code
                link.document_id = document.document_id
                link.link_text = module.replace_link_place_holders(link_template or "", code_reference, document, nil,
                    nil)
                link.sequence = sequence
                link.permanent = permanent
                link.hidden = hidden
                table.insert(links, link)
                if not fixed_sequence then
                    sequence = sequence + 1
                end
            else
                for j = 1, #document_types do
                    if document_types[j] == document.document_type then
                        local link = cdi_alert_link()
                        link.code = code_reference.code
                        link.document_id = document.document_id
                        link.link_text = module.replace_link_place_holders(link_template, code_reference, document, nil,
                            nil)
                        link.sequence = sequence
                        link.permanent = permanent
                        link.hidden = hidden
                        table.insert(links, link)
                        if max_per_value and #links >= max_per_value then
                            break
                        end
                        if not fixed_sequence then
                            sequence = sequence + 1
                        end
                    end
                end
            end
        end

        return links
    end

    --------------------------------------------------------------------------------
    --- Builds a single link for a code on the account that matches some criteria
    ---
    --- @param args GetCodeLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink? # the link to the first code or nil if not found
    --------------------------------------------------------------------------------
    function module.get_code_link(args)
        args.max_per_value = 1
        local links = module.get_code_links(args)
        if #links > 0 then
            return links[1]
        else
            return nil
        end
    end

    --------------------------------------------------------------------------------
    --- Build links for all abstractions in the account that match some criteria
    --- without including the value of the abstraction
    ---
    --- @param args GetCodeLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink[] # a list of CdiAlertLink objects or a single CdiAlertLink object
    --------------------------------------------------------------------------------
    function module.get_abstraction_links(args)
        if args.include_standard_suffix == nil or args.include_standard_suffix then
            args.include_standard_suffix = false
            args.text = args.text .. " '[PHRASE]' ([DOCUMENTTYPE], [DOCUMENTDATE])"
        end
        return module.get_code_links(args)
    end

    --------------------------------------------------------------------------------
    --- Builds a single link for an abstraction on the account that matches some criteria
    --- without including the value of the abstraction
    ---
    --- @param args GetCodeLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink? # the link to the first abstraction or nil if not found
    -----------------------------------------------------------------------------
    function module.get_abstraction_link(args)
        args.max_per_value = 1
        local links = module.get_abstraction_links(args)
        if #links > 0 then
            return links[1]
        else
            return nil
        end
    end

    --------------------------------------------------------------------------------
    --- Build links for all codes in the account that match some criteria with the
    --- value of the abstraction included
    ---
    --- @param args GetCodeLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink[] # a list of CdiAlertLink objects or a single CdiAlertLink object
    --------------------------------------------------------------------------------
    function module.get_abstraction_value_links(args)
        if args.include_standard_suffix == nil or args.include_standard_suffix then
            args.include_standard_suffix = false
            args.text = args.text .. ": [ABSTRACTVALUE] '[PHRASE]' ([DOCUMENTTYPE], [DOCUMENTDATE])"
        end
        return module.get_code_links(args)
    end

    --------------------------------------------------------------------------------
    --- Builds a single link for an abstraction on the account that matches some criteria
    --- with the value of the abstraction included
    ---
    --- @param args GetCodeLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink? # the link to the first abstraction or nil if not found
    --------------------------------------------------------------------------------
    function module.get_abstraction_value_link(args)
        args.max_per_value = 1
        local links = module.get_abstraction_value_links(args)
        if #links > 0 then
            return links[1]
        else
            return nil
        end
    end

    --- @class (exact) GetDocumentLinksArgs : LinkArgs
    --- @field documentTypes string[]? List of document types to search for
    --- @field documentType string? Single document type to search for
    --- @field predicate (fun(document: CACDocument): boolean)? Predicate function to filter documents
    --- @field sort(fun(l: CACDocument, r: CACDocument): boolean)? Sort function to sort the matched values before creating links

    --------------------------------------------------------------------------------
    --- Build links for all documents in the account that match some criteria
    ---
    --- @param args GetDocumentLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink[] # a list of CdiAlertLink objects or a single CdiAlertLink object
    --------------------------------------------------------------------------------
    function module.get_document_links(args)
        local account = args.account or Account
        local document_types = args.documentTypes or { args.documentType }
        local link_template = args.text or ""
        local predicate = args.predicate
        local sequence = args.seq or 0
        local fixed_sequence = args.fixed_seq or false
        local max_per_value = args.max_per_value or 9999
        local include_standard_suffix = args.include_standard_suffix
        local hidden = args.hidden or false
        local permanent = args.permanent or false

        --- sorts the documents by date
        --- @param a CACDocument
        --- @param b CACDocument
        --- @return boolean
        local sort = args.sort or function(a, b)
            return a.document_date_time > b.document_date_time
        end

        if include_standard_suffix == nil or include_standard_suffix then
            link_template = link_template
        end

        --- @type CdiAlertLink[]
        local links = {}
        --- @type CACDocument[]
        local documents = {}

        for i = 1, #document_types do
            local document_type = document_types[i]
            local documents_for_type = account:find_documents(document_type or "")
            for j = 1, #documents_for_type do
                if predicate == nil or predicate(documents[i]) then
                    table.insert(documents, documents_for_type[j])
                    if max_per_value and #documents >= max_per_value then
                        break
                    end
                end
            end
        end

        table.sort(documents, sort)

        for i = 1, #documents do
            local document = documents[i]
            local link = cdi_alert_link()
            link.document_id = document.document_id
            link.link_text = module.replace_link_place_holders(link_template, nil, document, nil, nil)
            link.sequence = sequence
            link.permanent = permanent
            link.hidden = hidden
            table.insert(links, link)
            if not fixed_sequence then
                sequence = sequence + 1
            end
        end
        return links
    end

    --------------------------------------------------------------------------------
    --- Builds a single link for a document on the account that matches some criteria
    ---
    --- @param args GetDocumentLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink? # the link to the first document or nil if not found
    --------------------------------------------------------------------------------
    function module.get_document_link(args)
        args.max_per_value = 1
        local links = module.get_document_links(args)
        if #links > 0 then
            return links[1]
        else
            return nil
        end
    end

    --- @class (exact) GetMedicationLinksArgs : LinkArgs
    --- @field cats string[]? List of medication categories to search for
    --- @field cat string? Single medication category to search for
    --- @field predicate (fun(medication: Medication): boolean)? Predicate function to filter medications
    --- @field sort(fun(l: Medication, r: Medication): boolean)? Sort function to sort the matched values before creating links
    --- @field useCdiAlertCategoryField boolean? If true, use the cdi_alert_category field to search for medications instead of the category field
    --- @field onePerDate boolean? If true, only one link will be created per date

    --------------------------------------------------------------------------------
    --- Build links for all medications in the account that match some criteria
    ---
    --- @param args GetMedicationLinksArgs table of arguments
    ---
    --- @return CdiAlertLink[] # a list of CdiAlertLink objects or a single CdiAlertLink object
    --------------------------------------------------------------------------------
    function module.get_medication_links(args)
        local account = args.account or Account
        local medication_categories = args.cats or { args.cat }
        local link_template = args.text or ""
        local predicate = args.predicate
        local sequence = args.seq or 0
        local fixed_sequence = args.fixed_seq or false
        local max_per_value = args.max_per_value or 9999
        local include_standard_suffix = args.include_standard_suffix
        local use_cdi_alert_category_field = args.useCdiAlertCategoryField or false
        local one_per_date = args.onePerDate or false
        local hidden = args.hidden or false
        local permanent = args.permanent or false
        local sort = args.sort or function(a, b)
            return a.start_date > b.start_date
        end

        if include_standard_suffix == nil or include_standard_suffix then
            if link_template == "" then
                link_template = "[MEDICATION], Dosage [DOSAGE], Route [ROUTE] ([STARTDATE])"
            else
                link_template = link_template .. ": [MEDICATION], Dosage [DOSAGE], Route [ROUTE] ([STARTDATE])"
            end
        end

        --- @type CdiAlertLink[]
        local links = {}
        --- @type Medication[]
        local medications = {}

        for _, medication_category in ipairs(medication_categories) do
            local medications_for_category = {}

            if use_cdi_alert_category_field then
                for _, med in ipairs(account.medications) do
                    if med.cdi_alert_category == medication_category then
                        table.insert(medications, med)
                    end
                end
            else
                medications_for_category = account:find_medications(medication_category)
            end

            if one_per_date then
                local unique_dates = {}
                local unique_medications = {}
                for j = 1, #medications_for_category do
                    local medication = medications_for_category[j]
                    if not unique_dates[medication.start_date] then
                        ---@diagnostic disable-next-line: no-unknown
                        unique_dates[medication.start_date] = true
                        table.insert(unique_medications, medication)
                    end
                end
                medications_for_category = unique_medications
            end

            for j = 1, #medications_for_category do
                if predicate == nil or predicate(medications_for_category[j]) then
                    table.insert(medications, medications_for_category[j])
                    if max_per_value and #medications >= max_per_value then
                        break
                    end
                end
            end
        end

        table.sort(medications, sort)
        for _, medication in ipairs(medications) do
            local link         = cdi_alert_link()
            link.medication_id = medication.external_id
            link.link_text     = module.replace_link_place_holders(link_template, nil, nil, nil, medication)
            link.sequence      = sequence
            link.permanent     = permanent
            link.hidden        = hidden
            table.insert(links, link)
            if not fixed_sequence then
                sequence = sequence + 1
            end
        end
        return links
    end

    --------------------------------------------------------------------------------
    --- Builds a single link for a medication on the account that matches some criteria
    ---
    --- @param args GetMedicationLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink? # the link to the first medication or nil if not found
    --------------------------------------------------------------------------------
    function module.get_medication_link(args)
        args.max_per_value = 1
        local links = module.get_medication_links(args)
        if #links > 0 then
            return links[1]
        else
            return nil
        end
    end

    --- @class (exact) GetDiscreteValueLinksArgs : LinkArgs
    --- @field discreteValueNames string[]? List of discrete value names to search for
    --- @field discreteValueName string? Single discrete value name to search for
    --- @field predicate (fun(discrete_value: DiscreteValue, num: number?): boolean)? Predicate function to filter discrete values
    --- @field sort(fun(l: DiscreteValue, r: DiscreteValue): boolean)? Sort function to sort the matched values before creating links

    --------------------------------------------------------------------------------
    --- Build links for all discrete values in the account that match some criteria
    ---
    --- @param args GetDiscreteValueLinksArgs table of arguments
    ---
    --- @return CdiAlertLink[] # a list of CdiAlertLink objects or a single CdiAlertLink object
    --------------------------------------------------------------------------------
    function module.get_discrete_value_links(args)
        local account = args.account or Account
        local discrete_value_names = args.discreteValueNames or { args.discreteValueName }
        local link_template = args.text or ""
        local predicate = args.predicate
        local sequence = args.seq or 0
        local fixed_sequence = args.fixed_seq or false
        local max_per_value = args.max_per_value or 10
        local include_standard_suffix = args.include_standard_suffix
        local hidden = args.hidden or false
        local permanent = args.permanent or false
        local sort = args.sort or function(a, b)
            return a.result_date < b.result_date
        end

        if include_standard_suffix == nil or include_standard_suffix then
            link_template = link_template .. ": [DISCRETEVALUE] (Result Date: [RESULTDATE])"
        end

        --- @type CdiAlertLink[]
        local links = {}
        --- @type DiscreteValue[]
        local discrete_values = {}

        for i = 1, #discrete_value_names do
            local discrete_value_name = discrete_value_names[i]
            local discrete_values_for_name = account:find_discrete_values(discrete_value_name)
            for j = 1, #discrete_values_for_name do
                local dv = discrete_values_for_name[j]
                local result_as_number =
                    dv.result and
                    tonumber(string.gsub(dv.result, "[<>]", ""), 10) or
                    nil

                if predicate == nil or predicate(dv, result_as_number) then
                    table.insert(discrete_values, discrete_values_for_name[j])

                    if max_per_value and #discrete_values >= max_per_value then
                        break
                    end
                end
            end
        end

        table.sort(discrete_values, sort)
        
        for i = 1, #discrete_values do
            local discrete_value = discrete_values[i]
            local link = cdi_alert_link()
            link.discrete_value_name = discrete_value.name
            link.discrete_value_id = discrete_value.unique_id
            link.link_text = module.replace_link_place_holders(link_template, nil, nil, discrete_value, nil)
            link.sequence = sequence
            link.permanent = permanent
            link.hidden = hidden
            table.insert(links, link)
            if not fixed_sequence then
                sequence = sequence + 1
            end
        end
        return links
    end

    --------------------------------------------------------------------------------
    --- Builds a single link for a discrete value on the account that matches some criteria
    ---
    --- @param args GetDiscreteValueLinksArgs a table of arguments
    ---
    --- @return CdiAlertLink? # the link to the first discrete value or nil if not found
    --------------------------------------------------------------------------------
    function module.get_discrete_value_link(args)
        if args.permanent == nil then
            args.permanent = true
        end
        args.max_per_value = 1
        args.sort = args.sort or function(a, b)
            return a.result_date > b.result_date
        end
        local links = module.get_discrete_value_links(args)
        if #links > 0 then
            return links[#links]
        else
            return nil
        end
    end

    --------------------------------------------------------------------------------
    --- Replace placeholders in a link template with values from the code reference,
    --- document, discrete value, or medication
    ---
    --- @param link_template string the template for the link
    --- @param code_reference CodeReference? the code reference to use for the link
    --- @param document CACDocument? the document to use for the link
    --- @param discrete_value DiscreteValue? the discrete value to use for the link
    --- @param medication Medication? the medication to use for the link
    ---
    --- @return string # the link with placeholders replaced
    --------------------------------------------------------------------------------
    function module.replace_link_place_holders(link_template, code_reference, document, discrete_value, medication)
        local link = link_template

        if code_reference ~= nil then
            link = string.gsub(link, "%[CODE%]", code_reference.code or "")
            link = string.gsub(link, "%[ABSTRACTVALUE%]", code_reference.value or "")
            link = string.gsub(link, "%[PHRASE%]", code_reference.phrase or "")
        end

        if document ~= nil then
            link = string.gsub(link, "%[DOCUMENTID%]", document.document_id or "")
            link = string.gsub(link, "%[DOCUMENTDATE%]", dates.date_int_to_string(document.document_date_time, "%m/%d/%Y") or "")
            link = string.gsub(link, "%[DOCUMENTTYPE%]", document.document_type or "")
        end


        if discrete_value ~= nil then
            link = string.gsub(link, "%[DISCRETEVALUENAME%]", discrete_value.name or "")
            link = string.gsub(link, "%[DISCRETEVALUE%]", discrete_value.result or "")
            link = string.gsub(link, "%[RESULTDATE%]", dates.date_int_to_string(discrete_value.result_date) or "")
        end

        if medication ~= nil then
            link = string.gsub(link, "%[MEDICATIONID%]", medication.external_id or "")
            link = string.gsub(link, "%[MEDICATION%]", medication.medication or "")
            link = string.gsub(link, "%[DOSAGE%]", medication.dosage or "")
            link = string.gsub(link, "%[ROUTE%]", medication.route or "")
            link = string.gsub(link, "%[STARTDATE%]", dates.date_int_to_string(medication.start_date) or "")
            link = string.gsub(link, "%[STATUS%]", medication.status or "")
            link = string.gsub(link, "%[CATEGORY%]", medication.category or "")
        end

        if discrete_value ~= nil and discrete_value.result ~= nil then
            link = string.gsub(link, "%[VALUE%]", discrete_value.result or "")
        elseif code_reference ~= nil and code_reference.value ~= nil then
            link = string.gsub(link, "%[VALUE%]", code_reference.value or "")
        end

        return link
    end

    --------------------------------------------------------------------------------
    --- Create a link to a header
    ---
    --- @param header_text string The text of the header
    --- @param validated boolean? Whether the header is validated
    ---
    --- @return CdiAlertLink - the link to the header
    --------------------------------------------------------------------------------
    function module.make_header_link(header_text, validated)
        local is_validated = true
        if validated ~= nil then
            is_validated = validated
        end
        local link = cdi_alert_link()
        link.link_text = header_text
        link.is_validated = is_validated
        return link
    end

    --------------------------------------------------------------------------------
    --- Sort through headers and readd links alphabetized by their link text
    ---
    --- @param headers CdiAlertLink[] The links to check through to alphabetize
    --- @return CdiAlertLink - the link to the header
    --------------------------------------------------------------------------------
    function module.alphabetize_links(headers)
        --- @type CdiAlertLink[]
        local resequenced_links = {}

        for _, header in ipairs(headers) do
            local resequenced_header = {}
            resequenced_header = header
            resequenced_header.links = module.alphabetize_links_in_header(header.links)
            table.insert(resequenced_links, resequenced_header)
        end

        return resequenced_links
    end

    --------------------------------------------------------------------------------
    --- Resequence links in a header by alphabetizing them 
    ---
    --- @param links CdiAlertLink[] The links to check through to alphabetize
    --- @return CdiAlertLink[] - The unique links by discrete _id
    --------------------------------------------------------------------------------
    function module.alphabetize_links_in_header(links)
        --- @type CdiAlertLink[]
        local log = require("cdi.log")
        local resequenced_links = {}

        local function sort_by_link_text(a, b)
            return a.link_text < b.link_text
        end
        
        table.sort(links, sort_by_link_text)
        for i, link in ipairs(links) do
            if link.link_text == "Major:" or link.link_text == "Minor:" or link.link_text == "ABG" or link.link_text == "VBG" then
                local resequenced_sub_header = {}
                -- go through sub header links
                resequenced_sub_header = link
                resequenced_sub_header.links = module.alphabetize_links_in_header(link.links)
                table.insert(resequenced_links, resequenced_sub_header)

            elseif link.sequence < 85 then
                local resequenced_link = {}
                resequenced_link = link
                resequenced_link.sequence = i
                table.insert(resequenced_links, resequenced_link)

            elseif link.sequence >= 85 then
                local resequenced_sub_header = {}
                -- go through sub header links
                resequenced_sub_header = link
                -- Recursively resequence the subheader’s links
                local sub_links = link.links
                -- Sort by extracted date (oldest to newest)
                table.sort(sub_links, function(a, b)
                    local date_a = module.extract_result_date(a.link_text) or 0
                    local date_b = module.extract_result_date(b.link_text) or 0
                    return date_a < date_b -- Sort oldest first
                end)

                -- Resequence the sorted links
                for idx, l in ipairs(sub_links) do
                    l.sequence = idx 
                end
                resequenced_sub_header.links = sub_links
                table.insert(resequenced_links, resequenced_sub_header)
            end
        end
        return resequenced_links
    end

    --------------------------------------------------------------------------------
    --- Abstract date from link text for sorting
    ---
    --------------------------------------------------------------------------------
    function module.extract_result_date(link_text)
        -- Example format: "WBC: 19 (ResultDate: 04/15/2025 13:54)"
        local month, day, year, hour, minute = string.match(link_text, "Result%s+Date:%s*(%d%d?)/(%d%d?)/(%d%d%d%d)%s+(%d%d?):(%d%d)")
        if not (month and day and year and hour and minute) then
            return nil
        end
        return os.time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(minute),
            sec = 0,
        })
    end

    --------------------------------------------------------------------------------
    --- Remove duplicate links from a header
    ---
    ---@param links CdiAlertLink[] The links to check for duplicates
    --- 
    --- @return CdiAlertLink[] - The unique links by discrete _id
    --------------------------------------------------------------------------------
    function module.remove_duplicate_links_in_header(links)
        local discrete_id = {}
        --- @type CdiAlertLink[]
        local unique_links = {}

        for _, link in ipairs(links) do
            if link.discrete_value_id ~= nil and not discrete_id[link.discrete_value_id] then
                discrete_id[link.discrete_value_id] = true
                table.insert(unique_links, link)
            end
        end
        return unique_links
    end

    --------------------------------------------------------------------------------
    --- Merge links with old links
    ---
    --- @param old_links CdiAlertLink[] The existing alert
    --- @param new_links CdiAlertLink[] The links to merge
    ---
    --- @return CdiAlertLink[] - The merged links
    --------------------------------------------------------------------------------
    function module.merge_links(old_links, new_links)
        local log = require("cdi.log")

        --- @type CdiAlertLink[]
        local merged_links = {}

        --- Compare two links
        --- @param a CdiAlertLink
        --- @param b CdiAlertLink
        --- @return boolean
        local function compare_links(a, b)
            return
                (a.code and a.code == b.code) or
                (a.medication_id and a.medication_id == b.medication_id) or
                (a.discrete_value_id and a.discrete_value_id == b.discrete_value_id) or
                (not a.code and not a.medication_id and not a.discrete_value_id and a.link_text and a.link_text == b.link_text)
        end

        if #old_links == 0 then
            return new_links
        elseif #new_links == 0 then
            return old_links
        else
            local permanent_discrete_value_names = {}
            local permanent_codes = {}
            local permanent_medication_names = {}

            -- First, add all of the old links
            for _, old_link in ipairs(old_links) do
                table.insert(merged_links, old_link)

                if old_link.permanent then
                    if old_link.code then
                        permanent_codes[old_link.code] = true
                    elseif old_link.discrete_value_id then
                        permanent_discrete_value_names[old_link.discrete_value_name] = true
                    elseif old_link.medication_id then
                        permanent_medication_names[old_link.medication_name] = true
                    end
                end
            end

            -- Next, upsert the new links
            for _, new_link in ipairs(new_links) do
                local matching_existing_link = nil

                if new_link.code ~= nil and permanent_codes[new_link.code] then goto continue end
                if new_link.discrete_value_name ~= nil and permanent_discrete_value_names[new_link.discrete_value_name] then goto continue end
                if new_link.medication_name ~= nil and permanent_medication_names[new_link.medication_name] then goto continue end

                for _, existing_link in ipairs(merged_links) do
                    if compare_links(existing_link, new_link) then
                        matching_existing_link = existing_link
                        break
                    end
                end

                if matching_existing_link == nil then
                    table.insert(merged_links, new_link)
                else
                    matching_existing_link.is_validated = new_link.is_validated
                    matching_existing_link.sequence = new_link.sequence
                    matching_existing_link.hidden = new_link.hidden
                    matching_existing_link.link_text = new_link.link_text
                    matching_existing_link.links = module.merge_links(matching_existing_link.links, new_link.links)
                end
                ::continue::
            end
            return merged_links
        end
    end

    return module
end
