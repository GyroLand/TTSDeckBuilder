local deckbuilder_i18n = {}

deckbuilder_i18n.locales = {}
deckbuilder_i18n.currentlocale = 'en'

---Sets the language to newlocale
---@param newlocale string 2 letter language code
function deckbuilder_i18n.setlocale(newlocale)
  assert(deckbuilder_i18n.locales[newlocale], ("The locale %q was unknown. Reverting back to Englsh."):format(newlocale))
  deckbuilder_i18n.currentlocale = newlocale
end

---Returns the translated text for id. If it doesn't exist, it returns the English text.
---@param id string id of the text to be translated
---@return string
function deckbuilder_i18n.translate(id)
  local result = deckbuilder_i18n.locales[deckbuilder_i18n.currentlocale][id] or deckbuilder_i18n.locales['en'][id] --Using english text if translated text doesn't exist.
  assert(result,("The id %q was not found."):format(id))
  return result
end

deckbuilder_i18n.locales.en = {
    description = [[This is a deck builder. Paste the list of cards in the text box below and press Submit. Each individual cards needs to be in separate line. You can set validation rules in the Settings. ]],
    l_windowtitle = "Deckbuilder",
    l_cardlist = "Card list",
    l_settings = "Settings",
    l_cardlistcsvurl = "Card list csv URL",
    l_cardbackurl = "Card back URL",
    l_validationrule = "Validation rule",
    l_validityrule = "Validity rule",
    l_name = "Name",
    l_minimumnumberofcardsindeck = "Minimum number of cards in deck:",
    l_maximumnumberofcardsindeck = "Maximum number of cards in deck:",
    l_checkuniqueness = "Check uniqueness",
    l_limitnumberofsamecards = "Limit number of same cards:",
    l_exclusionlist = "Exclusion list",
    l_mandatorycards = "Mandatory cards",
    l_bannedcards = "Banned cards",
    l_processing = "Processing...",
    l_locale = "Language",
    deckbuilder_button = "DECK",
    submit_button = "Submit",
    deleteButton = "Delete",
    save_settings_button = "Save",
    save_validity_rule_button = "Save",
    cancel_button = "Cancel",
    create_button = "Create",
    cardlist_placeholder = "Enter card list here...",
    csv_url_placeholder = "URL",
    card_back_url_placeholder = "URL",
    name_placeholder = "Name of validity rule",
    exclusion_list_placeholder = "List of cards",
    mandatory_list_placeholder = "List of cards",
    banned_list_placeholder = "List of cards",
    min_cards_placeholder = "#",
    max_cards_placeholder = "#",
    max_individual_cards_placeholder = "#",
}

deckbuilder_i18n.locales.hu = {
    description = [[Ez egy pakli készítő izé. A lenti szövegdobozba írd, vagy másold be a kártyák listáját.]],
    l_windowtitle = "Pakli készítő",
    l_cardlist = "Kártya lista",
    l_settings = "Beállítások",
    l_cardlistcsvurl = "Kártya lista csv URL",
    l_locale = "Nyelv",
    l_cardbackurl = "Kártya hátlap URL",
    l_validationrule = "Érvényességi szabály",
    l_validityrule = "Érvényességi szabály",
    l_name = "Név",
    l_minimumnumberofcardsindeck = "Minimum kártya szám a pakliban:",
    l_maximumnumberofcardsindeck = "Maximum kártya szám a pakliban:",
    l_checkuniqueness = "Egyediség ellenőrzése",
    l_limitnumberofsamecards = "Ugyanolyan kártyák számának korlátozása:",
    l_exclusionlist = "Kivétel lista",
    l_mandatorycards = "Kötelező kártyák",
    l_bannedcards = "Tiltott kártyák",
    l_processing = "Feldolgozás...",
    deckbuilder_button = "PAKLI",
    submit_button = "Mehet",
    deleteButton = "Törlés",
    save_settings_button = "Mentés",
    save_validity_rule_button = "Mentés",
    cancel_button = "Mégse",
    create_button = "Létrehoz",
    cardlist_placeholder = "Írd be a kártyák neveit...",
    csv_url_placeholder = "URL",
    card_back_url_placeholder = "URL",
    name_placeholder = "Érvényességi szabály neve",
    exclusion_list_placeholder = "Kártyák listája",
    mandatory_list_placeholder = "Kártyák listája",
    banned_list_placeholder = "Kártyák listája",
    min_cards_placeholder = "db",
    max_cards_placeholder = "db",
    max_individual_cards_placeholder = "db",
}

return deckbuilder_i18n