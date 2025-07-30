local apropos = {}

local function logToFile(message)
    -- local file = io.open("logfile.txt", "a")  -- Open the file in append mode
    -- if file then
    --     file:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. message .. "\n")  -- Write the log message with timestamp
    --     file:close()  -- Close the file
    -- else
    --     print("Error: Unable to open the log file.")
    -- end
end

-- an alias to logToFile method
local Debug = logToFile

local function printTable(table)
    -- for key, value in pairs(table) do
    --     logToFile(key .. " = " .. tostring(value))
    -- end
end

local function CheckIsJMap(mapId)
    return JMap:isEqualToTypeOf(mapId)
end

local Apropos2Util = {}

function Apropos2Util.QueryKey(aKey, bKey, cKey)
    local res = ".apropos2_" .. aKey
    if bKey ~= nil then
        res = res .. "." .. bKey
    end
    if cKey ~= nil then
        res = res .. "." .. cKey
    end
    return res
end

function Apropos2Util.StringArrayFromJMapKeys(mapId)
    if CheckIsJMap(mapId) == false then
        return {}
    end
    local allKeysArrayId = JMap.allKeys(mapId)
    return allKeysArrayId
end

local Apropos2DescriptionDb = {}
apropos.Apropos2DescriptionDb = Apropos2DescriptionDb

function Apropos2DescriptionDb.AllMapKeysAsStringArray(storageKey)
    local mapId = JValue.solvePath(JDB, Apropos2Util.QueryKey(storageKey))
    if CheckIsJMap(mapId) == false then
        Debug("Could not read storageKey or storageKey is not a map : " .. Apropos2Util.QueryKey(storageKey))
        return {}
    end
    return Apropos2Util.StringArrayFromJMapKeys(mapId)
end

function Apropos2DescriptionDb.AllSynonymTokenNames()
    return Apropos2DescriptionDb.AllMapKeysAsStringArray("synonyms")
end

function Apropos2DescriptionDb.RandomSynonym(tokenName)
    local arrayId = JValue.solvePath(JDB, Apropos2Util.QueryKey("synonyms", tokenName))
    if arrayId == nil then
        Debug("Could not find synonym array for " .. tokenName)
        return ""
    end

    local random = math.random(1, #arrayId)
    return arrayId[random]
end

function Apropos2DescriptionDb.replaceTokens(inputString, tokenDict)
    -- logToFile("apropos.replaceTokens begin")
    -- logToFile("inputString: " .. inputString)

    local result = inputString

    for token, value in pairs(tokenDict) do
        if result:find(token) then
            result = result:gsub(token, value)
            -- logToFile("token, value: " .. token .. " " .. value)
        end
    end

    -- logToFile("result: " .. result)
    -- logToFile("apropos.replaceTokens end")

    return result
end

local Apropos2Descriptions = {}
apropos.Apropos2Descriptions = Apropos2Descriptions

function Apropos2Descriptions.AddAllSynonymTokensToMap(jmap)
    local allSynonymTokenNames = Apropos2DescriptionDb.AllSynonymTokenNames()

    for i, token in ipairs(allSynonymTokenNames) do
        local randomSynonym = Apropos2DescriptionDb.RandomSynonym(token)
        jmap[token] = randomSynonym
    end
end

-- logToFile("Returning Apropos module:")
-- printTable(apropos)

return apropos
