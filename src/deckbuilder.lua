local ValidityRule = require("src.ValidityRule")
local formhandler = require("src.formhandler")
local deckvalidator = require("src.deckvalidator")
local cardlist_helper = require("src.cardlist_helper")
local deckbuilder_i18n = require("src.deckbuilder_i18n")
local deckbuilder = {}
deckbuilder.cardlist_table = {}
deckbuilder.found_cards = {}
deckbuilder.not_found_cards = {}

--TODO Internationalization https://stackoverflow.com/questions/8886615/lua-how-to-do-internationalization
--TODO Proper error handling and user feedback for errors. Currently the mod just fails silently if something goes wrong with the web request or csv parsing.
--TODO Documentation for functions and code in general. Also user guide for how to use the mod. Maybe even a tutorial video.

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


---Activates/deactivates UI
---@param main_active boolean Indicates whether the UI is active (shown) or not
---@return boolean
function deckbuilder.deck_builder(main_active)
    if Xmltable == nil then
        --Globals to store ui xml table structure
        Xmltable, Xml_dropdown, Xml_dropdown_options = deckbuilder.init_dropdown()
        --formhandler.setattribute("description", "text", deckbuilder.description)
    end
    assert(Xmltable)
    --formhandler.set_labels()
    local csv_url = formhandler.get_value("csv_url")
    if csv_url ~= nil and csv_url ~= "" then formhandler.setattribute("csv_url","text",csv_url) end
    local cardback_url = formhandler.get_value("card_back_url")
    if cardback_url ~= nil and cardback_url ~= "" then formhandler.setattribute("card_back_url","text",cardback_url) end
    local selected_validity_rule = formhandler.get_value("ValidityRuleSet","value") or "0"
    if selected_validity_rule then
        formhandler.setattribute("ValidityRuleSet","value",selected_validity_rule) --Initializing dropdown
    end
    if not main_active then
        self.UI.show("main")
        formhandler.setattribute("main", "active", true)
        formhandler.setattribute("submit_button", "interactable", true)
        --self.UI.show("settings")
    else
        self.UI.hide("main")
        formhandler.setattribute("open_settings", "interactable", true)
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
    local success, error = pcall(function () assert(input_cardlist ~= "" and input_cardlist ~= nil, deckbuilder_i18n.translate("error_cardlist_empty")) end)
    if not success then
        ---@cast error -nil
        error = error:match(":[^:]*:(.*)") or error
        broadcastToColor(error,player.color,"Red")
        return
    end
    success, error = pcall(function () assert(formhandler.get_value("csv_url") ~= "", deckbuilder_i18n.translate("error_csv_url_not_set")) end)
    if not success then
        ---@cast error -nil
        error = error:match(":[^:]*:(.*)") or error
        broadcastToColor(error,player.color,"Red")
        return
    end
    formhandler.setattribute("submit_button", "interactable", false)
    formhandler.setattribute("deckbuilder_button", "interactable", false)
    formhandler.setattribute("progressbar","percentage",0)
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
        formhandler.setattribute("progressbar","percentage",percent)
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
            local missing_cards = next(deckbuilder.not_found_cards) ~= nil and deckbuilder_i18n.translate("validation_cards_not_found").. "\n\t" .. table.concat(deckbuilder.not_found_cards,"\n\t") or nil
            formhandler.setattribute("validate_log_title","text",validity_rule.name)
            local validaton_log_text = deckbuilder_i18n.translate("validation_everything_ok")
            formhandler.update_value("true","validation_success")
            if missing_cards and next(validation_result) ~= nil then
                validaton_log_text = deckbuilder_i18n.translate("validation_results_label").. "\n\n" .. missing_cards .. "\n\n" .. table.concat(validation_result,"\n")
                formhandler.update_value("false","validation_success")
            elseif missing_cards then
                validaton_log_text = deckbuilder_i18n.translate("validation_results_label").. "\n\n" .. missing_cards
                formhandler.update_value("false","validation_success")
            elseif next(validation_result) ~= nil then
                validaton_log_text = deckbuilder_i18n.translate("validation_results_label").. "\n\n" .. table.concat(validation_result,"\n")
                formhandler.update_value("false","validation_success")
            end
            formhandler.setattribute("validation_results","text",validaton_log_text)
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
    formhandler.setattribute("open_settings", "interactable", false)
    formhandler.setattribute("submit_button", "interactable", false)
    if formhandler.get_value("cardlist") ~= nil then
        formhandler.setattribute("cardlist", "text", formhandler.get_value("cardlist"))
    end
    self.UI.setXmlTable(Xmltable)
    self.UI.show("settings")
end

