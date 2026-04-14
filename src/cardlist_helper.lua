local cardlist_helper = {}

function cardlist_helper.trim(s)
    return s:match("^%s*(.-)%s*$")
end

function cardlist_helper.read_csv_lines(csv)
    local lines = {}
    local buffer = ""
    for line in csv:gmatch("([^\r\n]*)\r?\n?") do
        if line ~= "" or buffer ~= "" then
            buffer = buffer ~= "" and (buffer .. "\n" .. line) or line
            local quote_count = select(2, buffer:gsub('"', ""))
            if quote_count % 2 == 0 then
                table.insert(lines, buffer)
                buffer = ""
            end
        end
    end
    if buffer ~= "" then
        table.insert(lines, buffer)
    end
    return lines
end

function cardlist_helper.parse_csv_line(line)
    local res = {}
    local in_quotes = false
    local field = ""
    local i = 1
    while i <= #line do
        local c = line:sub(i, i)
        if c == '"' then
            if line:sub(i + 1, i + 1) == '"' then
                field = field .. '"'
                i = i + 1
            else
                in_quotes = not in_quotes
            end
        elseif c == ',' and not in_quotes then
            table.insert(res, field)
            field = ""
        else
            field = field .. c
        end
        i = i + 1
    end
    table.insert(res, field)
    return res
end

---Gets a csv cardlist and converts it into a lua table
---@param csv_string string
---@return table
function cardlist_helper.prepare_card_table(csv_string)
    local lines = cardlist_helper.read_csv_lines(csv_string)
    if #lines < 2 then return {false, "CSV must have header and at least one row"} end

    local headers = cardlist_helper.parse_csv_line(lines[1])
    local output = {}

    for i = 2, #lines do
        local row_data = cardlist_helper.parse_csv_line(lines[i])
        local row_table = {}
        local start_col = 2

        local cardname = string.upper(cardlist_helper.trim(row_data[1]))
        row_table["display_title"] = cardlist_helper.trim(row_data[1])
        for j = start_col, #headers do
            local header = cardlist_helper.trim(headers[j])
            row_table[header] = row_data[j]
        end
--[[         local keyed_table = {}
        for k, v in pairs(row_table) do
            local part = k .. " = \"" .. v .. "\""
            table.insert(keyed_table, part)
        end ]]
        --row_table = keyed_table
        --table.insert(output, "[\"" .. cardname .. "\"] = { " .. table.concat(row_table, ", ") .. " },")
        output[cardname] = row_table
    end
--[[     table.insert(output, 1, "CARDLIST_LUATABLE = {")
    table.insert(output, "}")
    local result = table.concat(output, "\n") ]]
    return output
end

function cardlist_helper.parse_title(title)
    --Premiere
    if string.find(title,"Promo - ",1,true) ~= nil or string.find(title,"Premiere - ",1,true) ~= nil then
        title = string.gsub(title,"_","'")
        local s = string.reverse(string.sub(title,1,string.find(title,"%.png")-1))
        title = string.reverse(string.sub(s,1,string.find(s,"%s%-%s")-1))
    else
        --Resurrection
        if string.find(title,"%.png") ~= nil then
            title = string.sub(title,1,string.find(title,"%.png")-1)
        --Atmosphere
        elseif string.find(title,"%.jpg") ~= nil then
            local s = string.reverse(string.sub(title,1,string.find(title,"%.jpg")-1))
            title = string.reverse(string.sub(s,1,string.find(s,"%s%-%s")-1))
        end
    end
    return string.upper(title)
end


---Searches card in table by title and returns all the information found.
---@param table table Contains the list of cards, with information
---@param title string Title of the card
---@return table|nil
function cardlist_helper.search_card(table,title)
    title = cardlist_helper.parse_title(title)
    local cardinfo = table[title]
    if  cardinfo ~= nil then
        --print(title .. " found!")
        local result = {title = title}
        for key, value in pairs(cardinfo) do
            result[key] = value
        end
        return result
    end
    return nil
end


---From a list of elements it returns a list containing each element only once
---@param cardlist table A list, possibly containing elements multiple times
---@return table
function cardlist_helper.get_unique_elements(cardlist)
    local hash = {}
    local res = {}
    for _, v in ipairs(cardlist) do
        if not hash[v.title] then
            table.insert(res, v)
            hash[v.title] = true
        end
    end
    return res
end


return cardlist_helper