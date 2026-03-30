local formhandler = {}
formhandler.formdata = {}

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

return formhandler