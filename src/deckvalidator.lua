local cardlist_helper = require("src.cardlist_helper")
local deckvalidator = {}


--[[ function deckvalidator.get_card_info(cardname,cardlist_table)
    local cardinfo = ""
    return cardinfo or nil
end
 ]]

---Counts cards in decklist
---@param decklist table
---@param card table
---@return integer
function deckvalidator.count_card(decklist,card)
    local qty = 0
    for _, crd in ipairs(decklist) do
        if string.upper(crd.title) == string.upper(card.title) then
            qty = qty + 1
        end
    end
    return qty
end

---Checks if a card is excluded by the exclusion rule
---@param card table A card to check
---@param exclusion_rule string
---@return boolean
function deckvalidator.is_excluded(card,exclusion_rule)
    local rules = cardlist_helper.parse_csv_line(exclusion_rule)
    for _, rule in ipairs(rules) do
        --Direct match
        if string.upper(rule) == string.upper(card.title) then
            return true
        end
        --field match
        if string.find(rule, ":") then
            local colonPos = string.find(rule, ":")
            local field = string.sub(rule, 1, colonPos - 1)
            local value = string.sub(rule, colonPos + 1)
            if card[field] and string.upper(card[field]) == string.upper(value) then
                return true
            end
        end
    end
    return false
end

---Validates decklist against validity rule
function deckvalidator.validate(decklist, validity_rule)
    local result = {}
    local unique_cards = cardlist_helper.get_unique_elements(decklist)
    --minimum size
    if tonumber(validity_rule.minimum) and #decklist < tonumber(validity_rule.minimum) then
        table.insert(result,"Number of cards (" .. #decklist .. ") less than minimum (" .. validity_rule.minimum .. ").")
    end
    --maximum size
    if tonumber(validity_rule.maximum) and #decklist > tonumber(validity_rule.maximum) then
        table.insert(result,"Number of cards (" .. #decklist .. ") more than maximum (" .. validity_rule.maximum .. ").")
    end

    --Uniqueness and limit of copies
    for _, card in ipairs(unique_cards) do
        local qty = deckvalidator.count_card(decklist,card)
        if validity_rule.check_uniqueness and card.unique ~= "" and qty > 1 then
            table.insert(result, card.title .. " is unique, but has " .. qty .. " copies in the list.")
        else
            if not deckvalidator.is_excluded(card,validity_rule.exclusion) then
                if qty > tonumber(validity_rule.limit) then
                    table.insert(result, card.title .. " has " .. qty .. " copies in the list, but limit is " .. validity_rule.limit)
                end
            end
        end
    end

    --Mandatory cards
    local mandatory_cards = cardlist_helper.parse_csv_line(validity_rule.mandatory)
    for _, mandatory in ipairs(mandatory_cards) do
        mandatory = cardlist_helper.trim(mandatory)
        local qty = deckvalidator.count_card(decklist,{title = mandatory})
        if qty == 0 then
            table.insert(result, "Mandatory card " .. mandatory .. " is missing from the list.")
        end
    end

    --Banned cards
    local banned_cards = cardlist_helper.parse_csv_line(validity_rule.banned)
    for _, banned in ipairs(banned_cards) do
        banned = cardlist_helper.trim(banned)
        local qty = deckvalidator.count_card(decklist,{title = banned})
        if qty > 0 then
            table.insert(result, "Banned card " .. banned .. " is present in the list.")
        end
    end
    return result
end

return deckvalidator