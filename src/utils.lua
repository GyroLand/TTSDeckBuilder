local utils = {}

---Helper function to dump tables into string for printing
---@param o table
---@return string
function utils.dump(o)
    if type(o) == 'table' then
        local s = ''
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. utils.dump(v) .. ', '
        end
        return '{ ' .. string.sub(s, 1, -3) .. ' } '
    else
        return tostring(o)
    end
end


---More sophisticated helper function to dump tables into string for printing
---@param tbl table
---@param indent integer
---@return string
function utils.tabledump(tbl, indent)
    if not indent then indent = 0 end
    local toprint = string.rep(" ", indent) .. "{\n"
    indent = indent + 2
    for k, v in pairs(tbl) do
        toprint = toprint .. string.rep(" ", indent)
        if (type(k) == "number") then
            toprint = toprint .. "[" .. k .. "] = "
        elseif (type(k) == "string") then
            toprint = toprint  .. k ..  "= "   
        end
        if (type(v) == "number") then
            toprint = toprint .. v .. ",\n"
        elseif (type(v) == "string") then
            toprint = toprint .. "\"" .. v .. "\",\n"
        elseif (type(v) == "table") then
            toprint = toprint .. utils.tabledump(v, indent + 2) .. ",\n"
        else
            toprint = toprint .. "\"" .. tostring(v) .. "\",\n"
        end
    end
    return toprint .. string.rep(" ", indent - 2) .. "}"
end

---Rotates a 2D vector based on Y-axis rotation (Euler angle)
---@param vec table Vector with x, y, z components (y is preserved)
---@param rotation_y number Y-axis rotation in degrees
---@return table Rotated vector
function utils.rotate_vector_2d(vec, rotation_y)
    local rad = math.rad(rotation_y)
    local cos_y = math.cos(rad)
    local sin_y = math.sin(rad)
    
    -- Rotate around Y axis (only affects X and Z)
    local x = vec.x * cos_y - vec.z * sin_y
    local z = - vec.x * sin_y + vec.z * cos_y
    
    return Vector(x, vec.y, z)
end

return utils