function deckbuilder.save_settings()
    formhandler.setattribute("csv_url","text",formhandler.get_value("csv_url"))
    formhandler.setattribute("card_back_url","text",formhandler.get_value("card_back_url"))
    self.UI.hide("settings")
    formhandler.setattribute("open_settings", "interactable", true)
    formhandler.setattribute("submit_button", "interactable", true)
end

function deckbuilder.exit_settings()
    self.UI.hide("settings")
    formhandler.setattribute("open_settings", "interactable", true)
    formhandler.setattribute("submit_button", "interactable", true)
end

function deckbuilder.locale_selected(player, selected_index, id)
    -- convert string to number
    local selected_idx = tonumber(selected_index)
    assert(type(selected_idx) == "number")

    -- set dropdown value to item index
    formhandler.setattribute(id, "value", selected_idx)
    formhandler.update_value(selected_index, id)
    
    local selected_locale = ""
    if selected_index == "0" then
        selected_locale = "en"
    elseif selected_index == "1" then
        selected_locale = "hu"
    end
    if selected_locale ~= deckbuilder_i18n.currentlocale then
        deckbuilder_i18n.setlocale(selected_locale)
        formhandler.set_labels()
    end
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
        formhandler.setattribute("ValidityRuleSet", "value", selected_index-1)
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
    formhandler.setattribute("ValidityRuleSet","value",0) --Initializing dropdown

    self.UI.hide("validity_rule")
    self.UI.show("settings")
end

function deckbuilder.init_dropdown()
    local xmltable = self.UI.getXmlTable()
    local dropdown = formhandler.find_xml_table_element_by_id(xmltable, "ValidityRuleSet")
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
        value = deckbuilder_i18n.translate("dropdown_create_new"),
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
    formhandler.setattribute(id, "value", selected_idx)
    formhandler.update_value(selected_index,"ValidityRuleSet")
end

function deckbuilder.exit_validity_log()
    formhandler.setattribute("submit_button", "interactable", true)
    formhandler.setattribute("deckbuilder_button", "interactable", true)
    formhandler.set_button_text_color("deckbuilder_button")
    formhandler.setattribute("validation_results","text","")
    self.UI.hide("validate_log")
    self.UI.show("main")
end

---Shows a custom confirmation dialog with translatable buttons
---@param message string The message to display
---@param onYes function Callback when Yes is clicked
function deckbuilder.show_custom_dialog(message, onYes)
    formhandler.setattribute("confirm_dialog_message", "text", message)
    formhandler.setattribute("confirm_dialog_yes", "text", deckbuilder_i18n.translate("button_yes"))
    formhandler.setattribute("confirm_dialog_no", "text", deckbuilder_i18n.translate("button_no"))
    
    -- Store the callback for the Yes button
    deckbuilder.confirm_dialog_callback = onYes
    
    self.UI.show("confirm_dialog")
end

function deckbuilder.confirm_dialog_yes()
    self.UI.hide("confirm_dialog")
    if deckbuilder.confirm_dialog_callback then
        deckbuilder.confirm_dialog_callback()
        deckbuilder.confirm_dialog_callback = nil
    end
end

function deckbuilder.confirm_dialog_no()
    self.UI.hide("confirm_dialog")
    deckbuilder.confirm_dialog_callback = nil
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
        deckbuilder.show_custom_dialog(
            deckbuilder_i18n.translate("dialog_deck_validation_failed"),
            function()
                self.UI.hide("validate_log")
                formhandler.setattribute("deckbuilder_button", "interactable", true)
                formhandler.set_button_text_color("deckbuilder_button")
                deckbuilder.deck_creation(deckbuilder.found_cards, formhandler.get_value("card_back_url"),player)
            end
        )
    else
        self.UI.hide("validate_log")
        formhandler.setattribute("deckbuilder_button", "interactable", true)
        formhandler.set_button_text_color("deckbuilder_button")
        deckbuilder.deck_creation(deckbuilder.found_cards, formhandler.get_value("card_back_url"), player)
    end
end


function deckbuilder.deck_creation(cards_list, card_back_url, player)
    local success, error = pcall(function () assert(card_back_url ~= "", deckbuilder_i18n.translate("error_cardback_url_not_set")) end)
    if not success then
        ---@cast error -nil
        error = error:match(":[^:]*:(.*)") or error
        broadcastToColor(error,player.color,"Red")
        return
    end
    local pos = self.getPosition()
    local rot = self.getRotation()

    local base_offset = Vector(-2, 2, 0)
    local rotated_offset = deckbuilder.rotate_vector_2d(base_offset, rot.y)
    pos = pos + rotated_offset
    rot = Vector(rot.x + 180, rot.y, rot.z)
    for _, card in ipairs(cards_list) do
        local sideways = false
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
                obj.setName(card.display_title)
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
