local ValidityRule = require("src.ValidityRule")
local formhandler = require("src.formhandler")
local deckvalidator = require("src.deckvalidator")
local cardlist_helper = require("src.cardlist_helper")
local deckbuilder = {}
deckbuilder.cardlist_table = {}
deckbuilder.found_cards = {}
deckbuilder.not_found_cards = {}

--TODO Internationalization https://stackoverflow.com/questions/8886615/lua-how-to-do-internationalization
--TODO Proper error handling and user feedback for errors. Currently the mod just fails silently if something goes wrong with the web request or csv parsing.
--TODO Documentation for functions and code in general. Also user guide for how to use the mod. Maybe even a tutorial video.

deckbuilder.description =
[[This is a deck builder. Paste the list of cards in the text box below and press Submit. Each individual cards needs to be in separate line. You can set validation rules in the Settings. ]]

---Helper function to dump tables into string for printing
---@param o table
---@return string
function deckbuilder.dump(o)
    if type(o) == 'table' then
        local s = ''
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. deckbuilder.dump(v) .. ', '
        end
        return '{ ' .. string.sub(s, 1, -3) .. ' } '
    else
        return tostring(o)
    end
end

---Wrapper around self.UI.SetAttribute that will also update the stored xml table.
---@param id tts__UIElement_Id
---@param name string
---@param value string | number | boolean
---@return boolean
function deckbuilder.setattribute(id,name,value)
    local e = deckbuilder.find_xml_table_element_by_id(Xmltable,id)
    assert(e)
    e["attributes"][name] = value
    return self.UI.setAttribute(id, name, value)
end

---Activates/deactivates UI
---@param main_active boolean Indicates whether the UI is active (shown) or not
---@return boolean
function deckbuilder.deck_builder(main_active)
    if Xmltable == nil then
        --Globals to store ui xml table structure
        Xmltable, Xml_dropdown, Xml_dropdown_options = deckbuilder.init_dropdown()
        deckbuilder.setattribute("description", "text", deckbuilder.description)
    end
    if Csv_url then deckbuilder.setattribute("csv_url","text",Csv_url) end
    if Cardback_url then deckbuilder.setattribute("card_back_url","text",Cardback_url) end
    if Selected_validity_rule then
        deckbuilder.setattribute("ValidityRuleSet","value",Selected_validity_rule) 
    else
        deckbuilder.setattribute("ValidityRuleSet","value",0) --Initializing dropdown
    end
    if not main_active then
        self.UI.show("main")
        deckbuilder.setattribute("main", "active", true)
        deckbuilder.setattribute("submit_button", "interactable", true)
        --self.UI.show("settings")
    else
        self.UI.hide("main")
        deckbuilder.setattribute("open_settings", "interactable", true)
        self.UI.hide("settings")
        self.UI.hide("validity_rule")
    end

    return not main_active
end

---Handles validation check, when the Submit button is pressed on the main window.
function deckbuilder.validate_deck(player, value, id)
    --get info from csv_url and turn it into lua table
    local input_cardlist = formhandler.get_value("cardlist","text")
    local input_cardlist_table = {}
    local success, error = pcall(function () assert(input_cardlist ~= "" and input_cardlist ~= nil, "Card list is empty! Please paste the list of cards in the text box before submitting the deck.") end)
    if not success then
        ---@cast error -nil
        error = error:match(":[^:]*:(.*)") or error
        broadcastToColor(error,player.color,"Red")
        return
    end
    success, error = pcall(function () assert(formhandler.get_value("csv_url") ~= "", "CSV URL is not set! Please set it in settings before submitting the deck.") end)
    if not success then
        ---@cast error -nil
        error = error:match(":[^:]*:(.*)") or error
        broadcastToColor(error,player.color,"Red")
        return
    end
    deckbuilder.setattribute("submit_button", "interactable", false)
    deckbuilder.setattribute("deckbuilder_button", "interactable", false)
    deckbuilder.setattribute("progressbar","percentage",0)
    self.UI.show("validate_log")
    self.UI.show("progress_indicator")
    self.UI.hide("main")
    self.UI.hide("settings")
    self.UI.hide("validity_rule")
    --local not_found_cards = {}
    --local found_cards = {}
    for s in input_cardlist:gmatch("[^\r\n]+") do
        table.insert(input_cardlist_table, s)
    end
    local wi = Wait.time(function ()
        local percent = tonumber(self.UI.getAttribute("progressbar","percentage"))+10
        percent = percent > 100 and 0 or percent
        deckbuilder.setattribute("progressbar","percentage",percent)
    end,0.1,-1)
    WebRequest.get(formhandler.get_value("csv_url"), function (request)
        if request.is_error then
            log(request.error)
        else
            --get cardlist info from csv and turn it into lua table
            deckbuilder.cardlist_table = cardlist_helper.prepare_card_table(request.text)
            deckbuilder.found_cards = {}
            deckbuilder.not_found_cards = {}
            for _, title in ipairs(input_cardlist_table) do
                --find cards from infobox in csv list, move not found to exception list, move found ones to found_cards
                local cardinfo = cardlist_helper.search_card(deckbuilder.cardlist_table,title)
                if cardinfo == nil or not next(cardinfo) then
                    table.insert(deckbuilder.not_found_cards,title)
                else
                    table.insert(deckbuilder.found_cards,cardinfo)
                end
            end
            self.UI.hide("progress_indicator")
            Wait.stop(wi)
            --evaluate found_cards against validity rule that is selected on the form. Gather problems to exception list.
            local validity_rule = Validity_rules[tostring(formhandler.get_value("ValidityRuleSet","value"))+1]
            local validation_result = deckvalidator.validate(deckbuilder.found_cards,validity_rule)
            local missing_cards = next(deckbuilder.not_found_cards) ~= nil and "These cards were not found in the list:\n\t" .. table.concat(deckbuilder.not_found_cards,"\n\t") or nil
            deckbuilder.setattribute("validate_log_title","text",validity_rule.name)
            local validaton_log_text = "Everything OK!"
            formhandler.update_value("true","validation_success")
            if missing_cards and next(validation_result) ~= nil then
                validaton_log_text = "<b>Validation results:</b>\n\n" .. missing_cards .. "\n\n" .. table.concat(validation_result,"\n")
                formhandler.update_value("false","validation_success")
            elseif missing_cards then
                validaton_log_text = "<b>Validation results:</b>\n\n" .. missing_cards
                formhandler.update_value("false","validation_success")
            elseif next(validation_result) ~= nil then
                validaton_log_text = "<b>Validation results:</b>\n\n" .. table.concat(validation_result,"\n")
                formhandler.update_value("false","validation_success")
            end
            deckbuilder.setattribute("validation_results","text",validaton_log_text)
        end
    end)
