
local deckbuilder_i18n = require("src.deckbuilder_i18n")

---@class ValidityRule
local ValidityRule = {
    name = deckbuilder_i18n.translate("default_rule_name"),
    minimum = 40,
    maximum = nil,
    limit = 3,
    exclusion = "type:item",
    mandatory = "Operations",
    banned = "",
    check_uniqueness = true,
}


function ValidityRule.push_to_ui(validity_rule)
    self.UI.setAttribute("name","text",validity_rule.name)
    self.UI.setAttribute("min_cards","text",validity_rule.minimum or "")
    self.UI.setAttribute("max_cards","text",validity_rule.maximum or "")
    self.UI.setAttribute("check_uniqueness","isOn",validity_rule.check_uniqueness)
    self.UI.setAttribute("max_individual_cards","text",validity_rule.limit or "")
    self.UI.setAttribute("exclusion_list","text",validity_rule.exclusion)
    self.UI.setAttribute("mandatory_list","text",validity_rule.mandatory)
    self.UI.setAttribute("banned_list","text",validity_rule.banned)
end

function ValidityRule.select_by_name(name)
    for _, validity_rule in ipairs(Validity_rules) do
        if validity_rule.name == name then
            return validity_rule
        end
    end
    return nil
end

function ValidityRule:__tostring()
    local s = ""
    for key, value in pairs(self) do
        s = s .. key .. ": " .. value .. "\n"
    end
    return s
end

---Creates new instance of validity rule
---@param o table|nil
---@return ValidityRule 
function ValidityRule:new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

return ValidityRule