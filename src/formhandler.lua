local deckbuilder_i18n = require("src.deckbuilder_i18n")
local formhandler = {}
formhandler.formdata = {}

function formhandler.find_xml_table_element_by_id(xmltable, id)
    for _, element in ipairs(xmltable) do
        if element.attributes and element.attributes.id == id then return element end
        if element.children then
            local found = formhandler.find_xml_table_element_by_id(element.children, id)
            if found then return found end
        end
    end
    return nil
end

---Wrapper around self.UI.SetAttribute that will also update the stored xml table.
---@param id tts__UIElement_Id
---@param name string
---@param value string | number | boolean
---@return boolean
function formhandler.setattribute(id,name,value)
    local e = formhandler.find_xml_table_element_by_id(Xmltable,id)
    assert(e)
    e["attributes"][name] = value
    return self.UI.setAttribute(id, name, value)
end

---Saves the values from the form to a table
---@param value string|table
---@param id string
function formhandler.update_value(value, id)
    formhandler.formdata[id] = value
end

---Returns the value of the form element either from formdata table or from the UI XML.
---@param id string Id of the UI element
---@param attribute? string Name of the attribute in XML
---@return string
function formhandler.get_value(id, attribute)
    local attr = attribute or "text"
    if formhandler.formdata[id] ~= nil then
        return formhandler.formdata[id]
    end
    return self.UI.getAttribute(id, attr)
end

function formhandler.set_labels()
    local tr = deckbuilder_i18n.translate
    local labels = deckbuilder_i18n.locales['en']
    for l, _ in pairs(labels) do
        if not l:find("_placeholder") then --Placeholders are handled separately, because they use different attribute in XML.
           formhandler.setattribute(l, "text", tr(l))
        end
    end
    local placeholders = {
        cardlist = "cardlist_placeholder",
        csv_url = "csv_url_placeholder",
        card_back_url = "card_back_url_placeholder",
        name = "name_placeholder",
        exclusion_list = "exclusion_list_placeholder",
        mandatory_list = "mandatory_list_placeholder",
        banned_list = "banned_list_placeholder",
        min_cards = "min_cards_placeholder",
        max_cards = "max_cards_placeholder",
        max_individual_cards = "max_individual_cards_placeholder",
    }
    for id, text_id in pairs(placeholders) do
       formhandler.setattribute(id,"placeholder",tr(text_id))
    end
    local tint = self.getColorTint()
    local textcolor = Color(1-tint.r,1-tint.g,1-tint.b,tint.a)
    formhandler.setattribute("deckbuilder_button","textColor",'#' .. textcolor:toHex(true))
end

return formhandler