end

function deckbuilder.open_settings()
    deckbuilder.clear_dropdown()
    if Validity_rules then
        for i, validity_rule in ipairs(Validity_rules) do
            deckbuilder.insert_dropdown_option(i, validity_rule.name)
        end
    end
    deckbuilder.setattribute("open_settings", "interactable", false)
    deckbuilder.setattribute("submit_button", "interactable", false)
    self.UI.setXmlTable(Xmltable)
    self.UI.show("settings")
end

function deckbuilder.save_settings()
    deckbuilder.setattribute("csv_url","text",formhandler.get_value("csv_url"))
    deckbuilder.setattribute("card_back_url","text",formhandler.get_value("card_back_url"))
    self.UI.hide("settings")
    deckbuilder.setattribute("open_settings", "interactable", true)
    deckbuilder.setattribute("submit_button", "interactable", true)
end

function deckbuilder.exit_settings()
    self.UI.hide("settings")
    deckbuilder.setattribute("open_settings", "interactable", true)
    deckbuilder.setattribute("submit_button", "interactable", true)
end

function deckbuilder.edit_validity_rule()
    self.UI.show("validity_rule")
    self.UI.hide("settings")
    local selected_index = tonumber(self.UI.getAttribute("ValidityRuleSet", "value"))
    if selected_index + 1 > #Validity_rules then
        local validity_rule = ValidityRule:new()
        ValidityRule.push_to_ui(validity_rule)
    else
        ValidityRule.push_to_ui(Validity_rules[selected_index + 1])
    end
end

function deckbuilder.exit_validity_rule()
    self.UI.hide("validity_rule")
    self.UI.show("settings")
end

function deckbuilder.save_validity_rule()
    local selected_index = tonumber(self.UI.getAttribute("ValidityRuleSet", "value"))+1 --Dropdown options start with 0
    local validity_rule = {
        name = formhandler.get_value("name"),
        minimum = formhandler.get_value("min_cards"),
        maximum = formhandler.get_value("max_cards"),
        check_uniqueness = formhandler.get_value("check_uniqueness", "isOn"),
        limit = formhandler.get_value("max_individual_cards"),
        exclusion = formhandler.get_value("exclusion_list"),
        mandatory = formhandler.get_value("mandatory_list"),
        banned = formhandler.get_value("banned_list"),
    }
    if Validity_rules[selected_index] == nil then
        deckbuilder.insert_dropdown_option(selected_index, validity_rule.name)
        self.UI.setXmlTable(Xmltable)
        deckbuilder.setattribute("ValidityRuleSet", "value", selected_index-1)
    end
    Validity_rules[selected_index] = ValidityRule:new(validity_rule)
    self.UI.hide("validity_rule")
    self.UI.show("settings")
end

function deckbuilder.delete_validity_rule()
    local selected_index = tonumber(self.UI.getAttribute("ValidityRuleSet", "value"))
    if #Validity_rules >= selected_index + 1 then
        table.remove(Validity_rules, selected_index + 1)
        deckbuilder.clear_dropdown()
        if #Validity_rules ~= 0 then
            for i, validity_rule in ipairs(Validity_rules) do
                deckbuilder.insert_dropdown_option(i, validity_rule.name)
            end
        end
    end
    self.UI.setXmlTable(Xmltable)
    deckbuilder.setattribute("ValidityRuleSet","value",0) --Initializing dropdown

    self.UI.hide("validity_rule")
    self.UI.show("settings")
