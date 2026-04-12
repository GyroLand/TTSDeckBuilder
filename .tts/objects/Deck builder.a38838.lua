local cardlist_helper = require("src.cardlist_helper")
local deckbuilder = require("src.deckbuilder")
local ValidityRule = require("src.ValidityRule")
local formhandler = require("src.formhandler")
local deckbuilder_i18n = require("src.deckbuilder_i18n")
local main_window_shown = false
Validity_rules = {}

function Deck_builder()
    main_window_shown = deckbuilder.deck_builder(main_window_shown)
end

function Validate_deck(player, value, id)
    deckbuilder.validate_deck(player, value, id)
end

function Save_settings()
    deckbuilder.save_settings()
end

function Open_settings()
    deckbuilder.open_settings()
end

function Locale_selected(player, value, id)
    deckbuilder.locale_selected(player, value, id)
end

function Exit_settings()
    deckbuilder.exit_settings()
end

function Edit_validity_rule()
    deckbuilder.edit_validity_rule()
end

function Exit_validity_rule()
    deckbuilder.exit_validity_rule()
end

function Save_validity_rule()
    deckbuilder.save_validity_rule()
end

function Delete_validity_rule()
    deckbuilder.delete_validity_rule()
end

function Validity_rule_selected(player, value, id)
    deckbuilder.validity_rule_selected(player, value, id)
end

function Exit_validity_log()
    deckbuilder.exit_validity_log()
end

function Create_deck(player, value, id)
    deckbuilder.create_deck(player, value, id)
end

function Update_value(player, value, id)
    formhandler.update_value(value, id)
end

function onSave()
    local saved_data = {}
    saved_data["locale"] = deckbuilder_i18n.currentlocale
    local urls = {}
    table.insert(urls,self.UI.getAttribute("csv_url","text"))
    table.insert(urls,self.UI.getAttribute("card_back_url","text"))
    saved_data["urls"] = urls
    saved_data["selected_validity_rule"] = formhandler.get_value("ValidityRuleSet","value") or "0"
    saved_data["validity_rules"] = Validity_rules
    return JSON.encode(saved_data)
end

function onLoad(saved_data)
    local saved_data_table = JSON.decode(saved_data) or {}
    if saved_data_table.urls then
        formhandler.update_value(saved_data_table.urls[1] or "","csv_url")
        formhandler.update_value(saved_data_table.urls[2] or "","card_back_url")
    end
    if saved_data_table.validity_rules then
        Validity_rules = saved_data_table.validity_rules or {}
    end
    if saved_data_table.selected_validity_rule then
        formhandler.update_value(saved_data_table.selected_validity_rule, "ValidityRuleSet")
    end
    if saved_data_table.locale then
        deckbuilder_i18n.setlocale(saved_data_table.locale)
    end
    
    if Xmltable == nil then
        --Globals to store ui xml table structure
        Xmltable, Xml_dropdown, Xml_dropdown_options = deckbuilder.init_dropdown()
    end
    assert(Xmltable)
    formhandler.set_labels()
    formhandler.setattribute("locale_dropdown", "value", deckbuilder_i18n.currentlocale == "en" and "0" or "1")
end