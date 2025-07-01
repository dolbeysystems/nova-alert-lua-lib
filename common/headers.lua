---@diagnostic disable-next-line:name-style-check
return function(Account)
    ---------------------------------------------------------------------------------------------
    --- headers.lua - A library of functions for creating alert headers
    ---------------------------------------------------------------------------------------------
    local links_lib = require "libs.common.basic_links" (Account)
    local codes_lib = require "libs.common.codes" (Account)
    local lists = require "libs.common.lists"
    local module = {}

    --- @class header_builder
    --- @field name string
    --- @field sequence_counter integer
    --- @field sequence integer
    --- @field links CdiAlertLink[]
    --- @field make_header_builder (fun (name: string, seq: integer): header_builder)
    --- @field build (fun (self: header_builder, require_links: boolean): CdiAlertLink)
    --- @field add_link (fun (self: header_builder, link: CdiAlertLink?)) : CdiAlertLink?
    --- @field add_autoresolve_link (fun (self: header_builder, link: CdiAlertLink?)) : CdiAlertLink?
    --- @field add_star_link (fun (self: header_builder, ...: CdiAlertLink?)) : boolean
    --- @field add_star_autoresolve_link (fun (self: header_builder, ...: CdiAlertLink?)) : boolean
    --- @field add_links (fun (self: header_builder, ...: CdiAlertLink?)) : boolean
    --- @field add_autoresolve_links (fun (self: header_builder, ...: CdiAlertLink?)) : boolean
    --- @field add_star_links (fun (self: header_builder, ...: CdiAlertLink?)) : boolean
    --- @field add_star_autoresolve_links (fun (self: header_builder, ...: CdiAlertLink?)) : boolean
    --- @field add_text_link (fun (self: header_builder, text: string, validated: boolean?)) : CdiAlertLink?
    --- @field add_document_link (fun (self: header_builder, document_type: string, description: string)) : CdiAlertLink?
    --- @field add_code_link (fun (self: header_builder, code: string, description: string)) : CdiAlertLink?
    --- @field add_code_one_of_link (fun (self: header_builder, codes: string[], description: string)) : CdiAlertLink?
    --- @field add_code_prefix_link (fun (self: header_builder, prefix: string, description: string)) : CdiAlertLink?
    --- @field add_abstraction_link (fun (self: header_builder, abstraction: string, description: string)) : CdiAlertLink?
    --- @field add_abstraction_link_with_value (fun (self: header_builder, abstraction: string, description: string)) : CdiAlertLink?
    --- @field add_discrete_value_link (fun (self: header_builder, dv_name: string, description: string, predicate: (fun (dv: DiscreteValue, num: number?): boolean)?)) : CdiAlertLink?
    --- @field add_discrete_value_one_of_link (fun (self: header_builder, dv_names: string[], description: string, predicate: (fun (dv: DiscreteValue, num: number?): boolean)?)) : CdiAlertLink?
    --- @field add_discrete_value_links (fun (self: header_builder, dv_name: string, description: string, predicate: (fun (dv: DiscreteValue, num: number?): boolean)?, max_per_value: number?)) : CdiAlertLink?
    --- @field add_discrete_value_many_links (fun (self: header_builder, dv_names: string[], description: string, predicate: (fun (dv: DiscreteValue, num: number?): boolean)?, max_per_value: number?)) : CdiAlertLink?
    --- @field add_medication_link (fun (self: header_builder, cat: string, description: string?, predicate: (fun (med: Medication): boolean)?)) : CdiAlertLink?
    --- @field add_medication_links (fun (self: header_builder, cats: string[], description: string?, predicate: (fun (med: Medication): boolean)?)) : CdiAlertLink?

    local header_builder_meta = {
        __index = {
            --- @param self header_builder
            --- @param require_links boolean
            --- @return CdiAlertLink?
            build = function(self, require_links)
                if require_links and #self.links == 0 then
                    return nil
                end
                local header = links_lib.make_header_link(self.name)
                header.links = self.links
                header.sequence = self.sequence
                return header
            end,

            --- @param self header_builder
            --- @param link CdiAlertLink?
            --- @return CdiAlertLink?
            add_link = function(self, link)
                if link and not type(link) == "userdata" then
                    error("link must be a CdiAlertLink")
                end

                if link and not link.sequence then
                    link.sequence = 1
                end
                table.insert(self.links, link)
                return link
            end,

            --- @param self header_builder
            --- @param link CdiAlertLink?
            --- @return CdiAlertLink?
            add_autoresolve_link = function(self, link)
                if link and not type(link) == "userdata" then
                    error("link must be a CdiAlertLink")
                end
                if link and (link.code or link.discrete_value_id or link.medication_id) then
                    link.link_text = "Autoresolved Evidence  - " .. link.link_text
                end
                if link and not link.sequence then
                    link.sequence = 1
                end
                table.insert(self.links, link)
                return link
            end,

            --- @param self header_builder
            --- @param link CdiAlertLink?
            --- @return CdiAlertLink?
            add_star_link = function(self, link)
                if link and not type(link) == "userdata" then
                    error("link must be a CdiAlertLink")
                end
                if link and (link.code or link.discrete_value_id or link.medication_id) then
                    link.link_text = "span style='color:#005079;' title='Priority alert'>&starf; </span>" .. link.link_text
                end
                if link and not link.sequence then
                    link.sequence = 1
                end
                table.insert(self.links, link)
                return link
            end,

            --- @param self header_builder
            --- @param link CdiAlertLink?
            --- @return CdiAlertLink?
            add_star_autoresolve_link = function(self, link)
                if link and not type(link) == "userdata" then
                    error("link must be a CdiAlertLink")
                end
                if link and (link.code or link.discrete_value_id or link.medication_id) then
                    link.link_text = "span style='color:#005079;' title='Priority alert'>&starf; </span>Autoresolved Evidence  - " .. link.link_text
                end
                if link and not link.sequence then
                    link.sequence = 1
                end
                table.insert(self.links, link)
                return link
            end,

            --- @param self header_builder
            --- @param ... CdiAlertLink[]
            --- @return boolean
            add_links = function(self, ...)
                local lnks = { ... }
                -- Detect sequences instead of varargs
                if type(lnks[1]) == "table" then lnks = lnks[1] end
                -- Do not use ipairs; nil values will end iteration!
                --for _, lnk in pairs(lnks or {}) do
                --    self:add_link(lnk)
                --end
                for _, lnk in ipairs(lnks) do
                    self:add_link(lnk)
                end
                return lists.some(lnks)
            end,

            --- @param self header_builder
            --- @param ... CdiAlertLink[]
            --- @return boolean
            add_autoresolve_links = function(self, ...)
                local lnks = { ... }
                -- Detect sequences instead of varargs
                if type(lnks[1]) == "table" then lnks = lnks[1] end
                -- Do not use ipairs; nil values will end iteration!
                --for _, lnk in pairs(lnks or {}) do
                --    self:add_link(lnk)
                --end
                for _, lnk in ipairs(lnks) do
                    if lnk and (lnk.code or lnk.discrete_value_id or lnk.medication_id) then
                        lnk.link_text = "Autoresolved Evidence  - " .. lnk.link_text
                    end
                    self:add_link(lnk)
                end
                return lists.some(lnks)
            end,

            --- @param self header_builder
            --- @param ... CdiAlertLink[]
            --- @return boolean
            add_star_links = function(self, ...)
                local lnks = { ... }
                -- Detect sequences instead of varargs
                if type(lnks[1]) == "table" then lnks = lnks[1] end
                for _, lnk in ipairs(lnks) do
                    if lnk and (lnk.code or lnk.discrete_value_id or lnk.medication_id) then
                        lnk.link_text = "span style='color:#005079;' title='Priority alert'>&starf; </span>" .. lnk.link_text
                    end
                    self:add_link(lnk)
                end
                return lists.some(lnks)
            end,

            --- @param self header_builder
            --- @param ... CdiAlertLink[]
            --- @return boolean
            add_star_autoresolve_links = function(self, ...)
                local lnks = { ... }
                -- Detect sequences instead of varargs
                if type(lnks[1]) == "table" then lnks = lnks[1] end
                for _, lnk in ipairs(lnks) do
                    if lnk and (lnk.code or lnk.discrete_value_id or lnk.medication_id) then
                        lnk.link_text = "span style='color:#005079;' title='Priority alert'>&starf; </span>Autoresolved Evidence  - " .. lnk.link_text
                    end
                    self:add_link(lnk)
                end
                return lists.some(lnks)
            end,

            --- @param self header_builder
            --- @param text string
            --- @param validated boolean?
            --- @return CdiAlertLink?
            add_text_link = function(self, text, validated)
                local link = links_lib.make_header_link(text, validated)
                if link then
                    link.permanent = true
                    link.sequence = 0
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param document_type string
            --- @param description string
            --- @return CdiAlertLink?
            add_document_link = function(self, document_type, description)
                local link = links_lib.get_document_link { documentType = document_type, text = description }
                if link then
                    link.sequence = 1
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param code string
            --- @param description string
            --- @return CdiAlertLink?
            add_code_link = function(self, code, description)
                local link = links_lib.get_code_link { code = code, text = description }
                if link then
                    link.sequence = 1
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param codes string[];
            --- @param description string
            --- @return CdiAlertLink?
            add_code_one_of_link = function(self, codes, description)
                ---@type CdiAlertLink[]
                for _, code in ipairs(codes) do
                    local link = links_lib.get_code_link { code = code, text = description }
                    if link then
                        link.sequence = 1
                        self:add_link(link)
                        return link
                    end
                end
            end,

            --- @param self header_builder
            --- @param prefix string
            --- @param description string
            --- @return CdiAlertLink?
            add_code_prefix_link = function(self, prefix, description)
                local link = codes_lib.get_code_prefix_link { prefix = prefix, text = description }
                if link then
                    link.sequence = 1
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param abstraction string
            --- @param description string
            --- @return CdiAlertLink?
            add_abstraction_link = function(self, abstraction, description)
                local link = links_lib.get_abstraction_link { code = abstraction, text = description }
                if link then
                    link.sequence = 1
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param abstraction string
            --- @param description string
            --- @return CdiAlertLink?
            add_abstraction_link_with_value = function(self, abstraction, description)
                local link = links_lib.get_abstraction_value_link { code = abstraction, text = description }
                if link then
                    link.sequence = 1
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param dv_name string
            --- @param description string
            --- @param predicate (fun (dv: DiscreteValue, num: number): boolean)?
            --- @return CdiAlertLink?
            add_discrete_value_link = function(self, dv_name, description, predicate)
                local link = links_lib.get_discrete_value_link {
                    discreteValueName = dv_name,
                    text = description,
                    predicate = predicate
                }
                if link then
                    link.sequence = 1
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param dv_names string[]
            --- @param description string
            --- @param predicate (fun (dv: DiscreteValue, num: number): boolean)?
            --- @return CdiAlertLink?
            add_discrete_value_one_of_link = function(self, dv_names, description, predicate)
                local link = links_lib.get_discrete_value_link {
                    discreteValueNames = dv_names,
                    text = description, predicate = predicate
                }
                if link then
                    link.sequence = 1
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param dv_name string
            --- @param description string
            --- @param predicate (fun (dv: DiscreteValue, num: number): boolean)?
            --- @param max_per_value number?
            --- @return CdiAlertLink?
            add_discrete_value_links = function(self, dv_name, description, predicate, max_per_value)
                local lnks = links_lib.get_discrete_value_links {
                    discreteValueName = dv_name,
                    text = description,
                    predicate = predicate,
                    max_per_value = max_per_value
                }

                for _, link in ipairs(lnks) do
                    link.sequence = 1
                    self:add_link(link)
                end
                return lnks
            end,

            --- @param self header_builder
            --- @param dv_names string[]
            --- @param description string
            --- @param predicate (fun (dv: DiscreteValue, num: number): boolean)?
            --- @param max_per_value number?
            --- @return CdiAlertLink[]
            add_discrete_value_many_links = function(self, dv_names, description, predicate, max_per_value)
                local lnks = links_lib.get_discrete_value_links {
                    discreteValueNames = dv_names,
                    text = description,
                    predicate = predicate,
                    max_per_value = max_per_value
                }

                for _, link in ipairs(lnks) do
                    link.sequence = 1
                    self:add_link(link)
                end
                return lnks
            end,

            --- @param self header_builder
            --- @param cat string
            --- @param description string?
            --- @param predicate (fun (med: Medication): boolean)?
            --- @return CdiAlertLink?
            add_medication_link = function(self, cat, description, predicate)
                description = description or ""
                local link = links_lib.get_medication_link { cat = cat, text = description, predicate = predicate }
                if link then
                    link.sequence = 1
                    self:add_link(link)
                end
                return link
            end,

            --- @param self header_builder
            --- @param cats string[]
            --- @param description string?
            --- @param predicate (fun (med: Medication): boolean)?
            --- @return CdiAlertLink[]?
            add_medication_links = function(self, cats, description, predicate)
                description = description or ""
                local lnks = links_lib.get_medication_links { cats = cats, text = description, predicate = predicate }
                for _, link in ipairs(lnks) do
                    link.sequence = 1
                    self:add_link(link)
                end
                return lnks
            end,
        }
    }

    --- @param name string
    --- @param seq integer
    --- @return header_builder
    function module.make_header_builder(name, seq)
        --- @type header_builder
        ---@diagnostic disable-next-line: missing-fields
        local h = {}
        h.name = name
        h.links = {}
        h.sequence = seq
        h.sequence_counter = 1

        setmetatable(h, header_builder_meta)

        return h
    end

    return module
end