end

--[[ function deckbuilder.store_csv_url(player, id, value)
    
end ]]

function deckbuilder.find_xml_table_element_by_id(xmltable, id)
    for _, element in ipairs(xmltable) do
        if element.attributes and element.attributes.id == id then return element end
        if element.children then
            local found = deckbuilder.find_xml_table_element_by_id(element.children, id)
            if found then return found end
        end
    end
    return nil
end

function deckbuilder.init_dropdown()
    local xmltable = self.UI.getXmlTable()
    local dropdown = deckbuilder.find_xml_table_element_by_id(xmltable, "ValidityRuleSet")
    assert(dropdown, "Couldn't find dropdown in xml table!")
    local options = dropdown.children
    return xmltable, dropdown, options
end

---Changes the text of the selected dropdown option
---@param index integer Index of the option of which text to change. Starts with 1.
---@param text string The text to change the option's value to.
function deckbuilder.rename_dropdown_option(index, text)
    --TODO implement rename function
end

function deckbuilder.insert_dropdown_option(index, text)
    local option = {
        tag = "Option",
        value = text,
        attributes = {},
        children = {},
    }
    table.insert(Xml_dropdown_options, index, option)
    Xml_dropdown.children = Xml_dropdown_options
end

function deckbuilder.clear_dropdown()
    local last_option = {
        tag = "Option",
        value = "Create new ...",
        attributes = {},
        children = {},
    }
    Xml_dropdown_options = {}
    table.insert(Xml_dropdown_options, last_option)
    Xml_dropdown.children = Xml_dropdown_options
    --deckbuilder.update_dropdown(dropdown)
end

function deckbuilder.validity_rule_selected(_, selected_index, id)
    -- convert string to number
    local selected_idx = tonumber(selected_index)
    assert(type(selected_idx) == "number")

    -- set dropdown value to item index
    deckbuilder.setattribute(id, "value", selected_idx)
    formhandler.update_value(selected_index,"ValidityRuleSet")
end

function deckbuilder.exit_validity_log()
    deckbuilder.setattribute("submit_button", "interactable", true)
    deckbuilder.setattribute("deckbuilder_button", "interactable", true)
    deckbuilder.setattribute("validation_results","text","")
    self.UI.hide("validate_log")
    self.UI.show("main")
end

---Rotates a 2D vector based on Y-axis rotation (Euler angle)
---@param vec table Vector with x, y, z components (y is preserved)
---@param rotation_y number Y-axis rotation in degrees
---@return table Rotated vector
function deckbuilder.rotate_vector_2d(vec, rotation_y)
    local rad = math.rad(rotation_y)
    local cos_y = math.cos(rad)
    local sin_y = math.sin(rad)
    
    -- Rotate around Y axis (only affects X and Z)
    local x = vec.x * cos_y - vec.z * sin_y
    local z = - vec.x * sin_y + vec.z * cos_y
    
    return Vector(x, vec.y, z)
end

function deckbuilder.create_deck(player, value, id)
    if formhandler.get_value("validation_success") == "false" then
        player.showConfirmDialog("This deck did not pass the validation. Are you sure you want to create it?", function (player_color)
            self.UI.hide("validate_log")
            deckbuilder.setattribute("deckbuilder_button", "interactable", true)
            deckbuilder.deck_creation(deckbuilder.found_cards, formhandler.get_value("card_back_url"))
        end)
    else
        self.UI.hide("validate_log")
        deckbuilder.setattribute("deckbuilder_button", "interactable", true)
        deckbuilder.deck_creation(deckbuilder.found_cards, formhandler.get_value("card_back_url"),player)
    end
end


function deckbuilder.deck_creation(cards_list, card_back_url,player)
    local success, error = pcall(function () assert(card_back_url ~= "", "Card back URL is not set! Please set it in settings before submitting the deck.") end)
    if not success then
        ---@cast error -nil
        error = error:match(":[^:]*:(.*)") or error
        broadcastToColor(error,player.color,"Red")
        return
    end
    local pos = self.getPosition()
    local rot = self.getRotation()

    local base_offset = Vector(-1.75, 2, 0)
    local rotated_offset = deckbuilder.rotate_vector_2d(base_offset, rot.y)
    pos = pos + rotated_offset
    rot = Vector(rot.x + 180, rot.y, rot.z)
    for _, card in ipairs(cards_list) do
        local cardinfo = {}
        cardinfo["CARDINFO"] = {}
        for key, value in pairs(card) do
            if key ~= "FaceURL" then
               cardinfo["CARDINFO"][key] = value
            end
        end
        spawnObject({
            type = "Card",
            position = pos,
            rotation = rot,
            callback_function = function (obj)
                obj.setName(card.title)
                obj.setDescription(card.text)
                obj.script_state = JSON.encode(cardinfo)
                obj.setCustomObject({
                    face = card.FaceURL,
                    back = card_back_url,
                })
            end
        })
    end
end

return deckbuilder
