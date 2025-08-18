BetterBlizzFrames = nil
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
--local anchorPoints = {"CENTER", "TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
local anchorPoints = {"CENTER", "TOP", "LEFT", "RIGHT", "BOTTOM"}
local anchorPoints2 = {"TOP", "LEFT", "RIGHT", "BOTTOM"}
local pixelsBetweenBoxes = 6
local pixelsOnFirstBox = -1
local sliderUnderBoxX = 12
local sliderUnderBoxY = -10
local sliderUnderBox = "12, -10"
local titleText = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: \n\n"
local playerClass = select(2, UnitClass("player"))
local playerClassResourceScale = "classResource" .. playerClass .. "Scale"

local LibDeflate = LibStub("LibDeflate")
local LibSerialize = LibStub("LibSerialize")

BBF.squareGreenGlow = "Interface\\AddOns\\BetterBlizzFrames\\media\\blizzTex\\newplayertutorial-drag-slotgreen.tga"

local checkBoxList = {}
local sliderList = {}

local function ConvertOldWhitelist(oldWhitelist)
    local optimizedWhitelist = {}
    for _, aura in ipairs(oldWhitelist) do
        local key = aura["id"] or string.lower(aura["name"])
        local flags = aura["flags"] or {}
        local entryColors = aura["entryColors"] or {}
        local textColors = entryColors["text"] or {}

        optimizedWhitelist[key] = {
            name = aura["name"] or nil,
            id = aura["id"] or nil,
            important = flags["important"] or nil,
            pandemic = flags["pandemic"] or nil,
            enlarged = flags["enlarged"] or nil,
            compacted = flags["compacted"] or nil,
            color = {textColors["r"] or 0, textColors["g"] or 1, textColors["b"] or 0, textColors["a"] or 1}
        }
    end
    return optimizedWhitelist
end

local function ConvertOldBlacklist(oldBlacklist)
    local optimizedBlacklist = {}
    for _, aura in ipairs(oldBlacklist) do
        local key = aura["id"] or string.lower(aura["name"])

        optimizedBlacklist[key] = {
            name = aura["name"] or nil,
            id = aura["id"] or nil,
            showMine = aura["showMine"] or nil,
        }
    end
    return optimizedBlacklist
end

local function ExportProfile(profileTable, dataType)
    -- Include a dataType in the table being serialized
    local wowVersion = GetBuildInfo()
    BetterBlizzFramesDB.exportVersion = "BBF: "..BBF.VersionNumber.." WoW: "..wowVersion

    local arenaOptiSaved = BetterBlizzFramesDB.arenaOptimizerSavedCVars
    local arenaOptiNoPrint = BetterBlizzFramesDB.arenaOptimizerDisablePrint

    BetterBlizzFramesDB.arenaOptimizerSavedCVars = nil
    BetterBlizzFramesDB.arenaOptimizerDisablePrint = nil

    local exportTable = {
        dataType = dataType,
        data = profileTable
    }
    local serialized = LibSerialize:Serialize(exportTable)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForPrint(compressed)

    BetterBlizzFramesDB.arenaOptimizerSavedCVars = arenaOptiSaved
    BetterBlizzFramesDB.arenaOptimizerDisablePrint = arenaOptiNoPrint

    return "!BBF" .. encoded .. "!BBF"
end

function BBF.ImportProfile(encodedString, expectedDataType)
    -- Check if the string starts and ends with !BBF
    if encodedString:sub(1, 4) == "!BBF" and encodedString:sub(-4) == "!BBF" then
        encodedString = encodedString:sub(5, -5) -- Remove both prefix and suffix
    elseif encodedString:sub(1, 4) == "!BBP" and encodedString:sub(-4) == "!BBP" then
        return nil, "This is a BetterBlizz|cffff4040Plates|r profile string, not a BetterBlizz|cff40ff40Frames|r one. Two different addons."
    else
        return nil, "Invalid format: Prefix or suffix not found."
    end

    -- Decode and decompress the data
    local compressed = LibDeflate:DecodeForPrint(encodedString)
    local serialized, decompressMsg = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
        return nil, "Error decompressing: " .. tostring(decompressMsg)
    end

    -- Deserialize the data
    local success, importTable = LibSerialize:Deserialize(serialized)
    if not success then
        return nil, "Error deserializing the data."
    end

    -- Function to check if the data is in the new format
    local function IsNewFormat(auraList)
        local consecutiveIndex = 1  -- Start with the first numeric index
        -- Loop through the table to inspect its structure
        for key, _ in pairs(auraList) do
            if type(key) == "number" then
                if key ~= consecutiveIndex then
                    return true
                end
                consecutiveIndex = consecutiveIndex + 1
            elseif type(key) == "string" then
                return true
            end
        end
        return false
    end

    -- Convert old format to the new format if necessary
    local function ConvertIfNeeded(subTable, expectedType)
        if expectedType == "auraBlacklist" and not IsNewFormat(subTable) then
            return ConvertOldBlacklist(subTable)
        elseif expectedType == "auraWhitelist" and not IsNewFormat(subTable) then
            return ConvertOldWhitelist(subTable)
        end
        return subTable -- Return as-is if no conversion is needed
    end

    -- Handling full profile import by checking and converting the relevant portion if needed
    if importTable.dataType == "fullProfile" then
        if importTable.data[expectedDataType] then
            -- Check the subtable and convert if necessary
            importTable.data[expectedDataType] = ConvertIfNeeded(importTable.data[expectedDataType], expectedDataType)
            return importTable.data[expectedDataType], nil
        else
            return importTable.data, nil
        end
    elseif importTable.dataType ~= expectedDataType then
        return nil, "Data type mismatch"
    end

    -- For normal imports, check if conversion is needed for auraWhitelist and auraBlacklist
    importTable.data = ConvertIfNeeded(importTable.data, expectedDataType)

    return importTable.data, nil
end


local function deepMergeTables(destination, source)
    for k, v in pairs(source) do
        if destination[k] == nil then
            if type(v) == "table" then
                destination[k] = {}
                deepMergeTables(destination[k], v)
            else
                destination[k] = v
            end
        end
    end
end




local function OpenColorOptions(entryColors, func)
    local colorData = entryColors or {0, 1, 0, 1}
    local r, g, b = colorData[1] or 1, colorData[2] or 1, colorData[3] or 1
    local a = colorData[4] or 1

    local function updateColors(newR, newG, newB, newA)
        entryColors[1] = newR
        entryColors[2] = newG
        entryColors[3] = newB
        entryColors[4] = newA or 1

        if func then
            func()
        end
    end

    local function swatchFunc()
        r, g, b = ColorPickerFrame:GetColorRGB()
        updateColors(r, g, b, a)
    end

    local function opacityFunc()
        a = ColorPickerFrame:GetColorAlpha()
        updateColors(r, g, b, a)
    end

    local function cancelFunc(previousValues)
        if previousValues then
            r, g, b, a = previousValues.r, previousValues.g, previousValues.b, previousValues.a
            updateColors(r, g, b, a)
        end
    end

    ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }

    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b, opacity = a, hasOpacity = true,
        swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
    })
end







local LSM = LibStub("LibSharedMedia-3.0")


local function CreateFontDropdown(name, parentFrame, defaultText, settingKey, toggleFunc, point, dropdownWidth, maxVisibleItems)
    maxVisibleItems = maxVisibleItems or 25  -- Default to 25 visible items if not provided

    -- Create container for label and dropdown
    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(dropdownWidth or 155, 50)

    -- Create and position label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall2")
    label:SetPoint("LEFT", container, "LEFT", -50, -12)
    label:SetText("Font")
    label:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 13)

    -- Create the dropdown button with the new dropdown template
    local dropdown = CreateFrame("DropdownButton", nil, parentFrame, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    dropdown:SetWidth(dropdownWidth or 155)
    dropdown:SetDefaultText(BetterBlizzFramesDB[settingKey] or defaultText)
    dropdown.Background:SetVertexColor(0.9,0.9,0.9)
    dropdown.Arrow:SetVertexColor(0.9,0.9,0.9)

    -- Custom font display for the selected font
    -- dropdown.customFontText = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- dropdown.customFontText:SetPoint("LEFT", dropdown, "LEFT", 8, 0)
    -- dropdown.customFontText:SetText(BetterBlizzFramesDB[settingKey] or defaultText)
    -- dropdown.customFontText:SetTextColor(1,1,1)
    -- local initialFont = LSM:Fetch(LSM.MediaType.FONT, BetterBlizzFramesDB[settingKey] or "")
    -- if initialFont then
    --     dropdown.customFontText:SetFont(initialFont, 12)
    -- end

    -- Initialize a unique font pool for this dropdown
    dropdown.fontPool = {}

    -- Fetch and sort fonts
    C_Timer.After(1, function()
        local fonts = LSM:HashTable(LSM.MediaType.FONT)
        local sortedFonts = {}
        for fontName in pairs(fonts) do
            table.insert(sortedFonts, fontName)
        end
        table.sort(sortedFonts)

        -- Define the generator function for the dropdown menu
        local function GeneratorFunction(owner, rootDescription)
            local itemHeight = 20  -- Each item's height
            local maxScrollExtent = maxVisibleItems * itemHeight
            rootDescription:SetScrollMode(maxScrollExtent)

            for index, fontName in ipairs(sortedFonts) do
                local fontPath = fonts[fontName]

                -- Create each item as a button with the custom font
                local button = rootDescription:CreateButton("                                                  ", function()
                    BetterBlizzFramesDB[settingKey] = fontName
                    -- dropdown.customFontText:SetText(fontName)
                    -- dropdown.customFontText:SetFont(fontPath, 12)
                    dropdown:SetDefaultText(BetterBlizzFramesDB[settingKey] or defaultText)
                    toggleFunc(fontPath)
                end)

                -- Use the pooled font string for each button
                button:AddInitializer(function(button)
                    local fontDisplay = dropdown.fontPool[index]
                    if not fontDisplay then
                        fontDisplay = dropdown:CreateFontString(nil, "BACKGROUND")
                        dropdown.fontPool[index] = fontDisplay
                    end

                    -- Attach the font display to the button and set the font
                    fontDisplay:SetParent(button)
                    fontDisplay:SetPoint("LEFT", button, "LEFT", 5, 0)
                    fontDisplay:SetFont(fontPath, 12)
                    fontDisplay:SetText(fontName)
                    fontDisplay:Show()
                end)
            end
        end

        -- Hide any unused font strings when the menu is closed
        hooksecurefunc(dropdown, "OnMenuClosed", function()
            for _, fontDisplay in pairs(dropdown.fontPool) do
                fontDisplay:Hide()
            end
        end)

        -- Set up the dropdown menu with the generator function
        dropdown:SetupMenu(GeneratorFunction)
    end)

    -- Position the container on the specified anchor point
    container:SetPoint("TOPLEFT", point.anchorFrame, "TOPLEFT", point.x, point.y)

    return dropdown, container
end

local function CreateTextureDropdown(name, parentFrame, labelText, settingKey, toggleFunc, point, dropdownWidth, maxVisibleItems)
    maxVisibleItems = maxVisibleItems or 25  -- Default to 25 visible items if not provided

    -- Create container for label and dropdown
    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(dropdownWidth or 155, 50)

    -- -- Create and position label
    -- local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- label:SetPoint("BOTTOMLEFT", container, "TOPLEFT", 0, 2)
    -- label:SetText(labelText)

    -- Create the dropdown button with the new dropdown template
    local dropdown = CreateFrame("DropdownButton", nil, parentFrame, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    dropdown:SetWidth(dropdownWidth or 155)
    dropdown:SetDefaultText(BetterBlizzFramesDB[settingKey] or "Select texture")
    dropdown.Background:SetVertexColor(0.9,0.9,0.9)
    dropdown.Arrow:SetVertexColor(0.9,0.9,0.9)

    -- Initialize a unique texture pool for this dropdown
    dropdown.texturePool = {}

    -- Fetch and sort textures
    C_Timer.After(1, function()
        local textures = LSM:HashTable(LSM.MediaType.STATUSBAR)
        local sortedTextures = {}
        for textureName in pairs(textures) do
            table.insert(sortedTextures, textureName)
        end
        table.sort(sortedTextures)

        -- Get class colors table
        local classColors = RAID_CLASS_COLORS
        local classKeys = {}
        for class in pairs(classColors) do
            table.insert(classKeys, class)
        end

        -- Define the generator function for the dropdown menu
        local function GeneratorFunction(owner, rootDescription)
            local itemHeight = 20  -- Each item's height
            local maxScrollExtent = maxVisibleItems * itemHeight
            rootDescription:SetScrollMode(maxScrollExtent)

            for index, textureName in ipairs(sortedTextures) do
                local texturePath = textures[textureName]

                -- Create each item as a button with the background texture
                local button = rootDescription:CreateButton(textureName, function()
                    BetterBlizzFramesDB[settingKey] = textureName
                    dropdown:SetDefaultText(textureName)
                    toggleFunc(texturePath)
                end)

                -- Use the pooled texture for the background on each button
                button:AddInitializer(function(button)
                    local textureBackground = dropdown.texturePool[index]
                    if not textureBackground then
                        textureBackground = dropdown:CreateTexture(nil, "BACKGROUND")
                        dropdown.texturePool[index] = textureBackground
                    end

                    -- Attach the background to the button and set the texture
                    textureBackground:SetParent(button)
                    textureBackground:SetAllPoints(button)
                    textureBackground:SetTexture(texturePath)

                    -- Pick a random class color and apply it
                    local randomClass = classKeys[math.random(#classKeys)]
                    local color = classColors[randomClass]
                    textureBackground:SetVertexColor(color.r, color.g, color.b)

                    textureBackground:Show()
                end)
            end
        end

        hooksecurefunc(dropdown, "OnMenuClosed", function()
            for _, texture in pairs(dropdown.texturePool) do
                texture:Hide()
            end
        end)

        dropdown:SetupMenu(GeneratorFunction)
    end)

    container:SetPoint("TOPLEFT", point.anchorFrame, "TOPLEFT", point.x, point.y)

    return dropdown, container
end

local function CreateSimpleDropdown(name, parentFrame, labelText, settingKey, optionsTable, toggleFunc, point, dropdownWidth)
    dropdownWidth = dropdownWidth or 155  -- Default dropdown width if not provided

    -- Create container for label and dropdown
    local container = CreateFrame("Frame", nil, parentFrame)
    container:SetSize(dropdownWidth, 50)

    -- Create the dropdown button with the new dropdown template
    local dropdown = CreateFrame("DropdownButton", nil, parentFrame, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
    dropdown:SetWidth(dropdownWidth)
    dropdown:SetDefaultText(BetterBlizzFramesDB[settingKey] or ("Select "..labelText))
    dropdown.Background:SetVertexColor(0.9, 0.9, 0.9)
    dropdown.Arrow:SetVertexColor(0.9, 0.9, 0.9)

    -- Create and position label
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall2")
    label:SetPoint("LEFT", container, "LEFT", -50, -12)
    label:SetText(labelText)
    label:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 13)
    dropdown.LabelText = label

    -- Define the generator function for the dropdown menu
    local function GeneratorFunction(owner, rootDescription)
        local itemHeight = 20  -- Each item's height
        local maxScrollExtent = math.min(#optionsTable, 25) * itemHeight
        rootDescription:SetScrollMode(maxScrollExtent)

        for _, option in ipairs(optionsTable) do
            -- Create each item as a button
            local button = rootDescription:CreateButton(option, function()
                BetterBlizzFramesDB[settingKey] = option
                dropdown:SetDefaultText(option)
                if toggleFunc then
                    toggleFunc(option)
                end
            end)

            -- Add the text initializer for the button
            button:AddInitializer(function(button)
                --button.Text:SetText(option) -- 11.1 error
            end)
        end
    end

    -- Reset dropdown contents when closed
    hooksecurefunc(dropdown, "OnMenuClosed", function()
        dropdown:SetDefaultText(BetterBlizzFramesDB[settingKey] or ("Select "..labelText))
    end)

    dropdown:SetupMenu(GeneratorFunction)
    container:SetPoint("TOPLEFT", point.anchorFrame, "TOPLEFT", point.x, point.y)

    return dropdown, container
end



















StaticPopupDialogs["BBF_CONFIRM_RELOAD"] = {
    text = titleText.."This requires a reload. Reload now?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        BetterBlizzFramesDB.reopenOptions = true
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs["BBF_TOT_MESSAGE"] = {
    text = titleText.."The default Blizzard code to \"wrap auras\" around the target of target frame is stupid.\n\nThe \"Target of Target\" frames have been moved 31 pixels to the right to make more space for auras.\nYou can change this at any time.\n\nDo you want to keep this? (pick yes)",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end,
    OnCancel = function()
        BetterBlizzFramesDB.targetToTXPos = 0
        BBF.targetToTXPos:SetValue(0)
        BetterBlizzFramesDB.focusToTXPos = 0
        BBF.focusToTXPos:SetValue(0)
        BBF.MoveToTFrames()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs["BBF_CONFIRM_PROFILE"] = {
    text = "",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
        if self.data and self.data.func then
            self.data.func()
        end
    end,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs["BBF_CONFIRM_PVP_WHITELIST"] = {
    text = titleText.."This will import a color coded PvP whitelist tailored by me.\nIt will only add auras you don't already have in your whitelist.\n\nAre you sure you want to continue?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        local importString = "!BBFnQ1FSXr1DE2D8UElrxVetGmusWZDIEHiLtqPNJQao7S76FLw7elVoBiOwD5T7(2Dh8SZSm)y9TMC0MuQevkrjkfvrqhKFueuKOQb6PqnqsOrPbsqu26R6sc6sGyXDLRLlbzku(dk(((9nZB2NJND89x278((99EF)1NV)yMi)DPkqSjp65KJFpxjBkDsf6loszIfvjtz1I27KQRrmlrlST)w1cij7tTsvdtBIU92gnVHMH53mIuej71LTr0xe4GQvqzlenTgTHmyVUgX2wJ4FtPb75)QRUw)1DDx3G9CLU7EBW)ijh)p)1bMQUSK5Sm0CSHdKAs1vTR7YlUUl34bi3XH(yK6Byt1OMvnMaiTGskIPPk1eO3JkGEKtGwzPHxI7UxJQxsvVKsAthlsbo1bDJ84g4uo2R(Ia3ZoIPAfdZcQenqOQr9UyWI(I17T0LQa8cxWOjRdSSVnOBtnHZKtm84MsrIBzL4L6gtPrTSWlLrrLmK8MQfvZtxSlgWCIh8k97Tv4dEWRWoqD4aj2i)YTT9pboGt2RAnvDqHAtPf8UhWk87HKKC73txO8LupVkv3gVgdzysxGIeiR3Km1U4nUFtyBnQWPwYJ6EtM4QposChzCmRPwduABq3YwvpVT1IkBx9XLJS3Nc5(w3GEEIPoXw1q)UvgWHG6FD8C3SPLrE)DYxZ7Dxb2LL2LbSf5gRSHPULNGdpleNW27CmGJd3RHrfLTOQxWQL7pqPCSZVk0ppDztdDdqLzuL7sC(vj4Rg5d(uGSzgZWjFz8I)TiMviEucRfY1jYE3dQd6CE6GKG1LyIBusRYKkeFFlG6aCeJCSDIIusR8u9ce98(uFSDUqQt8OhepWLUrQDzQPLTHzfL(1iLUwxbGozPCVcqBJ)AUIn3Ri4rjTKmmRxMQMusb0tzSYuLTarp3TYiMg208OWWzDjzcrje9d3hdnbVmJtPvzXSSyPpCFbiVXt9PmriPUT6F)WKsQ5bOlkhccxwW0eBhFgZFoTbgxdAyagjPLfXrZMBk3XNfWHi197XoeuOsrjw2G3IDzvFbQ73ZLPb75)9V8fipa3Nz)7)eZn3Csj2(Uq3bFKOTysSl3k)mGy5ixylyu8MmZHg9rq0oUn8cBHFoF4N)xuy6Tt0zN9m3CFHeA5)(Ob6MBDmYX((YX(xEugebyMqtTAPY2liUhOro6n)SOeFtmZWAv6JyAxETke9ck9RA6JUDZpBa(un(ag07OgUETIiCOe24dclc4DpaW809QwSOdKeIzp5c)7EGqyuk3XMV35Xe8oJ(PNbwCNznulueeNwQGa6KB7DVu)meZ39sCTcimdsbfakn2OBTQgIRkh7NnccJUPQGtVl8ikZChPF2iIoExCB417g5lEXTfKx2TUbmhskndJcAow2T8Ecekh93JGDhoTrLCaPUbxTqQ(9gYXUWx1nkjNrfvxKfLHuRKRLmbmihtPt(LUfeP0PC026MH6VrITJjD1wkzMakCqhuiCNK26wqre)kVnUNk8WZR82bIH9iCpzx)2hjiTvUtWT4neteHlih)xvebrgMOrRzOr1fYVETcbq6JDeCNwJ7X9yhjOdt5Ym93iGLg3n0vyyiHrRnrkxwUJFm6FCyM9eWw9bUHNhWre7OdJ4eJcfpmb6lLsJmPFnhhD4q89J)rOoT6kgcu6utLwHe(rVTGDOTNBROmVCVfHF26diXwX6w2juV14wJZb9GhgchVWdJEYBauuG0NFCpwEHhw4giDxOwF67NQR0VrEhlLXO8SKWsIXohDi8QEN(6IHcdhyjYiX)v8DAjYEehzWE(LYYRNruS35G93InaPo6jzWDkUf0YoZ35Ga4ltJ934BYp3kwHle8bDTH(WSxyRjUZFPR8xxjlvLxmc80GCTw6pcTE3WOKsuoctgnXeFafbWx8x)vyi5uiDIs6Yyz6Cl9RlMAUT1ThrKr4Nclg5vpnE4lFaiFau5kuYwnvl1CQAnlehijmFVd(tybg9cx4YqEuOq76w2enFT0j7OdxT0mMMFpbTeWiyN7aDS6fCSeamGNgYb226278fN9kios)JdGH9ULZafTBYR)fwqWJkYfFgKSEjvQcEFdsyPeyY6fFMqo6iV1n5kRQuLC1Dnuty4FgWYHPOEQPzNjONusHA7YCR1tnDqw35IVo2QZfNHBJLZzHO23EAtv7145r)VT8LR452)vyOWBwZwTcb7MA(zDrceuarFVnl0jb(ta5jtvOkntOU9mEvfK47uLjVWcAAkJslQjwghSQyq6K7gX6YuXyCiM3WpZstyzGc5yNgtdwDzB0rttTyDeMldunTdxfcRlIqSeSNQzy9XGrgda9BwFHW9lPUSupRhOmvknh)yMEwFyOeXVo0XdXN6pScca6GW57Jh37gDFFUB8G9C5LTmVA9o1J9yhKz2ARef34XmDOwLnADgCGo5y)5FnkEO3VIV9TLCaud1zoi6dbvqcvFInApoxA7EqXOG1mfUXBwVSHwDH6BBHmUMPsmfcfBokPkMd3Z8o1rcrbgn2mOH8wa8c0GVrvNjjgRLfsa5TYpUYM(NBSyDAd7HS0k(CxxmEpJJraxS8(qbR4Zd7s8BZYqo9g8a4HKfQXMs0x8UPrELJvy1O6CekjpDck0HVFTBfwDt3WetHP(pCVQwaISvt3)PUCixTy76(erPGFkyFI(72iICNPmPGXek9scR6eGwzPBehhXHHoiGAqfqRGNh2vW6(XRqp8RG19hemt3VfquUuoMMgtWbK6(TcBB)r3fE5tAMNGZyWPzAhyLabYA3diRDeGQzFPk3(GqJu01WJ2J)4)dIysWprKcM2PzH3SkUKJEUxGz4tAHqw8v7JusZVZKZ9cbCxImk2Hu1BwCSc8HG8TaWiUBhqxR1ajgmn2Ga8hKMOZKc8kOMJd5BWm4ncUjq54R5PziFEZMzb9edRhwYJ4XrLo2Aoafte5lE8fkOjw(tIXZ9vJmpiLwn9LL)KaQ2qZhKBiU)QiQ59(FGe17cG2HfKJFM(Wfxf)EDM(eqYJSNtZWBnn0ZbWD8tzpHvzrhpXpm78vVUnx1cnS3vb4swAM2fd(GFke8fxhlZwit5i4uhPnhucqqyU)x2G1Ei8xM5Vr6wrPuxy1)x70(0ZBdoF8ARaAc5SI804CvZ5oaiUo7Pxxa276SXAS00AgKXzNddAzXN7w9pdA2)PD5La54NFdUbJibmihDU3erKCRZAIM5HGNly1LMjX8TdjeSdr(vFgtrc)9AphOmcNCq1OfDyylYrBSw8kU8(0nb))cqLiLGMKmj2))W5gzwoY2Fjm8zuqeR7omy)IB3(lfsK()(BaSn9WimLj0zBA)jBdRiiksDvlBZXU2pPMHFviDvtqFe7p9pH5Bsz4GyAPi8(IWfc5wC808aRgIJPbEUCStIfqFsOR08gLa34M4cWkIN8LMa3JVdFXlnraorRgHaMHnVjOpGIoc56w9qbGMgB2ddmSVm6gtuaQ1S1vyaeklDECEsnK5kMZh0KJoEj0RYTJMrGcb8o9JxkKGePupaElgel1rSG)upGi(ZB8GOMFi1IuL0g5n8vtWcHT3ZC9Z3b(6fbsYCYSE1qM2qJFUWtdzdJM)SOeoi00avyqRyP8)RRCLRxmVF(Zkh5z)EOOXkqSP6aFCihr8tDb8oZhnn8ZWiUDSzQd3xoOXIH9Q6NXv77nadU0KylmtZF9cSQU4QMjNU1hJ94SOpA(XrOWMD6zpEqhYmFP5RZ)sc68y7gNL6SBkNLkl)DM8eyl5E17ExHefTD0nz2KGIhs23lTiufYI)2GaUs8Xe8(8aE(IFmrmWFsmrZHHkElqzdp3xB0Easw0l(lyWjuBsfdZQLnSu9Nr2f)fbfGTRVmWqUrX5b53H0U(YTwiF)EqCYBsmJZ1wOX73ty(7RCwCdKNxklS5VjW6L0lXfVvoBy(uF4ZlAaHFkAavXQhnhqtTsvl)chvVlrSQpbL6QRCEVeK0G2IYQxRpnh9wxUmWSCS)WxJjfzmC0Y5ycC3lTIHUAEL0QM59lreiR5flXooAw289iQGxLJ3eD9X)2XrdrGJCOxhLjVcv4bPh61dY5E3sio0OK6OOmOrv)2Z3TuyQ05wPxn0ReRHuSg6SWP6xcD08y18tNeAUMTAteMb75SpXt8AWDyWE(Jp0dDqCxBI08wjof(U3A8iEs7PEQG8Ep3(rn0YNFn3J5yAlu09(dviw16Cx7Qh4aVMRrJvdV)KnCt0wFnUI6QKJ0dMxT6n4MsY9Lj18L(Y0Y9ulmdZEX3UvJDWjEVhmGCo1)ISS3PhK0rP3MJLbEEi7CSVX)ng4NudNz2yQvw8(nbosmekotNcGkyVszZMh2q1csJx)841F7CTB9ZVqIUTBhjzIf74VTBh8WAdj9h47W1wyAU357IxvVouDX3AzmhqSCSNBPOPAz9vbQld6fpTrLko6cLJ8ClnSJ7zUkMHiPL74Nk7wmbBVFMRgcM(RIDimlZQbLNLSqTMVVtynbyN4tItiFFzifPLCAwKa84WmY9YEBSDmai(QeaEhoJ(QKtJYH5bccH92gFcMkHvZVArvOW1bmHs)8FL8JpHaQN0zrqe3VFanxCHgIv7HeilLgFNp7lLrH6CXiCVoGHBJ9oC(2Uh6T1zyY7SJYqzG)IrD4ap0i5PvWeMPOK8GXK3Q(VbFBVnEiUA83KjOSxNM92SWOdLm2nFx5NEdIG9N6smuLmvvnvTXojyvANKwYp3iqstgs8g4aENDevOlyt3VgbJw)IYaQtS17gpGBSFtQ(KQlS5bKQTE3H4J11rzD73fldauarbyJiAybqJ6yvEba8)WZH5c8(AtAzidqMCK38NJipcP54(8V5ppK7Z94MOklPcQYYJEKMKfFGxaFYr6Qyqk7b84ND2Dvmmpelm790mtAVQZBoeWsHCPNQbdiVVkSVDhqZbQVTqjvB98obwE)7f18V)9Yu8n6QvxkPB4qz5VYgOeHMF(r4kHjmNcNRxJ167MDzb)YiNFs0pRFdtBV5uNYKYhqgSyi7B0VXfZY(4A8FlC3FZx9hSyiQPoXYVM1fLG9nua1U5b2aRfMS8tpdZWafk6)nZWLRF6zcJX)Zc4r2CilzkB44fpfYuwa2KB76rKLQRWF0TELe0VQTnviMSvyta)joc(AcNHL8fLxX8Vh5HddB9c)pSegoMefVQgwaGjqJCSPUJSyhLMKsgSHhWvktDhbGyfpHc6ruJdRLqzHeL4e7HHhCcg0F09nKA(Y5mm1B1G)sCC3pkkOnXCOzvH5sz7uGNN64pEiYPuUJNvSzOChVHFsTeV8ZZ8w4ZY0nQ2BxF5NpmT3F87Ya6H)ckXXalo05hOejA(U)7VpgkZM1PUEIJsTm0QTOOmiJ7e)GchREv60eW8SLYQ2unvl7)Vd!BBF"
        local profileData, errorMessage = BBF.ImportProfile(importString, "auraWhitelist")
        if errorMessage then
            print("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames: Error importing whitelist:", errorMessage)
            return
        end
        deepMergeTables(BetterBlizzFramesDB.auraWhitelist, profileData)
        BBF.auraWhitelistRefresh()
        Settings.OpenToCategory(BBF.aurasSubCategory)
    end,
    timeout = 0,
    whileDead = true,
}

StaticPopupDialogs["BBF_CONFIRM_PVP_BLACKLIST"] = {
    text = titleText.."This will import a large PvP blacklist focused on removing trash buffs, created by me.\nIt will only add auras you don't already have in your blacklist.\n\nAre you sure you want to continue?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        local importString = "!BBF11xcysr5z(70h1mOGccinxXwnrCtcM1K11igJo3mWmW4mat0eDtnDxtpLt1v1wDxZqZAwdKvtIU5snhAIXDnBUmRMOHaRAmrqmXK1SPxatWdubeburCaeq8G))EpQQ7bZ)8KNNxD6V6749(67Z6o7MYAwY8RhFQPsEx3Y)4zANLGn5AM3AJTwSOLBgR0nf4xS0QkoO3iDz7A9zByn38zJXbqLyfMs3w(f9CnDSxHv209zzwAql)ugRzX8ubyLyRVhpVsPxKvPr88hQsIpBkJrBu(1rBeZWKwM9WMzSlvoT3aPBZ3RyjzmnPJPPJFmDANBqEmjw9g5XayLyRQplhN0TzLL)67Rx5RVVEX636YZyvSyTZDl6C3Y7z998ZyXJzn6mSgmdfo1El5BwYkNDM0D4oqqrBpxEd8N)tYg4p)NWGMyt4iAz5MgOG0Tw2QinKK393wqQ393gd50A1XkVLBjtN0npOPxX5LUvt)sdYdCF3GmW9DdvIT)EmxHNp2XM5OHZZu9jeSgG0UUf8H2U5sp)aFF7mMU8Uo(SNhpgabgPPahNIwL1ZZs1ZZsReRY4XFQHvDc0Fbam0M98l45B6WdDLzKHUYmyHMwh5S9nNtX0n7hy5KEreYpVPVLC4Un9WDB)npCvX4pFNYu(8Dsl2G2P7ZCyzF92TE28V82Twj2D1JvXGcfCSTa31Timz3c2UjtzStDc2jMGkJJ)YDR)PD3jrH6ZUywV8enKq)9z6iNLD2L(DDf9D7Cr6FArH)PeN97k0XZ(DXunJUmbHgNIoCl5Z060TyMVGLRLpFOxXDZ7yazod7CUHRANGdXZnLrFfLZuFfjjKwDZywOyGdyGYMUfRIGSvoLXv6l7IR0NOM9yMZI5)k7phtmsMLW4K(IYyoPVi4IBlWNzr)ubweZxdZ6byY3SEGkXU5M9wr50TzlufJDEz6b8YIoZN0xsNPVe(tZI)tp(Ll)Ph)YjE3U8Y5BcPBqO7ku(Y4BoGmKV5a0q6Zgcy6jTfZryjaJ)YYKH8xwg2InHdN3ircOnSMBvOH3ktdJDO)apwabtWY8SZoGNFEEw(dFAzw(dFAcH1ybpG(lxOee3A2Z9AcSeUOKh5RlSBh5RJHn1(8nluaO0Lwauks1ZWqEGh3MVDzCB(2ReB7T5BzTcssPpB3SSKKXlRB6xgB6T37GMzXMU1897BQY(N0xvXwFvSoNzJoedz6(8TlwkxGPFwcj0Sx(cMUGAxCq7c8h906z4PXzy)qpso8nlXYLvTWdylFgzaB5ZqyZEla9vdasw6ElavM8cx)ee1MaI5yjwqYUFhR0lZUiypy57owRiF3XAReZV3bdgyahzl)19ewUVUhM8P3NPF)MUzt3feh98XgPtRHTCasivYN6oeCZtDheoShlhmehs9yharBx0gJNMWypVOBfqqybvOOvgOcuv8zK6RklxkcdnTgl5LNKyCkNUhlaT7N0wIf5X(bYI9y)aAXQQFOvSu0OSde6VHy5bqsyO9b9cCSlo4y01MChFpzU2X3J010MnzZPu55LUjhZmdLUBVrYkYNXoGiFdyLy3F7(cEWXsWtR3swP1BrReX0y5dE(LeuYYrrYj3HII2bHIMs1vQ1HTlMXIoAcx2)HYL9Fanxn75KL035ksoB9FswMT(pbPtIvFqlOVw2bdiOU1paFwj1kMoyl09GqW3D5PmEuvQ7rPbmTwlwYcOTSILcyDbmQapkN0fRNuYk7sG(50nHLrLcmwFo9OMdC5lZEf28jTxZHhUSCmVt9yEN0gP6XSNGcLcugYeFkEZcyLyBS1LxWRi2jTH95qPm(t6(8pXheigvQKfXRPUnqkaEkw7laehp0pvSeuoybCTRPIO(jfKj5NuGMKUmbJylGl0fgBdr0g3qzzm3qzW03bWxLSn5Z)fCcY5)cGjS7VjhpVSG5cSQ8wFCI(naPfVtGvSiudH)GllS00SAxKMMv70PdNER0DB5gU3IpRFV(Z)Em9m6Fei9BjsaN)xt2uN)xJvzL1eQRggcZL8CTkczaX8FIF(O8WaKiMqOpd8KWHqHfhI0Ja(wHTn(z97Kv7S(DyZ0eMfyffACdPMfxPW2uCLKDs7SwPBeh1CPIT5NwqcB(PjZrWTGHY7btwK1GragKNCJVPIc)MafUX2DSmZtOIEmllkeZCdYKN5g45Wh)EXaObl98TCkaSfyaUkbBM4QGMPUS8ZyZknasFefx2HIS6atXK72NSZbRHbfhdk9i3SmQJaFh3igug7IaNnON4IJXRQSuV6aSHtiB2FGVlTv7iNRDO2NeZCM82fqyiPvxORG02ySdB5R3HnOxnMjJJz(inwXpYTORmuX0)Y8CCSePGN6EePGN6EGuslww44cRB5YP8i1FIMYb)enjnU2zMdyG496ZLxwTNlpPBBjJydCUjTtDlc3gICBZyTJiJBTJqCan7xUiysbzf(iMVar9PHYl147xwQX3FKJjd3GW(mCdmcrSrr8nnnc4ZnZN1MxJTR7LTt7LtTzhOeq8NT7aFsMLpPVYptoPVYpJgute9JWSyu9rYB(YcooDbhhj1uZc2T5CgkGhYQpQmKvF0WTz9tiRSZNqwWDmFsvx50JXF8B66Ln4nD9KYBq4Z7j0tAQbgl0LJ6NGLotq)CLpT8T3G(TeZ5upUVTxph1QD9tya9thi6tN0ps4RN0pIDyWtSDBMg)tLgSmKGCk3WwFn6ZaaAQBXQeeqdT4CF)wbHDF)wcxmFtFysckNYyxGiFyinS4pc)Tl(Ja(WfeKnxiP04NTszp)ZG06254NgJWEIfmdHdEbZGMAYddtkslyNTKVNtkJdOQfpaulEZ9woF)2EfTz(P6U4Fn)tacU8EdYcfsPBXZtyk3R6v5EzVk7na8AyRMfRm05Mr8d5s((YyUKVpT2KcJbGKIvTkgpYTPcl3wOI1IwwdP7DJ5k0FJ5sEgaDj(zmjNAj9un87xnJr(9RgmcluuFLUlZmdkiSugpZYLf)zwoVbpoNGejMVZxwgZ35ltmQDpOTj73jzGlIrj5oxJqC25AG(WETSy9zc3wDB47kOOn8DbDPltxt4igBXi5SEz5RM1ldTaWZq3vi4KxEeHr5LjH0P0BPaGvzswVWfl2UrkJ)8)IST(Z)lGMCfaR3DGJiAzCKsYNFKsG1B(PmA8UKH24Db0q3(25jv(qsk0UAY39xk7J39xsYdseOKUs8pzpaCLkIhC7c1gqwO1Kd2lReRGPTgNWDO(REhK3yNwpKDmARdwQsJz2sCjNTq6UKZgSLiinOZQhlZio(4)d)VcD)F4)f77g9PWkXYKh(Qzk2rUvr)nGKw(odCn9t3yEipu7YySkjMxajXokQaC6TTG73Phb750DlUmhFcIjAaRWHpBMreQxMTFPabrD4hso)h(HWoI4vHxyqllCMTiZXNC3Qq6UHq6DrMvhSGNTifMCJpM8BB8XOJdKSkmicPOBp7I6g9c(VKn6f8FrK9UqacGr0EiR5r6KG79IN7j3SopB(Xc14LCRpQ8N26JIVC6iWpZmLddoId7fkvlLHjpX26lXJfqSnA2hBrjej3qB7V0QKTXlTkIxUamU7hA3VUz3aZAbijWWMmbJcCKRh7(7Nc281vvnVou1SQEmZYAsirXBHD(gay4cUL7hyl6MQ)HfM16FyiCZsh9wG5Wt(tEs5q9tEsWE0PLzbsOQns5GiygtW1asu)EZW(jeEQjVCPrv)4)C8Oamk8tRFSSKw)yYiRV6(bhqwkJBxIwdqmRZQfw9EM0n6xAEP7YJsNehVfLrb6u9z(k8P6Z8viwl4TLFEIGXo26mCely9tqewbmYyGXJiRJXJqKSfANziEV3gCHH1s5rAVLassE0niyIJUbIZeIUUuWO1oeJSsAaaeUY07i2duIS2weyzSQRux9vgT6R)wLvF93krhBgbKaDMuQs8CZQuMK74jKmlSJNGLJrmBMSc0w8nZ55IZyRLTsz06QLfU1vt4Rfzns6fzdLuUPxK3C71f)J2UZj9siKykJrVrzSJEJySV)qB(r0SMqalRWsN)bCiMsGFEmfp9yeEQn4C1)FXtgFtvr338UiRNMJ46eL8GR6xi)0v9lOddChdhzkcsmfqZu2CquvD67Rid8v)kSVbqDu42lmraQw29QdCV0aN8ImjTPuGt(E1y1or7xGOJR9lG57Z6f0V4AXPi(GaiSBXCoPRAbO(XFdkx7nejJFFBvycUVTckm5KswwhDhIo847w8Ncqih1Ph0kNfUhioJKOTlu2fTDHGJFHEd7bnxleQfGJHSy9n93Z)oGyxoFZa4aMk98L09Xxks6j2)Jk29)WgNCmdaowcMP3s(G7xWJN4Fug2j(hXWMDFsKGP711BK0TdpcHn2axgRRzMC3BsoE7EtSzwY3K0lgUCpYGwo5dv)4UCr9JlzVEITB74AzwKKgHyh0(K8N(IYK8tFr87ZOQTAlOfl9YG)eGI7eMbKxwLbEzsg40uNDC0SI5herdnEO)DzGp0)ojSSuxFonf8XX2sIs34GQPOdsHs0dD(wcuSuuTWgBxSBDeKsmfLBR0CMGKpEvkZ5QiMZuVxlul1ptjpbTEyDtFyAtp52rC(wU5OuHfknXitNdl4bNdJLRZaG)quGAyWW6TeJgG0bVd3SWls4vac5gMQB203vt9qIziPReqoDAWVQ0KhwAUsJTjLrytuGW5lyvkq2JX1FiotkjI4aQ0ARiC5CIvSn(cYMyJVaHufR2LPXuJbXlsccfqIC3dzPLsAqB0XrLcV9FUmKB)NJHagEZ(9CGUr41rGPZFlv2Ps(gpLSYVXtXAu89YNMmLtZjLinRIvZPVXTRuMBNOmt)9m9DBxkDNWpEm2gEHjtdfGqjL6w(hxKQw(hNiRle6okniL7AvadFzMHS0CBkEGbiW0D5jrz2Bj1pNN4hj)6tGah2Fh5jYj8he2MSvSWBkUyciXveQtKo2GxUGPTmnBxsreGCkyaBdmKKUptXZGgUxjd837jWgz4muiQARwPcjhnac9RlE50gu5Pm2NkJSV)DM)NS7dMyVmclrYv)6coF1VoPnOJmuqaHsNn757huOKKcavC6buY6d8Zjxy5)0j8CYF6eEoYwlmsKrSmhWX5un06PE184aK0baxTj39RAKPlpxWhB5lCHx8efBCx8eLCAZQuB3CfwnKEMm2infuFBo2fsV4abje75v2(NhUhXrJKX3ueKtEWDihZdUdGHBSiLGSMnra2Lve4h4VkF7h4Vsm9DKZ1IwV5d2T0lb(zXcDF6ficDF6fqPdMZ7rTbRzSRFSmh76ht0PoChMZQkyRApWws)ASHonrBZqNg5bN5aq3ly6eR637HKT49Eis4S3mM(owLsZzmQQF(BAVYG20Eb1SlZC5nzLS9RBHp4we74FWTa(X299cipvhYMymrKj346Kn4nUoYabcufUqf5nkgTQ(4wu33Uf4(2gfNu7QkLj(1kkraKIzLYQQxqjs(SFpElU(dkBX1FqApeMJ2AcI6wuhSULhHiTuuD1m9gBy1YVUHvtHn6tHwuLBo5o0Z)o2lHJBIZ6qBE(PHwo4qapKJShzihzpSih5So8nT8X5R(EFvzu79vd5JtUEv386HU57VnlAlLpuFt8n0SCQ3qZuOUM(9dbfkHuYEET6EETucwTH8zn756k8UITXcuvJo1L6MLslwPY1yDCJkkBJhKgrt(cbtmX0P9aYr)n0D8B8QKd8dAwOOxwbLDvso4beeSffKVF6JbLPOU1Br36TGJ6)h)fVR4tcGSRcC41mHosQK35x7Nq25x7NaKAIloB1nD8n0QoTTgoT1v4y6j9yK9RLmyaDwXobbhx9dn2HsH3XQ5tlLoBsTdx7uOMr8y8RlfbcqCMAe)YGqsb(5Ym6nCD)vUIrxhlT2iyTmH7DwfmLspKY4q3N81h6(OLymrEsA1ee65FMcc98ptHUmqGV4gTAZrqbxSIcUyCk3cuU86QsgOV8UwqaLaqxtrbuS1EsI09ApPiFd37He1y79qCe)197(q8qaKmy4IiNljwoHDyE9CxP6i1kzt0(5iMbe9Ce6RUFKyrcqmfDAzX0RQgNF)xj9ZV)ReSPSLv48oCJM3mZ(dlBMz)HXCpZARi5sgXMtndv(DQW8XEEjutaP4PPY1NMkqslwzmf5NzpxDUMljLv7C1Bgps3icxxKNaeOk4Jo(XOStT3TlhZ9UDQcwbfhmWU6rm2bK6Sci7cULz2YvnzfFkdlZ7ugo0b9(9zJI0Vw)j)lLsrCYuktM489gjQyKiKHHqW5XeQ(MJXB8cE2oSjOfz5aNa811ybIseaHW289kbT0cs045fNuaK59ksPQN(EvDkpMBvlC4TUmEnqaAKBNwWtmFoAebh4(5us9NJgv7UW5aFRCMU1iJDKFJSnoYVHomlbg7crYfSexqIpRfWZcGGdR5uj(Asb8bK87QD4Rl4WQwiHwDZYzKVnqs9Yl(aS5ekkjbMIxL)tpvC5p9uXbowuzf47hM2Y7qv4ChqHtHPr6F7dtMeQiLo3La31fpoFNlsg57CrCseCi(KfNxQnsDUFbfb8fQOLKOiDSQE(tmSirbiHSRjnZl0oF)bCP7t(06U)PtqD3b0rnGwG76CZOZFg2IkXPmczoOkJ29)negT7)Bq5pfMQksf6J5JgVMR6XNnkaRTjjZbqYxPfxOGp5z)WwPxmiRSL(oq0XbHUZB8T1u6)ThrOE55m3IfixKh)V4Nx28V4NNvu56Api58hIrbrIeM3N7uZw7DszRDYSNnZTxpZHGstXgpVHh3dkB4X9GqJzNyB5ugeIsw51IzVEzsE51tBgWgeWX9TeVOclySDn)GB)Rc199nOTOoeYFwcMEDtq2SRBcKnqpxlOCYvlNAD79fvj6xKYTFG3vBxdJCSdksDacIuJWPbF1qCDU)Rkr6FvuK4a8dxzQQMhF7FISUV9pHCH1AapQQrvtJ47O(R8oC6MQwP0wxEbQgGAznoqmrH1bIXedkBMuZB0JvjsejLXhsSbdizsSnobf4Sx2XAEPfvqco4uuCWPuj2wQlg93syijrcqWfrzRcE8P(vAiAYaeyfob)JnAlJDPrsTlej12HlWKxhikMWagRZ5hiOhhU04H4eo2zOO2CfW)OugxV6571)8roLFQIamGKKdfQxrU1RAYR)W03B8wklXBrSetIsltPbbYaX)uL37B1JmMVvpy)rQWO2)rA1l5aUg9aUgYPyly(GoGrX0z8RNV87)65tfhD5SpvUAfBt84DliUhVBkJNWdst4WRl5vUyMi5wf5Fajv92fgehDwoM)13ETkFbC7A7H19UplZckJX(vC7()DIAyFUDdsZfnLZFRWaMxza5II1HVN7auxzuJdlVX)TmpVX)nodqS3ZVuGRTIaUEXsgGso931Lk)776sHvpolLCjstz86Fd5hEDORz)T6MdXkkjNPjZCPI9ABteqETTr7IM9SzACxMWb92Gopbzo6diBKrFa2POmCzMGrln2SzOmBZ4DPCCZsjJy6i9s3HFc53omLZWtDzEoLmrmAmUK3F0GI)BxJyl53UgYZCZIdIJVz)owNb059NuDF)jkOahymGDGv)Yy)IPjB)FX0iPhO7Oybni1A96Uo3BqX13aRjZ2jNu85Ae23SWucyKE338XL1(nFC6RyVrOIJoe75uxMs3cM4Cf)JbKC9Hq75leLTVhzd8cdyfolJwHgs7WnRxE7s0PmvYrv2TrzZnnocuXsvfBbMzTcnQy8KQTVNCJKcGtL)BRu7wKvsDlY0wc0aiAGAJ8(On4JNzrPvesSGpVSpwaPVFIT745xBTVtz0I4ZeGvgtr36DqOOxCa5HvhqEyYbKj3tqPbzd6nMlhBospWJtBOGXnkfMmuwMlqYCyYJk1kgqkj7W3BnAHSkt2JODt2J8fjKa1Iq0Vrzhji0jlJrD08f7WJXRp8ZKXlsnJPF5g6rkVxpRMddvCBbY35d9e9J)jK9Wh)tqXbtAGZR1knvYdnv53o0ubDeCpfSR2qr19JEt(hbuSxMHYiiuiHGtYgfK4ANTmdRD2vI5JOPkvsc)U(4)rX3W4uQpNIg158iDbyqKEbI2Rk4h9ui0lwbBkLoGFkJNF0seFFsXiaK2hlzq)AA6nGNKmjBizAfqQ37qamvvBgFxcso(UieO0ZKh)z9FtItgqGi4AA1BqMmEAb49e67WEqm5k458L2KquEjk7EtSwxY7gNuywxtz22PuMnjPF2kNUXmz8TIYVWtMso9pzQOKLndbBcinTDgKzOWPTfFtoOLKp0PlF1dD6KEjfLXfes4wAtvB1gzdR2(OLldMPkALy4XRNPXti1A92Z3m3CgXuMmv(BuY3Zj1nSNykHU2jrCew45Pg)MxCYrLZTPZTTZnDBHkSxROPfqAv6jWLtT6WuIVOEVuMHnOM12a0ew5)M3DhsSecixIrxzRbY6CxG0DfZw7RKzBtX7maL698AAZI94Fl(3aeyOqN7s3U6eVXZQY0pljtpJ2GGMPVnCdSRYWHHmux16eumSjDUS3wg8L92uhaZUkq5SpQKkjFP7wihV0DZkrShM6IKESO(Vo010J9)jZXX()WqoRLbDpqleHlMhceA5bfNB3W0e3o0lS8Cg2AfcUFdVGIvOudpDUbocPIKoY0WeBb1zYel46e01cUosp55iC9ts4qJpj89P6ntGJKDXoL(bNZFSF5ugFqrffGv4mPf2XHZjQQkjVNpMCgVNpgqOlZwklEZLZO954v(wYmCLVfMHzfgf0FRwSLNTdR6Co8ujEcQbqIslz30mZZzMJk7(mhLSHut3p1j5qrFEWZ1IW8UMjXx)VgMfYi5eJRuPCx5Bt4Kfj4KjRAcMml1wGKZzl)zdZbHXzRPx6SxlzzJcpOjtxTnJnE4hu2vp8dsFFRupLjvpJvPNkPRuHjaz1P4ZQMf9K7(di)4U)avKkTaRn5evqJn18huZvYbptQHSWGcSQjO74NR48mGuNuutL)QF8I1eadvOeRfP5ZbSc3GriSCXixn9tLrM3rr2VdyY71YrAXcBw1sdNbR9ea4MsFCsoRwBIehtc(gqQGRdksAvlCq8tt5bpn28PxMHO6G2vvbseN1(e89DUVkCF)ZDZPdLGkl3CAVumHkYyMqfSkq)DXbfCEyACCvhDCRiH26AwSyqnvel(L82IVwxc4fU)UHcbfFcRtcheG0biiFEQn9SC9ll9v(M1AoV5nqXS6yd9XDOT2uDBr(Y62cTXBIsyN9Xxk24Pu(Tue)sJG51tCKI8MtOztqs(dGHLLo59CUQ425sTfxuJgBCvsCDasDkc1ZcJ19)4txxTPtQ(Hoy(3Pmg0yPsuT606WFk)fzjpL)cHVQ2fQbig78MChj1W2(NzQ(2(NHGvRlFqtOrm0S16KI5ci(8zoF4v1k4if8PEKGMhQU7rYtFzXtraPn1y6KakqjhPUrPmEEPObac8WRXl0(0UlEFFpYYsGJJvPIHXJyCBVHm(B7nQWLJml8coGu10tqu)zMjUYxtXLDAINtN3fwAWADFkLXRO2OEfYg1KAKtkhHXGc6WO1tEqnVhhmb3rlEJq5CwcSQ(eApULGAqYtvkgz6Oix0YS(rMKSiFKjX4Cth416qWJxYXvZHf)mmEiP(OaY(9BoIK9OWJC8PQstKIZP2y6MdCkb77IU6M9aQSyQKR6ILD6QUyQv0SClAvTQj1FIpJSvpXNHWO25sZfHvRY9P80kBbvq0jg1g2D77L1wlx50)uYKp9pf1mkkdynnJY20lXZ2AHk)o3jsrrqA8Akf(1afEJCGfSGGTERqMVKWdazgfV8rXS1OVVxUqRPjozXGlGKoLLaFskk5AlhLp7W0R0JeDbG0Sj(F575vItJJDHcHQ(IF6QmZPZsOUu7CWIm9g2ECj3T0Gwasgswg)zjVx5ZsEVept1MOVMIRK8E(iQy8hH(UUKLlTUCP5Gklb)KasOLa9sq8mIHwaPDtxw(uELmHP(s9df38S(MNLmRV5zr6QnDZfqoCun1ugBBpknypswqiUXXu6SJQePJ2suMZ)1Ad3(RVhAsvNvR2cOnSTRv0gCTvI1tVMABre7LLwJbWkuKyEb(0vudEJcrqleJsgQ7RtzSf9IeSLBHkhO0aBDpONLR9YP5(E2dnlaqQMRTUc3H6c9DqUqFQHDqxJzV6GAU0dXe0bGyYxk5fRZyU2iV2UvMUDZw8HleSotj)QI52Rvdc(APGGJZF1oLCLayuCXJQt0O7M1sKX3RFZsCu9HD7rdPNcJLspfyPSDU0VGSmIAd7a63Fa89RxAAUA2MPLimaK6kUve4FC(qM8EUwLz6A58WBszzoYLGe7YrKj2LdL4hX7ulvUo5bL2AbqUz0YffED8jRnt)K)94xA3ZVC62ceff1jThhGeAtQph76BMYq9ipTRv91zTxiDDcjp7RY83q6zlOcegZQUCtttF8)4LCMIuoG0el3teyrTmSMhQ1oTJIlWHz79e0F5XIksSlx9W6sYv3mVFpVTjbBEEKo8PuB4yTU8cqXOLFcUp6s8K0Y2mPbWzmvYjvIkseGaILLAyCIaw93t(OsFmaiCfGDhhSqcgE17x(PvVFo1AVNc5NCu1I(ONlX8C5bZXHBDSA7wfJNuZj6ts5eDYSpurvRNAEBr493in6nGeFa5aB)b5qabsL64UPcaekERujXLoqo5oppz5355rN(oid1sJWmVW2ZT(XjSNaIth7jD)H34TdCokN75GVo9cnherWMMusynsOncMFwAhewDXwzr6TTv8btV20OshMfAdojkv4PsU3Ji7R9EKWuPg)5KE4aqsOVdxRL75t5lkDJflAc7D8M9K1n7jtYItPQ2xWNyxSA3yKu7hKKFxMPWYUyEY1JmzcYtHLOQqITxPh0aK8sq65QieVLtXs(cAm2wolrF3wiDnH8ynzsz8a(VMuwS7mjMLzeEnD15rcn5YcSKIXK8iQPHJatd3vhuNZBs6k5dxc5sUciftdLNw)S261C81(OsE1FTpkXJ0BGnzpJTwL3Mtgm2CNHUjpd60mMAfoKTFE4uiC7nrlY1PcqiGsQtc9dR(XlwOams133VE5O99RNo3VNoyo(18wI31xZBv54kpzFuVrdkD87vYHfGv4cIqxpe2urtEUbWRL7Fwcc5(Nft2Z6Xj45Y9YLBU9A6RRZqstSci1pgEoLgtgOJ1KCZHaKvTqlTqjJAk7KhudK9GFmQFh4k2UKbT8ud2R7MfS764gPES5zcipkGZvyiOIvyqy3OgYOhlBkr2zI8)i(1OrCCnV97rHeObIJNRsRn)QOAZp93BdV1OL)iLDPdxd)b2)taOJgu2Y3ctrpJAi87FIkr6eJuFqcMwoKJUr6oVj5gsbizYUr3CoWrO5qD)e3gfSl8IRijeDgawHDmQ4i8fjRBFZYHd5fL8dciLZmi7dKjf8p)JpO4XmGKkVAKheTF8y(HANu9dVtkrnrDWG0lfnSTNt0IqD60K6RSFEkh71K869kPiaqUyaXh66u2JRtAP7mdjLulmJ713G4RhGCD2DeDxnbpNyN0p4TtZ3bPKmoX57565ZEFVekT7LszSu1rXLIp(M7KYbgvct5OQmfpiXumziowYMUSc0HDr2bRWKBvhJN5dkJ6z(GuZTrT4DZMfP7naZ794Y9RaqY1FIHLYYRFEjYG6NGKUlaJAE5huLkFW6jrMfA7Y5W44st2RPMlEnGJ2)sHyxEwLrvNb)WspsaiP2sso7iHP7Fj2zjIkvxtEWRu6OkajUNoHGzwtPveHz)0uVrd2xM9)eeDQasglTRTLL2LgGYUUyElrxOwqLqyUHCYNLCxwaKoylUFQhFnDpUCQTv5AgcyLJ7gC1ShDr)Yqr(WR3MKROpG69(aA6OEUJYanR3ylNTQX8SpE1xntPZgQltU6fkZXQxiLactrTWLxecw8MPr1czJNtT86TZ5ztnVh7gLoodqiSq1TKWYH2(3VMRQ9tAlovQfHcC1efys9qapOJPIBhJsh)exm8Cya6oqVmBi26rCILyhMl9lKWRYIqhQPls3EDYxV96inxrfdHBlMS12xSpJ08vaYCZC)uKvgxn9g3lixKvazLT1CX1cVg6jNEjzitVeXdyA7ef8EY9O0K90iTx5YG2Sz09Qm5XKgzaq2AaNQEMjHc3XumuL8ruAYJSqAhaEBlepkzoSAZVDEIzwaRqPaf67X)hi1oXUfoKm30ngLuT6KHcyLO81NEjwzg01MUR7mjSIibdyLy93QRV6Dx9jKK2dion9HdAyqRsc7Ft1r538c5BTTzUahVcG3q2JJEPYEC0lTcNmMQ5RxAMEAqjYj3zBazXPAAusJ3vBf639wjVHLR9(5P6Upps390(BCUBtZfEYlqSAai1QaWZi)I6Td8yZw52Okrm5gzbkYlUZr9Y)VJhv8PPPKGkf5mAKtwG0Z4ZTDFkl1TyxSGJz5ujFNlrwP35sO4F4YkwWYuV)A1N8DeuyY3Hof)oEU1MiWGBIGP0HJta3)hl0R)YqpxNa3Gt4hvpPFuw9179KwtN)wFdZqwKgMr1f5vodzcELZGsVzyBy0O2RW7tnITVeug3yKt6UTZmK5YfzLUAtmb1vBGYVu3(50JY(vKkr(FOqZY)dPugfWnNUELat(CYfZfqQx)SZbZWPB3JaIL1njfNbWkuJiyw1pePkCE(AZejp3gaIXnZoYxG6R0Ssgzk5bHfRACqQUlC78ObKM1O(lqirv9Dj5N0xovFsFkYot66al5apLXP8jLn2P8jzRKK))uGmlcFCyBeSUHK906gIvgg27l1Mq3KhwEizaKm8t9dN4NM2QcFX7ukC7xKUf8Ng1NpMCrJt3fzRMAfuYxS46RrtC61OzQARnYPiG6kQOgRm5LwuwSlLE5pMyKl9vXmn8W89mbaSBAnJJDbCI5SxXeJRvBYGRLLq7Hr)ujn4cPAzoayEgNYenoIuBZ3agT2jgVGskFHXtn6kL5qXcnFqNVuSDaPO507nQLg4vY7vUkEasbclM)kLMlyIW7QUK8kNETTquFHxW84xX)MOt7k(3q8GWEbuDkDv8hsslnGqDsJ9dM2q7QXg5XeJHJ8yqHqNEEAX63K88Lai1ScoblNE(gkfA(6foz9mEYqWkMKcLTRPZB7tGQzKvjYj05W3wk(NhvvVmkPEz281oXmtP5rUJNUx1Md7nPEwpM6TZXyVDy1r8Mo95mFsFKOnAdYbgq2Oe1Cq2UJPftnEu1u9JEoKBC2dqQhKEAi(VuUVPaIFQnlhPliXsolDPPytMuTlnDxA(7eM(bvM(bjvlVfVux)CKV76NdLuTc(qmhUXu1rNepI0QvaYNj9oDhabLQMJnoM6C5XiNlNyn6HjNtKJ9O6gC0zrO)XZZ9DkX(ciR803NUmcKRFs)f6P9b)7kTzpGK6pQNJRjFwtHRllauEJanbglpdEbBrSObiLJzUv)Sc7LVe)kn0YF1DuTx(MOm(TnrsgGUkaWPYa9MyU))o(hbKoGHxCmOOpQmsXTLK5cyfoQl6rLGCkLIVK6f0qQBYd3LQxPlSL7gmvGaVCEl8Gk)2dYfwVrYcOO0HBer(J3R8yXaiWfDuCittFt6NjBQnmlUApaq35dCule6bDYDlLQgqWO3uGVB6sEPPB9GmR74kLFEhxjzlU9Y(EfZ4vaXVTq4MQDw(FJO0nmvUX2aGufW5TNivMI14VNMMZV3zXijpUOHWBDhhpfVxNZ3vQcMdrXN1XN1LWo2QhojbBwmBciNRRHklVylrsjhqRwXb4AhVukzyK6xj3iuAhIAS74J))uOnJ))KmLHzH8TMB4lIxPHnjPKAtuUvMu4BhdTPQwKW1OMGxZzqCtEoGM2EyIrtEyvXZHVmQIc03uLvl5ZQLJ4z)uy2NERzi7c0CZLGMktF2i)VJFbIXFaP7PvgRbceLHjAvU6TaQM08lvSFkh1S9(uX7s62kaJsx(MvoLntpnstUxkvI6ZSIKkkbjUsjVRaIrDg9MNkmKpN3pe7jJh0nl5aEGYmTmLzIEfKOBtMlxuXEcSft47u8mgWiHRnOLuydPjvplq0imvvJWuhR21MH9Zm2SZeT4576LtFDX6xfO7)cROpuiffVnYom51Vw)XrNIoRtH0ZCE8goLOYfqSH(8YW0OehLIs80RU4nI4IY3VtuVOqpShAR2PLLF0jhnXjw8Vvill(3IjU7uXpt5ABbit)SZe6R0Ott)4PrF8htKfUnvwGEd0MsTYc9yMFitiiKk2Blr(cyTnAOEJv(es8RawHFtuYBL1UMUG92K85cyf(Pcq6iIO((MZEapphtE3JaScF1OfFGiRsa1sTjQwEWr1cfpAQOdrIXjLPfqY8a7ifB2zmTR83skofGaTWVQbYlkrYxsEzRaKKnAkWzeTzh6HloaVFvrG4Z69l42z9(jPuE3lY7vFLys(oQZiVZLl2HiLjJ9kzymQ8aAaigYmRs4Np8F1BKbiVyLlxskJNrAXbajM2)i)5ZrJeAoxALOsdm2YWM4eKQ1diTrxKhCz0rVgj5J4sNPIkNjHkVe6VfBM7uO1ZCNYTjBy7H5IM2KPGfFf16WRWrWf6jv4J3w9niC0asjosAXNX0eC7uEAPaKvZvBc2BYrE1em2NMG49LKoY7xw33NUUVVA9Gl69hS(gMMUWtlkILeJtXbJJXbG3mRwby4YR2XBjFvTArV61sYZi(b(kofLzeTV6MLK4dajm1fJLjLUCPQgG0O6wC03xKZfjFgXZgajkLCnwslVCqHsihq)SdWF2zZ)TtsAeraJuE9g6WEJ3hntsy3J55QkLXfPQrVisn6P1hXafQbHVVCJuwRV8bu3HpWPhTKjFvtfryceCyRLs1KophPCYTkntkGuI4ZyPU)WZ37QmfV7SPRnd5VbDNxT6pQsRhq18EG0rlyCdPNfaKOo6nqqI)H6(x(7QtCjaqO5rt75aAhZL8OkR0rjwPz33GML4I77rDoZhgbj6LL7Ie8VXS2gBvZRZwRJzTri801Yok5KjFbP7eaSYXNOMGIsZ82H0UYasDrnHG4B5m)BTlkWaKjq2UvVcPMs)Cvxm5HocqspvvThTynGv4nwO(g0CK0WSJyTs(LL85diPLokEu6z8RA312Wm4(yda62xZfBHcamGErhKCqbyysrRZ5ouf)0Ze3zE8ob1oL8iBt5mm)YxTPd82tViI79Wr1GAp6DEApdxHlwb9iLasFT1Rn(NvW6X)SewpJ(W0WEMYh3Xl81agYQhFi5Ilai8nTJmLt3AwTtWFdrUaqUUgU588G3FHANnEEnXXp)hKipCNWf17jJxtP94p9irQp0RlAH)q0LmEAh3DRyOYq3e5cOXFufR(JKy1uIYdl8)wA8lXms8ls4vbK6U4WmAwTRoQ7TwHq9FRvqPgvUwbY7(jVB2M2MoB7nyZg5GPl43nfH(IZQH2TxjV9acty8f3s49I9MskJaKfolNEjrVKCj7sAjmajdRSJLCV)0FzY(yMOmR2YnktEl3ijetbxAlYhYTkVHlNdCdamnW5ahh(233SFvVu43HJIouzp4z8M00oCtnr5toSAHvtwNXo03gRDq9D)exSF23RRHZwE52aKez42xvQxwn3OQ4NK0)daknYbLS3AFofIpRpSQ)MUIHZO1sKPyh9TxSfBZ8Ei(x2F)eni3xiajEc4JDw7Qf5m8LUcCrLuUPsrU6UDPy7acAWLfqnah9SAWNIhxPTpo3cwnwT)uryas1mB4H4hecaO2Fx79RMT91ohn52K2Eaqw7cD1yHg2bCIE6qA404xTfaWeeEBBRjR21RpoD1pa5NM(87Y1QJ(40CGXaGJZVHh)H(cY4p0xGzhPmjszaJA2OWob)11Bq8Rt3G4jlHRpMlxb8qrFjjNZ)eP4)s5JYV6yYr5xDmovGd6bhDJ6kNg22Zk1Y6zPmm1FTx4QelqTNVaYE(u6DilhlUtI8ChYQm1tfYDkzoQgN58zjKT(iXmw3Jm2T22k7MABLPX)PVI(yW8vUl(ZOmqsOOAFfpnUkT9kVksw6uBZ3oND2J)HWl5HeFebKcZ1JYUnXpAlTDEIhrEtOaKAGfjvgldQZJEPv)YskpbKmaCl8hD6Fh5Jo9Vdv0RW3e2EmLGDmEs5HbdqSVMLCjVtpxQGEwdrveQf4Wr1xtqJdQz)5Gu2FM0sDZ4XDZznImnSg(XQfaGFsYhRTixtFaPl4Bqgek889qCFfrSK8SgxDNm(mjF)i7s0X2l9cd7BThuY3bGuoI9C8ywQUIADQNrO8pdHxOlJynLWS(XRp)nJ)6JuF)T17W13E(v(B9wBmMEM8wvC6TsVVJtL9gI9V598igoIUmJu9A(in7hGexo)IXPAG4w3uITk(RjHJci5PIpj9h9WqM8P0hs2N6hqupllhPvhc8fYXEoFzf2Z5t81uUD10Jtx3QLqLdINL)6pvML)6pLE93476e93JDuPAxasmLqNUBXbuTKvFY(QtQBgGa3ZVt4de4uZJk860qkwhfsXXvr)2IsV06KN3haReE56)1ssDaKkwlFXaQMYkJ1kjshqIxUjEsMM(GBmTRUc9WevYt9qvUc3gBtFzC2gPjKEwUOBin1oRAtg(JL9aGyNotebqbBRms2mOZo928wZdjYvR3bKR(0fpu0CS3Kp1YOIzQ38pRe4)mRATCEHpcXQws73bJvPx3Wv1t1(PO61ml5MLawaSIEtLnEeP2GawHEYsjT8PRsZmEa5vkaqnp4utQPHPVF9ngy))HQPr5j0f4jQ(NUo9pDDe3pv0rF6cmoh5QNXfji6Dy5813s3ZNkb5P2Jh7bGecXaHxhM4NI(65Dk)VKsHLu2)92uej)5AT3)5Fz6QnMVqzOXGTJQVNjBw1rS51fj(Sh9QwVNl6VbZ98dZADY7(MKV8UVjmSurV1lh3JYopJx1MLz8Q2mD)L8lxtjctl2GbKiLQQ)Xuo86NG0ylaY214lt3yJ6i5E0RI2EAa0URGUffe2mILAZ69nEZuJ5DQu3ntU8swIHyVQeV(e)JYYK4FKTvf4mqG)C7uFnlPNXhvSRDvSRDY(4xJ)BhvtX0rPumDQvF6FRn78jFA1RUNgwIUlQTb6nZGwcLm5ZkpwdasYYlYkGVMaK3CzGEHUg6JLk5g17O6gxlhyfcPYXk8zMmMP8QybifRTNpLRBOqWvlbPrMpR43CgYaBTV3UDzMRa38pPVgLoCneVuR5PlQq2JRVe(CxHmMp3vuH6lHOCGWZhLV6SwIhSX)71h5K)(MPl7lNoBqq44BPFVUFJ8qsdyLAEbCQEDs2Q08MawTTAR5DrOUf9kY3VOxHUO0uUfO7JpJkQ7hkf5PUFi05sxyR2o3ugxG(E1Eb5zfyS6REgSCPbL7PqI5PK(5r00)tElSD91kB7Bccg)u8Nwf9F3kws5cwB0eKh2tuQtV()9!BBF"
        local profileData, errorMessage = BBF.ImportProfile(importString, "auraBlacklist")
        if errorMessage then
            print("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames: Error importing blacklist:", errorMessage)
            return
        end
        deepMergeTables(BetterBlizzFramesDB.auraBlacklist, profileData)
        BBF.auraBlacklistRefresh()
        Settings.OpenToCategory(BBF.aurasSubCategory)
    end,
    timeout = 0,
    whileDead = true,
}

------------------------------------------------------------
-- GUI Creation Functions
------------------------------------------------------------
local function CheckAndToggleCheckboxes(frame, alpha)
    for i = 1, frame:GetNumChildren() do
        local child = select(i, frame:GetChildren())
        if child and (child:GetObjectType() == "CheckButton" or child:GetObjectType() == "Slider" or child:GetObjectType() == "Button") then
            if frame:GetChecked() then
                child:Enable()
                child:SetAlpha(1)
            else
                child:Disable()
                child:SetAlpha(alpha or 0.5)
            end
        end

        -- Check if the child has children and if it's a CheckButton or Slider
        for j = 1, child:GetNumChildren() do
            local childOfChild = select(j, child:GetChildren())
            if childOfChild and (childOfChild:GetObjectType() == "CheckButton" or childOfChild:GetObjectType() == "Slider" or childOfChild:GetObjectType() == "Button") then
                if child.GetChecked and child:GetChecked() and frame.GetChecked and frame:GetChecked() then
                    childOfChild:Enable()
                    childOfChild:SetAlpha(1)
                else
                    childOfChild:Disable()
                    childOfChild:SetAlpha(0.5)
                end
            end
        end
    end
end

local function DisableElement(element)
    element:Disable()
    element:SetAlpha(0.5)
end

local function EnableElement(element)
    element:Enable()
    element:SetAlpha(1)
end

local function CreateBorderBox(anchor)
    local contentFrame = anchor:GetParent()
    local texture = contentFrame:CreateTexture(nil, "BACKGROUND")
    texture:SetAtlas("UI-Frame-Neutral-PortraitWiderDisable")
    texture:SetDesaturated(true)
    texture:SetRotation(math.rad(90))
    texture:SetSize(295, 163)
    texture:SetPoint("CENTER", anchor, "CENTER", 0, -95)
    return texture
end

--[[
-- dark grey with dark bg
border:SetBackdrop({
    bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
    edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
    tile = true,
    tileEdge = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 5, right = 5, top = 9, bottom = 9 },
})

]]

--[[
-- clean dark fancy
border:SetBackdrop({
    bgFile = "Interface\\FriendsFrame\\UI-Toast-Background",
    edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
    tile = true,
    tileEdge = true,
    tileSize = 12,
    edgeSize = 12,
    insets = { left = 5, right = 5, top = 5, bottom = 5 },
})

]]

-- Function to update the icon texture
local function UpdateIconTexture(editBox, textureFrame)
    local iconID = tonumber(editBox:GetText())
    if iconID then
        textureFrame:SetTexture(iconID)
    end
end

local function CreateIconChangeWindow()
    local window = CreateFrame("Frame", "IconChangeWindow", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(300, 180)  -- Adjust size as needed
    window:SetPoint("CENTER")
    window:SetFrameStrata("HIGH")

    -- Make the frame movable
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()

    -- Edit box
    local editBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
    editBox:SetSize(150, 20)
    editBox:SetPoint("CENTER", window, "CENTER", 20, 10)

    -- Text above the icon
    local text = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("BOTTOM", editBox, "TOP", -10, 15)
    text:SetText("Enter New Icon ID")

    -- Icon texture frame
    local textureFrame = window:CreateTexture(nil, "ARTWORK")
    textureFrame:SetSize(50, 50)  -- Enlarged icon
    textureFrame:SetPoint("RIGHT", editBox, "LEFT", -10, 0)
    textureFrame:SetTexture(BetterBlizzFramesDB.auraToggleIconTexture)

    -- Text for finding icon IDs
    local findIconText = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    findIconText:SetPoint("CENTER", window, "CENTER", 0, -40)
    findIconText:SetText("Find Icon IDs @ wowhead.com/icons")

    -- OK button
    local okButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    okButton:SetSize(60, 20)
    okButton:SetPoint("BOTTOM", window, "BOTTOM", 30, 10)
    okButton:SetText("OK")
    okButton:SetScript("OnClick", function()
        local newIconID = tonumber(editBox:GetText())
        if newIconID then
            BetterBlizzFramesDB.auraToggleIconTexture = newIconID
            if ToggleHiddenAurasButton then
                ToggleHiddenAurasButton.Icon:SetTexture(newIconID)
            end
        end
        window:Hide()
    end)

    local resetButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    resetButton:SetSize(60, 20)
    resetButton:SetPoint("BOTTOM", window, "BOTTOM", -30, 10)
    resetButton:SetText("Default")
    resetButton:SetScript("OnClick", function()
        BetterBlizzFramesDB.auraToggleIconTexture = 134430
        if ToggleHiddenAurasButton then
            ToggleHiddenAurasButton.Icon:SetTexture(134430)
        end
        textureFrame:SetTexture(134430)
        editBox:SetText(134430)
    end)

    editBox:SetScript("OnTextChanged", function()
        UpdateIconTexture(editBox, textureFrame)
    end)

    editBox:SetScript("OnEnterPressed", function()
        local newIconID = tonumber(editBox:GetText())
        if newIconID then
            BetterBlizzFramesDB.auraToggleIconTexture = newIconID
            if ToggleHiddenAurasButton then
                ToggleHiddenAurasButton.Icon:SetTexture(newIconID)
            end
        end
        window:Hide()
    end)

    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        window:Hide()
    end)

    window.editBox = editBox
    return window
end



local function CreateBorderedFrame(point, width, height, xPos, yPos, parent)
    local border = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    border:SetBackdrop({
        bgFile = "Interface\\FriendsFrame\\UI-Toast-Background",
        edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
        tile = true,
        tileEdge = true,
        tileSize = 10,
        edgeSize = 10,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    border:SetBackdropColor(1, 1, 1, 0.4)
    border:SetFrameLevel(1)
    border:SetSize(width, height)
    border:SetPoint("CENTER", point, "CENTER", xPos, yPos)

    return border
end

local function CreateSlider(parent, label, minValue, maxValue, stepValue, element, axis, sliderWidth)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetOrientation('HORIZONTAL')
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(stepValue)
    slider:SetObeyStepOnDrag(true)

    slider.Text:SetFontObject(GameFontHighlightSmall)
    slider.Text:SetTextColor(1, 0.81, 0, 1)
    slider.Text:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 11)

    slider.Low:SetText(" ")
    slider.High:SetText(" ")

    local category
    if parent.name then
        category = parent.name
    elseif parent:GetParent() and parent:GetParent().name then
        category = parent:GetParent().name
    elseif parent:GetParent() and parent:GetParent():GetParent() and parent:GetParent():GetParent().name then
        category = parent:GetParent():GetParent().name
    end

    if category == "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a" then
        category = "General"
    end

    slider.searchCategory = category

    table.insert(sliderList, {
        slider = slider,
        label = label,
        element = element
    })

    if sliderWidth then
        slider:SetWidth(sliderWidth)
    end

    local function UpdateSliderRange(newValue, minValue, maxValue)
        newValue = tonumber(newValue) -- Convert newValue to a number

        if (axis == "X" or axis == "Y") and (newValue < minValue or newValue > maxValue) then
            -- For X or Y axis: extend the range by ±30
            local newMinValue = math.min(newValue - 30, minValue)
            local newMaxValue = math.max(newValue + 30, maxValue)
            slider:SetMinMaxValues(newMinValue, newMaxValue)
        elseif newValue < minValue or newValue > maxValue then
            -- For other sliders: adjust the range, ensuring it never goes below a specified minimum (e.g., 0)
            local nonAxisRangeExtension = 2
            local newMinValue = math.max(newValue - nonAxisRangeExtension, 0.1)  -- Prevent going below 0.1
            local newMaxValue = math.max(newValue + nonAxisRangeExtension, maxValue)
            slider:SetMinMaxValues(newMinValue, newMaxValue)
        end
    end

    local function SetSliderValue()
        if BBF.variablesLoaded then
            local initialValue = tonumber(BetterBlizzFramesDB[element]) or 1 -- Convert to number

            if initialValue then
                local currentMin, currentMax = slider:GetMinMaxValues() -- Fetch the latest min and max values

                -- Check if the initial value is outside the current range and update range if necessary
                UpdateSliderRange(initialValue, currentMin, currentMax)

                slider:SetValue(initialValue) -- Set the initial value
                local textValue = initialValue % 1 == 0 and tostring(math.floor(initialValue)) or string.format("%.2f", initialValue)
                slider.Text:SetText(label .. ": " .. textValue)
            end
        else
            C_Timer.After(0.1, SetSliderValue)
        end
    end

    SetSliderValue()

    if parent:GetObjectType() == "CheckButton" and parent:GetChecked() == false then
        slider:Disable()
        slider:SetAlpha(0.5)
    else
        if parent:GetObjectType() == "CheckButton" and parent:IsEnabled() then
            slider:Enable()
            slider:SetAlpha(1)
        elseif parent:GetObjectType() ~= "CheckButton" then
            slider:Enable()
            slider:SetAlpha(1)
        end
    end

    -- Create Input Box on Right Click
    local editBox = CreateFrame("EditBox", nil, slider, "InputBoxTemplate")
    editBox:SetAutoFocus(false)
    editBox:SetWidth(50) -- Set the width of the EditBox
    editBox:SetHeight(20) -- Set the height of the EditBox
    editBox:SetMultiLine(false)
    editBox:SetPoint("CENTER", slider, "CENTER", 0, 0) -- Position it to the right of the slider
    editBox:SetFrameStrata("DIALOG") -- Ensure it appears above other UI elements
    editBox:Hide()
    editBox:SetFontObject(GameFontHighlightSmall)

    -- Function to handle the entered value and update the slider
    local function HandleEditBoxInput()
        local inputValue = tonumber(editBox:GetText())
        if inputValue then
            -- Check if it's a non-axis slider and inputValue is <= 0
            if (axis ~= "X" and axis ~= "Y") and inputValue <= 0 then
                inputValue = 0.1  -- Set to minimum allowed value for non-axis sliders
            end

            local currentMin, currentMax = slider:GetMinMaxValues()
            if inputValue < currentMin or inputValue > currentMax then
                UpdateSliderRange(inputValue, currentMin, currentMax)
            end

            slider:SetValue(inputValue)
            BetterBlizzFramesDB[element] = inputValue
        end
        editBox:Hide()
    end


    editBox:SetScript("OnEnterPressed", HandleEditBoxInput)

    slider:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            editBox:Show()
            editBox:SetFocus()
        end
    end)

    slider:SetScript("OnMouseWheel", function(slider, delta)
        if IsShiftKeyDown() then
            local currentVal = slider:GetValue()
            if delta > 0 then
                slider:SetValue(currentVal + stepValue)
            else
                slider:SetValue(currentVal - stepValue)
            end
        end
    end)

    slider:SetScript("OnValueChanged", function(self, value)
        if not BetterBlizzFramesDB.wasOnLoadingScreen then
            local textValue = value % 1 == 0 and tostring(math.floor(value)) or string.format("%.2f", value)
            self.Text:SetText(label .. ": " .. textValue)
            --if not BBF.checkCombatAndWarn() then
                -- Update the X or Y position based on the axis
                if axis == "X" then
                    BetterBlizzFramesDB[element .. "XPos"] = value
                elseif axis == "Y" then
                    BetterBlizzFramesDB[element .. "YPos"] = value
                elseif axis == "Alpha" then
                    BetterBlizzFramesDB[element .. "Alpha"] = value
                elseif axis == "Height" then
                    BetterBlizzFramesDB[element .. "Height"] = value
                end

                if not axis then
                    BetterBlizzFramesDB[element .. "Scale"] = value
                end

                local xPos = BetterBlizzFramesDB[element .. "XPos"] or 0
                local yPos = BetterBlizzFramesDB[element .. "YPos"] or 0
                local anchorPoint = BetterBlizzFramesDB[element .. "Anchor"] or "CENTER"

                --If no frames are present still adjust values
                if element == "targetToTXPos" then
                    BetterBlizzFramesDB.targetToTXPos = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "targetToTYPos" then
                    BetterBlizzFramesDB.targetToTYPos = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "targetToTScale" then
                    BetterBlizzFramesDB.targetToTScale = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "focusToTScale" then
                    BetterBlizzFramesDB.focusToTScale = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "focusToTXPos" then
                    BetterBlizzFramesDB.focusToTXPos = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "focusToTYPos" then
                    BetterBlizzFramesDB.focusToTYPos = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.MoveToTFrames()
                    end
                elseif element == "partyFrameScale" then
                    BetterBlizzFramesDB.partyFrameScale = value
                    BBF.CompactPartyFrameScale()
                elseif element == "darkModeColor" then
                    BetterBlizzFramesDB.darkModeColor = value
                    if not BBF.checkCombatAndWarn() then
                        BBF.DarkmodeFrames()
                    end
                elseif element == "lossOfControlScale" then
                    BetterBlizzFramesDB.lossOfControlScale = value
                    BBF.ToggleLossOfControlTestMode()
                    BBF.ChangeLossOfControlScale()
                elseif element == "targetAndFocusAuraOffsetX" then
                    BetterBlizzFramesDB.targetAndFocusAuraOffsetX = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusAuraOffsetY" then
                    BetterBlizzFramesDB.targetAndFocusAuraOffsetY = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusAuraScale" then
                    BetterBlizzFramesDB.targetAndFocusAuraScale = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusHorizontalGap" then
                    BetterBlizzFramesDB.targetAndFocusHorizontalGap = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusVerticalGap" then
                    BetterBlizzFramesDB.targetAndFocusVerticalGap = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "selfAuraPurgeGlowAlpha" then
                    BetterBlizzFramesDB.selfAuraPurgeGlowAlpha = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusAurasPerRow" then
                    BetterBlizzFramesDB.targetAndFocusAurasPerRow = value
                    BBF.RefreshAllAuraFrames()
                    --
                elseif element == "castBarInterruptHighlighterStartTime" then
                    BetterBlizzFramesDB.castBarInterruptHighlighterStartTime = value
                    BBF.CastbarRecolorWidgets()
                elseif element == "castBarInterruptHighlighterEndTime" then
                    BetterBlizzFramesDB.castBarInterruptHighlighterEndTime = value
                    BBF.CastbarRecolorWidgets()
                elseif element == "combatIndicatorScale" then
                    BetterBlizzFramesDB.combatIndicatorScale = value
                    BBF.CombatIndicatorCaller()
                elseif element == "combatIndicatorXPos" then
                    BetterBlizzFramesDB.combatIndicatorXPos = value
                    BBF.CombatIndicatorCaller()
                elseif element == "combatIndicatorYPos" then
                    BetterBlizzFramesDB.combatIndicatorYPos = value
                    BBF.CombatIndicatorCaller()
                elseif element == "healerIndicatorScale" then
                    BetterBlizzFramesDB.healerIndicatorScale = value
                    BBF.HealerIndicatorCaller()
                elseif element == "healerIndicatorXPos" then
                    BetterBlizzFramesDB.healerIndicatorXPos = value
                    BBF.HealerIndicatorCaller()
                elseif element == "healerIndicatorYPos" then
                    BetterBlizzFramesDB.healerIndicatorYPos = value
                    BBF.HealerIndicatorCaller()
                elseif element == "absorbIndicatorScale" then
                    BetterBlizzFramesDB.absorbIndicatorScale = value
                    BBF.AbsorbCaller()
                elseif element == "playerAbsorbXPos" then
                    BetterBlizzFramesDB.playerAbsorbXPos = value
                    BBF.AbsorbCaller()
                elseif element == "playerAbsorbYPos" then
                    BetterBlizzFramesDB.playerAbsorbYPos = value
                    BBF.AbsorbCaller()
                elseif element == "targetAbsorbXPos" then
                    BetterBlizzFramesDB.targetAbsorbXPos = value
                    BBF.AbsorbCaller()
                elseif element == "targetAbsorbYPos" then
                    BetterBlizzFramesDB.targetAbsorbYPos = value
                    BBF.AbsorbCaller()
                elseif element == "partyCastBarScale" then
                    BetterBlizzFramesDB.partyCastBarScale = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarXPos" then
                    BetterBlizzFramesDB.partyCastBarXPos = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarYPos" then
                    BetterBlizzFramesDB.partyCastBarYPos = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastbarIconXPos" then
                    BetterBlizzFramesDB.partyCastbarIconXPos = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastbarIconYPos" then
                    BetterBlizzFramesDB.partyCastbarIconYPos = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarWidth" then
                    BetterBlizzFramesDB.partyCastBarWidth = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarHeight" then
                    BetterBlizzFramesDB.partyCastBarHeight = value
                    BBF.UpdateCastbars()
                elseif element == "partyCastBarIconScale" then
                    BetterBlizzFramesDB.partyCastBarIconScale = value
                    BBF.UpdateCastbars()
                elseif element == "targetCastBarScale" then
                    BetterBlizzFramesDB.targetCastBarScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastBarXPos" then
                    BetterBlizzFramesDB.targetCastBarXPos = value
                    BBF.CastbarAdjustCaller()
                elseif element == "targetCastBarYPos" then
                    BetterBlizzFramesDB.targetCastBarYPos = value
                    BBF.CastbarAdjustCaller()
                elseif element == "targetCastBarWidth" then
                    BetterBlizzFramesDB.targetCastBarWidth = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastBarHeight" then
                    BetterBlizzFramesDB.targetCastBarHeight = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastBarIconScale" then
                    BetterBlizzFramesDB.targetCastBarIconScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastbarIconXPos" then
                    BetterBlizzFramesDB.targetCastbarIconXPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "targetCastbarIconYPos" then
                    BetterBlizzFramesDB.targetCastbarIconYPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastBarScale" then
                    BetterBlizzFramesDB.focusCastBarScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastBarXPos" then
                    BetterBlizzFramesDB.focusCastBarXPos = value
                    BBF.CastbarAdjustCaller()
                elseif element == "focusCastBarYPos" then
                    BetterBlizzFramesDB.focusCastBarYPos = value
                    BBF.CastbarAdjustCaller()
                elseif element == "focusCastBarWidth" then
                    BetterBlizzFramesDB.focusCastBarWidth = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastBarHeight" then
                    BetterBlizzFramesDB.focusCastBarHeight = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastBarIconScale" then
                    BetterBlizzFramesDB.focusCastBarIconScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastBarScale" then
                    BetterBlizzFramesDB.playerCastBarScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastbarIconXPos" then
                    BetterBlizzFramesDB.focusCastbarIconXPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "focusCastbarIconYPos" then
                    BetterBlizzFramesDB.focusCastbarIconYPos = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastBarIconScale" then
                    BetterBlizzFramesDB.playerCastBarIconScale = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastBarWidth" then
                    BetterBlizzFramesDB.playerCastBarWidth = value
                    BBF.ChangeCastbarSizes()
                elseif element == "playerCastBarHeight" then
                    BetterBlizzFramesDB.playerCastBarHeight = value
                    BBF.ChangeCastbarSizes()
                elseif element == "maxTargetBuffs" then
                    BetterBlizzFramesDB.maxTargetBuffs = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "maxTargetDebuffs" then
                    BetterBlizzFramesDB.maxTargetDebuffs = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "maxBuffFrameBuffs" then
                    BetterBlizzFramesDB.maxBuffFrameBuffs = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "maxBuffFrameDebuffs" then
                    BetterBlizzFramesDB.maxBuffFrameDebuffs = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "petCastBarScale" then
                    BetterBlizzFramesDB.petCastBarScale = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarXPos" then
                    BetterBlizzFramesDB.petCastBarXPos = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarYPos" then
                    BetterBlizzFramesDB.petCastBarYPos = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarWidth" then
                    BetterBlizzFramesDB.petCastBarWidth = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarHeight" then
                    BetterBlizzFramesDB.petCastBarHeight = value
                    BBF.UpdatePetCastbar()
                elseif element == "petCastBarIconScale" then
                    BetterBlizzFramesDB.petCastBarIconScale = value
                    BBF.UpdatePetCastbar()
                elseif element == "playerAuraMaxBuffsPerRow" then
                    BetterBlizzFramesDB.playerAuraMaxBuffsPerRow = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "playerAuraSpacingX" then
                    BetterBlizzFramesDB.playerAuraSpacingX = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "playerAuraSpacingY" then
                    BetterBlizzFramesDB.playerAuraSpacingY = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "auraTypeGap" then
                    BetterBlizzFramesDB.auraTypeGap = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "auraStackSize" then
                    BetterBlizzFramesDB.auraStackSize = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "targetAndFocusSmallAuraScale" then
                    BetterBlizzFramesDB.targetAndFocusSmallAuraScale = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "enlargedAuraSize" then
                    BetterBlizzFramesDB.enlargedAuraSize = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "compactedAuraSize" then
                    BetterBlizzFramesDB.compactedAuraSize = value
                    BBF.RefreshAllAuraFrames()
                elseif element == "racialIndicatorScale" then
                    BetterBlizzFramesDB.racialIndicatorScale = value
                    BBF.RacialIndicatorCaller()
                elseif element == "racialIndicatorXPos" then
                    BetterBlizzFramesDB.racialIndicatorXPos = value
                    BBF.RacialIndicatorCaller()
                elseif element == "racialIndicatorYPos" then
                    BetterBlizzFramesDB.racialIndicatorYPos = value
                    BBF.RacialIndicatorCaller()
                elseif element == "targetToTAdjustmentOffsetY" then
                    BetterBlizzFramesDB.targetToTAdjustmentOffsetY = value
                    BBF.CastbarAdjustCaller()
                elseif element == "focusToTAdjustmentOffsetY" then
                    BetterBlizzFramesDB.focusToTAdjustmentOffsetY = value
                    BBF.CastbarAdjustCaller()
                elseif element == "castBarInterruptIconScale" then
                    BetterBlizzFramesDB.castBarInterruptIconScale = value
                    BBF.UpdateInterruptIconSettings()
                elseif element == "castBarInterruptIconXPos" then
                    BetterBlizzFramesDB.castBarInterruptIconXPos = value
                    BBF.UpdateInterruptIconSettings()
                elseif element == "castBarInterruptIconYPos" then
                    BetterBlizzFramesDB.castBarInterruptIconYPos = value
                    BBF.UpdateInterruptIconSettings()
                elseif element == "uiWidgetPowerBarScale" then
                    BetterBlizzFramesDB.uiWidgetPowerBarScale = value
                    BBF.ResizeUIWidgetPowerBarFrame()
                elseif element == playerClassResourceScale then
                    BetterBlizzFramesDB[playerClassResourceScale] = value
                    BBF.UpdateClassComboPoints()
                    --end
                elseif element == "legacyComboScale" or element == "legacyComboXPos" or element == "legacyComboYPos" then
                    BetterBlizzFramesDB[element] = value
                    if BBF.UpdateLegacyComboPosition then
                        BBF.UpdateLegacyComboPosition()
                    end
                end
            end
        end)

    return slider
end

local function CreateTooltip(widget, tooltipText, anchor)
    widget.tooltipTitle = tooltipText
    widget:SetScript("OnEnter", function(self)
        if GameTooltip:IsShown() then
            GameTooltip:Hide()
        end

        if anchor then
            GameTooltip:SetOwner(self, anchor)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        end
        GameTooltip:SetText(tooltipText)

        GameTooltip:Show()
    end)

    widget:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

local function CreateTooltipTwo(widget, title, mainText, subText, anchor, cvarName, cpuUsage, category)
    widget.tooltipTitle = title
    widget.tooltipMainText = mainText
    widget.tooltipSubText = subText
    widget.tooltipCVarName = cvarName
    widget:SetScript("OnEnter", function(self)
        -- Clear the tooltip before showing new information
        GameTooltip:ClearLines()
        if GameTooltip:IsShown() then
            GameTooltip:Hide()
        end
        if anchor then
            GameTooltip:SetOwner(self, anchor)
        else
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        end
        -- Set the bold title
        GameTooltip:AddLine(title)
        --GameTooltip:AddLine(" ") -- Adding an empty line as a separator
        -- Set the main text
        GameTooltip:AddLine(mainText, 1, 1, 1, true) -- true for wrap text
        -- Set the subtext
        if subText then
            GameTooltip:AddLine("____________________________", 0.8, 0.8, 0.8, true)
            GameTooltip:AddLine(subText, 0.8, 0.80, 0.80, true)
        end
        -- Add CVar information if provided
        if cvarName then
            --GameTooltip:AddLine(" ")
            --GameTooltip:AddLine("Default Value: " .. cvarName, 0.5, 0.5, 0.5) -- grey color for subtext
            GameTooltip:AddDoubleLine("Changes CVar:", cvarName, 0.2, 1, 0.6, 0.2, 1, 0.6)
        end
        if cpuUsage then
            local star = "|A:UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star:16:16|a"
            local noStar = "|A:UI-HUD-UnitFrame-Target-PortraitOn-Boss-IconRing:16:16|a"

            -- Create star string based on cpuUsage (0-5)
            local starString = ""
            for i = 1, 5 do
                if i <= cpuUsage then
                    starString = starString .. star
                else
                    starString = starString .. noStar
                end
            end
            GameTooltip:AddDoubleLine(" ", " ")
            GameTooltip:AddDoubleLine("CPU Usage:", starString, 0.2, 1, 0.6, 0.2, 1, 0.6)
        end

        if category then
            GameTooltip:AddLine("")
            GameTooltip:AddLine("|A:shop-games-magnifyingglass:17:17|a Setting located in "..category.." section.", 0.4, 0.8, 1, true)
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

local CLASS_COLORS = {
    ROGUE = "|cfffff569",
    WARRIOR = "|cffc79c6e",
    MAGE = "|cff40c7eb",
    DRUID = "|cffff7d0a",
    HUNTER = "|cffabd473",
    PRIEST = "|cffffffff",
    WARLOCK = "|cff8787ed",
    SHAMAN = "|cff0070de",
    PALADIN = "|cfff58cba",
    DEATHKNIGHT = "|ffc41f3b",
    MONK = "|cff00ff96",
    DEMONHUNTER = "|cffa330c9",
    EVOKER = "|cff33937f",
    STARTER = "|cff32cd32",
    BLITZ = "|cffff8000",
    MYTHIC = "|cff7dd1c2",
}

local CLASS_ICONS = {
    ROGUE = "groupfinder-icon-class-rogue",
    WARRIOR = "groupfinder-icon-class-warrior",
    MAGE = "groupfinder-icon-class-mage",
    DRUID = "groupfinder-icon-class-druid",
    HUNTER = "groupfinder-icon-class-hunter",
    PRIEST = "groupfinder-icon-class-priest",
    WARLOCK = "groupfinder-icon-class-warlock",
    SHAMAN = "groupfinder-icon-class-shaman",
    PALADIN = "groupfinder-icon-class-paladin",
    DEATHKNIGHT = "groupfinder-icon-class-deathknight",
    MONK = "groupfinder-icon-class-monk",
    DEMONHUNTER = "groupfinder-icon-class-demonhunter",
    EVOKER = "groupfinder-icon-class-evoker",
    STARTER = "newplayerchat-chaticon-newcomer",
    BLITZ = "questlog-questtypeicon-pvp",
    MYTHIC = "worldquest-icon-dungeon",
}

local function ShowProfileConfirmation(profileName, class, profileFunction, additionalNote)
    local noteText = additionalNote or ""
    local color = CLASS_COLORS[class] or "|cffffffff"
    local icon = CLASS_ICONS[class] or "groupfinder-icon-role-leader"
    local profileText = string.format("|A:%s:16:16|a %s%s|r", icon, color, profileName.." Profile")
    local confirmationText = titleText .. "This action will delete all settings and apply\nthe " .. profileText .. " and reload the UI.\n\n" .. noteText .. "Are you sure you want to continue?"

    StaticPopupDialogs["BBF_CONFIRM_PROFILE"].text = confirmationText
    StaticPopup_Show("BBF_CONFIRM_PROFILE", nil, nil, { func = profileFunction })
end

local function CreateClassButton(parent, class, name, twitchName, onClickFunc)
    local bbfParent = parent == BetterBlizzFrames
    local btnWidth, btnHeight = bbfParent and 96 or 150, bbfParent and 22 or  30
    local button = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate")
    button:SetSize(btnWidth, btnHeight)

    local dontIncludeProfileText = bbfParent and "" or " Profile"
    local color = CLASS_COLORS[class] or "|cffffffff"
    local icon = CLASS_ICONS[class] or "groupfinder-icon-role-leader"

    button:SetText(string.format("|A:%s:16:16|a %s%s|r", icon, color, (name..dontIncludeProfileText)))
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightFontObject("GameFontHighlight")
    local a,b,c = button.Text:GetFont()
    button.Text:SetFont(a,b,"OUTLINE")
    local a,b,c,d,e = button.Text:GetPoint()
    button.Text:SetPoint(a,b,c,d,e-0.5)

    button:SetScript("OnClick", function()
        if onClickFunc then
            onClickFunc()
        end
    end)

    if class == "STARTER" then
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name.." Profile"), "A basic starter profile that only enables the few things you need.\n\nIntended to work as a very minimal quick start that can be built upon.", nil, "ANCHOR_TOP")
    elseif class == "BLITZ" then
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name.." Profile"), "A more advanced profile enabling a few more settings and customizing things a bit more.\n\nGreat for Battlegrounds (and Arenas) with Class Icons showing Healers, Tanks and Battleground Objectives.", nil, "ANCHOR_TOP")
    elseif class == "MYTHIC" then
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name.." Profile"), "A great well rounded profile made by |cffc79c6eJovelo|r that enhances the default Blizzard nameplates.\n\nGreat for all types of content with Mythic+ Season 2 NPC nameplate colors included.", nil, "ANCHOR_TOP")
    else
        CreateTooltipTwo(button, string.format("|A:%s:16:16|a %s%s|r", icon, color, name.." Profile"), string.format("Enable all of %s's profile settings.", name), string.format("www.twitch.tv/%s", twitchName), "ANCHOR_TOP")
    end

    return button
end

local function CreateImportExportUI(parent, title, dataTable, posX, posY, tableName)
    -- Frame to hold all import/export elements
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(210, 65) -- Adjust size as needed
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", posX, posY)
    
    -- Setting the backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", -- More subtle background
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Sleeker border
        tile = false, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7) -- Semi-transparent black

    -- Title
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    titleText:SetPoint("BOTTOM", frame, "TOP", 0, 0)
    titleText:SetText(title)

    -- Export EditBox
    local exportBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    exportBox:SetSize(100, 20)
    exportBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -10)
    exportBox:SetAutoFocus(false)
    CreateTooltipTwo(exportBox, "Ctrl+C to copy and share")

    -- Import EditBox
    local importBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    importBox:SetSize(100, 20)
    importBox:SetPoint("TOP", exportBox, "BOTTOM", 0, -5)
    importBox:SetAutoFocus(false)

    -- Export Button
    local exportBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    exportBtn:SetPoint("RIGHT", exportBox, "LEFT", -10, 0)
    exportBtn:SetSize(73, 20)
    exportBtn:SetText("Export")
    exportBtn:SetNormalFontObject("GameFontNormal")
    exportBtn:SetHighlightFontObject("GameFontHighlight")
    CreateTooltipTwo(exportBtn, "Export Data", "Create an export string to share your data.")

    -- Import Button
    local importBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    importBtn:SetPoint("RIGHT", importBox, "LEFT", -10, 0)
    importBtn:SetSize(title ~= "Full Profile" and 52 or 73, 20)
    importBtn:SetText("Import")
    importBtn:SetNormalFontObject("GameFontNormal")
    importBtn:SetHighlightFontObject("GameFontHighlight")
    CreateTooltipTwo(importBtn, "Import Data", "Import an export string.\nWill remove any current data (optional setting coming in non-beta)")

    -- Keep Old Checkbox
    local keepOldCheckbox
    if title ~= "Full Profile" then
        keepOldCheckbox = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
        keepOldCheckbox:SetPoint("RIGHT", importBtn, "LEFT", 3, -1)
        keepOldCheckbox:SetChecked(true)
        CreateTooltipTwo(keepOldCheckbox, "Keep Old Data", "Merge the imported data into your current data.\nWill keep your settings but add any new data.")
    end

    -- Button scripts
    exportBtn:SetScript("OnClick", function()
        local exportString = ExportProfile(dataTable, tableName)
        exportBox:SetText(exportString)
        exportBox:SetFocus()
        exportBox:HighlightText()
    end)

    local wipeButton = exportBox:CreateTexture(nil, "OVERLAY")
    wipeButton:SetSize(14,14)
    wipeButton:SetPoint("CENTER", exportBox, "TOPRIGHT", 8,6)
    wipeButton:SetAtlas("transmog-icon-remove")
    wipeButton:Hide()

    wipeButton:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" and IsShiftKeyDown() and IsAltKeyDown() then
            if title == "Full Profile" then
                BetterBlizzFramesDB = nil
            else
                BetterBlizzFramesDB[tableName] = nil
            end
            ReloadUI()
        end
    end)

    local function HideWipeButton()
        if not wipeButton:IsMouseOver() then
            wipeButton:Hide()
        end
    end

    frame:HookScript("OnEnter", function()
        wipeButton:Show()
        C_Timer.After(4, HideWipeButton)
    end)
    CreateTooltipTwo(wipeButton, "Delete "..title, "Delete all the data in "..title.."\n\nHold Shift+Alt and Right-Click to delete and reload.")

    wipeButton:HookScript("OnEnter", function()
        wipeButton:Show()
    end)

    wipeButton:HookScript("OnLeave", function()
        C_Timer.After(0.5, HideWipeButton)
    end)


    importBtn:SetScript("OnClick", function()
        local importString = importBox:GetText()
        local profileData, errorMessage = BBF.ImportProfile(importString, tableName)
        if errorMessage then
            print("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames: Error importing " .. title .. ":", errorMessage)
        else
            if not profileData then
                print("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames: Error importing.")
                return
            end
            if keepOldCheckbox and keepOldCheckbox:GetChecked() then
                -- Perform a deep merge if "Keep Old" is checked
                deepMergeTables(dataTable, profileData)
            else
                -- Replace existing data with imported data
                for k in pairs(dataTable) do dataTable[k] = nil end -- Clear current table
                for k, v in pairs(profileData) do
                    dataTable[k] = v -- Populate with new data
                end
            end
            print("|A:gmchat-icon-blizz:16:16|aBetter|cff00c0ffBlizz|rFrames: " .. title .. " imported successfully.")
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    return frame
end

local function CreateAnchorDropdown(name, parent, defaultText, settingKey, toggleFunc, point)
    -- Create the dropdown frame using the library's creation function
    local dropdown = LibDD:Create_UIDropDownMenu(name, parent)
    LibDD:UIDropDownMenu_SetWidth(dropdown, 125)

    -- Function to get the display text based on the setting value
    local function getDisplayTextForSetting(settingValue)
        if name == "combatIndicatorDropdown" or name == "playerAbsorbAnchorDropdown" then
            if settingValue == "LEFT" then
                return "INNER"
            elseif settingValue == "RIGHT" then
                return "OUTER"
            end
        end
        return settingValue
    end

    -- Set the initial dropdown text
    LibDD:UIDropDownMenu_SetText(dropdown, getDisplayTextForSetting(BetterBlizzFramesDB[settingKey]) or defaultText)

    local anchorPointsToUse = anchorPoints
    if name == "combatIndicatorDropdown" or name == "playerAbsorbAnchorDropdown" then
        anchorPointsToUse = anchorPoints2
    end

    -- Initialize the dropdown using the library's initialize function
    LibDD:UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = LibDD:UIDropDownMenu_CreateInfo()
        for _, anchor in ipairs(anchorPointsToUse) do
            local displayText = anchor

            -- Customize display text for specific dropdowns
            if name == "combatIndicatorDropdown" or name == "playerAbsorbAnchorDropdown" then
                if anchor == "LEFT" then
                    displayText = "INNER"
                elseif anchor == "RIGHT" then
                    displayText = "OUTER"
                end
            end

            info.text = displayText
            info.arg1 = anchor
            info.func = function(self, arg1)
                if BetterBlizzFramesDB[settingKey] ~= arg1 then
                    BetterBlizzFramesDB[settingKey] = arg1
                    LibDD:UIDropDownMenu_SetText(dropdown, getDisplayTextForSetting(arg1))
                    toggleFunc(arg1)
                    BBF.MoveToTFrames()
                end
            end
            info.checked = (BetterBlizzFramesDB[settingKey] == anchor)
            LibDD:UIDropDownMenu_AddButton(info)
        end
    end)

    -- Position the dropdown
    dropdown:SetPoint("TOPLEFT", point.anchorFrame, "TOPLEFT", point.x, point.y)

    -- Create and set up the label
    local dropdownText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownText:SetPoint("BOTTOM", dropdown, "TOP", 0, 3)
    dropdownText:SetText(point.label)

    -- Enable or disable the dropdown based on the parent's check state
    if parent:GetObjectType() == "CheckButton" and parent:GetChecked() == false then
        LibDD:UIDropDownMenu_DisableDropDown(dropdown)
    else
        LibDD:UIDropDownMenu_EnableDropDown(dropdown)
    end

    return dropdown
end

local function CreateCheckbox(option, label, parent, cvarName, extraFunc)
    local checkBox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkBox.Text:SetText(label)
    checkBox:SetSize(23,23)
    checkBox.Text:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 12)

    local category
    if parent.name then
        category = parent.name
    elseif parent:GetParent() and parent:GetParent().name then
        category = parent:GetParent().name
    elseif parent:GetParent() and parent:GetParent():GetParent() and parent:GetParent():GetParent().name then
        category = parent:GetParent():GetParent().name
    end

    if category == "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a" then
        category = "General"
    end

    checkBox.searchCategory = category


    table.insert(checkBoxList, {checkbox = checkBox, label = label})

    local function UpdateOption(value)
        if option == 'friendlyFrameClickthrough' and BBF.checkCombatAndWarn() then
            return
        end

        local function SetChecked()
            if BetterBlizzFramesDB.hasCheckedUi then
                BetterBlizzFramesDB[option] = value
                checkBox:SetChecked(value)
            else
                C_Timer.After(0.1, function()
                    SetChecked()
                end)
            end
        end
        SetChecked()

        local grandparent = parent:GetParent()

        if parent:GetObjectType() == "CheckButton" and (parent:GetChecked() == false or (grandparent:GetObjectType() == "CheckButton" and grandparent:GetChecked() == false)) then
            checkBox:Disable()
            checkBox:SetAlpha(0.5)
        else
            checkBox:Enable()
            checkBox:SetAlpha(1)
        end

        if extraFunc and not BetterBlizzFramesDB.wasOnLoadingScreen and BetterBlizzFrames.guiLoaded then
            extraFunc(option, value)
        end

        if not BetterBlizzFramesDB.wasOnLoadingScreen then
            BBF.UpdateUserTargetSettings()
        end

        if not BetterBlizzFramesDB.wasOnLoadingScreen and BetterBlizzFramesDB.playerAuraFiltering then
            BBF.RefreshAllAuraFrames()
        end
        --print("Checkbox option '" .. option .. "' changed to:", value)
    end

    UpdateOption(BetterBlizzFramesDB[option])

    checkBox:HookScript("OnClick", function(_, _, _)
        UpdateOption(checkBox:GetChecked())
    end)

    return checkBox
end




local function deleteEntry(listName, key)
    if not key then return end

    local entry = BetterBlizzFramesDB[listName][key]

    if not entry then
        if key == "example aura :3 (delete me)" then
            entry = BetterBlizzFramesDB[listName]["example"]
            key = "example"
        end
    end

    if entry then
        if entry.id then
            local spellName, _, icon = BBF.TWWGetSpellInfo(entry.id)
            if spellName and icon then
                local iconString = "|T" .. icon .. ":16:16:0:0|t"
                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconString .. " " .. spellName .. " (" .. entry.id .. ") removed from list.")
            elseif entry.name then
                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. entry.name .. " (" .. entry.id .. ") removed from list.")
            else
                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Spell ID " .. entry.id .. " removed from list (info not found).")
            end
        else
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. entry.name .. " removed from list.")
        end

        BetterBlizzFramesDB[listName][key] = nil
    end

    BBF.currentSearchFilter = ""

    if SettingsPanel:IsShown() then
        if BBF[listName.."Refresh"] then
            BBF[listName.."Refresh"]()
        end
    else
        --print("prepping delayed update")
        BBF[listName.."DelayedUpdate"] = BBF[listName.."Refresh"]
    end

    BBF.RefreshAllAuraFrames()
end

local lists = { "auraBlacklist", "auraWhitelist" }

for _, listName in ipairs(lists) do
    -- Create static popup dialogs for duplicate confirmations
    StaticPopupDialogs["BBF_DUPLICATE_NPC_CONFIRM_" .. listName] = {
        text = "This name or spellID is already in the list. Do you want to remove it from the list?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            deleteEntry(listName, BBF.entryToDelete)  -- Delete the entry when "Yes" is clicked
        end,
        timeout = 0,
        whileDead = true,
    }

    -- Create static popup dialogs for delete confirmations
    StaticPopupDialogs["BBF_DELETE_NPC_CONFIRM_" .. listName] = {
        text = "Are you sure you want to delete this entry?\nHold shift to delete without this prompt",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            deleteEntry(listName, BBF.entryToDelete)  -- Delete the entry when "Yes" is clicked
        end,
        timeout = 0,
        whileDead = true,
    }
end

StaticPopupDialogs["BBF_DUPLICATE_UPDATE_OR_DELETE"] = {
    text = "This name or spellID is already in the\nblacklist with \"Show Mine\" tag.\n\nDo you want to update the tag or\ndelete it from the blacklist?",
    button1 = "Update and always hide",
    button2 = "Delete from blacklist",
    OnAccept = function()
        BBF["auraBlacklist"](BBF.entryToDelete, "auraBlacklist", nil, true)  -- Update when accepted
    end,
    OnCancel = function()
        deleteEntry("auraBlacklist", BBF.entryToDelete)  -- Delete the entry when "Yes" is clicked
    end,
    timeout = 0,
    whileDead = true,
}


local function addOrUpdateEntry(inputText, listName, addShowMineTag, skipRefresh, color)
    BBF.entryToDelete = nil
    local name, comment = strsplit("/", inputText, 2)
    name = strtrim(name or "")
    comment = comment and strtrim(comment) or nil
    local id = tonumber(name)
    local printMsg
    local spellName
    local icon
    local iconString
    local _

    -- Check if there's a numeric ID within the name and clear the name if found
    if id then
        spellName, _, icon = BBF.TWWGetSpellInfo(id)
        name = spellName or ""

        if not spellName then
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: No spell found for ID: "..id)
            return
        end

        if icon then
            iconString = "|T" .. icon .. ":16:16:0:0|t"
        else
            iconString = ""
        end

        -- Check if the spell is being added to blacklist or whitelist
        if listName == "auraBlacklist" then
            printMsg = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconString .. " " .. spellName .. " (" .. id .. ") added to |cffff0000blacklist|r."
        elseif listName == "auraWhitelist" then
            printMsg = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconString .. " " .. spellName .. " (" .. id .. ") added to |cff00ff00whitelist|r."
        end
    end

    -- Remove unwanted characters from name and comment individually
    name = gsub(name, "[%/%(%)%[%]]", "")
    if comment then
        comment = gsub(comment, "[%/%(%)%[%]]", "")
    end

    if (name ~= "" or id) then
        local key = id or string.lower(name)  -- Use id if available, otherwise use name
        local isDuplicate = false

        -- Directly check if the key already exists in the list
        if BetterBlizzFramesDB[listName][key] then
            if listName == "auraBlacklist" then
                local hasShowMineTag = BetterBlizzFramesDB[listName][key].showMine
                if addShowMineTag and not hasShowMineTag then
                    -- do nothing, adds tag
                elseif not addShowMineTag and hasShowMineTag then
                    -- do nothing, removes tag
                else
                    isDuplicate = true
                    BBF.entryToDelete = key  -- Use key to identify the duplicate
                    if addShowMineTag then
                        BBF.DuplicateWithTag = true
                    end
                end
            elseif listName == "auraWhitelist" then
                isDuplicate = true
                BBF.entryToDelete = key  -- Use key to identify the duplicate
            end
        end

        if isDuplicate then
            if BBF.DuplicateWithTag then
                StaticPopup_Show("BBF_DUPLICATE_UPDATE_OR_DELETE")
                BBF.DuplicateWithTag = nil
            else
                StaticPopup_Show("BBF_DUPLICATE_NPC_CONFIRM_" .. listName)
            end
        else
            -- Initialize the new entry with appropriate structure
            local newEntry = {
                name = name,
                id = id,
                comment = comment or nil,
            }

            if listName == "auraWhitelist" then
                newEntry = {name = name, id = id, comment = comment or nil, color = {0,1,0,1}}
            end

            -- if color then
            --     --newEntry.color = {1,0.501960813999176,0,1} -- offensive
            --     --newEntry.color = {1,0.6627451181411743,0.9450981020927429,1} -- defensive
            --     newEntry.color = {0,1,1,1} -- mobility
            --     --newEntry.color = {0,1,0,1} --muy importante
            --     newEntry.important = true
            --     newEntry.enlarged = true
            -- end

            -- If adding to auraBlacklist and addShowMineTag is true, set showMine to true
            if addShowMineTag and listName == "auraBlacklist" then
                newEntry.showMine = true
                if id then
                    printMsg = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: " .. iconString .. " " .. spellName .. " (" .. id .. ") added to |cffff0000blacklist|r with tag."
                end
            end

            -- Add the new entry to the list using key
            BetterBlizzFramesDB[listName][key] = newEntry

            -- Update UI: Re-create text line button and refresh the list display
            if BBF["UpdateTextLine"..listName] then
                BBF["UpdateTextLine"..listName](newEntry, #BBF[listName.."TextLines"] + 1, BBF[listName.."ExtraBoxes"])
            end

            BBF.currentSearchFilter = ""

            if not skipRefresh then
                if BBF[listName.."Refresh"] then
                    BBF[listName.."Refresh"]()
                end
            else
                if SettingsPanel:IsShown() then
                    if BBF[listName.."Refresh"] then
                        BBF[listName.."Refresh"]()
                    end
                else
                    --print("prepping delayed update")
                    BBF[listName.."DelayedUpdate"] = BBF[listName.."Refresh"]
                end
            end

            if printMsg then
                print(printMsg)
            end

        end
    end

    BBF.RefreshAllAuraFrames()
    if BBF[listName.."EditBox"] then
        BBF[listName.."EditBox"]:SetText("")  -- Clear the EditBox
    end
end
BBF["auraBlacklist"] = addOrUpdateEntry
BBF["auraWhitelist"] = addOrUpdateEntry







local function CreateList(subPanel, listName, listData, refreshFunc, extraBoxes, colorText, width, pos)
    -- Create the scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, subPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(width or 322, 270)
    if not pos then
        scrollFrame:SetPoint("TOPLEFT", 10, -10)
    else
        scrollFrame:SetPoint("TOPLEFT", -48, -10)
    end

    -- Create the content frame
    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame:SetSize(width or 322, 270)
    scrollFrame:SetScrollChild(contentFrame)

    local textLines = {}
    BBF[listName.."TextLines"] = textLines
    BBF[listName.."ExtraBoxes"] = extraBoxes
    local framePool = {}
    BBF.entryToDelete = nil
    BBF.currentSearchFilter = ""

    -- Function to update the background colors of the entries
    local function updateBackgroundColors()
        for i, button in ipairs(textLines) do
            local bg = button.bgImg
            if i % 2 == 0 then
                bg:SetColorTexture(0.3, 0.3, 0.3, 0.1)  -- Dark color for even lines
            else
                bg:SetColorTexture(0.3, 0.3, 0.3, 0.3)  -- Light color for odd lines
            end
        end
    end

    local function createOrUpdateTextLineButton(npc, index, extraBoxes)
        local button

        -- Reuse frame from the pool if available
        if framePool[index] then
            button = framePool[index]
            button:Show()
        else
            -- Create a new frame if pool is exhausted
            button = CreateFrame("Frame", nil, contentFrame)
            button:SetSize((width and width - 12) or (322 - 12), 20)
            button:SetPoint("TOPLEFT", 10, -(index - 1) * 20)

            -- Background
            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            button.bgImg = bg  -- Store the background texture for later updates

            -- Icon
            local iconTexture = button:CreateTexture(nil, "OVERLAY")
            iconTexture:SetSize(20, 20)  -- Same height as the button
            iconTexture:SetPoint("LEFT", button, "LEFT", 0, 0)
            button.iconTexture = iconTexture

            -- Text
            local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", button, "LEFT", 25, 0)
            button.text = text
            text:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 13)

            -- Delete Button
            local deleteButton = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
            deleteButton:SetSize(20, 20)
            deleteButton:SetPoint("RIGHT", button, "RIGHT", 4, 0)
            deleteButton:SetText("X")
            deleteButton:SetScript("OnClick", function()
                if IsShiftKeyDown() then
                    deleteEntry(listName, button.npcData.id or button.npcData.name:lower())
                else
                    BBF.entryToDelete = button.npcData.id or button.npcData.name:lower()
                    StaticPopup_Show("BBF_DELETE_NPC_CONFIRM_" .. listName)
                end
            end)
            button.deleteButton = deleteButton

            -- Save button to the pool
            framePool[index] = button
        end

        -- Update button's content
        button.npcData = npc
        local displayText
        if npc.id then
            displayText = string.format("%s (%d)", (npc.name or C_Spell.GetSpellName(npc.id) or "Name Missing"), npc.id)  -- Display as "Name (id)"
        else
            displayText = npc.name  -- Display just the name if there's no id
        end
        button.text:SetText(displayText)
        button.iconTexture:SetTexture(C_Spell.GetSpellTexture(npc.id or npc.name))

        -- Function to set text color
        local function SetTextColor(r, g, b, a)
            if colorText and button.checkBoxI and button.checkBoxI:GetChecked() then
                button.text:SetTextColor(r or 1, g or 1, b or 0, a or 1)
            else
                button.text:SetTextColor(1, 1, 0, 1)
            end
        end

        -- Function to set important box color
        local function SetImportantBoxColor(r, g, b, a)
            if button.checkBoxI then
                if button.checkBoxI:GetChecked() then
                    button.checkBoxI.texture:SetVertexColor(r or 0, g or 1, b or 0, a or 1)
                else
                    button.checkBoxI.texture:SetVertexColor(0, 1, 0, 1)
                end
            end
        end

        -- Initialize colors based on npc data
        local entryColors = npc.color or {1, 0.8196, 0, 1}  -- Default yellowish color 
        

        -- Extra logic for handling additional checkboxes and flags
        if extraBoxes then
            -- CheckBox for Pandemic
            if not button.checkBoxP then
                local checkBoxP = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxP:SetSize(24, 24)
                checkBoxP:SetPoint("RIGHT", button.deleteButton, "LEFT", 4, 0)
                checkBoxP:SetScript("OnClick", function(self)
                    button.npcData.pandemic = self:GetChecked() and true or nil
                    BBF.RefreshAllAuraFrames()
                end)
                checkBoxP.texture = checkBoxP:CreateTexture(nil, "ARTWORK", nil, 1)
                checkBoxP.texture:SetAtlas("newplayertutorial-drag-slotgreen")
                checkBoxP.texture:SetDesaturated(true)
                checkBoxP.texture:SetVertexColor(1, 0, 0)
                checkBoxP.texture:SetSize(27, 27)
                checkBoxP.texture:SetPoint("CENTER", checkBoxP, "CENTER", -0.5, 0.5)
                button.checkBoxP = checkBoxP
                local isWarlock = playerClass == "WARLOCK"
                local extraText = isWarlock and "\n\nIf Agony or Unstable Affliction refresh talents are specced it will first glow orange when entering this window then switch to red once it enters the pandemic window as well." or ""
                CreateTooltipTwo(checkBoxP, "Pandemic Glow |A:elementalstorm-boss-air:22:22|a", "Check for a red glow when the aura has less than 30% of its duration remaining.\nOr last 5sec if the aura has no pandemic effect."..extraText, "Also check which frame(s) you want this on down below in settings.", "ANCHOR_TOPRIGHT")
            end
            button.checkBoxP:SetChecked(button.npcData.pandemic)
    
            -- CheckBox for Important with color picker
            if not button.checkBoxI then
                local checkBoxI = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxI:SetSize(24, 24)
                checkBoxI:SetPoint("RIGHT", button.checkBoxP, "LEFT", 4, 0)
                checkBoxI:SetScript("OnClick", function(self)
                    button.npcData.important = self:GetChecked() and true or nil
                    BBF.RefreshAllAuraFrames()
                    SetImportantBoxColor(button.npcData.color[1], button.npcData.color[2], button.npcData.color[3], button.npcData.color[4])
                    SetTextColor(button.npcData.color[1], button.npcData.color[2], button.npcData.color[3], button.npcData.color[4])
                end)
                checkBoxI.texture = checkBoxI:CreateTexture(nil, "ARTWORK", nil, 1)
                checkBoxI.texture:SetAtlas("newplayertutorial-drag-slotgreen")
                checkBoxI.texture:SetSize(27, 27)
                checkBoxI.texture:SetDesaturated(true)
                checkBoxI.texture:SetPoint("CENTER", checkBoxI, "CENTER", -0.5, 0.5)
                button.checkBoxI = checkBoxI
                CreateTooltipTwo(checkBoxI, "Important Glow |A:importantavailablequesticon:22:22|a", "Check for a glow on the aura to highlight it.\n|cff32f795Right-click to change color.|r", "Also check which frame(s) you want this on down below in settings.", "ANCHOR_TOPRIGHT")
            end
            button.checkBoxI:SetChecked(button.npcData.important)
    
            -- Color picker logic
            local function OpenColorPicker()
                local colorData = entryColors or {0, 1, 0, 1}
                local r, g, b = colorData[1] or 1, colorData[2] or 1, colorData[3] or 1
                local a = colorData[4] or 1 -- Default alpha to 1 if not present

                local function updateColors(newR, newG, newB, newA)
                    -- Assign RGB values directly, and set alpha to 1 if not provided
                    entryColors[1] = newR
                    entryColors[2] = newG
                    entryColors[3] = newB
                    entryColors[4] = newA or 1  -- Default alpha value to 1 if not provided

                    -- Update text and box colors
                    SetTextColor(newR, newG, newB, newA or 1)  -- Update text color with default alpha if needed
                    SetImportantBoxColor(newR, newG, newB, newA or 1)  -- Update important box color with default alpha if needed
                    -- Refresh frames or elements that depend on these colors
                    BBF.RefreshAllAuraFrames()
                end

                local function swatchFunc()
                    r, g, b = ColorPickerFrame:GetColorRGB()
                    updateColors(r, g, b, a)  -- Pass current color values to updateColors
                end

                local function opacityFunc()
                    a = ColorPickerFrame:GetColorAlpha()
                    updateColors(r, g, b, a)  -- Pass current color values to updateColors including the alpha value
                end

                local function cancelFunc(previousValues)
                    -- Revert to previous values if the selection is cancelled
                    if previousValues then
                        r, g, b, a = previousValues.r, previousValues.g, previousValues.b, previousValues.a
                        updateColors(r, g, b, a)  -- Reapply the previous colors
                    end
                end

                -- Store the initial values before showing the color picker
                ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }

                -- Setup and show the color picker with the necessary callbacks and initial values
                ColorPickerFrame:SetupColorPickerAndShow({
                    r = r, g = g, b = b, opacity = a, hasOpacity = true,
                    swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
                })
            end
    
            -- Right-click to open color picker
            button.checkBoxI:SetScript("OnMouseDown", function(self, button)
                if button == "RightButton" then
                    OpenColorPicker()
                end
            end)
    
            -- CheckBox for Compacted
            if not button.checkBoxC then
                local checkBoxC = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxC:SetSize(24, 24)
                checkBoxC:SetPoint("RIGHT", button.checkBoxI, "LEFT", 3, 0)
                button.checkBoxC = checkBoxC
                CreateTooltipTwo(checkBoxC, "Compacted Aura |A:ui-hud-minimap-zoom-out:22:22|a", "Check to make the aura smaller.", "Also check which frame(s) you want this on down below in settings.", "ANCHOR_TOPRIGHT")
            end
            button.checkBoxC:SetChecked(button.npcData.compacted)
    
            -- CheckBox for Enlarged
            if not button.checkBoxE then
                local checkBoxE = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxE:SetSize(24, 24)
                checkBoxE:SetPoint("RIGHT", button.checkBoxC, "LEFT", 3, 0)
                checkBoxE:SetScript("OnClick", function(self)
                    button.npcData.enlarged = self:GetChecked() and true or nil
                    button.checkBoxC:SetChecked(false)
                    button.npcData.compacted = false
                    BBF.RefreshAllAuraFrames()
                end)
                button.checkBoxC:SetScript("OnClick", function(self)
                    button.npcData.compacted = self:GetChecked() and true or nil
                    button.checkBoxE:SetChecked(false)
                    button.npcData.enlarged = false
                    BBF.RefreshAllAuraFrames()
                end)
                CreateTooltipTwo(checkBoxE, "Enlarged Aura |A:ui-hud-minimap-zoom-in:22:22|a", "Check to make the aura bigger.", "Also check which frame(s) you want this on down below in settings.", "ANCHOR_TOPRIGHT")
                button.checkBoxE = checkBoxE
            end
            button.checkBoxE:SetChecked(button.npcData.enlarged)
    
            -- CheckBox for "Only Mine"
            if not button.checkBoxOnlyMine then
                local checkBoxOnlyMine = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxOnlyMine:SetSize(24, 24)
                checkBoxOnlyMine:SetPoint("RIGHT", button.checkBoxE, "LEFT", 3, 0)
                checkBoxOnlyMine:SetScript("OnClick", function(self)
                    button.npcData.onlyMine = self:GetChecked() and true or nil
                    BBF.RefreshAllAuraFrames()
                end)
                button.checkBoxOnlyMine = checkBoxOnlyMine
                CreateTooltipTwo(checkBoxOnlyMine, "Only My Aura |A:UI-HUD-UnitFrame-Player-Group-FriendOnlineIcon:22:22|a", "Only show my aura.", nil, "ANCHOR_TOPRIGHT")
            end
            button.checkBoxOnlyMine:SetChecked(button.npcData.onlyMine)
        end

        if listName == "auraBlacklist" then
            if not button.checkBoxShowMine then
                -- Create Checkbox Only Mine if not already created
                local checkBoxShowMine = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                checkBoxShowMine:SetSize(24, 24)
                checkBoxShowMine:SetPoint("RIGHT", button, "RIGHT", -13, 0)
                CreateTooltipTwo(checkBoxShowMine, "Show mine |A:UI-HUD-UnitFrame-Player-Group-FriendOnlineIcon:22:22|a", "Disregard the blacklist and show aura if it is mine.", nil, "ANCHOR_TOPRIGHT")

                -- Handler for the show mine checkbox
                checkBoxShowMine:SetScript("OnClick", function(self)
                    button.npcData.showMine = self:GetChecked() and true or nil
                    BBF.RefreshAllAuraFrames()
                end)

                -- Adjust text width and settings
                button.text:SetWidth(196)
                button.text:SetWordWrap(false)
                button.text:SetJustifyH("LEFT")

                -- Save the reference to the button
                button.checkBoxShowMine = checkBoxShowMine
            end
            button.checkBoxShowMine:SetChecked(button.npcData.showMine)
        end

        if button.checkBoxI then
            if button.checkBoxI:GetChecked() then
                SetImportantBoxColor(entryColors[1], entryColors[2], entryColors[3], entryColors[4])
                SetTextColor(entryColors[1], entryColors[2], entryColors[3], entryColors[4])
            else
                SetImportantBoxColor(0, 1, 0, 1)
                SetTextColor(1, 0.8196, 0, 1)
            end
        end

        if npc.id and not button.idTip then
            button:SetScript("OnEnter", function(self)
                if not button.npcData.id then return end
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetSpellByID(button.npcData.id)
                GameTooltip:AddLine("Spell ID: " .. button.npcData.id, 1, 1, 1)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            button.idTip = true
        end

        -- Update background colors
        updateBackgroundColors()

        return button
    end
    BBF["UpdateTextLine"..listName] = createOrUpdateTextLineButton

    local editBox = CreateFrame("EditBox", nil, subPanel, "InputBoxTemplate")
    editBox:SetSize((width and width - 62) or (322 - 62), 19)
    editBox:SetPoint("TOP", scrollFrame, "BOTTOM", -15, -5)
    editBox:SetAutoFocus(false)
    BBF[listName.."EditBox"] = editBox
    CreateTooltipTwo(editBox, "Filter auras by spell id and/or spell name", "You can click auras to add to lists.\n\n|cff00ff00To Whitelist:|r\nShift+Alt + LeftClick\n\n|cffff0000To Blacklist:|r\nShift+Alt + RightClick\nCtrl+Alt RightClick with \"Show Mine\" tag", nil, "ANCHOR_TOP")

    local function cleanUpEntry(entry)
        -- Iterate through each field in the entry
        for key, value in pairs(entry) do
            if value == false then
                entry[key] = nil
            end
        end
    end

    local function getSortedNpcList()
        local sortableNpcList = {}

        -- Iterate over the structure using pairs to access all entries
        for key, entry in pairs(listData) do
            cleanUpEntry(entry)
            -- Apply the search filter
            if BBF.currentSearchFilter == "" or (entry.name and entry.name:lower():match(BBF.currentSearchFilter)) or (entry.id and tostring(entry.id):match(BBF.currentSearchFilter)) then
                table.insert(sortableNpcList, entry)
            end
        end

        -- Sort the list alphabetically by the 'name' field, and then by 'id' if the names are the same
        table.sort(sortableNpcList, function(a, b)
            local nameA = a.name and a.name:lower() or ""
            local nameB = b.name and b.name:lower() or ""

            -- First, compare by name
            if nameA ~= nameB then
                return nameA < nameB
            end

            -- If names are the same, compare by id (sort low to high)
            local idA = a.id or math.huge
            local idB = b.id or math.huge
            return idA < idB
        end)

        return sortableNpcList
    end

    -- Function to update the list with batching logic
    local function refreshList()
        local sortedListData = getSortedNpcList()
        local totalEntries = #sortedListData
        local batchSize = 35  -- Number of entries to process per frame
        local currentIndex = 1

        local function processNextBatch()
            for i = currentIndex, math.min(currentIndex + batchSize - 1, totalEntries) do
                local npc = sortedListData[i]
                local button = createOrUpdateTextLineButton(npc, i, extraBoxes)
                textLines[i] = button
            end

            -- Hide any extra frames
            for i = totalEntries + 1, #framePool do
                if framePool[i] then
                    framePool[i]:Hide()
                end
            end

            -- Update the content frame height
            contentFrame:SetHeight(totalEntries * 20)
            updateBackgroundColors()

            -- Continue processing if there are more entries
            currentIndex = currentIndex + batchSize
            if currentIndex <= totalEntries then
                C_Timer.After(0.04, processNextBatch)  -- Defer to the next frame
            end
        end
        -- Start processing in the first frame
        processNextBatch()
    end

    contentFrame.refreshList = refreshList
    refreshList()
    --BBF[listName.."DelayedUpdate"] = refreshList
    BBF[listName.."Refresh"] = refreshList
    --BBF.auraWhitelist & BBF.auraBlacklist

    editBox:SetScript("OnEnterPressed", function(self)
        addOrUpdateEntry(self:GetText(), listName)
    end)

        -- Function to search and filter the list
        local function searchList(searchText)
            BBF.currentSearchFilter = searchText:lower()
            refreshList()
        end

        -- Update the list as the user types
        editBox:SetScript("OnTextChanged", function(self, userInput)
            if userInput then
                searchList(self:GetText())
            end
        end, true)

    local addButton = CreateFrame("Button", nil, subPanel, "UIPanelButtonTemplate")
    addButton:SetSize(60, 24)
    addButton:SetText("Add")
    addButton:SetPoint("LEFT", editBox, "RIGHT", 10, 0)
    addButton:SetScript("OnClick", function()
        addOrUpdateEntry(editBox:GetText(), listName)
    end)
    scrollFrame:HookScript("OnShow", function()
        if BBF.auraWhitelistDelayedUpdate then
            BBF.auraWhitelistDelayedUpdate()
            --print("Ran delayed update WHITELIST, then set it to not run next time")
            BBF.auraWhitelistDelayedUpdate = nil
        end
        if BBF.auraBlacklistDelayedUpdate then
            BBF.auraBlacklistDelayedUpdate()
            --print("Ran delayed update BLACKLIST, then set it to not run next time")
            BBF.auraBlacklistDelayedUpdate = nil
        end
    end)
    return scrollFrame
end

SettingsPanel:HookScript("OnShow", function()
    if BBF.auraWhitelistDelayedUpdate then
        BBF.auraWhitelistDelayedUpdate()
        --print("Ran delayed update WHITELIST, then set it to not run next time")
        BBF.auraWhitelistDelayedUpdate = nil
    end
    if BBF.auraBlacklistDelayedUpdate then
        BBF.auraBlacklistDelayedUpdate()
        --print("Ran delayed update BLACKLIST, then set it to not run next time")
        BBF.auraBlacklistDelayedUpdate = nil
    end
end)

local function CreateCDManagerList(parent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    local width, height = 450, 510
    scrollFrame:SetSize(width, height)
    scrollFrame:SetPoint("TOPLEFT", 185, -14)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(width, height)
    scrollFrame:SetScrollChild(content)

    local spellText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    spellText:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 10, 3)
    spellText:SetText("Spell")

    local priorityText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    priorityText:SetPoint("BOTTOMLEFT", scrollFrame, "TOP", 95, 3)
    priorityText:SetText("Priority")

    local blacklistIcon = parent:CreateTexture(nil, "OVERLAY")
    blacklistIcon:SetAtlas("lootroll-toast-icon-pass-up")
    blacklistIcon:SetPoint("BOTTOM", scrollFrame, "TOPRIGHT", -29, 1)
    blacklistIcon:SetSize(22, 22)
    CreateTooltip(blacklistIcon, "Hide Spell Icon |A:lootroll-toast-icon-pass-up:22:22|a")

    local framePool = {}

    local function refreshList()
        if not BBF.cooldownManagerSpells or BBF.cdManagerNeedsUpdate then
            BBF.UpdateCooldownManagerSpellList(true)
        end
        local baseSpells = {}
        local blacklist = BetterBlizzFramesDB.cdManagerBlacklist or {}
        local priorityList = BetterBlizzFramesDB.cdManagerPriorityList or {}

        for _, id in ipairs(BBF.cooldownManagerSpells or {}) do
            baseSpells[id] = true
        end

        local fullList = {}
        for _, id in ipairs(BBF.cooldownManagerSpells or {}) do table.insert(fullList, id) end
        for idStr, _ in pairs(blacklist) do
            local id = tonumber(idStr)
            if id and not baseSpells[id] then
                table.insert(fullList, id)
            end
        end
        for idStr, _ in pairs(priorityList) do
            local id = tonumber(idStr)
            if id and not baseSpells[id] then
                table.insert(fullList, id)
            end
        end

        for i, button in ipairs(framePool) do button:Hide() end

        for i, spellID in ipairs(fullList) do
            local info = C_Spell.GetSpellInfo(spellID)
            if info then
                local name = info.name
                local icon = info.iconID or info.originalIconID
                local isCustom = not baseSpells[spellID]

                local button = framePool[i]
                if not button then
                    button = CreateFrame("Frame", nil, content)
                    button:SetSize(width - 12, 20)
                    button:SetPoint("TOPLEFT", 10, -(i - 1) * 20)

                    local bg = button:CreateTexture(nil, "BACKGROUND")
                    bg:SetAllPoints()
                    button.bg = bg

                    local iconTex = button:CreateTexture(nil, "ARTWORK")
                    iconTex:SetSize(20, 20)
                    iconTex:SetPoint("LEFT")
                    button.iconTex = iconTex

                    local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    label:SetPoint("LEFT", iconTex, "RIGHT", 5, 0)
                    button.label = label

                    local checkbox = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
                    checkbox:SetSize(24, 24)
                    checkbox:SetPoint("RIGHT", button, "RIGHT", -15, 0)
                    CreateTooltipTwo(checkbox, "Hide Spell Icon |A:lootroll-toast-icon-pass-up:22:22|a", "Hide the spell icon from Cooldown Manager.", nil, "ANCHOR_TOPRIGHT")
                    button.checkbox = checkbox

                    local slider = CreateFrame("Slider", nil, button, "OptionsSliderTemplate")
                    slider:SetSize(80, 16)
                    slider:SetPoint("RIGHT", checkbox, "LEFT", -20, 0)
                    slider:SetMinMaxValues(0, 20)
                    slider:SetValueStep(1)
                    slider:SetObeyStepOnDrag(true)
                    slider.Low:SetText("")
                    slider.High:SetText("")
                    CreateTooltipTwo(slider, "Priority value", "Highest value starts from the left.\n\n0 is disabled and default position.", nil, "ANCHOR_TOPRIGHT")
                    button.slider = slider

                    local text = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    text:SetPoint("RIGHT", slider, "LEFT", -5, 0)
                    button.sliderText = text

                    local del = CreateFrame("Button", nil, button, "UIPanelButtonTemplate")
                    del:SetSize(18, 18)
                    del:SetText("X")
                    del:SetPoint("RIGHT", button, "RIGHT", 0, 0)
                    button.del = del
                    CreateTooltipTwo(del, "Delete", "Remove custom Spell from list")

                    framePool[i] = button
                end

                button.iconTex:SetTexture(icon)
                button.label:SetText(name .. " (" .. spellID .. ")")

                local isBlacklisted = BetterBlizzFramesDB.cdManagerBlacklist[spellID]
                local priority = BetterBlizzFramesDB.cdManagerPriorityList[spellID]

                button.checkbox:SetChecked(isBlacklisted or false)
                if isBlacklisted then
                    button.slider:Disable()
                    button.slider:SetAlpha(0.3)
                else
                    button.slider:Enable()
                    button.slider:SetAlpha(1)
                end

                local value = priority or 0
                button.slider:SetValue(value)
                button.sliderText:SetText(value)
                if value == 0 then
                    button.slider:SetAlpha(0.3)
                else
                    button.slider:SetAlpha(1)
                end

                button.checkbox:SetScript("OnClick", function(self)
                    if self:GetChecked() then
                        BetterBlizzFramesDB.cdManagerBlacklist[spellID] = true
                        BetterBlizzFramesDB.cdManagerPriorityList[spellID] = nil
                    else
                        BetterBlizzFramesDB.cdManagerBlacklist[spellID] = false
                    end
                    refreshList()
                    BBF.ResetCooldownManagerIcons()
                    BBF.RefreshCooldownManagerIcons()
                end)

                button.slider:SetScript("OnValueChanged", function(self, value)
                    local v = math.floor(value + 0.5)
                    self:SetValue(v)
                    button.sliderText:SetText(v)

                    if v == 0 then
                        BetterBlizzFramesDB.cdManagerPriorityList[spellID] = nil
                        self:SetAlpha(0.3)
                    else
                        BetterBlizzFramesDB.cdManagerPriorityList[spellID] = v
                        self:SetAlpha(1)
                    end

                    BBF.RefreshCooldownManagerIcons()
                end)

                if isCustom then
                    button.del:SetScript("OnClick", function()
                        BetterBlizzFramesDB.cdManagerBlacklist[spellID] = nil
                        BetterBlizzFramesDB.cdManagerPriorityList[spellID] = nil
                        refreshList()
                        BBF.RefreshCooldownManagerIcons()
                    end)
                    button.del:Show()
                else
                    button.del:Hide()
                end

                button.bg:SetColorTexture(0.2, 0.2, 0.2, i % 2 == 0 and 0.1 or 0.3)
                button:Show()
            end
        end

        local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        input:SetSize(width-50, 20)
        input:SetPoint("TOPLEFT", scrollFrame, "BOTTOMLEFT", 15, -8)
        input:SetAutoFocus(false)
        CreateTooltipTwo(input, "Enter Spell ID", "Enter spell ID for Buffs you want to adjust.", "(Buffs cannot be fetched automatically)", "ANCHOR_TOP")

        function BBF.AddCDManagerSpellEntry(inputText, refreshList)
            if not inputText or inputText == "" then return end

            local id = tonumber(inputText)
            local info = C_Spell.GetSpellInfo(id or inputText)

            if info and info.spellID then
                local spellID = info.spellID
                if not BetterBlizzFramesDB.cdManagerPriorityList[spellID] and not BetterBlizzFramesDB.cdManagerBlacklist[spellID] then
                    BetterBlizzFramesDB.cdManagerBlacklist[spellID] = false
                    refreshList()
                    BBF.RefreshCooldownManagerIcons()
                end
            elseif not id then -- if it's not a number and didn't resolve to a spell, treat it as a raw name
                if not BetterBlizzFramesDB.cdManagerPriorityList[inputText] and not BetterBlizzFramesDB.cdManagerBlacklist[inputText] then
                    BetterBlizzFramesDB.cdManagerBlacklist[inputText] = false
                    refreshList()
                    BBF.RefreshCooldownManagerIcons()
                end
            else
                print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Invalid Spell ID: " .. inputText)
            end
        end

        input:SetScript("OnEnterPressed", function(self)
            BBF.AddCDManagerSpellEntry(self:GetText(), refreshList)
            self:SetText("")
        end)

        local add = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        add:SetSize(50, 22)
        add:SetText("Add")
        add:SetPoint("LEFT", input, "RIGHT", 6, 0)

        add:SetScript("OnClick", function()
            BBF.AddCDManagerSpellEntry(input:GetText(), refreshList)
            input:SetText("")
        end)

        content:SetHeight(#fullList * 22)
    end

    scrollFrame:HookScript("OnShow", function()
        if BBF.cdManagerNeedsUpdate then
            refreshList()
        end
    end)

    scrollFrame.Refresh = refreshList
    BBF.RefreshCdManagerList = refreshList
    BBF.cdManagerScrollFrame = scrollFrame

    refreshList()
    return scrollFrame
end



local function CreateTitle(parent)
    local mainGuiAnchor = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor:SetPoint("TOPLEFT", 15, -15)
    mainGuiAnchor:SetText(" ")
    local addonNameText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    addonNameText:SetPoint("TOPLEFT", mainGuiAnchor, "TOPLEFT", -20, 47)
    addonNameText:SetText("BetterBlizzFrames")
    local addonNameIcon = parent:CreateTexture(nil, "ARTWORK")
    addonNameIcon:SetAtlas("gmchat-icon-blizz")
    addonNameIcon:SetSize(22, 22)
    addonNameIcon:SetPoint("LEFT", addonNameText, "RIGHT", -2, -1)
    local verNumber = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    verNumber:SetPoint("LEFT", addonNameText, "RIGHT", 25, 0)
    verNumber:SetText("v" .. BBF.VersionNumber)
end

local function CreateSearchFrame()
    local searchFrame = CreateFrame("Frame", "BBFSearchFrame", UIParent)
    searchFrame:SetSize(680, 610)
    searchFrame:SetPoint("CENTER", UIParent, "CENTER")
    searchFrame:SetFrameStrata("HIGH")
    searchFrame:Hide()

    local wipText = searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    wipText:SetPoint("BOTTOM", searchFrame, "BOTTOM", -10, 10)
    wipText:SetText("Search is not complete and is WIP.")

    CreateTitle(searchFrame)

    local bgImg = searchFrame:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", searchFrame, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0, 0, 0)

    local settingsText = searchFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    settingsText:SetPoint("TOPLEFT", searchFrame, "TOPLEFT", 20, 0)
    settingsText:SetText("Search results:")

    -- Icon next to the title
    local searchIcon = searchFrame:CreateTexture(nil, "ARTWORK")
    searchIcon:SetAtlas("communities-icon-searchmagnifyingglass")
    searchIcon:SetSize(28, 28)
    searchIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)

    -- Reference the existing SettingsPanel.SearchBox to copy properties
    local referenceBox = SettingsPanel.SearchBox

    -- Create the search input field on top of SettingsPanel.SearchBox
    local searchBox = CreateFrame("EditBox", nil, SettingsPanel, "InputBoxTemplate")
    searchBox:SetSize(referenceBox:GetWidth() + 1, referenceBox:GetHeight() + 1)
    searchBox:SetPoint("CENTER", referenceBox, "CENTER")
    searchBox:SetFrameStrata("HIGH")
    searchBox:SetAutoFocus(false)
    searchBox.Left:Hide()
    searchBox.Right:Hide()
    searchBox.Middle:Hide()
    searchBox:SetFontObject(referenceBox:GetFontObject())
    searchBox:SetTextInsets(16, 8, 0, 0)
    searchBox:Hide()
    searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    CreateTooltipTwo(searchBox, "Search |A:shop-games-magnifyingglass:17:17|a", "You can now search for settings in BetterBlizzFrames. (WIP)", nil, "TOP")

    local resultsList = CreateFrame("Frame", nil, searchFrame)
    resultsList:SetSize(640, 500)
    resultsList:SetPoint("TOP", settingsText, "BOTTOM", 0, -10)

    local checkboxPool = {}
    local sliderPool = {}

    local function SearchElements(query)
        for _, child in ipairs({resultsList:GetChildren()}) do
            child:Hide()
        end

        if query == "" then
            return
        end

        -- Convert the query into lowercase and split it into individual words
        query = string.lower(query)
        local queryWords = { strsplit(" ", query) }

        local checkboxCount = 0
        local sliderCount = 0
        local yOffsetCheckbox = -20  -- Starting position for the first checkbox
        local yOffsetSlider = -20    -- Starting position for the first slider

        -- Helper function to check if all query words are in the label
        local function matchesQuery(label)
            label = string.lower(label)
            for _, queryWord in ipairs(queryWords) do
                if not string.find(label, queryWord) then
                    return false
                end
            end
            return true
        end

        local function applyRightClickScript(searchCheckbox, originalCheckbox)
            local originalScript = originalCheckbox:GetScript("OnMouseDown")
            if originalScript then
                searchCheckbox:SetScript("OnMouseDown", function(self, button)
                    if button == "RightButton" then
                        originalScript(originalCheckbox, button)
                    end
                end)
            end
        end

        -- Search through checkboxes
        for _, data in ipairs(checkBoxList) do
            if checkboxCount >= 20 then break end

            -- Prepare the label and tooltip text
            local label = string.lower(data.label or "")
            local tooltipTitle = string.lower(data.checkbox.tooltipTitle or "")
            local tooltipMainText = string.lower(data.checkbox.tooltipMainText or "")
            local tooltipSubText = string.lower(data.checkbox.tooltipSubText or "")
            local tooltipCVarName = string.lower(data.checkbox.tooltipCVarName or "")

            -- Check if all query words are found in any of the searchable fields
            if matchesQuery(label) or matchesQuery(tooltipTitle) or matchesQuery(tooltipMainText) or matchesQuery(tooltipSubText) or matchesQuery(tooltipCVarName) then
                checkboxCount = checkboxCount + 1

                -- Re-use or create a new checkbox from the pool
                local resultCheckBox = checkboxPool[checkboxCount]
                if not resultCheckBox then
                    resultCheckBox = CreateFrame("CheckButton", nil, resultsList, "InterfaceOptionsCheckButtonTemplate")
                    resultCheckBox:SetSize(23, 23)
                    resultCheckBox.Text:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 12)
                    checkboxPool[checkboxCount] = resultCheckBox
                end

                -- Update checkbox properties and position
                resultCheckBox:ClearAllPoints()
                resultCheckBox:SetPoint("TOPLEFT", searchIcon, "TOPLEFT", 27, yOffsetCheckbox)
                resultCheckBox.Text:SetText(data.label)
                if not data.label or data.label == "" then
                    resultCheckBox.Text:SetText(data.checkbox.tooltipTitle)
                end
                resultCheckBox:SetChecked(data.checkbox:GetChecked())

                -- Link the result checkbox to the main checkbox
                resultCheckBox:SetScript("OnClick", function()
                    data.checkbox:Click()
                end)

                applyRightClickScript(resultCheckBox, data.checkbox)

                -- Reapply tooltip
                if data.checkbox.tooltipMainText then
                    CreateTooltipTwo(resultCheckBox, data.checkbox.tooltipTitle, data.checkbox.tooltipMainText, data.checkbox.tooltipSubText, nil, data.checkbox.tooltipCVarName, nil, data.checkbox.searchCategory)
                elseif data.checkbox.tooltipTitle then
                    CreateTooltipTwo(resultCheckBox, data.checkbox.tooltipTitle, nil, nil, nil, nil, nil, data.checkbox.searchCategory)
                else
                    CreateTooltipTwo(resultCheckBox, "No data yet WIP", nil, nil, nil, nil, nil, data.checkbox.searchCategory)
                end

                resultCheckBox:Show()

                -- Move down for the next checkbox
                yOffsetCheckbox = yOffsetCheckbox - 24
            end
        end

        -- Search through sliders
        for _, data in ipairs(sliderList) do
            if sliderCount >= 13 then break end

            -- Prepare the label and tooltip text
            local label = string.lower(data.label or "")
            local tooltipTitle = string.lower(data.slider.tooltipTitle or "")
            local tooltipMainText = string.lower(data.slider.tooltipMainText or "")
            local tooltipSubText = string.lower(data.slider.tooltipSubText or "")
            local tooltipCVarName = string.lower(data.slider.tooltipCVarName or "")

            -- Check if all query words are found in any of the searchable fields
            if matchesQuery(label) or matchesQuery(tooltipTitle) or matchesQuery(tooltipMainText) or matchesQuery(tooltipSubText) or matchesQuery(tooltipCVarName) then
                sliderCount = sliderCount + 1

                -- Re-use or create a new slider from the slider pool
                local resultSlider = sliderPool[sliderCount]
                if not resultSlider then
                    resultSlider = CreateFrame("Slider", nil, resultsList, "OptionsSliderTemplate")
                    resultSlider:SetOrientation('HORIZONTAL')
                    resultSlider:SetValueStep(data.slider:GetValueStep())
                    resultSlider:SetObeyStepOnDrag(true)
                    resultSlider.Text = resultSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    resultSlider.Text:SetTextColor(1, 0.81, 0, 1)
                    resultSlider.Text:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 11)
                    resultSlider.Text:SetPoint("TOP", resultSlider, "BOTTOM", 0, -1)
                    resultSlider.Low:SetText(" ")
                    resultSlider.High:SetText(" ")
                    sliderPool[sliderCount] = resultSlider
                end

                -- Format the slider text value
                local function formatSliderValue(value)
                    return value % 1 == 0 and tostring(math.floor(value)) or string.format("%.2f", value)
                end

                -- Update slider properties and position
                resultSlider:ClearAllPoints()
                resultSlider:SetPoint("TOPLEFT", searchIcon, "TOPLEFT", 277, yOffsetSlider)
                resultSlider:SetScript("OnValueChanged", nil)
                resultSlider:SetMinMaxValues(data.slider:GetMinMaxValues())
                resultSlider:SetValue(data.slider:GetValue())
                resultSlider.Text:SetText(data.label .. ": " .. formatSliderValue(data.slider:GetValue()))

                resultSlider:SetScript("OnValueChanged", function(self, value)
                    data.slider:SetValue(value) -- Trigger the original slider's script
                    resultSlider.Text:SetText(data.label .. ": " .. formatSliderValue(value))
                end)

                -- Tooltip setup for sliders
                if data.slider.tooltipMainText then
                    CreateTooltipTwo(resultSlider, data.slider.tooltipTitle, data.slider.tooltipMainText, data.slider.tooltipSubText, nil, data.slider.tooltipCVarName, nil, data.slider.searchCategory)
                elseif data.slider.tooltipTitle then
                    CreateTooltipTwo(resultSlider, data.slider.tooltipTitle, nil, nil, nil, nil, nil, data.slider.searchCategory)
                else
                    CreateTooltipTwo(resultSlider, "No data yet WIP", nil, nil, nil, nil, nil, data.slider.searchCategory)
                end

                -- Show the slider and prepare for the next slider
                resultSlider:Show()
                yOffsetSlider = yOffsetSlider - 42
            end
        end
    end

    searchBox:SetScript("OnTextChanged", function(self)
        local query = self:GetText()
        if #query > 0 then
            SettingsPanelSearchIcon:SetVertexColor(1, 1, 1)
            SettingsPanel.SearchBox.Instructions:SetAlpha(0)
            searchFrame:Show()
            if SettingsPanel.currentLayout and SettingsPanel.currentLayout.frame then
                SettingsPanel.currentLayout.frame:Hide()
            end
        else
            SettingsPanelSearchIcon:SetVertexColor(0.6, 0.6, 0.6)
            SettingsPanel.SearchBox.Instructions:SetAlpha(1)
            searchFrame:Hide()
            if SettingsPanel.currentLayout and SettingsPanel.currentLayout.frame then
                SettingsPanel.currentLayout.frame:Show()
            end
        end
        if #query >= 1 then
            SearchElements(query)
        else
            SearchElements("")
        end

        if not searchBox.hookedSettings then
            SettingsPanel:HookScript("OnHide", function()
                SettingsPanelSearchIcon:SetVertexColor(0.6, 0.6, 0.6)
                SettingsPanel.SearchBox.Instructions:SetAlpha(1)
                searchFrame:Hide()
                searchBox:Hide()
                if SettingsPanel.currentLayout and SettingsPanel.currentLayout.frame then
                    searchBox:SetText("")
                    SettingsPanel.currentLayout.frame:Show()
                end
            end)
            searchBox.hookedSettings = true
        end
    end)

    hooksecurefunc(SettingsPanel, "DisplayLayout", function()
        if SettingsPanel.currentLayout.frame and SettingsPanel.currentLayout.frame.name == "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a" or
        (SettingsPanel.currentLayout.frame and SettingsPanel.currentLayout.frame.parent == "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a") then
            SettingsPanel.SearchBox.Instructions:SetText("Search in BetterBlizzFrames")
            searchBox:Show()
            searchBox:SetText("")
            searchFrame:Hide()
            searchFrame:ClearAllPoints()
            searchFrame:SetPoint("TOPLEFT", SettingsPanel.currentLayout.frame, "TOPLEFT")
            searchFrame:SetPoint("BOTTOMRIGHT", SettingsPanel.currentLayout.frame, "BOTTOMRIGHT")
            if not SettingsPanel.currentLayout.frame:IsShown() then
                SettingsPanel.currentLayout.frame:Show()
            end
        else
            if SettingsPanel.SearchBox.Instructions:GetText() == "Search in BetterBlizzFrames" then
                SettingsPanel.SearchBox.Instructions:SetText("Search")
            end
            searchBox:Hide()
            searchFrame:Hide()
        end
    end)
end

------------------------------------------------------------
-- GUI Panels
------------------------------------------------------------
local function guiGeneralTab()
    ----------------------
    -- Main panel:
    ----------------------
    local mainGuiAnchor = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor:SetPoint("TOPLEFT", 15, -15)
    mainGuiAnchor:SetText(" ")

    BetterBlizzFrames.searchName = "General"

    local bgImg = BetterBlizzFrames:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", BetterBlizzFrames, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local newSearch = BetterBlizzFrames:CreateTexture(nil, "BACKGROUND")
    newSearch:SetAtlas("NewCharacter-Horde", true)
    newSearch:SetPoint("BOTTOM", BetterBlizzFrames, "TOP", -70, 2)
    CreateTooltipTwo(newSearch, "Search |A:shop-games-magnifyingglass:17:17|a", "You can now search for settings in BetterBlizzFrames. (WIP)")

    local newSearchPoint = BetterBlizzFrames:CreateTexture(nil, "BACKGROUND")
    newSearchPoint:SetAtlas("auctionhouse-icon-buyallarrow", true)
    newSearchPoint:SetPoint("LEFT", newSearch, "RIGHT", -25, 0)
    newSearchPoint:SetRotation(math.pi / 2)

    CreateSearchFrame()
    -- local addonNameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    -- addonNameText:SetPoint("TOPLEFT", mainGuiAnchor, "TOPLEFT", -20, 47)
    -- addonNameText:SetText("BetterBlizzFrames")
    -- local addonNameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    -- addonNameIcon:SetAtlas("gmchat-icon-blizz")
    -- addonNameIcon:SetSize(22, 22)
    -- addonNameIcon:SetPoint("LEFT", addonNameText, "RIGHT", -2, -1)
    -- local verNumber = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- verNumber:SetPoint("LEFT", addonNameText, "RIGHT", 25, 0)
    -- verNumber:SetText("v" .. BBF.VersionNumber)
    CreateTitle(BetterBlizzFrames)

    ----------------------
    -- General:
    ----------------------
    -- "General:" text
    local settingsText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 0, 30)
    settingsText:SetText("General settings")
    settingsText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    settingsText:SetTextColor(1,1,1)
    local generalSettingsIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    generalSettingsIcon:SetAtlas("optionsicon-brown")
    generalSettingsIcon:SetSize(22, 22)
    generalSettingsIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)


    if BetterBlizzFrames.titleText then
        BetterBlizzFrames.titleText:Hide()
        BetterBlizzFrames.loadGUI:Hide()
    end



    local hideArenaFrames = CreateCheckbox("hideArenaFrames", "Hide Arena Frames", BetterBlizzFrames, nil, BBF.HideArenaFrames)
    hideArenaFrames:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    hideArenaFrames:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(hideArenaFrames, "Hide the standard Blizzard Arena Frames.\nThis uses the same code as the addon\n\"Arena Anti-Malware\", also made by me.")

    local hideBossFrames = CreateCheckbox("hideBossFrames", "Hide Boss Frames", BetterBlizzFrames, nil, BBF.HideArenaFrames)
    hideBossFrames:SetPoint("TOPLEFT", hideArenaFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideBossFrames, "Hide the Blizzard Boss Frames that are underneath the minimap.")

    local hideBossFramesParty = CreateCheckbox("hideBossFramesParty", "Party", BetterBlizzFrames, nil, BBF.HideArenaFrames)
    hideBossFramesParty:SetPoint("LEFT", hideBossFrames.text, "RIGHT", 0, 0)
    CreateTooltip(hideBossFramesParty, "Hide Boss Frames in Party", "ANCHOR_LEFT")

    local hideBossFramesRaid = CreateCheckbox("hideBossFramesRaid", "Raid", BetterBlizzFrames, nil, BBF.HideArenaFrames)
    hideBossFramesRaid:SetPoint("LEFT", hideBossFramesParty.text, "RIGHT", 0, 0)
    CreateTooltip(hideBossFramesRaid, "Hide Boss Frames in Raid", "ANCHOR_LEFT")

    hideBossFrames:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.overShieldsCompact = true
            BetterBlizzFramesDB.hideBossFramesParty = true
            hideBossFramesParty:SetAlpha(1)
            hideBossFramesParty:Enable()
            hideBossFramesParty:SetChecked(true)
            hideBossFramesRaid:SetAlpha(1)
            hideBossFramesRaid:Enable()
            hideBossFramesRaid:SetChecked(true)
        else
            BetterBlizzFramesDB.overShieldsCompact = false
            BetterBlizzFramesDB.hideBossFramesParty = false
            hideBossFramesParty:SetAlpha(0)
            hideBossFramesParty:Disable()
            hideBossFramesParty:SetChecked(false)
            hideBossFramesRaid:SetAlpha(0)
            hideBossFramesRaid:Disable()
            hideBossFramesRaid:SetChecked(false)
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    if not BetterBlizzFramesDB.hideBossFrames then
        hideBossFramesParty:SetAlpha(0)
        hideBossFramesParty:Disable()
        hideBossFramesRaid:SetAlpha(0)
        hideBossFramesRaid:Disable()
    end

    local playerFrameOCD = CreateCheckbox("playerFrameOCD", "OCD Tweaks", BetterBlizzFrames, nil, BBF.FixStupidBlizzPTRShit)
    playerFrameOCD:SetPoint("TOPLEFT", hideBossFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(playerFrameOCD, "Removes small gap around player portrait, healthbars and manabars, etc.\nJust in general tiny OCD fixes on a few things. Requires a reload for full effect.\nTemporary setting I might remove if blizz fixes their stuff.")

    -- local playerFrameOCDTextureBypass = CreateCheckbox("playerFrameOCDTextureBypass", "OCD: Skip Bars", BetterBlizzFrames, nil, BBF.HideFrames)
    -- playerFrameOCDTextureBypass:SetPoint("LEFT", playerFrameOCD.text, "RIGHT", 0, 0)
    -- CreateTooltip(playerFrameOCDTextureBypass, "If healthbars & manabars look weird enable this to skip\nadjusting them and only fix portraits + reputation color")

    playerFrameOCD:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    -- if not BetterBlizzFramesDB.playerFrameOCD then
    --     playerFrameOCDTextureBypass:Disable()
    --     playerFrameOCDTextureBypass:SetAlpha(0)
    -- end

    local hideLossOfControlFrameBg = CreateCheckbox("hideLossOfControlFrameBg", "Hide CC Background", BetterBlizzFrames, nil, BBF.HideFrames)
    hideLossOfControlFrameBg:SetPoint("TOPLEFT", playerFrameOCD, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideLossOfControlFrameBg, "Hide the dark background on the LossOfControl frame (displaying CC on you)")
    hideLossOfControlFrameBg:HookScript("OnClick", function()
        BBF.ToggleLossOfControlTestMode()
    end)

    local hideLossOfControlFrameLines = CreateCheckbox("hideLossOfControlFrameLines", "Hide CC Red-lines", BetterBlizzFrames, nil, BBF.HideFrames)
    hideLossOfControlFrameLines:SetPoint("TOPLEFT", hideLossOfControlFrameBg, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideLossOfControlFrameLines, "Hide the red lines on top and bottom of the LossOfControl frame (displaying CC on you)")
    hideLossOfControlFrameLines:HookScript("OnClick", function()
        BBF.ToggleLossOfControlTestMode()
    end)

    local lossOfControlScale = CreateSlider(BetterBlizzFrames, "CC Scale", 0.4, 1.4, 0.01, "lossOfControlScale", nil, 90)
    lossOfControlScale:SetPoint("LEFT", hideLossOfControlFrameBg.text, "RIGHT", 3, -16)
    CreateTooltipTwo(lossOfControlScale, "Loss of Control Scale", "Adjust the scale of the LossOfControlFrame\n(displaying cc on you center screen)")

    local darkModeUi = CreateCheckbox("darkModeUi", "Dark Mode", BetterBlizzFrames)
    darkModeUi:SetPoint("TOPLEFT", hideLossOfControlFrameLines, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeUi:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeUi, "Simple dark mode for: UnitFrames, Actionbars & Aura Icons.\n\nIf you want a more advanced & thorough dark mode\nI recommend the addon FrameColor instead of this setting.")

    local darkModeActionBars = CreateCheckbox("darkModeActionBars", "ActionBars", darkModeUi)
    darkModeActionBars:SetPoint("TOPLEFT", darkModeUi, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeActionBars:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeActionBars, "Dark borders for action bars.")

    local darkModeMinimap = CreateCheckbox("darkModeMinimap", "Minimap", darkModeUi)
    darkModeMinimap:SetPoint("TOPLEFT", darkModeActionBars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeMinimap:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeMinimap, "Dark mode for Minimap")

    local darkModeCastbars = CreateCheckbox("darkModeCastbars", "Castbars", darkModeUi)
    darkModeCastbars:SetPoint("LEFT", darkModeUi.Text, "RIGHT", 5, 0)
    darkModeCastbars:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeCastbars, "Dark borders for castbars.")

    local darkModeUiAura = CreateCheckbox("darkModeUiAura", "Auras", darkModeUi)
    darkModeUiAura:SetPoint("TOPLEFT", darkModeCastbars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeUiAura:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeUiAura, "Dark borders for Player, Target and Focus aura icons")

    local darkModeNameplateResource = CreateCheckbox("darkModeNameplateResource", "Nameplate Resource", darkModeUi)
    darkModeNameplateResource:SetPoint("TOPLEFT", darkModeUiAura, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeNameplateResource:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltip(darkModeNameplateResource, "Dark mode for nameplate resource (Combopoints etc)\n\n(If you are using this same feature in BBP\nthat one will be prioritized)")

    local darkModeGameTooltip = CreateCheckbox("darkModeGameTooltip", "Tooltip", darkModeUi)
    darkModeGameTooltip:SetPoint("TOPLEFT", darkModeMinimap, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeGameTooltip:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltipTwo(darkModeGameTooltip, "Dark Mode: Tooltip", "Dark mode for the Game Tooltip.")

    local darkModeEliteTexture = CreateCheckbox("darkModeEliteTexture", "Elite Texture", darkModeUi)
    darkModeEliteTexture:SetPoint("TOPLEFT", darkModeGameTooltip, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    darkModeEliteTexture:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltipTwo(darkModeEliteTexture, "Dark Mode: Elite Texture", "Dark mode for the Elite Texture on Target/FocusFrame.\n\n|cff32f795Right-click to toggle desaturation on/off.|r")
    darkModeEliteTexture:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if not BetterBlizzFramesDB.darkModeEliteTextureDesaturated then
                BetterBlizzFramesDB.darkModeEliteTextureDesaturated = true
            else
                BetterBlizzFramesDB.darkModeEliteTextureDesaturated = nil
            end
            BBF.DarkmodeFrames(true)
        end
    end)

    local darkModeObjectiveFrame = CreateCheckbox("darkModeObjectiveFrame", "Objectives", darkModeUi)
    darkModeObjectiveFrame:SetPoint("LEFT", darkModeGameTooltip.Text, "RIGHT", 5, 0)
    darkModeObjectiveFrame:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltipTwo(darkModeObjectiveFrame, "Dark Mode: Objectives", "Dark mode for Objectives/Quest Tracker")

    local darkModeVigor = CreateCheckbox("darkModeVigor", "Vigor", darkModeUi)
    darkModeVigor:SetPoint("LEFT", darkModeObjectiveFrame.Text, "RIGHT", 5, 0)
    darkModeVigor:HookScript("OnClick", function()
        BBF.DarkmodeFrames(true)
    end)
    CreateTooltipTwo(darkModeVigor, "Dark Mode: Vigor", "Dark mode for flying mount Vigor charges")

    local darkModeColor = CreateSlider(darkModeUi, "Darkness", 0, 1, 0.01, "darkModeColor", nil, 90)
    darkModeColor:SetPoint("LEFT", darkModeUiAura.text, "RIGHT", 3, -1)
    CreateTooltipTwo(darkModeColor, "Dark Mode Value", "Adjust how dark you want the dark mode to be.\nTip: You can rightclick all sliders to input a specific value.")

    darkModeUi:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(darkModeUi, 0)
    end)
    if not BetterBlizzFramesDB.darkModeUi then
        CheckAndToggleCheckboxes(darkModeUi, 0)
    end










    local playerFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    playerFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 0, -173)
    playerFrameText:SetText("Player Frame")
    playerFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    playerFrameText:SetTextColor(1,1,1)
    local playerFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    playerFrameIcon:SetAtlas("groupfinder-icon-friend")
    playerFrameIcon:SetSize(28, 28)
    playerFrameIcon:SetPoint("RIGHT", playerFrameText, "LEFT", -0.5, 0)

    local playerFrameClickthrough = CreateCheckbox("playerFrameClickthrough", "Clickthrough", BetterBlizzFrames, nil, BBF.ClickthroughFrames)
    playerFrameClickthrough:SetPoint("TOPLEFT", playerFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(playerFrameClickthrough, "Makes the PlayerFrame clickthrough.\nYou can still hold shift to left/right click it\nwhile out of combat for trade/inspect etc.\n\nNOTE: You will NOT be able to click the frame\nat all during combat with this setting on.")
    playerFrameClickthrough:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local textures = BetterBlizzFramesDB.classicFrames and 7 or 4
    local extraText = "\n\n|cffc084f7Shift + Right-click to allow Dark Mode to color Elite Texture.|r"
    local playerEliteFrame = CreateCheckbox("playerEliteFrame", "Elite Texture", BetterBlizzFrames)
    playerEliteFrame:SetPoint("LEFT", playerFrameClickthrough.text, "RIGHT", 5, 0)
    playerEliteFrame:HookScript("OnClick", function(self)
        BBF.PlayerElite(BetterBlizzFramesDB.playerEliteFrameMode)
    end)
    playerEliteFrame:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" and IsShiftKeyDown() then
            if not BetterBlizzFramesDB.playerEliteFrameDarkmode then
                BetterBlizzFramesDB.playerEliteFrameDarkmode = true
            else
                BetterBlizzFramesDB.playerEliteFrameDarkmode = nil
            end
            BBF.PlayerElite(BetterBlizzFramesDB["playerEliteFrameMode"])
        elseif button == "RightButton" then
            BetterBlizzFramesDB["playerEliteFrameMode"] = BetterBlizzFramesDB["playerEliteFrameMode"] % textures + 1
            BBF.PlayerElite(BetterBlizzFramesDB["playerEliteFrameMode"])
        end
    end)
    CreateTooltipTwo(playerEliteFrame, "Show Elite Texture", "Show elite dragon around PlayerFrame.\n\n|cff32f795Right-click to swap between the "..textures.." different textures available.|r"..extraText)

    local playerReputationColor = CreateCheckbox("playerReputationColor", "Add Reputation Color", BetterBlizzFrames, nil, BBF.PlayerReputationColor)
    playerReputationColor:SetPoint("TOPLEFT", playerFrameClickthrough, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(playerReputationColor, "Add reputation color behind name like on Target & Focus.|A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a\nCan be class colored as well.")

    local playerReputationClassColor = CreateCheckbox("playerReputationClassColor", "Class color", BetterBlizzFrames, nil, BBF.PlayerReputationColor)
    playerReputationClassColor:SetPoint("LEFT", playerReputationColor.text, "RIGHT", 5, 0)
    CreateTooltip(playerReputationClassColor, "Class color the Player reputation texture.")
    playerReputationColor:HookScript("OnClick", function(self)
        if self:GetChecked() then
            playerReputationClassColor:Enable()
            playerReputationClassColor:SetAlpha(1)
        else
            playerReputationClassColor:Disable()
            playerReputationClassColor:SetAlpha(0)
        end
    end)
    if not BetterBlizzFramesDB.playerReputationColor then
        playerReputationClassColor:SetAlpha(0)
        playerReputationClassColor:Disable()
    end

    local hidePlayerName = CreateCheckbox("hidePlayerName", "Hide Name", BetterBlizzFrames, nil, BBF.UpdateNameSettings)
    hidePlayerName:SetPoint("TOPLEFT", playerReputationColor, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    hidePlayerName:HookScript("OnClick", function(self)
        -- if self:GetChecked() then
        --     PlayerFrame.name:SetAlpha(0)
        --     if PlayerFrame.bbfName then
        --         PlayerFrame.bbfName:SetAlpha(0)
        --     end
        -- else
        --     PlayerFrame.name:SetAlpha(0)
        --     if PlayerFrame.bbfName then
        --         PlayerFrame.bbfName:SetAlpha(1)
        --     else
        --         PlayerFrame.name:SetAlpha(1)
        --     end
        -- end
        BBF.SetCenteredNamesCaller()
    end)

    local symmetricPlayerFrame = CreateCheckbox("symmetricPlayerFrame", "Mirror TargetFrame", BetterBlizzFrames, nil, BBF.SymmetricPlayerFrame)
    symmetricPlayerFrame:SetPoint("LEFT", hidePlayerName.text, "RIGHT", 0, 0)
    CreateTooltipTwo(symmetricPlayerFrame, "Mirror TargetFrame", "Make the PlayerFrame texture a mirrored version of TargetFrame (round circle etc).\n\n|cfffc8312EXPERIMENTAL:|r\nCan cause glitches/taint on certain updates (Vehicles/PvE/?).\nIf you decide to use this understand the potential risk and please report issues. (WIP)\n\n|cff32f795Toggle on/off with right-click.|r")
    -- symmetricPlayerFrame:HookScript("OnClick", function(self)
    --     if not self:GetChecked() then
    --         StaticPopup_Show("BBF_CONFIRM_RELOAD")
    --         BetterBlizzFramesDB.playerFrameOCD = nil
    --     end
    -- end)
    symmetricPlayerFrame:SetScript("OnClick", function(self)
        self:SetChecked(BetterBlizzFramesDB.symmetricPlayerFrame or false)
    end)

    symmetricPlayerFrame:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            if BetterBlizzFramesDB.symmetricPlayerFrame then
                BetterBlizzFramesDB.symmetricPlayerFrame = nil
                symmetricPlayerFrame:SetChecked(false)
                return
            end
            symmetricPlayerFrame:SetChecked(true)
            BetterBlizzFramesDB.symmetricPlayerFrame = true
        end
    end)

    -- local hidePlayerMaxHpReduction = CreateCheckbox("hidePlayerMaxHpReduction", "Hide Reduced HP", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hidePlayerMaxHpReduction:SetPoint("LEFT", hidePlayerName.text, "RIGHT", 0, 0)
    -- CreateTooltipTwo(hidePlayerMaxHpReduction, "Hide Reduced HP", "Hide the new max health loss indication introduced in TWW from PlayerFrame.")

    local hidePlayerPower = CreateCheckbox("hidePlayerPower", "Hide Resource/Power", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerPower:SetPoint("TOPLEFT", hidePlayerName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePlayerPower, "Hide Resource/Power", "Hide Resource/Power under PlayerFrame. Rogue combopoints, Warlock shards etc.\n\n|cff32f795Right-click for class specific options.|r")

    local classOptionsFrame
    local function OpenClassSpecificWindow()
        if not classOptionsFrame then
            classOptionsFrame = CreateFrame("Frame", "ClassOptionsFrame", UIParent, "BasicFrameTemplateWithInset")
            classOptionsFrame:SetSize(185, 210)
            classOptionsFrame:SetPoint("CENTER")
            classOptionsFrame:SetFrameStrata("DIALOG")
            classOptionsFrame:SetMovable(true)
            classOptionsFrame:EnableMouse(true)
            classOptionsFrame:RegisterForDrag("LeftButton")
            classOptionsFrame:SetScript("OnDragStart", classOptionsFrame.StartMoving)
            classOptionsFrame:SetScript("OnDragStop", classOptionsFrame.StopMovingOrSizing)
            classOptionsFrame.title = classOptionsFrame:CreateFontString(nil, "OVERLAY")
            classOptionsFrame.title:SetFontObject("GameFontHighlight")
            classOptionsFrame.title:SetPoint("LEFT", classOptionsFrame.TitleBg, "LEFT", 5, 0)
            classOptionsFrame.title:SetText("Class Specific Options")

            local classes = {
                { class = "Druid", var = "hidePlayerPowerNoDruid", color = RAID_CLASS_COLORS["DRUID"] },
                { class = "Rogue", var = "hidePlayerPowerNoRogue", color = RAID_CLASS_COLORS["ROGUE"] },
                { class = "Warlock", var = "hidePlayerPowerNoWarlock", color = RAID_CLASS_COLORS["WARLOCK"] },
                { class = "Paladin", var = "hidePlayerPowerNoPaladin", color = RAID_CLASS_COLORS["PALADIN"] },
                { class = "Death Knight", var = "hidePlayerPowerNoDeathKnight", color = RAID_CLASS_COLORS["DEATHKNIGHT"] },
                { class = "Evoker", var = "hidePlayerPowerNoEvoker", color = RAID_CLASS_COLORS["EVOKER"] },
                { class = "Monk", var = "hidePlayerPowerNoMonk", color = RAID_CLASS_COLORS["MONK"] },
                { class = "Mage", var = "hidePlayerPowerNoMage", color = RAID_CLASS_COLORS["MAGE"] },
            }

            local previousCheckbox
            for i, classData in ipairs(classes) do
                local classCheckbox = CreateFrame("CheckButton", nil, classOptionsFrame, "UICheckButtonTemplate")
                classCheckbox:SetSize(24, 24)
                classCheckbox.Text:SetText("Ignore " .. classData.class)

                -- Set the color of the checkbox label to the class color
                local r, g, b = classData.color.r, classData.color.g, classData.color.b
                classCheckbox.Text:SetTextColor(r, g, b)

                -- Position the checkboxes
                if i == 1 then
                    classCheckbox:SetPoint("TOPLEFT", classOptionsFrame, "TOPLEFT", 10, -30)
                else
                    classCheckbox:SetPoint("TOPLEFT", previousCheckbox, "BOTTOMLEFT", 0, 3)
                end

                -- Set the state from the DB
                classCheckbox:SetChecked(BetterBlizzFramesDB[classData.var])

                -- Save the state back to the DB when toggled
                classCheckbox:SetScript("OnClick", function(self)
                    BetterBlizzFramesDB[classData.var] = self:GetChecked() or nil
                    BBF.HideFrames()
                end)

                previousCheckbox = classCheckbox
            end
            classOptionsFrame:Show()
        else
            -- Toggle visibility of the frame when the function is called
            if classOptionsFrame:IsShown() then
                classOptionsFrame:Hide()
            else
                classOptionsFrame:Show()
            end
        end
    end

    hidePlayerPower:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenClassSpecificWindow()
        end
    end)

    local hideResourceTooltip = CreateCheckbox("hideResourceTooltip", "Hide Resource Tooltip", BetterBlizzFrames, nil, BBF.HideClassResourceTooltip)
    hideResourceTooltip:SetPoint("TOPLEFT", hidePlayerPower, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideResourceTooltip, "Hide Resource Tooltip", "Hide Resource Mouseover Tooltip.")

    local hideManaFeedback = CreateCheckbox("hideManaFeedback", "Hide Mana Feedback", BetterBlizzFrames, nil, BBF.HideFrames)
    hideManaFeedback:SetPoint("TOPLEFT", hideResourceTooltip, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideManaFeedback, "Hide Mana Feedback", "Remove the manabar feedback animations for instant feedback on your mana/energy/rage etc.")

    local hidePlayerRestAnimation = CreateCheckbox("hidePlayerRestAnimation", "Hide \"Zzz\" Rest Animation", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerRestAnimation:SetPoint("TOPLEFT", hideManaFeedback, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerRestAnimation, "Hide the \"Zzz\" animation on PlayerFrame while rested.")

    local hidePlayerCornerIcon = CreateCheckbox("hidePlayerCornerIcon", "Hide Corner Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerCornerIcon:SetPoint("TOPLEFT", hidePlayerRestAnimation, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerCornerIcon, "Hide corner icon on PlayerFrame.|A:UI-HUD-UnitFrame-Player-PortraitOn-CornerEmbellishment:22:22|a\n")

    local hidePlayerHealthLossAnim = CreateCheckbox("hidePlayerHealthLossAnim", "Hide Health Loss FX", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerHealthLossAnim:SetPoint("LEFT", hidePlayerCornerIcon.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hidePlayerHealthLossAnim, "Hide Health Loss Animations", "Hide the red health loss animation on PlayerFrame and always see current HP properly.")

    local hidePlayerRestGlow = CreateCheckbox("hidePlayerRestGlow", "Hide Rest Glow", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerRestGlow:SetPoint("TOPLEFT", hidePlayerCornerIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerRestGlow, "Hide the flashing yellow rest glow animation around PlayerFrame while rested.|A:UI-HUD-UnitFrame-Player-PortraitOn-Status:30:80|a")

    local hideFullPower = CreateCheckbox("hideFullPower", "Hide Full Mana FX", BetterBlizzFrames, nil, BBF.HideFrames)
    hideFullPower:SetPoint("LEFT", hidePlayerRestGlow.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideFullPower, "Hide Full Mana Animations |A:FullAlert-FrameGlow:27:51|a", "Hide the flashing mana/energy animation on the right side of the manabar when its full.")

    local hideCombatIcon = CreateCheckbox("hideCombatIcon", "Hide Combat Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    hideCombatIcon:SetPoint("TOPLEFT", hidePlayerRestGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideCombatIcon, "Hide combat icon on in the bottom right corner of the PlayerFrame.|A:UI-HUD-UnitFrame-Player-CombatIcon:22:22|a\n")

    local hideHitIndicator = CreateCheckbox("hideHitIndicator", "Hide Hit Indicator", BetterBlizzFrames, nil, BBF.HideFrames)
    hideHitIndicator:SetPoint("LEFT", hideCombatIcon.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideHitIndicator, "Hide Hit Indicator", "Hide the Hit Indicator on PlayerFrame displaying damage/healing inc on Portrait.")

    local hideGroupIndicator = CreateCheckbox("hideGroupIndicator", "Hide Group Indicator", BetterBlizzFrames, nil, BBF.HideFrames)
    hideGroupIndicator:SetPoint("TOPLEFT", hideCombatIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideGroupIndicator, "Hide the group indicator on top of PlayerFrame\nwhile you are in a group.")

    local hideTotemFrame = CreateCheckbox("hideTotemFrame", "Hide Totem Frame", BetterBlizzFrames, nil, BBF.HideFrames)
    hideTotemFrame:SetPoint("LEFT", hideGroupIndicator.text, "RIGHT", 0, 0)
    CreateTooltip(hideTotemFrame, "Hide the TotemFrame under PlayerFrame.")

    local hidePlayerLeaderIcon = CreateCheckbox("hidePlayerLeaderIcon", "Hide Leader Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerLeaderIcon:SetPoint("TOPLEFT", hideGroupIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerLeaderIcon, "Hide the party leader icon from PlayerFrame.|A:UI-HUD-UnitFrame-Player-Group-LeaderIcon:22:22|a")

    local hidePlayerGuideIcon = CreateCheckbox("hidePlayerGuideIcon", "Hide Guide Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerGuideIcon:SetPoint("LEFT", hidePlayerLeaderIcon.text, "RIGHT", 0, 0)
    CreateTooltip(hidePlayerGuideIcon, "Hide the guide icon from PlayerFrame.|A:UI-HUD-UnitFrame-Player-Group-GuideIcon:22:22|a")

    local hidePlayerRoleIcon = CreateCheckbox("hidePlayerRoleIcon", "Hide Role Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePlayerRoleIcon:SetPoint("TOPLEFT", hidePlayerLeaderIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePlayerRoleIcon, "Hide the role icon from PlayerFrame|A:roleicon-tiny-dps:22:22|a")

    local hidePvpTimerText = CreateCheckbox("hidePvpTimerText", "Hide PvP Timer", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePvpTimerText:SetPoint("LEFT", hidePlayerRoleIcon.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hidePvpTimerText, "Hide PvP Timer", "Hide the PvP timer bottom left on PlayerFrame. This indicates the 5min timer when you will drop PvP tag. Maybe useful in back in 2004.")





    local petFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    petFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, -455)
    petFrameText:SetText("Pet Frame")
    petFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    petFrameText:SetTextColor(1,1,1)
    local petFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    petFrameIcon:SetAtlas("newplayerchat-chaticon-newcomer")
    petFrameIcon:SetSize(21, 21)
    petFrameIcon:SetPoint("RIGHT", petFrameText, "LEFT", -2, 0)

    local petCastbar = CreateCheckbox("petCastbar", "Pet Castbar", BetterBlizzFrames, nil, BBF.UpdatePetCastbar)
    petCastbar:SetPoint("TOPLEFT", petFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(petCastbar, "Show pet castbar.\n\nMore settings in the \"Castbars\" tab")

    local hidePetName = CreateCheckbox("hidePetName", "Hide Name", BetterBlizzFrames)
    hidePetName:SetPoint("TOPLEFT", petCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    hidePetName:HookScript("OnClick", function (self)
        BBF.AllNameChanges()
    end)
    CreateTooltipTwo(hidePetName, "Hide Pet Name", "Hide the pet name on PetFrame")

    local colorPetAfterOwner = CreateCheckbox("colorPetAfterOwner", "Color Pet After Player Class", BetterBlizzFrames)
    colorPetAfterOwner:SetPoint("TOPLEFT", hidePetName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    colorPetAfterOwner:HookScript("OnClick", function (self)
        BBF.UpdateFrames()
    end)

    local hidePetText = CreateCheckbox("hidePetText", "Hide Pet Statusbar Text", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePetText:SetPoint("TOPLEFT", colorPetAfterOwner, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePetText, "Hide Pet Statusbar Text", "Hide the health and mana text on PetFrame.")

    local hidePetHitIndicator = CreateCheckbox("hidePetHitIndicator", "Hide Hit Indicator", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePetHitIndicator:SetPoint("TOPLEFT", hidePetText, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePetHitIndicator, "Hide Pet Hit Indicator", "Hide the health loss/gain numbers on PetFrame Portrait.")

    local partyFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    partyFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 0, -427)
    partyFrameText:SetText("Party Frame")
    partyFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    partyFrameText:SetTextColor(1,1,1)
    local partyFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    partyFrameIcon:SetAtlas("groupfinder-icon-friend")
    partyFrameIcon:SetSize(25, 25)
    partyFrameIcon:SetPoint("RIGHT", partyFrameText, "LEFT", -4, -1)
    local partyFrameIcon2 = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    partyFrameIcon2:SetAtlas("groupfinder-icon-friend")
    partyFrameIcon2:SetSize(20, 20)
    partyFrameIcon2:SetPoint("RIGHT", partyFrameText, "LEFT", 0, 4)

    local showPartyCastbar = CreateCheckbox("showPartyCastbar", "Party Castbars", BetterBlizzFrames, nil, BBF.UpdateCastbars)
    showPartyCastbar:SetPoint("TOPLEFT", partyFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    showPartyCastbar:HookScript("OnClick", function(self)
        --BBF.AbsorbCaller()
    end)
    CreateTooltip(showPartyCastbar, "Show party members castbar on party frames.\n\nMore settings in the \"Castbars\" tab.")

    local hidePartyRoles = CreateCheckbox("hidePartyRoles", "Hide Role Icons", BetterBlizzFrames)
    hidePartyRoles:SetPoint("LEFT", showPartyCastbar.text, "RIGHT", 0, 0)
    hidePartyRoles:HookScript("OnClick", function()
        BBF.PartyNameChange()
    end)
    CreateTooltip(hidePartyRoles, "Hide the role icons from party frame|A:roleicon-tiny-dps:22:22|a|A:spec-role-dps:22:22|a")

--[=[
    local sortGroup = CreateCheckbox("sortGroup", "Sort Group", BetterBlizzFrames, nil, BBF.SortGroup)
    sortGroup:SetPoint("TOPLEFT", showPartyCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(sortGroup, "Always sort the group members in chronological order from top to bottom. ")

    local sortGroupPlayerTop = CreateCheckbox("sortGroupPlayerTop", "Player on Top", BetterBlizzFrames, nil, BBF.SortGroup)
    sortGroupPlayerTop:SetPoint("LEFT", sortGroup.text, "RIGHT", 0, 0)

    local sortGroupPlayerBottom = CreateCheckbox("sortGroupPlayerBottom", "Player on Bottom", BetterBlizzFrames, nil, BBF.SortGroup)
    sortGroupPlayerBottom:SetPoint("LEFT", sortGroupPlayerTop.text, "RIGHT", 0, 0)

    sortGroupPlayerTop:HookScript("OnClick", function(self)
        if self:GetChecked() then
            sortGroupPlayerBottom:SetChecked(false)
            BetterBlizzFramesDB.sortGroupPlayerBottom = false
        end
    end)

    sortGroupPlayerBottom:HookScript("OnClick", function(self)
        if self:GetChecked() then
            sortGroupPlayerTop:SetChecked(false)
            BetterBlizzFramesDB.sortGroupPlayerTop = false
        end
    end)

    sortGroup:HookScript("OnClick", function(self)
        if self:GetChecked() then
            sortGroupPlayerTop:Enable()
            sortGroupPlayerTop:SetAlpha(1)
            sortGroupPlayerBottom:Enable()
            sortGroupPlayerBottom:SetAlpha(1)
        else
            sortGroupPlayerTop:Disable()
            sortGroupPlayerTop:SetAlpha(0)
            sortGroupPlayerBottom:Disable()
            sortGroupPlayerBottom:SetAlpha(0)
        end
    end)
    if not BetterBlizzFramesDB.sortGroup then
        sortGroupPlayerTop:SetAlpha(0)
        sortGroupPlayerBottom:SetAlpha(0)
    end

]=]


    local hidePartyFramesInArena = CreateCheckbox("hidePartyFramesInArena", "Hide Party in Arena (GEX)", BetterBlizzFrames, nil, BBF.HidePartyInArena)
    hidePartyFramesInArena:SetPoint("TOPLEFT", showPartyCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePartyFramesInArena, "Hide Party Frames in Arena. Made with GladiusEx Party Frames in mind.")

    local hidePartyNames = CreateCheckbox("hidePartyNames", "Hide Names", BetterBlizzFrames)
    hidePartyNames:SetPoint("TOPLEFT", hidePartyFramesInArena, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    hidePartyNames:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
    end)

    local hidePartyAggroHighlight = CreateCheckbox("hidePartyAggroHighlight", "Hide Aggro Highlight", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePartyAggroHighlight:SetPoint("LEFT", hidePartyNames.text, "RIGHT", 0, 0)
    CreateTooltip(hidePartyAggroHighlight, "Hide the Aggro Highlight border around each party frame.")

    -- local hidePartyMaxHpReduction = CreateCheckbox("hidePartyMaxHpReduction", "Hide Reduced HP", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hidePartyMaxHpReduction:SetPoint("LEFT", hidePartyRoles.text, "RIGHT", 0, 0)
    -- CreateTooltipTwo(hidePartyMaxHpReduction, "Hide Reduced HP", "Hide the new max health loss indication introduced in TWW from party frames.")

    local hidePartyFrameTitle = CreateCheckbox("hidePartyFrameTitle", "Hide CompactPartyFrame Title", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePartyFrameTitle:SetPoint("TOPLEFT", hidePartyNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hidePartyFrameTitle, "Hide the \"Party\" text above \"Raid-Style\" Party Frames.")

    local hideRaidFrameManager = CreateCheckbox("hideRaidFrameManager", "Hide RaidFrameManager", BetterBlizzFrames, nil, BBF.HideFrames)
    hideRaidFrameManager:SetPoint("TOPLEFT", hidePartyFrameTitle, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideRaidFrameManager, "Hide the CompactRaidFrameManager. Can still be shown with mouseover.")

    local hideRaidFrameContainerBorder = CreateCheckbox("hideRaidFrameContainerBorder", "Hide Container Border", BetterBlizzFrames, nil, BBF.HideFrames)
    hideRaidFrameContainerBorder:SetPoint("TOPLEFT", hideRaidFrameManager, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideRaidFrameContainerBorder, "Hide CompactRaidFrame Container Border", "Hide the thick Border around all the raid frame members.\n\nNote: This needs to have \"Border\" enabled in Blizzard settings for RaidFrames otherwise it does nothing.\n\nThis lets you keep \"Border\" enabled in Blizzard settings for a thin border around each party member but removes the thick one surrounding all of them.")

    local partyFrameScale = CreateSlider(BetterBlizzFrames, "Party Frame Scale", 0.7, 1.7, 0.01, "partyFrameScale", nil, 120)
    partyFrameScale:SetPoint("TOPLEFT", hideRaidFrameContainerBorder, "BOTTOMLEFT", 15, -9)









    local targetFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 250, -173)
    targetFrameText:SetText("Target Frame")
    targetFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    targetFrameText:SetTextColor(1,1,1)
    local targetFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    targetFrameIcon:SetAtlas("groupfinder-icon-friend")
    targetFrameIcon:SetSize(28, 28)
    targetFrameIcon:SetPoint("RIGHT", targetFrameText, "LEFT", -0.5, 0)
    targetFrameIcon:SetDesaturated(1)
    targetFrameIcon:SetVertexColor(1, 0, 0)

    local targetFrameClickthrough = CreateCheckbox("targetFrameClickthrough", "Clickthrough", BetterBlizzFrames, nil, BBF.ClickthroughFrames)
    targetFrameClickthrough:SetPoint("TOPLEFT", targetFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(targetFrameClickthrough, "Makes the TargetFrame clickthrough.\nYou can still hold shift to left/right click it\nwhile out of combat for trade/inspect etc.\n\nNOTE: You will NOT be able to click the frame\nat all during combat with this setting on.")
    targetFrameClickthrough:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideTargetName = CreateCheckbox("hideTargetName", "Hide Name", BetterBlizzFrames, nil, BBF.UpdateNameSettings)
    hideTargetName:SetPoint("TOPLEFT", targetFrameClickthrough, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideTargetName, "Hide the name of the target\n\nWill still show arena names if enabled.")
    hideTargetName:HookScript("OnClick", function(self)
        -- if self:GetChecked() then
        --     TargetFrame.name:SetAlpha(0)
        --     if TargetFrame.bbfName then
        --         TargetFrame.bbfName:SetAlpha(0)
        --     end
        -- else
        --     TargetFrame.name:SetAlpha(0)
        --     if TargetFrame.bbfName then
        --         TargetFrame.bbfName:SetAlpha(1)
        --     else
        --         TargetFrame.name:SetAlpha(1)
        --     end
        -- end
        BBF.AllNameChanges()
    end)

    -- local hideTargetMaxHpReduction = CreateCheckbox("hideTargetMaxHpReduction", "Hide Reduced HP", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hideTargetMaxHpReduction:SetPoint("LEFT", hideTargetName.text, "RIGHT", 0, 0)
    -- CreateTooltipTwo(hideTargetMaxHpReduction, "Hide Reduced HP", "Hide the new max health loss indication introduced in TWW from TargetFrame.")

    local hideTargetLeaderIcon = CreateCheckbox("hideTargetLeaderIcon", "Hide Leader Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    hideTargetLeaderIcon:SetPoint("TOPLEFT", hideTargetName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideTargetLeaderIcon, "Hide the party leader icon from Target.|A:UI-HUD-UnitFrame-Player-Group-LeaderIcon:22:22|a")

    local classColorTargetReputationTexture = CreateCheckbox("classColorTargetReputationTexture", "Reputation Class Color", BetterBlizzFrames)
    classColorTargetReputationTexture:SetPoint("TOPLEFT", hideTargetLeaderIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(classColorTargetReputationTexture, "Use class colors instead of the reputation color for Target. |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")
    classColorTargetReputationTexture:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.ClassColorReputation(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "target")
        else
            BBF.ResetClassColorReputation(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "target")
        end
    end)

    local hideTargetReputationColor = CreateCheckbox("hideTargetReputationColor", "Hide Reputation Color", BetterBlizzFrames, nil, BBF.HideFrames)
    hideTargetReputationColor:SetPoint("TOPLEFT", classColorTargetReputationTexture, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideTargetReputationColor, "Hide the color behind Target name. |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")






    local targetToTFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetToTFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 250, -298)
    targetToTFrameText:SetText("Target of Target")
    targetToTFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    targetToTFrameText:SetTextColor(1,1,1)
    local targetToTFrameIcon = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    targetToTFrameIcon:SetAtlas("groupfinder-icon-friend")
    targetToTFrameIcon:SetSize(28, 28)
    targetToTFrameIcon:SetPoint("RIGHT", targetToTFrameText, "LEFT", -0.5, 0)
    targetToTFrameIcon:SetDesaturated(1)
    targetToTFrameIcon:SetVertexColor(1, 0, 0)
    local targetToTFrameIcon2 = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    targetToTFrameIcon2:SetAtlas("TargetCrosshairs")
    targetToTFrameIcon2:SetSize(28, 28)
    targetToTFrameIcon2:SetPoint("TOPLEFT", targetToTFrameIcon, "TOPLEFT", 13.5, -13)

    local hideTargetToT = CreateCheckbox("hideTargetToT", "Hide Frame", BetterBlizzFrames, nil, BBF.HideFrames)
    hideTargetToT:SetPoint("TOPLEFT", targetToTFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)

    local hideTargetToTName = CreateCheckbox("hideTargetToTName", "Hide Name", BetterBlizzFrames)
    hideTargetToTName:SetPoint("LEFT", hideTargetToT.Text, "RIGHT", 0, 0)
    hideTargetToTName:HookScript("OnClick", function(self)
        if self:GetChecked() then
            TargetFrame.totFrame.Name:SetAlpha(0)
            if TargetFrame.totFrame.bbfName then
                TargetFrame.totFrame.bbfName:SetAlpha(0)
            end
        else
            TargetFrame.totFrame.Name:SetAlpha(0)
            if TargetFrame.totFrame.bbfName then
                TargetFrame.totFrame.bbfName:SetAlpha(1)
            end
        end
    end)

    local hideTargetToTDebuffs = CreateCheckbox("hideTargetToTDebuffs", "Hide ToT Debuffs", BetterBlizzFrames, nil, BBF.HideFrames)
    hideTargetToTDebuffs:SetPoint("TOPLEFT", hideTargetToT, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideTargetToTDebuffs, "Hide the 4 small debuff icons to the right of ToT frame.")

    local targetToTScale = CreateSlider(BetterBlizzFrames, "Size", 0.6, 2.5, 0.01, "targetToTScale", nil, 120)
    targetToTScale:SetPoint("TOPLEFT", targetToTFrameText, "BOTTOMLEFT", -20, -50)
    CreateTooltip(targetToTScale, "Target of target size.\n\nYou can right-click sliders to enter a specific value.")

    BBF.targetToTXPos = CreateSlider(BetterBlizzFrames, "x offset", -100, 100, 1, "targetToTXPos", "X", 120)
    BBF.targetToTXPos:SetPoint("TOP", targetToTScale, "BOTTOM", 0, -15)
    CreateTooltip(BBF.targetToTXPos, "Target of target x offset.\n\nYou can right-click sliders to enter a specific value.")

    local targetToTYPos = CreateSlider(BetterBlizzFrames, "y offset", -100, 100, 1, "targetToTYPos", "Y", 120)
    targetToTYPos:SetPoint("TOP", BBF.targetToTXPos, "BOTTOM", 0, -15)
    CreateTooltip(targetToTYPos, "Target of target y offset.\n\nYou can right-click sliders to enter a specific value.")




    local chatFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 250, -455)
    chatFrameText:SetText("Chat Frame")
    chatFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    chatFrameText:SetTextColor(1,1,1)
    local chatFrameIcon = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    chatFrameIcon:SetAtlas("transmog-icon-chat")
    chatFrameIcon:SetSize(18, 16)
    chatFrameIcon:SetPoint("RIGHT", chatFrameText, "LEFT", -4, 0)

    local hideChatButtons = CreateCheckbox("hideChatButtons", "Hide Chat Buttons", BetterBlizzFrames, nil, BBF.HideFrames)
    hideChatButtons:SetPoint("TOPLEFT", chatFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(hideChatButtons, "Hide the chat buttons. Can still be shown with mouseover.")

    local chatFrameFilters = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chatFrameFilters:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 232, -495)
    chatFrameFilters:SetText("Filters:")
    chatFrameFilters:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 12)
    chatFrameFilters:SetTextColor(1,1,1)

    local filterGladiusSpam = CreateCheckbox("filterGladiusSpam", "Gladius Spam", BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterGladiusSpam:SetPoint("TOPLEFT", hideChatButtons, "BOTTOMLEFT", 0, -10)
    CreateTooltip(filterGladiusSpam, "Filter out Gladius \"LOW HEALTH\" spam from chat.")

    local filterNpcArenaSpam = CreateCheckbox("filterNpcArenaSpam", "Arena Npc Talk", BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterNpcArenaSpam:SetPoint("LEFT", filterGladiusSpam.text, "RIGHT", 0, 0)
    CreateTooltip(filterNpcArenaSpam, "Filter out npc chat messages like \"Get in there and fight, stop hiding!\"\nfrom chat during arena.")

    local filterTalentSpam = CreateCheckbox("filterTalentSpam", "Talent Spam", BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterTalentSpam:SetPoint("TOPLEFT", filterGladiusSpam, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(filterTalentSpam, "Filter out \"You have learned/unlearned\" spam from chat.\nEspecially annoying during respec.")

    local filterEmoteSpam = CreateCheckbox("filterEmoteSpam", "Emote Spam", BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterEmoteSpam:SetPoint("TOPLEFT", filterTalentSpam, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(filterEmoteSpam, "Filter out \"yells at his/her team members.\" and\n\"makes some strange gestures.\" from chat.")

    local filterSystemMessages = CreateCheckbox("filterSystemMessages", "System Messages", BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterSystemMessages:SetPoint("TOPLEFT", filterNpcArenaSpam, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(filterSystemMessages, "Filter out a few excessive system messages. Some examples:\n\"You have joined the queue for Arena Skirmish\"\n\"Your group has been disbanded.\"\n\"You have been awarded x currency\"\n\"You are in both a party and an instance group.\"\n\nFull lists in modules\\chatFrame.lua")

    local filterMiscInfo = CreateCheckbox("filterMiscInfo", "Misc Info", BetterBlizzFrames, nil, BBF.ChatFilterCaller)
    filterMiscInfo:SetPoint("TOPLEFT", filterSystemMessages, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(filterMiscInfo, "Filter out \"Your equipped items suffer a durability loss\" message.")

    local arenaNamesText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    arenaNamesText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, -98)
    arenaNamesText:SetText("Arena Names")
    arenaNamesText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    arenaNamesText:SetTextColor(1,1,1)
    CreateTooltip(arenaNamesText, "Change player names into spec/arena id instead during arena", "ANCHOR_LEFT")
    local arenaNamesIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    arenaNamesIcon:SetAtlas("questlog-questtypeicon-pvp")
    arenaNamesIcon:SetSize(19, 22)
    arenaNamesIcon:SetPoint("RIGHT", arenaNamesText, "LEFT", -3.5, 0)

    local targetAndFocusArenaNames = CreateCheckbox("targetAndFocusArenaNames", "Target & Focus", BetterBlizzFrames)
    targetAndFocusArenaNames:SetPoint("TOPLEFT", arenaNamesText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltipTwo(targetAndFocusArenaNames, "Arena Names","Change Target & Focus name to arena ID and/or spec name during arena.", nil, "ANCHOR_LEFT")

    local partyArenaNames = CreateCheckbox("partyArenaNames", "Party", BetterBlizzFrames)
    partyArenaNames:SetPoint("LEFT", targetAndFocusArenaNames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(partyArenaNames, "Arena Names", "Change party frame names to party ID and/or spec name during arena", nil, "ANCHOR_LEFT")

    local showSpecName = CreateCheckbox("showSpecName", "Show Spec Name", BetterBlizzFrames)
    showSpecName:SetPoint("TOPLEFT", targetAndFocusArenaNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(showSpecName, "Show Spec Name", "Show spec name instead of player names.\n\nIf both spec name and arena id is selected it will display as for instance \"Fury 3\".\n\n|cff32f795Right-click to change whether Party units should have spec names or not.\nShow spec for Party units: "..(BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride and "True" or "|cffff0000False|r").."|r")
    showSpecName:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride then
                BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride = false
            else
                BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride = true
            end
            local value = (BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride and "True" or "|cffff0000False|r")
            local showSpecNameTip = "Show spec name instead of player names.\n\nIf both spec name and arena id is selected it will display as for instance \"Fury 3\".\n\n|cff32f795Right-click to change whether Party units should have spec names or not.\nShow spec for Party units: "..value.."|r"
            GameTooltip:ClearLines()
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Show Spec Name")
            GameTooltip:AddLine(showSpecNameTip, 1, 1, 1, true)
            GameTooltip:Show()
            CreateTooltipTwo(showSpecName, "Show Spec Name", "Show spec name instead of player names.\n\nIf both spec name and arena id is selected it will display as for instance \"Fury 3\".\n\n|cff32f795Right-click to change whether Party units should have spec names or not.\nShow spec for Party units: "..(BetterBlizzFramesDB.targetAndFocusArenaNamePartyOverride and "True" or "|cffff0000False|r").."|r")
            BBF.AllNameChanges()
        end
    end)

    local shortArenaSpecName = CreateCheckbox("shortArenaSpecName", "Short", BetterBlizzFrames)
    shortArenaSpecName:SetPoint("LEFT", showSpecName.Text, "RIGHT", 0, 0)
    CreateTooltip(shortArenaSpecName, "Enable to use abbreviated specialization names.\nFor instance, \"Assassination\" will be displayed as \"Assa\".", "ANCHOR_LEFT")

    local showArenaID = CreateCheckbox("showArenaID", "Show Arena/Party ID", BetterBlizzFrames)
    showArenaID:SetPoint("TOPLEFT", showSpecName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(showArenaID, "Show arena/party id instead of name\n\nIf both spec name and arena id is selected\nit will display as for instance \"Fury 3\"")

    local function ToggleDependentCheckboxes()
        local enable = targetAndFocusArenaNames:GetChecked() or partyArenaNames:GetChecked()

        if enable then
            EnableElement(showSpecName)
            EnableElement(shortArenaSpecName)
            EnableElement(showArenaID)
        else
            DisableElement(showSpecName)
            DisableElement(shortArenaSpecName)
            DisableElement(showArenaID)
        end
    end
    -- Initial setup to ensure correct state upon UI load/reload
    ToggleDependentCheckboxes()
    -- Hook into the OnClick event of targetAndFocusArenaNames
    targetAndFocusArenaNames:HookScript("OnClick", ToggleDependentCheckboxes)
    -- Hook into the OnClick event of partyArenaNames
    partyArenaNames:HookScript("OnClick", ToggleDependentCheckboxes)

    local focusFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    focusFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, -173)
    focusFrameText:SetText("Focus Frame")
    focusFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    focusFrameText:SetTextColor(1,1,1)
    local focusFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    focusFrameIcon:SetAtlas("groupfinder-icon-friend")
    focusFrameIcon:SetSize(28, 28)
    focusFrameIcon:SetPoint("RIGHT", focusFrameText, "LEFT", -0.5, 0)
    focusFrameIcon:SetDesaturated(1)
    focusFrameIcon:SetVertexColor(0, 1, 0)

    local focusFrameClickthrough = CreateCheckbox("focusFrameClickthrough", "Clickthrough", BetterBlizzFrames, nil, BBF.ClickthroughFrames)
    focusFrameClickthrough:SetPoint("TOPLEFT", focusFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltip(focusFrameClickthrough, "Makes the FocusFrame clickthrough.\nYou can still hold shift to left/right click it\nwhile out of combat for trade/inspect etc.\n\nNOTE: You will NOT be able to click the frame\nat all during combat with this setting on.")
    focusFrameClickthrough:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideFocusName = CreateCheckbox("hideFocusName", "Hide Name", BetterBlizzFrames, nil, BBF.UpdateNameSettings)
    hideFocusName:SetPoint("TOPLEFT", focusFrameClickthrough, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideFocusName, "Hide the name of the focus\n\nWill still show arena names if enabled.")
    hideFocusName:HookScript("OnClick", function(self)
        -- if self:GetChecked() then
        --     FocusFrame.name:SetAlpha(0)
        --     if FocusFrame.bbfName then
        --         FocusFrame.bbfName:SetAlpha(0)
        --     end
        -- else
        --     FocusFrame.name:SetAlpha(0)
        --     if FocusFrame.bbfName then
        --         FocusFrame.bbfName:SetAlpha(1)
        --     else
        --         FocusFrame.name:SetAlpha(1)
        --     end
        -- end
        BBF.AllNameChanges()
    end)

    -- local hideFocusMaxHpReduction = CreateCheckbox("hideFocusMaxHpReduction", "Hide Reduced HP", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hideFocusMaxHpReduction:SetPoint("LEFT", hideFocusName.text, "RIGHT", 0, 0)
    -- CreateTooltipTwo(hideFocusMaxHpReduction, "Hide Reduced HP", "Hide the new max health loss indication introduced in TWW from FocusFrame.")

    local hideFocusLeaderIcon = CreateCheckbox("hideFocusLeaderIcon", "Hide Leader Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    hideFocusLeaderIcon:SetPoint("TOPLEFT", hideFocusName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideFocusLeaderIcon, "Hide the party leader icon from Focus.|A:UI-HUD-UnitFrame-Player-Group-LeaderIcon:22:22|a")

    local classColorFocusReputationTexture = CreateCheckbox("classColorFocusReputationTexture", "Reputation Class Color", BetterBlizzFrames)
    classColorFocusReputationTexture:SetPoint("TOPLEFT", hideFocusLeaderIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(classColorFocusReputationTexture, "Use class colors instead of the reputation color for Focus. |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")
    classColorFocusReputationTexture:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.ClassColorReputation(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "focus")
        else
            BBF.ResetClassColorReputation(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor, "focus")
        end
    end)

    local hideFocusReputationColor = CreateCheckbox("hideFocusReputationColor", "Hide Reputation Color", BetterBlizzFrames, nil, BBF.HideFrames)
    hideFocusReputationColor:SetPoint("TOPLEFT", classColorFocusReputationTexture, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideFocusReputationColor, "Hide the color behind Focus name. |A:UI-HUD-UnitFrame-Target-PortraitOn-Type:18:98|a")







    local focusToTFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    focusToTFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, -298)
    focusToTFrameText:SetText("Focus ToT")
    focusToTFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    focusToTFrameText:SetTextColor(1,1,1)
    local focusToTFrameIcon = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    focusToTFrameIcon:SetAtlas("groupfinder-icon-friend")
    focusToTFrameIcon:SetSize(28, 28)
    focusToTFrameIcon:SetPoint("RIGHT", focusToTFrameText, "LEFT", -0.5, 0)
    focusToTFrameIcon:SetDesaturated(1)
    focusToTFrameIcon:SetVertexColor(0, 1, 0)
    local focusToTFrameIcon2 = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    focusToTFrameIcon2:SetAtlas("TargetCrosshairs")
    focusToTFrameIcon2:SetSize(28, 28)
    focusToTFrameIcon2:SetPoint("TOPLEFT", focusToTFrameIcon, "TOPLEFT", 13.5, -13)

    local hideFocusToT = CreateCheckbox("hideFocusToT", "Hide Frame", BetterBlizzFrames, nil, BBF.HideFrames)
    hideFocusToT:SetPoint("TOPLEFT", focusToTFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)

    local hideFocusToTName = CreateCheckbox("hideFocusToTName", "Hide Name", BetterBlizzFrames)
    hideFocusToTName:SetPoint("LEFT", hideFocusToT.Text, "RIGHT", 0, 0)
    hideFocusToTName:HookScript("OnClick", function(self)
        if self:GetChecked() then
            FocusFrame.totFrame.Name:SetAlpha(0)
            if FocusFrame.totFrame.bbfName then
                FocusFrame.totFrame.bbfName:SetAlpha(0)
            end
        else
            FocusFrame.totFrame.Name:SetAlpha(0)
            if FocusFrame.totFrame.bbfName then
                FocusFrame.totFrame.bbfName:SetAlpha(1)
            end
        end
    end)

    local hideFocusToTDebuffs = CreateCheckbox("hideFocusToTDebuffs", "Hide FocusToT Debuffs", BetterBlizzFrames, nil, BBF.HideFrames)
    hideFocusToTDebuffs:SetPoint("TOPLEFT", hideFocusToT, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideFocusToTDebuffs, "Hide the 4 small debuff icons to the right of ToT frame.")

    local focusToTScale = CreateSlider(BetterBlizzFrames, "Size", 0.6, 2.5, 0.01, "focusToTScale", nil, 120)
    focusToTScale:SetPoint("TOPLEFT", focusToTFrameText, "BOTTOMLEFT", -20, -50)
    CreateTooltip(focusToTScale, "Focus target of target size.\n\nYou can right-click sliders to enter a specific value.")

    BBF.focusToTXPos = CreateSlider(BetterBlizzFrames, "x offset", -100, 100, 1, "focusToTXPos", "X", 120)
    BBF.focusToTXPos:SetPoint("TOP", focusToTScale, "BOTTOM", 0, -15)
    CreateTooltip(BBF.focusToTXPos, "Focus target of target x offset.\n\nYou can right-click sliders to enter a specific value.")

    local focusToTYPos = CreateSlider(BetterBlizzFrames, "y offset", -100, 100, 1, "focusToTYPos", "Y", 120)
    focusToTYPos:SetPoint("TOP", BBF.focusToTXPos, "BOTTOM", 0, -15)
    CreateTooltip(focusToTYPos, "Focus target of target y offset.\n\nYou can right-click sliders to enter a specific value.")





    local allFrameText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    allFrameText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 250, 30)
    allFrameText:SetText("All Frames")
    allFrameText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    allFrameText:SetTextColor(1,1,1)
    local allFrameIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    allFrameIcon:SetAtlas("groupfinder-icon-friend")
    allFrameIcon:SetSize(25, 25)
    allFrameIcon:SetPoint("RIGHT", allFrameText, "LEFT", -2, -1)
    local allFrameIcon2 = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    allFrameIcon2:SetAtlas("groupfinder-icon-friend")
    allFrameIcon2:SetSize(20, 20)
    allFrameIcon2:SetPoint("RIGHT", allFrameText, "LEFT", 2, 4)
    allFrameIcon2:SetDesaturated(1)
    allFrameIcon2:SetVertexColor(0, 1, 0)
    local allFrameIcon3 = BetterBlizzFrames:CreateTexture(nil, "BORDER")
    allFrameIcon3:SetAtlas("groupfinder-icon-friend")
    allFrameIcon3:SetSize(20, 20)
    allFrameIcon3:SetPoint("RIGHT", allFrameText, "LEFT", -10, 4)
    allFrameIcon3:SetDesaturated(1)
    allFrameIcon3:SetVertexColor(1, 0, 0)

    local classicFrames = CreateCheckbox("classicFrames", "Classic Frames", BetterBlizzFrames)
    classicFrames:SetPoint("TOPLEFT", allFrameText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    CreateTooltipTwo(classicFrames, "Classic Frames", "Enable for the old style UnitFrames from before Dragonflight.")
    classicFrames:HookScript("OnClick", function(self)
        if self:GetChecked() and C_AddOns.IsAddOnLoaded("ClassicFrames") then
            C_AddOns.DisableAddOn("ClassicFrames")
        end
        if self:GetChecked() then
            if not BBF.ClassicReloadWindow then
                local statusText = classicFrames:GetChecked() and "|cff00ff00ON|r" or "|cffff0000OFF|r"
                StaticPopupDialogs["BBF_CLASSIC_RELOAD"] = {
                    text = titleText.."Classic Frames will turn "..statusText.." after reload.\n\nSelect which optional settings you want.\n|cFFAAAAAA(These can be changed individually later)|r\n\n\n\n\n ",
                    button1 = "Reload UI",
                    button2 = "Cancel",
                    OnAccept = function()
                        BetterBlizzFramesDB.reopenOptions = true
                        if BBF.ChangesOnReload then
                            for key, value in pairs(BBF.ChangesOnReload) do
                                BetterBlizzFramesDB[key] = value
                                if key == "comboPointLocation" and value ~= nil and not InCombatLockdown() then
                                    C_CVar.SetCVar("comboPointLocation", value)
                                end
                            end
                        end
                        C_AddOns.DisableAddOn("ClassicFrames")
                        ReloadUI()
                    end,
                    OnShow = function(self)
                        local statusText = classicFrames:GetChecked() and "|cff00ff00ON|r" or "|cffff0000OFF|r"
                        self.Text:SetText(titleText.."Classic Frames will turn "..statusText.." after reload.\n\nSelect which optional settings you want.\n|cFFAAAAAA(These can be changed individually later)|r\n\n\n\n\n ")
                        if not self.classicSettings then
                            BBF.ChangesOnReload = {}
                            self.cfTextures = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
                            self.cfTextures:SetSize(26, 26)
                            CreateTooltipTwo(self.cfTextures, "Use Classic Textures for Bars", "Use the old Classic Textures for Health & Manabars.\n\nUnchecked will keep the default retail textures and use a little less CPU.")
                            self.cfTextures.Text:SetText("Classic Health & Mana Textures")

                            self.cfCastbars = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
                            self.cfCastbars:SetSize(26, 26)
                            CreateTooltipTwo(self.cfCastbars, "Use Classic Castbars", "Use the old Classic Castbar look for Player, Target, Focus & Party.")
                            self.cfCastbars.Text:SetText("Classic Castbars")

                            self.cfComboPoints = CreateFrame("CheckButton", nil, self, "UICheckButtonTemplate")
                            self.cfComboPoints:SetSize(26, 26)
                            CreateTooltipTwo(self.cfComboPoints, "Use Classic Combo Points", "Use the old Classic Combo Points look on TargetFrame.\n\nNote: If you would rather move the new Combo Points to TargetFrame you can do so in the Misc section.")
                            self.cfComboPoints.Text:SetText("Classic Combo Points")

                            local firstClick = BetterBlizzFramesDB.classicFramesClicked == nil
                            BetterBlizzFramesDB.classicFramesClicked = true

                            self.cfCastbars:SetChecked((firstClick and true) or BetterBlizzFramesDB.classicCastbars or false)
                            self.cfComboPoints:SetChecked(C_CVar.GetCVar("comboPointLocation") == "1" and true or false)
                            self.cfTextures:SetChecked(BetterBlizzFramesDB.changeUnitFrameHealthbarTexture or false)

                            self.classicSettings = true
                        end

                        local function CheckBoxes()
                            local castbarsEnabled = self.cfCastbars:GetChecked()
                            if castbarsEnabled then
                                BBF.ChangesOnReload["classicCastbarsParty"] = castbarsEnabled
                                BBF.ChangesOnReload["classicCastbarsPlayer"] = castbarsEnabled
                                BBF.ChangesOnReload["classicCastbarsPlayerBorder"] = castbarsEnabled
                                BBF.ChangesOnReload["classicCastbars"] = castbarsEnabled
                                BBF.ChangesOnReload["classicCastbarsParty"] = castbarsEnabled
                                BBF.ChangesOnReload["targetToTXPos"] = -1
                                BBF.ChangesOnReload["targetToTYPos"] = 17
                                BBF.ChangesOnReload["focusToTXPos"] = -1
                                BBF.ChangesOnReload["focusToTYPos"] = 17
                                BBF.ChangesOnReload["targetToTScale"] = 0.97
                                BBF.ChangesOnReload["focusToTScale"] = 0.97
                                BBF.ChangesOnReload["targetCastBarXPos"] = 5
                                BBF.ChangesOnReload["focusCastBarXPos"] = 5
                                BBF.ChangesOnReload["targetCastBarWidth"] = 143
                                BBF.ChangesOnReload["focusCastBarWidth"] = 143
                                BBF.ChangesOnReload["playerCastBarWidth"] = 205
                                BBF.ChangesOnReload["playerCastBarHeight"] = 12.5
                            end

                            local comboPointsEnabled = self.cfComboPoints:GetChecked()
                            BBF.ChangesOnReload["comboPointLocation"] = comboPointsEnabled and "1" or nil
                            BBF.ChangesOnReload["enableLegacyComboPoints"] = comboPointsEnabled and true or nil
                            BBF.ChangesOnReload["legacyCombosTurnedOff"] = comboPointsEnabled and nil or true

                            local statusBarsEnabled = self.cfTextures:GetChecked()
                            BBF.ChangesOnReload["changeUnitFrameHealthbarTexture"] = statusBarsEnabled or false
                            BBF.ChangesOnReload["changeUnitFrameManabarTexture"] = statusBarsEnabled or false
                            BBF.ChangesOnReload["unitFrameHealthbarTexture"] = statusBarsEnabled and "Blizzard CF" or nil
                            BBF.ChangesOnReload["unitFrameManabarTexture"] = statusBarsEnabled and "Blizzard CF" or nil
                            BBF.ChangesOnReload["hidePlayerHealthLossAnim"] = statusBarsEnabled and true or nil
                        end
                        CheckBoxes()

                        self.cfCastbars:SetScript("OnClick", function()
                            CheckBoxes()
                        end)
                        self.cfComboPoints:SetScript("OnClick", function()
                            CheckBoxes()
                        end)
                        self.cfTextures:SetScript("OnClick", function()
                            CheckBoxes()
                        end)
                        self.cfCastbars:SetPoint("BOTTOMLEFT", self.ButtonContainer.Button1, "TOPLEFT", 15, 43)
                        self.cfComboPoints:SetPoint("TOPLEFT", self.cfCastbars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
                        self.cfTextures:SetPoint("TOPLEFT", self.cfComboPoints, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
                        self.cfTextures:Show()
                    end,
                    OnHide = function(self)
                        if self.cfTextures then
                            self.cfTextures:Hide()
                        end
                        if self.cfComboPoints then
                            self.cfComboPoints:Hide()
                        end
                        if self.cfCastbars then
                            self.cfCastbars:Hide()
                        end
                    end,
                    timeout = 0,
                    whileDead = true,
                }
                BBF.ClassicReloadWindow = true
            end
            StaticPopup_Show("BBF_CLASSIC_RELOAD")
        else
            local db = BetterBlizzFramesDB
            db.classicCastbarsParty = false
            db.classicCastbarsPlayer = false
            db.classicCastbarsPlayerBorder = false
            db.classicCastbars = false
            db.classicCastbarsParty = false
            db.changeUnitFrameHealthbarTexture = false
            db.changeUnitFrameManabarTexture = false
            db.comboPointLocation = nil
            db.targetToTXPos = -1
            db.targetToTYPos = 17
            db.focusToTXPos = -1
            db.focusToTYPos = 17
            db.targetToTScale = 0.97
            db.focusToTScale = 0.97
            db.targetCastBarXPos = 5
            db.focusCastBarXPos = 5
            db.targetCastBarWidth = 143
            db.focusCastBarWidth = 143
            db.playerCastBarWidth = 205
            db.playerCastBarHeight = 12.5
            db.hidePlayerHealthLossAnim = nil
            if not InCombatLockdown() then
                C_CVar.SetCVar("comboPointLocation", "2")
            end
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local classColorFrames = CreateCheckbox("classColorFrames", "Class Color Health", BetterBlizzFrames)
    classColorFrames:SetPoint("TOPLEFT", classicFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    classColorFrames:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local classColorFramesSkipPlayer = CreateCheckbox("classColorFramesSkipPlayer", "Skip Self", BetterBlizzFrames)
    classColorFramesSkipPlayer:SetPoint("LEFT", classColorFrames.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(classColorFramesSkipPlayer, "Skip Self", "Skip PlayerFrame healthbar coloring and leave it default green.")
    classColorFramesSkipPlayer:HookScript("OnClick", function(self)
        BBF.UpdateFrames()
        if self:GetChecked() then
            PlayerFrame.healthbar:SetStatusBarDesaturated(false)
            PlayerFrame.healthbar:SetStatusBarColor(1, 1, 1)
        else
            BBF.updateFrameColorToggleVer(PlayerFrame.healthbar, "player")
            if CfPlayerFrameHealthBar then
                BBF.updateFrameColorToggleVer(CfPlayerFrameHealthBar, "player")
            end
        end
    end)

    classColorFrames:HookScript("OnClick", function (self)
        local function UpdateCVar()
            if not InCombatLockdown() then
                if BetterBlizzFramesDB.classColorFrames then
                    SetCVar("raidFramesDisplayClassColor", 1)
                end
            else
                C_Timer.After(1, function()
                    UpdateCVar()
                end)
            end
        end
        UpdateCVar()
        BBF.UpdateFrames()
        if self:GetChecked() then
            classColorFramesSkipPlayer:Show()
        else
            classColorFramesSkipPlayer:Hide()
        end
    end)
    CreateTooltipTwo(classColorFrames, "Class Color Healthbars", "Class color Player, Target, Focus & Party frames.")

    if not BetterBlizzFramesDB.classColorFrames then
        classColorFramesSkipPlayer:Hide()
    end

    local classColorTargetNames = CreateCheckbox("classColorTargetNames", "Class Color Names", BetterBlizzFrames)
    classColorTargetNames:SetPoint("TOPLEFT", classColorFrames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(classColorTargetNames, "Class Color Names","Class color Player, Target & Focus Names.")

    local classColorLevelText = CreateCheckbox("classColorLevelText", "Level", classColorTargetNames)
    classColorLevelText:SetPoint("LEFT", classColorTargetNames.text, "RIGHT", 0, 0)
    CreateTooltip(classColorLevelText, "Also class color the level text.")

    classColorTargetNames:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
        if self:GetChecked() then
            classColorLevelText:Enable()
            classColorLevelText:SetAlpha(1)
        else
            classColorLevelText:Disable()
            classColorLevelText:SetAlpha(0)
        end
    end)
    if not BetterBlizzFramesDB.classColorTargetNames then
        classColorLevelText:SetAlpha(0)
    end

    local classColorFrameTexture = CreateCheckbox("classColorFrameTexture", "Class Color FrameTexture", BetterBlizzFrames)
    classColorFrameTexture:SetPoint("TOPLEFT", classColorTargetNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    classColorFrameTexture:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        else
            BBF.HookFrameTextureColor()
        end
    end)
    CreateTooltipTwo(classColorFrameTexture, "Class Color FrameTexture","Class color the FrameTexture (Border) for Player, Target & Focus.")


    local centerNames = CreateCheckbox("centerNames", "Center Name", BetterBlizzFrames, nil, BBF.SetCenteredNamesCaller)
    centerNames:SetPoint("TOPLEFT", classColorFrameTexture, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(centerNames, "Center Names", "Center the name on Player, Target & Focus frames.")
    centerNames:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local removeRealmNames = CreateCheckbox("removeRealmNames", "Hide Realm", BetterBlizzFrames)
    removeRealmNames:SetPoint("LEFT", centerNames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(removeRealmNames, "Hide Realm Indicator", "Hide realm name and different realm indicator \"(*)\" from Target, Focus & Party frames.")

    local formatStatusBarText = CreateCheckbox("formatStatusBarText", "Format Numbers", BetterBlizzFrames, nil, BBF.HookStatusBarText)
    formatStatusBarText:SetPoint("TOPLEFT", centerNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(formatStatusBarText, "Format Numbers", "Format the health & mana numbers on Player, Target & Focus frames to be millions instead of thousands.\n\n6800 K |A:glueannouncementpopup-arrow:20:20|a 6.8 M", "Requires reload.")

    local singleValueStatusBarText = CreateCheckbox("singleValueStatusBarText", "No Max", formatStatusBarText)
    singleValueStatusBarText:SetPoint("LEFT", formatStatusBarText.text, "RIGHT", 0, 0)
    CreateTooltipTwo(singleValueStatusBarText, "No Max Value", "If Numeric Value is selected as Status Text this setting will make it only display current HP instead of max HP as well.\n\n6.8 M / 6.8 M |A:glueannouncementpopup-arrow:20:20|a 6.8 M", "Requires reload.")
    singleValueStatusBarText:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    formatStatusBarText:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        CheckAndToggleCheckboxes(self)
    end)

    local hidePrestigeBadge = CreateCheckbox("hidePrestigeBadge", "Hide Prestige & PvP Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    hidePrestigeBadge:SetPoint("TOPLEFT", formatStatusBarText, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hidePrestigeBadge, "Hide Prestige/Honor Badge & PvP Icon |A:honorsystem-portrait-alliance:40:42|a |A:honorsystem-portrait-horde:40:42|a |A:honorsystem-portrait-neutral:40:42|a|A:UI-HUD-UnitFrame-Player-PVP-FFAIcon:44:28|a", "Hide Prestige/Honor Badge & PvP Icon from Player, Target & Focus frames.")

    local hideCombatGlow = CreateCheckbox("hideCombatGlow", "Hide Combat Glow", BetterBlizzFrames, nil, BBF.HideFrames)
    hideCombatGlow:SetPoint("TOPLEFT", hidePrestigeBadge, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideCombatGlow, "Hide the red combat around Player, Target & Focus.|A:UI-HUD-UnitFrame-Player-PortraitOn-InCombat:30:80|a")

    local hideUnitFrameShadow = CreateCheckbox("hideUnitFrameShadow", "Hide Shadow", BetterBlizzFrames, nil, BBF.HideFrames)
    hideUnitFrameShadow:SetPoint("LEFT", hideCombatGlow.text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideUnitFrameShadow, "Hide Shadow", "Hide shadow texture behind name on Player, Target & Focus frames.\n\n(Target/Focus Reputation Color shows in front of this as well, maybe disable those as well)")
    hideUnitFrameShadow:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideLevelText = CreateCheckbox("hideLevelText", "Hide Level 80 Text", BetterBlizzFrames, nil, BBF.HideFrames)
    hideLevelText:SetPoint("TOPLEFT", hideCombatGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideLevelText, "Hide the level text for Player, Target & Focus frames if they are level 80")
    hideLevelText:HookScript("OnClick", function()
        if BetterBlizzFramesDB.classicFrames then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideLevelTextAlways = CreateCheckbox("hideLevelTextAlways", "Always", BetterBlizzFrames, nil, BBF.HideFrames)
    hideLevelTextAlways:SetPoint("LEFT", hideLevelText.Text, "RIGHT", 0, 0)
    CreateTooltip(hideLevelTextAlways, "Always hide the level text.")
    hideLevelTextAlways:HookScript("OnClick", function()
        if BetterBlizzFramesDB.classicFrames then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    hideLevelText:HookScript("OnClick", function(self)
        if self:GetChecked() then
            hideLevelTextAlways:Enable()
            hideLevelTextAlways:Show()
        else
            hideLevelTextAlways:Disable()
            hideLevelTextAlways:Hide()
        end
    end)

    if not BetterBlizzFramesDB.hideLevelText then
        hideLevelTextAlways:Hide()
        hideLevelTextAlways:Disable()
    end

    -- local hidePvpIcon = CreateCheckbox("hidePvpIcon", "Hide PvP Icon", BetterBlizzFrames, nil, BBF.HideFrames)
    -- hidePvpIcon:SetPoint("TOPLEFT", hideLevelText, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    -- CreateTooltip(hidePvpIcon, "Hide PvP Icon on Player, Target & Focus|A:UI-HUD-UnitFrame-Player-PVP-FFAIcon:44:28|a")

    local hideRareDragonTexture = CreateCheckbox("hideRareDragonTexture", "Hide Dragon", BetterBlizzFrames, nil, BBF.HideFrames)
    hideRareDragonTexture:SetPoint("TOPLEFT", hideLevelText, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideRareDragonTexture, "Hide Elite Dragon texture on Target & Focus|A:UI-HUD-UnitFrame-Target-PortraitOn-Boss-Gold:38:28|a")
    hideRareDragonTexture:HookScript("OnClick", function()
        if BetterBlizzFramesDB.classicFrames then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideThreatOnFrame = CreateCheckbox("hideThreatOnFrame", "Hide Threat", BetterBlizzFrames, nil, BBF.HideFrames)
    hideThreatOnFrame:SetPoint("LEFT", hideRareDragonTexture.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(hideThreatOnFrame, "Hide Threat Meter", "Hide the threat meter displaying on Target & Focus frames.")

    local extraFeaturesText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    extraFeaturesText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 460, 30)
    extraFeaturesText:SetText("Extra Features")
    extraFeaturesText:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    extraFeaturesText:SetTextColor(1,1,1)
    local extraFeaturesIcon = BetterBlizzFrames:CreateTexture(nil, "ARTWORK")
    extraFeaturesIcon:SetAtlas("Campaign-QuestLog-LoreBook")
    extraFeaturesIcon:SetSize(24, 24)
    extraFeaturesIcon:SetPoint("RIGHT", extraFeaturesText, "LEFT", -1, 0)

    local combatIndicator = CreateCheckbox("combatIndicator", "Combat Indicator", BetterBlizzFrames)
    combatIndicator:SetPoint("TOPLEFT", extraFeaturesText, "BOTTOMLEFT", -24, pixelsOnFirstBox)
    combatIndicator:HookScript("OnClick", function()
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltipTwo(combatIndicator, "Combat Indicator", "Show combat status on Player, Target and Focus Frame.\nSword icon for combat, Sap icon for no combat.\nMore settings in \"Advanced Settings\"", nil, nil, nil, 1)

    local healerIndicator = CreateCheckbox("healerIndicator", "Healer Indicator", BetterBlizzFrames)
    healerIndicator:SetPoint("TOPLEFT", combatIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    healerIndicator:HookScript("OnClick", function(self)
        BBF.HealerIndicatorCaller()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltipTwo(healerIndicator, "Healer Indicator", "Show Healer Icon on Target and FocusFrame and/or change portrait to Healer Icon\nMore settings in \"Advanced Settings\"")

    local absorbIndicator = CreateCheckbox("absorbIndicator", "Absorb Indicator", BetterBlizzFrames, nil, BBF.AbsorbCaller)
    absorbIndicator:SetPoint("TOPLEFT", healerIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    absorbIndicator:HookScript("OnClick", function()
        BBF.AbsorbCaller()
    end)
    CreateTooltipTwo(absorbIndicator, "Absorb Indicator", "Show absorb amount on Player, Target and Focus Frame\nMore settings in \"Advanced Settings\"", nil, nil, nil, 1)

    local racialIndicator = CreateCheckbox("racialIndicator", "PvP Racial Indicator", BetterBlizzFrames, nil, BBF.RacialIndicatorCaller)
    racialIndicator:SetPoint("TOPLEFT", absorbIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicator:HookScript("OnClick", function()
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltipTwo(racialIndicator, "Racial Indicator", "Show important PvP racial icons on Target/Focus Frame", nil, nil, nil, 1)

    local overShields = CreateCheckbox("overShields", "Overshields", BetterBlizzFrames)
    overShields:SetPoint("TOPLEFT", racialIndicator, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(overShields, "Overshields", "Make the healthbar absorb texture grow backwards onto the healthbars for however much over-absorb there is you can can always accurate see their total health status.", nil, "ANCHOR_LEFT", nil, 2)

    local overShieldsUnitFrames = CreateCheckbox("overShieldsUnitFrames", "A", BetterBlizzFrames)
    overShieldsUnitFrames:SetPoint("LEFT", overShields.text, "RIGHT", 0, 0)
    CreateTooltipTwo(overShieldsUnitFrames, "UnitFrame Overshields", "Show Overshields on UnitFrames (Player, Target, Focus)", nil, "ANCHOR_LEFT", nil, 1)
    overShieldsUnitFrames:HookScript("OnClick", function(self)
        BBF.HookOverShields()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local overShieldsCompactUnitFrames = CreateCheckbox("overShieldsCompactUnitFrames", "B", BetterBlizzFrames)
    overShieldsCompactUnitFrames:SetPoint("LEFT", overShieldsUnitFrames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(overShieldsCompactUnitFrames, "Compact-UnitFrames Overshields", "Show Overshields on Compact UnitFrames (Party, Raid)", nil, "ANCHOR_LEFT", nil, 2)
    overShieldsCompactUnitFrames:HookScript("OnClick", function(self)
        BBF.HookOverShields()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    overShields:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.overShieldsCompact = true
            BetterBlizzFramesDB.overShieldsUnitFrames = true
            BBF.HookOverShields()
            overShieldsUnitFrames:SetAlpha(1)
            overShieldsUnitFrames:Enable()
            overShieldsUnitFrames:SetChecked(true)
            overShieldsCompactUnitFrames:SetAlpha(1)
            overShieldsCompactUnitFrames:Enable()
            overShieldsCompactUnitFrames:SetChecked(true)
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        else
            BetterBlizzFramesDB.overShieldsCompact = false
            BetterBlizzFramesDB.overShieldsUnitFrames = false
            overShieldsUnitFrames:SetAlpha(0)
            overShieldsUnitFrames:Disable()
            overShieldsUnitFrames:SetChecked(false)
            overShieldsCompactUnitFrames:SetAlpha(0)
            overShieldsCompactUnitFrames:Disable()
            overShieldsCompactUnitFrames:SetChecked(false)
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    if BetterBlizzFramesDB.overShields then
        overShieldsUnitFrames:SetAlpha(1)
        overShieldsUnitFrames:Enable()
        overShieldsCompactUnitFrames:SetAlpha(1)
        overShieldsCompactUnitFrames:Enable()
    else
        overShieldsUnitFrames:SetAlpha(0)
        overShieldsUnitFrames:Disable()
        overShieldsCompactUnitFrames:SetAlpha(0)
        overShieldsCompactUnitFrames:Disable()
    end

    local queueTimer = CreateCheckbox("queueTimer", "Queue Timer", BetterBlizzFrames)
    queueTimer:SetPoint("TOPLEFT", overShields, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(queueTimer, "Queue Timer", "Show the remaining time to accept a queue when it pops.\n\nWorks for both PvP and PvE.\n\nOptionally plays a queue pop sound and warns when the queue timer is about to expire.", nil, "ANCHOR_LEFT")

    local queueTimerAudio = CreateCheckbox("queueTimerAudio", "SFX", queueTimer)
    queueTimerAudio:SetPoint("LEFT", queueTimer.text, "RIGHT", 0, 0)
    CreateTooltipTwo(queueTimerAudio, "Sound Effect", "Play an alarm sound when queue pops.", "(Plays with game sounds muted)\n\nNote that \"Enable Sound\" needs to be on in the audio settings but you can disable the subcategories: Sound Effects, Ambience, Dialog and Music.", "ANCHOR_LEFT")

    local queueTimerWarning = CreateCheckbox("queueTimerWarning", "!", queueTimer)
    queueTimerWarning:SetPoint("LEFT", queueTimerAudio.text, "RIGHT", 0, 0)
    CreateTooltipTwo(queueTimerWarning, "Sound Alert!", "Warning sound if there is less than 6 seconds left to accept the queue.", "(Plays with game sounds muted.)\n\nNote that \"Enable Sound\" needs to be on in the audio settings but you can disable the subcategories: Sound Effects, Ambience, Dialog and Music.", "ANCHOR_LEFT")

    queueTimerAudio:HookScript("OnClick", function(self)
        if self:GetChecked() then
            EnableElement(queueTimerWarning)
        else
            DisableElement(queueTimerWarning)
        end
    end)

    if not BetterBlizzFramesDB.queueTimerAudio then
        DisableElement(queueTimerWarning)
    end

    queueTimer:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        CheckAndToggleCheckboxes(queueTimer)
        if not BetterBlizzFramesDB.queueTimerAudio then
            DisableElement(queueTimerWarning)
        end
        if self:GetChecked() then
            BBF.SBUncheck()
            if C_AddOns.IsAddOnLoaded("SafeQueue") then
                C_AddOns.DisableAddOn("SafeQueue")
            end
        end
    end)



    local btnGap = 5
    local starterButton = CreateClassButton(BetterBlizzFrames, "STARTER", "Starter", nil, function()
        ShowProfileConfirmation("Starter", "STARTER", BBF.StarterProfile, "|cff808080(If you want to completely reset BBF there\nis a button in Advanced Settings)|r\n\n")
    end)
    starterButton:SetPoint("TOPLEFT", SettingsPanel, "BOTTOMLEFT", 258, 38)

    local aeghisButton = CreateClassButton(BetterBlizzFrames, "MAGE", "Aeghis", "aeghis", function()
        ShowProfileConfirmation("Aeghis", "MAGE", BBF.AeghisProfile)
    end)
    aeghisButton:SetPoint("LEFT", starterButton, "RIGHT", btnGap, 0)

    local kalvishButton = CreateClassButton(BetterBlizzFrames, "ROGUE", "Kalvish", "kalvish", function()
        ShowProfileConfirmation("Kalvish", "ROGUE", BBF.KalvishProfile)
    end)
    kalvishButton:SetPoint("LEFT", aeghisButton, "RIGHT", btnGap, 0)

    local magnuszButton = CreateClassButton(BetterBlizzFrames, "WARRIOR", "Magnusz", "magnusz", function()
        ShowProfileConfirmation("Magnusz", "WARRIOR", BBF.MagnuszProfile)
    end)
    magnuszButton:SetPoint("LEFT", kalvishButton, "RIGHT", btnGap, 0)

    local nahjButton = CreateClassButton(BetterBlizzFrames, "ROGUE", "Nahj", "nahj", function()
        ShowProfileConfirmation("Nahj", "ROGUE", BBF.NahjProfile)
    end)
    nahjButton:SetPoint("LEFT", magnuszButton, "RIGHT", btnGap, 0)

    local snupyButton = CreateClassButton(BetterBlizzFrames, "DRUID", "Snupy", "snupy", function()
        ShowProfileConfirmation("Snupy", "DRUID", BBF.SnupyProfile)
    end)
    snupyButton:SetPoint("LEFT", nahjButton, "RIGHT", btnGap, 0)




    ----------------------
    -- Reload etc
    ----------------------
    local reloadUiButton = CreateFrame("Button", nil, BetterBlizzFrames, "UIPanelButtonTemplate")
    reloadUiButton:SetText("Reload UI")
    reloadUiButton:SetWidth(96)
    reloadUiButton:SetPoint("RIGHT", SettingsPanel.CloseButton, "LEFT", -3, 0)
    reloadUiButton:SetScript("OnClick", function()
        BetterBlizzFramesDB.reopenOptions = true
        ReloadUI()
    end)

    if not SettingsPanel.CloseButton.origPoint then
        SettingsPanel.CloseButton.origPoint, SettingsPanel.CloseButton.origRel, SettingsPanel.CloseButton.origAnchor, SettingsPanel.CloseButton.origX, SettingsPanel.CloseButton.origY = SettingsPanel.CloseButton:GetPoint()
    end
    SettingsPanel.CloseButton:ClearAllPoints()
    SettingsPanel.CloseButton:SetPoint("TOPRIGHT", BetterBlizzFrames, "BOTTOMRIGHT", 6, -41)
    BetterBlizzFrames:HookScript("OnShow", function()
        SettingsPanel.CloseButton:ClearAllPoints()
        SettingsPanel.CloseButton:SetPoint("TOPRIGHT", BetterBlizzFrames, "BOTTOMRIGHT", 6, -41)
    end)
    BetterBlizzFrames:HookScript("OnHide", function()
        if BetterBlizzPlates and BetterBlizzPlates:IsShown() then return end
        SettingsPanel.CloseButton:ClearAllPoints()
        SettingsPanel.CloseButton:SetPoint(SettingsPanel.CloseButton.origPoint, SettingsPanel.CloseButton.origRel, SettingsPanel.CloseButton.origAnchor, SettingsPanel.CloseButton.origX, SettingsPanel.CloseButton.origY)
    end)
end

local function guiCastbars()

    ----------------------
    -- Advanced settings
    ----------------------
    local firstLineX = 53
    local firstLineY = -65
    local secondLineX = 222
    local secondLineY = -360
    local thirdLineX = 391
    local thirdLineY = -655
    local fourthLineX = 560

    local BetterBlizzFramesCastbars = CreateFrame("Frame")
    BetterBlizzFramesCastbars.name = "Castbars"
    BetterBlizzFramesCastbars.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(BetterBlizzFramesCastbars)
    local castbarsSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, BetterBlizzFramesCastbars, BetterBlizzFramesCastbars.name, BetterBlizzFramesCastbars.name)
    castbarsSubCategory.ID = BetterBlizzFramesCastbars.name;
    CreateTitle(BetterBlizzFramesCastbars)

    local bgImg = BetterBlizzFramesCastbars:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", BetterBlizzFramesCastbars, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local scrollFrame = CreateFrame("ScrollFrame", nil, BetterBlizzFramesCastbars, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(700, 612)
    scrollFrame:SetPoint("CENTER", BetterBlizzFramesCastbars, "CENTER", -20, 3)

    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame.name = BetterBlizzFramesCastbars.name
    contentFrame:SetSize(680, 520)
    scrollFrame:SetScrollChild(contentFrame)

    local mainGuiAnchor2 = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor2:SetPoint("TOPLEFT", 55, 20)
    mainGuiAnchor2:SetText(" ")

   ----------------------
    -- Party Castbars
    ----------------------
    local anchorSubPartyCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubPartyCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX, firstLineY)
    anchorSubPartyCastbar:SetText("Party Castbars")

    local partyCastbarBorder = CreateBorderedFrame(anchorSubPartyCastbar, 157, 386, 0, -145, contentFrame)

    local partyCastbars = contentFrame:CreateTexture(nil, "ARTWORK")
    partyCastbars:SetAtlas("ui-castingbar-filling-channel")
    partyCastbars:SetSize(110, 13)
    partyCastbars:SetPoint("BOTTOM", anchorSubPartyCastbar, "TOP", -1, 10)

    local partyCastBarScale = CreateSlider(contentFrame, "Size", 0.5, 1.9, 0.01, "partyCastBarScale")
    partyCastBarScale:SetPoint("TOP", anchorSubPartyCastbar, "BOTTOM", 0, -15)

    local partyCastBarXPos = CreateSlider(contentFrame, "x offset", -200, 200, 1, "partyCastBarXPos", "X")
    partyCastBarXPos:SetPoint("TOP", partyCastBarScale, "BOTTOM", 0, -15)

    local partyCastBarYPos = CreateSlider(contentFrame, "y offset", -200, 200, 1, "partyCastBarYPos", "Y")
    partyCastBarYPos:SetPoint("TOP", partyCastBarXPos, "BOTTOM", 0, -15)

    local partyCastBarWidth = CreateSlider(contentFrame, "Width", 20, 200, 1, "partyCastBarWidth")
    partyCastBarWidth:SetPoint("TOP", partyCastBarYPos, "BOTTOM", 0, -15)

    local partyCastBarHeight = CreateSlider(contentFrame, "Height", 5, 30, 1, "partyCastBarHeight")
    partyCastBarHeight:SetPoint("TOP", partyCastBarWidth, "BOTTOM", 0, -15)

    local partyCastBarIconScale = CreateSlider(contentFrame, "Icon Size", 0.4, 2, 0.01, "partyCastBarIconScale")
    partyCastBarIconScale:SetPoint("TOP", partyCastBarHeight, "BOTTOM", 0, -15)

    local partyCastbarIconXPos = CreateSlider(contentFrame, "Icon x offset", -50, 50, 1, "partyCastbarIconXPos")
    partyCastbarIconXPos:SetPoint("TOP", partyCastBarIconScale, "BOTTOM", 0, -15)

    local partyCastbarIconYPos = CreateSlider(contentFrame, "Icon y offset", -50, 50, 1, "partyCastbarIconYPos")
    partyCastbarIconYPos:SetPoint("TOP", partyCastbarIconXPos, "BOTTOM", 0, -15)

    local partyCastBarTestMode = CreateCheckbox("partyCastBarTestMode", "Test", contentFrame, nil, BBF.partyCastBarTestMode)
    partyCastBarTestMode:SetPoint("TOPLEFT", partyCastbarIconYPos, "BOTTOMLEFT", 10, -4)
    CreateTooltip(partyCastBarTestMode, "Need to be in party to test")

    local partyCastBarTimer = CreateCheckbox("partyCastBarTimer", "Timer", contentFrame, nil, BBF.partyCastBarTestMode)
    partyCastBarTimer:SetPoint("LEFT", partyCastBarTestMode.Text, "RIGHT", 10, 0)
    CreateTooltip(partyCastBarTimer, "Show cast timer next to the castbar.")

    local partyCastbarSelf = CreateCheckbox("partyCastbarSelf", "Self", contentFrame, nil, BBF.partyCastBarTestMode)
    partyCastbarSelf:SetPoint("TOPLEFT", partyCastBarTimer, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(partyCastbarSelf, "Show castbar on party frame belonging to yourself as well.")

    local showPartyCastBarIcon = CreateCheckbox("showPartyCastBarIcon", "Icon", contentFrame, nil, BBF.partyCastBarTestMode)
    showPartyCastBarIcon:SetPoint("TOPLEFT", partyCastBarTestMode, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    anchorSubPartyCastbar.classicCastbarsParty = CreateCheckbox("classicCastbarsParty", "Classic Castbars", contentFrame, nil, BBF.partyCastBarTestMode)
    anchorSubPartyCastbar.classicCastbarsParty:SetPoint("TOPLEFT", showPartyCastBarIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(anchorSubPartyCastbar.classicCastbarsParty, "Classic Castbars", "Use classic style castbars for party castbars.")

    anchorSubPartyCastbar.classicCastbarsParty:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local resetPartyCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetPartyCastbar:SetText("Reset")
    resetPartyCastbar:SetWidth(70)
    resetPartyCastbar:SetPoint("TOP", partyCastbarBorder, "BOTTOM", 0, -2)
    resetPartyCastbar:SetScript("OnClick", function()
        partyCastBarScale:SetValue(1)
        partyCastBarIconScale:SetValue(1)
        partyCastBarXPos:SetValue(0)
        partyCastBarYPos:SetValue(0)
        partyCastbarIconXPos:SetValue(0)
        partyCastbarIconYPos:SetValue(0)
        partyCastBarWidth:SetValue(100)
        partyCastBarHeight:SetValue(12)
        partyCastBarTimer:SetChecked(true)
        BetterBlizzFramesDB.partyCastBarTimer = true
        BBF.CastBarTimerCaller()
    end)


   ----------------------
    -- Target Castbar
    ----------------------
    local anchorSubTargetCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubTargetCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", thirdLineX, firstLineY)
    anchorSubTargetCastbar:SetText("Target Castbar")

    local targetCastbarBorder = CreateBorderedFrame(anchorSubTargetCastbar, 157, 386, 0, -145, contentFrame)

    local targetCastBar = contentFrame:CreateTexture(nil, "ARTWORK")
    targetCastBar:SetAtlas("ui-castingbar-tier1-empower-2x")
    targetCastBar:SetSize(110, 13)
    targetCastBar:SetPoint("BOTTOM", anchorSubTargetCastbar, "TOP", -1, 10)

    local targetCastBarScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.01, "targetCastBarScale")
    targetCastBarScale:SetPoint("TOP", anchorSubTargetCastbar, "BOTTOM", 0, -15)

    local targetCastBarXPos = CreateSlider(contentFrame, "x offset", -130, 130, 1, "targetCastBarXPos", "X")
    targetCastBarXPos:SetPoint("TOP", targetCastBarScale, "BOTTOM", 0, -15)

    local targetCastBarYPos = CreateSlider(contentFrame, "y offset", -130, 130, 1, "targetCastBarYPos", "Y")
    targetCastBarYPos:SetPoint("TOP", targetCastBarXPos, "BOTTOM", 0, -15)

    local targetCastBarWidth = CreateSlider(contentFrame, "Width", 60, 220, 1, "targetCastBarWidth")
    targetCastBarWidth:SetPoint("TOP", targetCastBarYPos, "BOTTOM", 0, -15)

    local targetCastBarHeight = CreateSlider(contentFrame, "Height", 5, 30, 1, "targetCastBarHeight")
    targetCastBarHeight:SetPoint("TOP", targetCastBarWidth, "BOTTOM", 0, -15)

    local targetCastBarIconScale = CreateSlider(contentFrame, "Icon Size", 0.4, 2, 0.01, "targetCastBarIconScale")
    targetCastBarIconScale:SetPoint("TOP", targetCastBarHeight, "BOTTOM", 0, -15)

    local targetCastbarIconXPos = CreateSlider(contentFrame, "Icon x offset", -160, 160, 1, "targetCastbarIconXPos", "X")
    targetCastbarIconXPos:SetPoint("TOP", targetCastBarIconScale, "BOTTOM", 0, -15)

    local targetCastbarIconYPos = CreateSlider(contentFrame, "Icon y offset", -160, 160, 1, "targetCastbarIconYPos", "Y")
    targetCastbarIconYPos:SetPoint("TOP", targetCastbarIconXPos, "BOTTOM", 0, -15)

    local targetStaticCastbar = CreateCheckbox("targetStaticCastbar", "Static", contentFrame)
    targetStaticCastbar:SetPoint("TOPLEFT", targetCastbarIconYPos, "BOTTOMLEFT", 10, -4)
    CreateTooltip(targetStaticCastbar, "Lock the castbar in place on its frame.\nNo longer moves depending on aura amount.")

    local targetCastBarTimer = CreateCheckbox("targetCastBarTimer", "Timer", contentFrame, nil, BBF.CastBarTimerCaller)
    targetCastBarTimer:SetPoint("LEFT", targetStaticCastbar.Text, "RIGHT", 10, 0)
    CreateTooltip(targetCastBarTimer, "Show cast timer next to the castbar.")

    local targetToTCastbarAdjustment = CreateCheckbox("targetToTCastbarAdjustment", "ToT Offset", contentFrame)
    targetToTCastbarAdjustment:SetPoint("TOPLEFT", targetStaticCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(targetToTCastbarAdjustment, "Enable ToT Offset", "Makes sure the castbar is under Target ToT frame until enough auras are displayed to push it down.\nUncheck this if you have moved your ToT frame out of the way and want to have the castbar follow the bottom of the auras no matter what")

    local targetToTAdjustmentOffsetY = CreateSlider(targetToTCastbarAdjustment, "extra", -20, 50, 1, "targetToTAdjustmentOffsetY", "Y", 55)
    targetToTAdjustmentOffsetY:SetPoint("LEFT", targetToTCastbarAdjustment.text, "RIGHT", 2, -5)
    CreateTooltipTwo(targetToTAdjustmentOffsetY, "Extra Finetuning for ToT Offset", "Finetune the space between castbar and auras when ToT is showing. This extra offset is only active when the ToT frame is showing.")

    targetToTCastbarAdjustment:HookScript("OnClick", function(self)
        if self:GetChecked() then
            targetToTAdjustmentOffsetY:Enable()
            targetToTAdjustmentOffsetY:SetAlpha(1)
        else
            targetToTAdjustmentOffsetY:Disable()
            targetToTAdjustmentOffsetY:SetAlpha(0.5)
        end
    end)

    local targetDetachCastbar = CreateCheckbox("targetDetachCastbar", "Detach from frame", contentFrame)
    targetDetachCastbar:SetPoint("TOPLEFT", targetToTCastbarAdjustment, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    targetDetachCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            targetCastBarXPos:SetMinMaxValues(-900, 900)
            targetCastBarXPos:SetValue(0)
            targetCastBarYPos:SetMinMaxValues(-900, 900)
            targetCastBarYPos:SetValue(0)
            targetToTCastbarAdjustment:Disable()
            targetToTCastbarAdjustment:SetAlpha(0.5)
            targetToTAdjustmentOffsetY:Disable()
            targetToTAdjustmentOffsetY:SetAlpha(0.5)
            targetStaticCastbar:SetChecked(false)
            BetterBlizzFramesDB.targetStaticCastbar = false
        else
            targetCastBarXPos:SetMinMaxValues(-130, 130)
            targetCastBarXPos:SetValue(0)
            targetToTCastbarAdjustment:Enable()
            targetToTCastbarAdjustment:SetAlpha(1)
            targetToTAdjustmentOffsetY:Enable()
            targetToTAdjustmentOffsetY:SetAlpha(1)
        end
        BBF.ChangeCastbarSizes()
    end)
    CreateTooltip(targetDetachCastbar, "Detach castbar from frame and enable wider xy positioning.\nRight-click a slider to enter a specific number.")

    if BetterBlizzFramesDB.targetDetachCastbar then
        targetCastBarXPos:SetMinMaxValues(-900, 900)
        targetCastBarYPos:SetMinMaxValues(-900, 900)
        targetToTCastbarAdjustment:Disable()
        targetToTCastbarAdjustment:SetAlpha(0.5)
        targetToTAdjustmentOffsetY:Disable()
        targetToTAdjustmentOffsetY:SetAlpha(0.5)
        targetStaticCastbar:SetChecked(false)
        BetterBlizzFramesDB.targetStaticCastbar = false
    end
    targetStaticCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            targetToTCastbarAdjustment:Disable()
            targetToTCastbarAdjustment:SetAlpha(0.5)
            targetToTAdjustmentOffsetY:Disable()
            targetToTAdjustmentOffsetY:SetAlpha(0.5)
            targetDetachCastbar:SetChecked(false)
            BetterBlizzFramesDB.targetDetachCastbar = false
        else
            targetToTCastbarAdjustment:Enable()
            targetToTCastbarAdjustment:SetAlpha(1)
            targetToTAdjustmentOffsetY:Enable()
            targetToTAdjustmentOffsetY:SetAlpha(1)
        end
    end)
    if BetterBlizzFramesDB.targetStaticCastbar then
        targetToTCastbarAdjustment:Disable()
        targetToTCastbarAdjustment:SetAlpha(0.5)
        targetToTAdjustmentOffsetY:Disable()
        targetToTAdjustmentOffsetY:SetAlpha(0.5)
        targetDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.targetDetachCastbar = false
    end

    local resetTargetCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetTargetCastbar:SetText("Reset")
    resetTargetCastbar:SetWidth(70)
    resetTargetCastbar:SetPoint("TOP", targetCastbarBorder, "BOTTOM", 0, -2)
    resetTargetCastbar:SetScript("OnClick", function()
        targetCastBarScale:SetValue(1)
        targetCastBarIconScale:SetValue(1)
        targetCastBarXPos:SetValue(0)
        targetCastBarYPos:SetValue(0)
        targetCastbarIconXPos:SetValue(0)
        targetCastbarIconYPos:SetValue(0)
        targetCastBarWidth:SetValue(150)
        targetCastBarHeight:SetValue(10)
        targetCastBarTimer:SetChecked(false)
        BetterBlizzFramesDB.targetCastBarTimer = false
        targetStaticCastbar:SetChecked(false)
        BetterBlizzFramesDB.targetStaticCastbar = false
        targetDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.targetDetachCastbar = false
        targetToTCastbarAdjustment:Enable()
        targetToTCastbarAdjustment:SetAlpha(1)
        targetToTCastbarAdjustment:SetChecked(true)
        targetToTAdjustmentOffsetY:Enable()
        targetToTAdjustmentOffsetY:SetValue(0)
        BetterBlizzFramesDB.targetToTCastbarAdjustment = true
        BBF.CastBarTimerCaller()
        BBF.ChangeCastbarSizes()
    end)


    ----------------------
    -- Pet Castbars
    ----------------------
    local anchorSubPetCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubPetCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", firstLineX, secondLineY + 5)
    anchorSubPetCastbar:SetText("Pet Castbar")

    local petCastbarBorder = CreateBorderedFrame(anchorSubPetCastbar, 157, 320, 0, -112, contentFrame)

    local petCastbars = contentFrame:CreateTexture(nil, "ARTWORK")
    petCastbars:SetAtlas("ui-castingbar-filling-channel")
    petCastbars:SetDesaturated(true)
    petCastbars:SetVertexColor(1, 0.25, 0.98)
    petCastbars:SetSize(110, 13)
    petCastbars:SetPoint("BOTTOM", anchorSubPetCastbar, "TOP", -1, 10)

    local petCastBarScale = CreateSlider(contentFrame, "Size", 0.5, 1.9, 0.01, "petCastBarScale")
    petCastBarScale:SetPoint("TOP", anchorSubPetCastbar, "BOTTOM", 0, -15)

    local petCastBarXPos = CreateSlider(contentFrame, "x offset", -200, 200, 1, "petCastBarXPos", "X")
    petCastBarXPos:SetPoint("TOP", petCastBarScale, "BOTTOM", 0, -15)

    local petCastBarYPos = CreateSlider(contentFrame, "y offset", -200, 200, 1, "petCastBarYPos", "Y")
    petCastBarYPos:SetPoint("TOP", petCastBarXPos, "BOTTOM", 0, -15)

    local petCastBarWidth = CreateSlider(contentFrame, "Width", 20, 200, 1, "petCastBarWidth")
    petCastBarWidth:SetPoint("TOP", petCastBarYPos, "BOTTOM", 0, -15)

    local petCastBarHeight = CreateSlider(contentFrame, "Height", 5, 30, 1, "petCastBarHeight")
    petCastBarHeight:SetPoint("TOP", petCastBarWidth, "BOTTOM", 0, -15)

    local petCastBarIconScale = CreateSlider(contentFrame, "Icon Size", 0.4, 2, 0.01, "petCastBarIconScale")
    petCastBarIconScale:SetPoint("TOP", petCastBarHeight, "BOTTOM", 0, -15)

    local petCastBarTestMode = CreateCheckbox("petCastBarTestMode", "Test", contentFrame, nil, BBF.petCastBarTestMode)
    petCastBarTestMode:SetPoint("TOPLEFT", petCastBarIconScale, "BOTTOMLEFT", 10, -4)
    CreateTooltip(petCastBarTestMode, "Need pet to test.")

    local petCastBarTimer = CreateCheckbox("petCastBarTimer", "Timer", contentFrame, nil, BBF.petCastBarTestMode)
    petCastBarTimer:SetPoint("LEFT", petCastBarTestMode.Text, "RIGHT", 10, 0)
    CreateTooltip(petCastBarTimer, "Show cast timer next to the castbar.")

    local showPetCastBarIcon = CreateCheckbox("showPetCastBarIcon", "Icon", contentFrame, nil, BBF.petCastBarTestMode)
    showPetCastBarIcon:SetPoint("TOPLEFT", petCastBarTestMode, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local petDetachCastbar = CreateCheckbox("petDetachCastbar", "Detach from frame", contentFrame, nil, BBF.petCastBarTestMode)
    petDetachCastbar:SetPoint("TOPLEFT", showPetCastBarIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    petDetachCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            petCastBarXPos:SetMinMaxValues(-900, 900)
            petCastBarXPos:SetValue(0)
            petCastBarYPos:SetMinMaxValues(-900, 900)
            petCastBarYPos:SetValue(0)
        else
            petCastBarXPos:SetMinMaxValues(-130, 130)
            petCastBarXPos:SetValue(0)
        end
        BBF.petCastBarTestMode()
        BBF.ChangeCastbarSizes()
    end)
    CreateTooltip(petDetachCastbar, "Detach castbar from frame and enable wider xy positioning.\nRight-click a slider to enter a specific number.")

    if BetterBlizzFramesDB.petDetachCastbar then
        petCastBarXPos:SetMinMaxValues(-900, 900)
        petCastBarXPos:SetValue(0)
        petCastBarYPos:SetMinMaxValues(-900, 900)
        petCastBarYPos:SetValue(0)
    end

    local resetpetCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetpetCastbar:SetText("Reset")
    resetpetCastbar:SetWidth(70)
    resetpetCastbar:SetPoint("TOP", petCastbarBorder, "BOTTOM", 0, -2)
    resetpetCastbar:SetScript("OnClick", function()
        petCastBarScale:SetValue(1)
        petCastBarIconScale:SetValue(1)
        petCastBarXPos:SetValue(0)
        petCastBarYPos:SetValue(0)
        petCastBarWidth:SetValue(100)
        petCastBarHeight:SetValue(12)
        petCastBarTimer:SetChecked(true)
        petDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.petDetachCastbar = false
        BetterBlizzFramesDB.petCastBarTimer = true
        BBF.CastBarTimerCaller()
        BBF.ChangeCastbarSizes()
    end)

   ----------------------
    -- Focus Castbar
    ----------------------
    local anchorSubFocusCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubFocusCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", fourthLineX, firstLineY)
    anchorSubFocusCastbar:SetText("Focus Castbar")

    local focusCastbarBorder = CreateBorderedFrame(anchorSubFocusCastbar, 157, 386, 0, -145, contentFrame)

    local focusCastBar = contentFrame:CreateTexture(nil, "ARTWORK")
    focusCastBar:SetAtlas("ui-castingbar-full-applyingcrafting")
    focusCastBar:SetSize(110, 16)
    focusCastBar:SetPoint("BOTTOM", anchorSubFocusCastbar, "TOP", -1, 8.5)

    local focusCastBarScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.01, "focusCastBarScale")
    focusCastBarScale:SetPoint("TOP", anchorSubFocusCastbar, "BOTTOM", 0, -15)

    local focusCastBarXPos = CreateSlider(contentFrame, "x offset", -130, 130, 1, "focusCastBarXPos", "X")
    focusCastBarXPos:SetPoint("TOP", focusCastBarScale, "BOTTOM", 0, -15)

    local focusCastBarYPos = CreateSlider(contentFrame, "y offset", -130, 130, 1, "focusCastBarYPos", "Y")
    focusCastBarYPos:SetPoint("TOP", focusCastBarXPos, "BOTTOM", 0, -15)

    local focusCastBarWidth = CreateSlider(contentFrame, "Width", 60, 220, 1, "focusCastBarWidth")
    focusCastBarWidth:SetPoint("TOP", focusCastBarYPos, "BOTTOM", 0, -15)

    local focusCastBarHeight = CreateSlider(contentFrame, "Height", 5, 30, 1, "focusCastBarHeight")
    focusCastBarHeight:SetPoint("TOP", focusCastBarWidth, "BOTTOM", 0, -15)

    local focusCastBarIconScale = CreateSlider(contentFrame, "Icon Size", 0.4, 2, 0.01, "focusCastBarIconScale")
    focusCastBarIconScale:SetPoint("TOP", focusCastBarHeight, "BOTTOM", 0, -15)

    local focusCastbarIconXPos = CreateSlider(contentFrame, "Icon x offset", -160, 160, 1, "focusCastbarIconXPos", "X")
    focusCastbarIconXPos:SetPoint("TOP", focusCastBarIconScale, "BOTTOM", 0, -15)

    local focusCastbarIconYPos = CreateSlider(contentFrame, "Icon y offset", -160, 160, 1, "focusCastbarIconYPos", "Y")
    focusCastbarIconYPos:SetPoint("TOP", focusCastbarIconXPos, "BOTTOM", 0, -15)

    local focusStaticCastbar = CreateCheckbox("focusStaticCastbar", "Static", contentFrame)
    focusStaticCastbar:SetPoint("TOPLEFT", focusCastbarIconYPos, "BOTTOMLEFT", 10, -4)
    CreateTooltip(focusStaticCastbar, "Lock the castbar in place on its frame.\nNo longer moves depending on aura amount.")

    local focusCastBarTimer = CreateCheckbox("focusCastBarTimer", "Timer", contentFrame, nil, BBF.CastBarTimerCaller)
    focusCastBarTimer:SetPoint("LEFT", focusStaticCastbar.Text, "RIGHT", 10, 0)
    CreateTooltip(focusCastBarTimer, "Show cast timer next to the castbar.")

    local focusToTCastbarAdjustment = CreateCheckbox("focusToTCastbarAdjustment", "ToT Offset", contentFrame)
    focusToTCastbarAdjustment:SetPoint("TOPLEFT", focusStaticCastbar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(focusToTCastbarAdjustment, "Enable ToT Offset", "Makes sure the castbar is under Focus ToT frame until enough auras are displayed to push it down.\nUncheck this if you have moved your ToT frame out of the way and want to have the castbar follow the bottom of the auras no matter what.")

    local focusToTAdjustmentOffsetY = CreateSlider(focusToTCastbarAdjustment, "extra", -20, 50, 1, "focusToTAdjustmentOffsetY", "Y", 55)
    focusToTAdjustmentOffsetY:SetPoint("LEFT", focusToTCastbarAdjustment.text, "RIGHT", 2, -5)
    CreateTooltipTwo(focusToTAdjustmentOffsetY, "Extra Finetuning for ToT Offset", "Finetune the space between castbar and auras when ToT is showing. This extra offset is only active when the ToT frame is showing.")

    focusToTCastbarAdjustment:HookScript("OnClick", function(self)
        if self:GetChecked() then
            focusToTAdjustmentOffsetY:Enable()
            focusToTAdjustmentOffsetY:SetAlpha(1)
        else
            focusToTAdjustmentOffsetY:Disable()
            focusToTAdjustmentOffsetY:SetAlpha(0.5)
        end
    end)

    local focusDetachCastbar = CreateCheckbox("focusDetachCastbar", "Detach from frame", contentFrame)
    focusDetachCastbar:SetPoint("TOPLEFT", focusToTCastbarAdjustment, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    focusDetachCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            focusCastBarXPos:SetMinMaxValues(-900, 900)
            focusCastBarXPos:SetValue(0)
            focusCastBarYPos:SetMinMaxValues(-900, 900)
            focusCastBarYPos:SetValue(0)
            focusToTCastbarAdjustment:Disable()
            focusToTCastbarAdjustment:SetAlpha(0.5)
            focusToTAdjustmentOffsetY:Disable()
            focusToTAdjustmentOffsetY:SetAlpha(0.5)
            focusStaticCastbar:SetChecked(false)
            BetterBlizzFramesDB.focusStaticCastbar = false
        else
            focusCastBarXPos:SetMinMaxValues(-130, 130)
            focusCastBarXPos:SetValue(0)
            focusToTCastbarAdjustment:Enable()
            focusToTCastbarAdjustment:SetAlpha(1)
            focusToTAdjustmentOffsetY:Enable()
            focusToTAdjustmentOffsetY:SetAlpha(1)
        end
        BBF.ChangeCastbarSizes()
    end)
    CreateTooltip(focusDetachCastbar, "Detach castbar from frame and enable wider xy positioning.\nRight-click a slider to enter a specific number.")

    if BetterBlizzFramesDB.focusDetachCastbar then
        focusCastBarXPos:SetMinMaxValues(-900, 900)
        focusCastBarYPos:SetMinMaxValues(-900, 900)
        focusToTCastbarAdjustment:Disable()
        focusToTCastbarAdjustment:SetAlpha(0.5)
        focusToTAdjustmentOffsetY:Disable()
        focusToTAdjustmentOffsetY:SetAlpha(0.5)
        focusStaticCastbar:SetChecked(false)
        BetterBlizzFramesDB.focusStaticCastbar = false
    end
    focusStaticCastbar:HookScript("OnClick", function(self)
        if self:GetChecked() then
            focusToTCastbarAdjustment:Disable()
            focusToTCastbarAdjustment:SetAlpha(0.5)
            focusToTAdjustmentOffsetY:Disable()
            focusToTAdjustmentOffsetY:SetAlpha(0.5)
            focusDetachCastbar:SetChecked(false)
        else
            focusToTCastbarAdjustment:Enable()
            focusToTCastbarAdjustment:SetAlpha(1)
            focusToTAdjustmentOffsetY:Enable()
            focusToTAdjustmentOffsetY:SetAlpha(1)
        end
    end)
    if BetterBlizzFramesDB.focusStaticCastbar then
        focusToTCastbarAdjustment:Disable()
        focusToTCastbarAdjustment:SetAlpha(0.5)
        focusToTAdjustmentOffsetY:Disable()
        focusToTAdjustmentOffsetY:SetAlpha(0.5)
        focusDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.focusDetachCastbar = false
    end

    local resetFocusCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetFocusCastbar:SetText("Reset")
    resetFocusCastbar:SetWidth(70)
    resetFocusCastbar:SetPoint("TOP", focusCastbarBorder, "BOTTOM", 0, -2)
    resetFocusCastbar:SetScript("OnClick", function()
        focusCastBarScale:SetValue(1)
        focusCastBarIconScale:SetValue(1)
        focusCastBarXPos:SetValue(0)
        focusCastBarYPos:SetValue(0)
        focusCastbarIconXPos:SetValue(0)
        focusCastbarIconYPos:SetValue(0)
        focusCastBarWidth:SetValue(150)
        focusCastBarHeight:SetValue(10)
        focusCastBarTimer:SetChecked(false)
        BetterBlizzFramesDB.focusCastBarTimer = false
        focusStaticCastbar:SetChecked(false)
        BetterBlizzFramesDB.focusStaticCastbar = false
        focusDetachCastbar:SetChecked(false)
        BetterBlizzFramesDB.focusDetachCastbar = false
        focusToTCastbarAdjustment:Enable()
        focusToTCastbarAdjustment:SetAlpha(1)
        focusToTCastbarAdjustment:SetChecked(true)
        focusToTAdjustmentOffsetY:Enable()
        focusToTAdjustmentOffsetY:SetValue(0)
        BetterBlizzFramesDB.focusToTCastbarAdjustment = true
        BBF.CastBarTimerCaller()
        BBF.ChangeCastbarSizes()
    end)


   ----------------------
    -- Player Castbar
    ----------------------
    local anchorSubPlayerCastbar = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubPlayerCastbar:SetPoint("CENTER", mainGuiAnchor2, "CENTER", firstLineX, firstLineY)
    anchorSubPlayerCastbar:SetText("Player Castbar")

    local playerCastbarBorder = CreateBorderedFrame(anchorSubPlayerCastbar, 157, 250, 0, -77, contentFrame)

    local playerCastBar = contentFrame:CreateTexture(nil, "ARTWORK")
    playerCastBar:SetAtlas("ui-castingbar-filling-standard")
    playerCastBar:SetSize(110, 13)
    playerCastBar:SetPoint("BOTTOM", anchorSubPlayerCastbar, "TOP", -1, 10)


    local playerCastBarScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.01, "playerCastBarScale")
    playerCastBarScale:SetPoint("TOP", anchorSubPlayerCastbar, "BOTTOM", 0, -15)
--[[
    local playerCastBarXPos = CreateSlider(contentFrame, "x offset", -200, 200, 1, "playerCastBarXPos")
    playerCastBarXPos:SetPoint("TOP", playerCastBarScale, "BOTTOM", 0, -15)

    local playerCastBarYPos = CreateSlider(contentFrame, "y offset", -200, 200, 1, "playerCastBarYPos")
    playerCastBarYPos:SetPoint("TOP", playerCastBarXPos, "BOTTOM", 0, -15)

]]

    local playerCastBarIconScale = CreateSlider(contentFrame, "Icon Size", 0.4, 2, 0.01, "playerCastBarIconScale")
    playerCastBarIconScale:SetPoint("TOP", playerCastBarScale, "BOTTOM", 0, -15)

    local playerCastBarWidth = CreateSlider(contentFrame, "Width", 60, 230, 1, "playerCastBarWidth")
    --playerCastBarWidth:SetPoint("TOP", playerCastBarYPos, "BOTTOM", 0, -15)
    playerCastBarWidth:SetPoint("TOP", playerCastBarIconScale, "BOTTOM", 0, -15)

    local playerCastBarHeight = CreateSlider(contentFrame, "Height", 5, 30, 1, "playerCastBarHeight")
    playerCastBarHeight:SetPoint("TOP", playerCastBarWidth, "BOTTOM", 0, -15)

    local playerCastBarShowIcon = CreateCheckbox("playerCastBarShowIcon", "Icon", contentFrame, nil, BBF.ShowPlayerCastBarIcon)
    playerCastBarShowIcon:SetPoint("TOPLEFT", playerCastBarHeight, "BOTTOMLEFT", 10, -4)
    CreateTooltip(playerCastBarShowIcon, "Show spell icon to the left of the castbar\nlike on every other castbar in the game")

    local playerCastBarTimer = CreateCheckbox("playerCastBarTimer", "Timer", contentFrame, nil, BBF.CastBarTimerCaller)
    playerCastBarTimer:SetPoint("LEFT", playerCastBarShowIcon.Text, "RIGHT", 7, 0)
    CreateTooltip(playerCastBarTimer, "Show cast timer next to the castbar.")

    local playerCastBarTimerCentered = CreateCheckbox("playerCastBarTimerCentered", "Center", contentFrame, nil, BBF.CastBarTimerCaller)
    --playerStaticCastbar:SetPoint("TOPLEFT", playerCastBarIconScale, "BOTTOMLEFT", 10, -4)
    playerCastBarTimerCentered:SetPoint("LEFT", playerCastBarTimer.Text, "RIGHT", 2, 0)
    CreateTooltip(playerCastBarTimerCentered, "Center the timer in the middle of the castbar")

    local playerCastBarNoTextBorder = CreateCheckbox("playerCastBarNoTextBorder", "Simple Castbar", contentFrame, nil, BBF.ChangeCastbarSizes)
    --playerStaticCastbar:SetPoint("TOPLEFT", playerCastBarIconScale, "BOTTOMLEFT", 10, -4)
    playerCastBarNoTextBorder:SetPoint("TOPLEFT", playerCastBarShowIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(playerCastBarNoTextBorder, "Simple Castbar", "Hide the text background and move the text up inside the castbar.")

    local classicCastbarsPlayer = CreateCheckbox("classicCastbarsPlayer", "Classic Castbar", contentFrame, nil, BBF.ChangeCastbarSizes)
    classicCastbarsPlayer:SetPoint("TOPLEFT", playerCastBarNoTextBorder, "BOTTOMLEFT", -15, pixelsBetweenBoxes)
    CreateTooltipTwo(classicCastbarsPlayer, "Classic Castbar", "Use Classic layout for Player Castbar")

    local classicCastbarsPlayerBorder = CreateCheckbox("classicCastbarsPlayerBorder", "Border", classicCastbarsPlayer, nil, BBF.ChangeCastbarSizes)
    classicCastbarsPlayerBorder:SetPoint("LEFT", classicCastbarsPlayer.text, "RIGHT", 0, 0)
    CreateTooltipTwo(classicCastbarsPlayerBorder, "Classic Border", "Use the default Player Classic Castbar Boder")

    classicCastbarsPlayer:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
    end)

    local resetPlayerCastbar = CreateFrame("Button", nil, contentFrame, "UIPanelButtonTemplate")
    resetPlayerCastbar:SetText("Reset")
    resetPlayerCastbar:SetWidth(70)
    resetPlayerCastbar:SetPoint("TOP", playerCastbarBorder, "BOTTOM", 0, -2)
    resetPlayerCastbar:SetScript("OnClick", function()
        playerCastBarScale:SetValue(1)
        playerCastBarIconScale:SetValue(1)
        playerCastBarWidth:SetValue(208)
        playerCastBarHeight:SetValue(11)
        playerCastBarShowIcon:SetChecked(false)
        playerCastBarTimer:SetChecked(false)
        playerCastBarTimerCentered:SetChecked(false)
        BetterBlizzFramesDB.playerCastBarShowIcon = false
        BetterBlizzFramesDB.playerCastBarTimer = false
        BetterBlizzFramesDB.playerStaticCastbar = false
        BetterBlizzFramesDB.playerCastBarTimerCentered = false
        --PlayerCastingBarFrame.showShield = false
        BBF.CastBarTimerCaller()
        BBF.ShowPlayerCastBarIcon()
        BBF.ChangeCastbarSizes()
    end)

    local function UpdateColorSquare(icon, r, g, b, a)
        if r and g and b and a then
            icon:SetVertexColor(r, g, b, a)
        else
            icon:SetVertexColor(r, g, b)
        end
    end

    local function OpenColorPicker(colorType, icon)
        -- Ensure originalColorData has four elements, defaulting alpha (a) to 1 if not present
        local originalColorData = BetterBlizzFramesDB[colorType] or {1, 1, 1, 1}
        if #originalColorData == 3 then
            table.insert(originalColorData, 1) -- Add default alpha value if not present
        end
        local r, g, b, a = unpack(originalColorData)

        local function updateColors()
            UpdateColorSquare(icon, r, g, b, a)
            ColorPickerFrame.Content.ColorSwatchCurrent:SetAlpha(a)
        end

        local function swatchFunc()
            r, g, b = ColorPickerFrame:GetColorRGB()
            BetterBlizzFramesDB[colorType] = {r, g, b, a}
            updateColors()
        end

        local function opacityFunc()
            a = ColorPickerFrame:GetColorAlpha()
            BetterBlizzFramesDB[colorType] = {r, g, b, a}
            updateColors()
        end

        local function cancelFunc()
            r, g, b, a = unpack(originalColorData)
            BetterBlizzFramesDB[colorType] = {r, g, b, a}
            updateColors()
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, opacity = a, hasOpacity = true,
            swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
        })
    end

    local castBarInterruptHighlighterText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    castBarInterruptHighlighterText:SetPoint("LEFT", contentFrame, "TOPRIGHT", -235, -465)
    castBarInterruptHighlighterText:SetText("Castbar Edge Highlight settings")

    local castBarInterruptHighlighter = CreateCheckbox("castBarInterruptHighlighter", "Castbar Edge Highlight", contentFrame, nil, BBF.CastbarRecolorWidgets)
    castBarInterruptHighlighter:SetPoint("TOPLEFT", castBarInterruptHighlighterText, "BOTTOMLEFT", 0, pixelsOnFirstBox)
    CreateTooltip(castBarInterruptHighlighter, "Color the start and end of the castbar differently.\nSet the percentile of cast to color down below.")

    local targetCastbarEdgeHighlight = CreateCheckbox("targetCastbarEdgeHighlight", "Target", castBarInterruptHighlighter, nil, BBF.CastbarRecolorWidgets)
    targetCastbarEdgeHighlight:SetPoint("TOPLEFT", castBarInterruptHighlighter, "BOTTOMLEFT", 15, pixelsBetweenBoxes)
    CreateTooltip(targetCastbarEdgeHighlight, "Enable for TargetFrame Castbar")

    local focusCastbarEdgeHighlight = CreateCheckbox("focusCastbarEdgeHighlight", "Focus", castBarInterruptHighlighter, nil, BBF.CastbarRecolorWidgets)
    focusCastbarEdgeHighlight:SetPoint("LEFT", targetCastbarEdgeHighlight.text, "RIGHT", 0, 0)
    CreateTooltip(focusCastbarEdgeHighlight, "Enable for FocusFrame Castbar")

    local castBarInterruptHighlighterColorDontInterrupt = CreateCheckbox("castBarInterruptHighlighterColorDontInterrupt", "Re-color between portion", castBarInterruptHighlighter, nil, BBF.CastbarRecolorWidgets)
    castBarInterruptHighlighterColorDontInterrupt:SetPoint("TOPLEFT", targetCastbarEdgeHighlight, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(castBarInterruptHighlighterColorDontInterrupt,"Re-color the middle part of the castbar between the percentages")

    local castBarInterruptHighlighterDontInterruptRGB = CreateFrame("Button", nil, castBarInterruptHighlighterColorDontInterrupt, "UIPanelButtonTemplate")
    castBarInterruptHighlighterDontInterruptRGB:SetText("Color")
    castBarInterruptHighlighterDontInterruptRGB:SetPoint("LEFT", castBarInterruptHighlighterColorDontInterrupt.text, "RIGHT", 2, 0)
    castBarInterruptHighlighterDontInterruptRGB:SetSize(50, 20)
    CreateTooltip(castBarInterruptHighlighterDontInterruptRGB, "Castbar color inbetween the start and finish")
    local castBarInterruptHighlighterDontInterruptRGBIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    castBarInterruptHighlighterDontInterruptRGBIcon:SetAtlas("newplayertutorial-icon-key")
    castBarInterruptHighlighterDontInterruptRGBIcon:SetSize(18, 17)
    castBarInterruptHighlighterDontInterruptRGBIcon:SetPoint("LEFT", castBarInterruptHighlighterDontInterruptRGB, "RIGHT", 0, -1)
    UpdateColorSquare(castBarInterruptHighlighterDontInterruptRGBIcon, unpack(BetterBlizzFramesDB["castBarInterruptHighlighterDontInterruptRGB"] or {1, 1, 1}))
    castBarInterruptHighlighterDontInterruptRGB:SetScript("OnClick", function()
        OpenColorPicker("castBarInterruptHighlighterDontInterruptRGB", castBarInterruptHighlighterDontInterruptRGBIcon)
    end)

    local castBarInterruptHighlighterStartTime = CreateSlider(castBarInterruptHighlighter, "Start Seconds", 0, 2, 0.01, "castBarInterruptHighlighterStartTime", "Height")
    castBarInterruptHighlighterStartTime:SetPoint("TOPLEFT", castBarInterruptHighlighterColorDontInterrupt, "BOTTOMLEFT", 10, -6)
    CreateTooltip(castBarInterruptHighlighterStartTime, "How many seconds of the start of the cast you want to color the castbar.")

    local castBarInterruptHighlighterEndTime = CreateSlider(castBarInterruptHighlighter, "End Seconds", 0, 2, 0.01, "castBarInterruptHighlighterEndTime", "Height")
    castBarInterruptHighlighterEndTime:SetPoint("TOPLEFT", castBarInterruptHighlighterStartTime, "BOTTOMLEFT", 0, -10)
    CreateTooltip(castBarInterruptHighlighterEndTime, "How many seconds of the end of the cast you want to color the castbar.")

    local castBarInterruptHighlighterInterruptRGB = CreateFrame("Button", nil, castBarInterruptHighlighter, "UIPanelButtonTemplate")
    castBarInterruptHighlighterInterruptRGB:SetText("Color")
    castBarInterruptHighlighterInterruptRGB:SetPoint("LEFT", castBarInterruptHighlighterEndTime, "RIGHT", 0, 15)
    castBarInterruptHighlighterInterruptRGB:SetSize(50, 20)
    CreateTooltip(castBarInterruptHighlighterInterruptRGB, "Castbar edge color")
    local castBarInterruptHighlighterInterruptRGBIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    castBarInterruptHighlighterInterruptRGBIcon:SetAtlas("newplayertutorial-icon-key")
    castBarInterruptHighlighterInterruptRGBIcon:SetSize(18, 17)
    castBarInterruptHighlighterInterruptRGBIcon:SetPoint("LEFT", castBarInterruptHighlighterInterruptRGB, "RIGHT", 0, -1)
    UpdateColorSquare(castBarInterruptHighlighterInterruptRGBIcon, unpack(BetterBlizzFramesDB["castBarInterruptHighlighterInterruptRGB"] or {1, 1, 1}))
    castBarInterruptHighlighterInterruptRGB:SetScript("OnClick", function()
        OpenColorPicker("castBarInterruptHighlighterInterruptRGB", castBarInterruptHighlighterInterruptRGBIcon)
    end)

    castBarInterruptHighlighter:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(castBarInterruptHighlighter)
        if self:GetChecked() then
            if BetterBlizzFramesDB.castBarInterruptHighlighterColorDontInterrupt then
                castBarInterruptHighlighterDontInterruptRGBIcon:SetAlpha(1)
            end
            castBarInterruptHighlighterInterruptRGBIcon:SetAlpha(1)
        else
            castBarInterruptHighlighterDontInterruptRGBIcon:SetAlpha(0)
            castBarInterruptHighlighterInterruptRGBIcon:SetAlpha(0)
        end
    end)

    castBarInterruptHighlighterColorDontInterrupt:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(castBarInterruptHighlighter)
        if self:GetChecked() then
            castBarInterruptHighlighterDontInterruptRGBIcon:SetAlpha(1)
        else
            castBarInterruptHighlighterDontInterruptRGBIcon:SetAlpha(0)
        end
    end)



    local castBarRecolorInterrupt = CreateCheckbox("castBarRecolorInterrupt", "Interrupt CD Color", contentFrame, nil, BBF.CastbarRecolorWidgets)
    castBarRecolorInterrupt:SetPoint("LEFT", contentFrame, "TOPRIGHT", -428, -460)
    CreateTooltipTwo(castBarRecolorInterrupt, "Interrupt CD Color", "Checks if you have interrupt ready and colors Target & Focus Castbar thereafter. By default Red when you don't have interrupt ready and purple when you will get interrupt back during the cast.")

    local castBarRecolorInterruptArenaFrames = CreateCheckbox("castBarRecolorInterruptArenaFrames", "Arena", contentFrame, nil, BBF.CastbarRecolorWidgets)
    castBarRecolorInterruptArenaFrames:SetPoint("LEFT", castBarRecolorInterrupt.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(castBarRecolorInterruptArenaFrames, "Interrupt CD Color: Arena Frames", "Enable Interrupt CD Color on Arena Frame Castbars as well (Gladius, GEX, sArena, Blizzard)")

    local castBarInterruptIconEnabled = CreateCheckbox("castBarInterruptIconEnabled", "Interrupt CD Icon", contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarInterruptIconEnabled:SetPoint("BOTTOMLEFT", castBarRecolorInterrupt, "TOPLEFT", 0, -pixelsBetweenBoxes)
    CreateTooltipTwo(castBarInterruptIconEnabled, "Interrupt CD Icon", "Shows your interrupt CD next to the enemy castbars.\nMore settings in Advanced Settings", "Needs a few tweaks still for pet class interrupts etc.")

    local castBarNoInterruptColor = CreateFrame("Button", nil, castBarRecolorInterrupt, "UIPanelButtonTemplate")
    castBarNoInterruptColor:SetText("Interrupt on CD")
    castBarNoInterruptColor:SetPoint("TOPLEFT", castBarRecolorInterrupt, "BOTTOMRIGHT", -35, 3)
    castBarNoInterruptColor:SetSize(139, 20)
    CreateTooltip(castBarNoInterruptColor, "Castbar color when interrupt is on CD")
    local castBarNoInterruptColorIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    castBarNoInterruptColorIcon:SetAtlas("newplayertutorial-icon-key")
    castBarNoInterruptColorIcon:SetSize(18, 17)
    castBarNoInterruptColorIcon:SetPoint("LEFT", castBarNoInterruptColor, "RIGHT", 0, -1)
    UpdateColorSquare(castBarNoInterruptColorIcon, unpack(BetterBlizzFramesDB["castBarNoInterruptColor"] or {1, 1, 1}))
    castBarNoInterruptColor:SetScript("OnClick", function()
        OpenColorPicker("castBarNoInterruptColor", castBarNoInterruptColorIcon)
    end)

    local castBarDelayedInterruptColor = CreateFrame("Button", nil, castBarRecolorInterrupt, "UIPanelButtonTemplate")
    castBarDelayedInterruptColor:SetText("Interrupt CD soon")
    castBarDelayedInterruptColor:SetPoint("TOPLEFT", castBarNoInterruptColor, "BOTTOMLEFT", 0, -5)
    castBarDelayedInterruptColor:SetSize(139, 20)
    CreateTooltip(castBarDelayedInterruptColor, "Castbar color when interrupt is on CD but\nwill be ready before the cast ends")
    local castBarDelayedInterruptColorIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    castBarDelayedInterruptColorIcon:SetAtlas("newplayertutorial-icon-key")
    castBarDelayedInterruptColorIcon:SetSize(18, 17)
    castBarDelayedInterruptColorIcon:SetPoint("LEFT", castBarDelayedInterruptColor, "RIGHT", 0, -1)
    UpdateColorSquare(castBarDelayedInterruptColorIcon, unpack(BetterBlizzFramesDB["castBarDelayedInterruptColor"] or {1, 1, 1}))
    castBarDelayedInterruptColor:SetScript("OnClick", function()
        OpenColorPicker("castBarDelayedInterruptColor", castBarDelayedInterruptColorIcon)
    end)


    local buffsOnTopReverseCastbarMovement = CreateCheckbox("buffsOnTopReverseCastbarMovement", "Buffs on Top: Reverse Castbar Movement", contentFrame, nil, BBF.CastbarAdjustCaller)
    buffsOnTopReverseCastbarMovement:SetPoint("LEFT", contentFrame, "TOPRIGHT", -470, -540)
    CreateTooltipTwo(buffsOnTopReverseCastbarMovement, "Buffs on Top: Reverse Castbar Movement", "Changes the castbar movement to follow the top row of auras on Target/Focus Frame similar to how it works by default without \"Buffs on Top\" enabled except in reverse.\n\nBy default with Buffs on Top enabled your castbar will just sit beneath the target frame and not move.")

    local normalCastbarForEmpoweredCasts = CreateCheckbox("normalCastbarForEmpoweredCasts", "Normal Evoker Empowered Castbar", contentFrame, nil, BBF.HookCastbarsForEvoker)
    normalCastbarForEmpoweredCasts:SetPoint("TOPLEFT", buffsOnTopReverseCastbarMovement, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(normalCastbarForEmpoweredCasts, "Normal Evoker Castbar", "Change Evoker empowered castbars to look like normal ones.\n(Easier to see if you can interrupt)")
    normalCastbarForEmpoweredCasts:HookScript("OnClick", function(self)
        if BetterBlizzPlatesDB then
            if self:GetChecked() then
                BetterBlizzPlatesDB.normalCastbarForEmpoweredCasts = true
            else
                BetterBlizzPlatesDB.normalCastbarForEmpoweredCasts = false
            end
        end
    end)

    local quickHideCastbars = CreateCheckbox("quickHideCastbars", "Quick Hide Castbars", contentFrame)
    quickHideCastbars:SetPoint("TOPLEFT", normalCastbarForEmpoweredCasts, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(quickHideCastbars, "Quick Hide Castbars", "Instantly hide target and focus castbars after their cast is finished or interrupted.\nBy default there is a slow fade out animation.")
    quickHideCastbars:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local classicCastbars = CreateCheckbox("classicCastbars", "Classic Castbars", contentFrame, nil, BBF.ChangeCastbarSizes)
    classicCastbars:SetPoint("TOPLEFT", quickHideCastbars, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(classicCastbars, "Classic Castbars", "Use Classic layout for Target & Focus castbars")
    classicCastbars:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
end

local function guiPositionAndScale()

    ----------------------
    -- Advanced settings
    ----------------------
    local firstLineX = 53
    local firstLineY = -65
    local secondLineX = 222
    local secondLineY = -360
    local thirdLineX = 391
    local thirdLineY = -655
    local fourthLineX = 560

    local BetterBlizzFramesSubPanel = CreateFrame("Frame")
    BetterBlizzFramesSubPanel.name = "Advanced Settings"
    BetterBlizzFramesSubPanel.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(BetterBlizzFramesSubPanel)
    local advancedSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, BetterBlizzFramesSubPanel, BetterBlizzFramesSubPanel.name, BetterBlizzFramesSubPanel.name)
    advancedSubCategory.ID = BetterBlizzFramesSubPanel.name;
    BBF.category.AdvancedSettings = BetterBlizzFramesSubPanel.name
    CreateTitle(BetterBlizzFramesSubPanel)

    local bgImg = BetterBlizzFramesSubPanel:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", BetterBlizzFramesSubPanel, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)





    local scrollFrame = CreateFrame("ScrollFrame", nil, BetterBlizzFramesSubPanel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(700, 612)
    scrollFrame:SetPoint("CENTER", BetterBlizzFramesSubPanel, "CENTER", -20, 3)

    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame.name = BetterBlizzFramesSubPanel.name
    contentFrame:SetSize(680, 520)
    scrollFrame:SetScrollChild(contentFrame)

    local mainGuiAnchor2 = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor2:SetPoint("TOPLEFT", 55, 20)
    mainGuiAnchor2:SetText(" ")

 --[[
    ----------------------
    -- Focus Target
    ----------------------
    local anchorFocusTarget = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorFocusTarget:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX, firstLineY)
    anchorFocusTarget:SetText("Focus ToT")

    CreateBorderBox(anchorFocusTarget)

    local focusTargetFrameIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    focusTargetFrameIcon:SetAtlas("greencross")
    focusTargetFrameIcon:SetSize(32, 32)
    focusTargetFrameIcon:SetPoint("BOTTOM", anchorFocusTarget, "TOP", 0, 0)
    focusTargetFrameIcon:SetTexCoord(0.1953125, 0.8046875, 0.1953125, 0.8046875)

    local focusToTScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.1, "focusToTScale")
    focusToTScale:SetPoint("TOP", anchorFocusTarget, "BOTTOM", 0, -15)

    local focusToTXPos = CreateSlider(contentFrame, "x offset", -100, 100, 1, "focusToTXPos", "X")
    focusToTXPos:SetPoint("TOP", focusToTScale, "BOTTOM", 0, -15)

    local focusToTYPos = CreateSlider(contentFrame, "y offset", -100, 100, 1, "focusToTYPos", "Y")
    focusToTYPos:SetPoint("TOP", focusToTXPos, "BOTTOM", 0, -15)

    local focusToTDropdown = CreateAnchorDropdown(
        "focusToTDropdown",
        contentFrame,
        "Select Anchor Point",
        "focusToTAnchor",
        function(arg1) 
            BBF.MoveToTFrames()
        end,
        { anchorFrame = focusToTYPos, x = -16, y = -35, label = "Anchor" }
    )

    local combatIndicatorEnemyOnly = CreateCheckbox("combatIndicatorEnemyOnly", "Enemies only", contentFrame)
    combatIndicatorEnemyOnly:SetPoint("TOPLEFT", focusToTDropdown, "BOTTOMLEFT", 16, pixelsBetweenBoxes)
 
 ]]
 


 --[[
    ----------------------
    -- Pet Frame
    ----------------------
    local anchorPetFrame = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorPetFrame:SetPoint("CENTER", mainGuiAnchor2, "CENTER", thirdLineX, firstLineY)
    anchorPetFrame:SetText("Pet Frame")

    CreateBorderBox(anchorPetFrame)

    local partyFrameIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    partyFrameIcon:SetAtlas("greencross")
    partyFrameIcon:SetSize(32, 32)
    partyFrameIcon:SetPoint("BOTTOM", anchorPetFrame, "TOP", 0, 0)
    partyFrameIcon:SetTexCoord(0.1953125, 0.8046875, 0.1953125, 0.8046875)

    local petFrameScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.1, "petFrameScale")
    petFrameScale:SetPoint("TOP", anchorPetFrame, "BOTTOM", 0, -15)

    local petFrameXPos = CreateSlider(contentFrame, "x offset", -100, 100, 1, "petFrameXPos", "X")
    petFrameXPos:SetPoint("TOP", petFrameScale, "BOTTOM", 0, -15)

    local petFrameYPos = CreateSlider(contentFrame, "y offset", -100, 100, 1, "petFrameYPos", "Y")
    petFrameYPos:SetPoint("TOP", petFrameXPos, "BOTTOM", 0, -15)

    local petFrameDropdown = CreateAnchorDropdown(
        "petFrameDropdown",
        contentFrame,
        "Select Anchor Point",
        "petFrameAnchor",
        function(arg1) 
            BBF.MoveToTFrames()
        end,
        { anchorFrame = petFrameYPos, x = -16, y = -35, label = "Anchor" }
    )
 
 ]]
 



   ----------------------
    -- Absorb Indicator
    ----------------------
    local anchorSubAbsorb = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubAbsorb:SetPoint("CENTER", mainGuiAnchor2, "CENTER", fourthLineX - 30, firstLineY)
    anchorSubAbsorb:SetText("Absorb Indicator")

    --CreateBorderBox(anchorSubAbsorb)
    CreateBorderedFrame(anchorSubAbsorb, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local absorbIndicator = contentFrame:CreateTexture(nil, "ARTWORK")
    absorbIndicator:SetAtlas("ParagonReputation_Glow")
    absorbIndicator:SetSize(56, 56)
    absorbIndicator:SetPoint("BOTTOM", anchorSubAbsorb, "TOP", -1, -10)
    CreateTooltip(absorbIndicator, "Show absorb amount on target/focus frame. Enable on the General page.")

    local absorbIndicatorScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.01, "absorbIndicatorScale")
    absorbIndicatorScale:SetPoint("TOP", anchorSubAbsorb, "BOTTOM", 0, -15)

    local absorbIndicatorXPos = CreateSlider(contentFrame, "x offset", -100, 100, 1, "playerAbsorbXPos", "X")
    absorbIndicatorXPos:SetPoint("TOP", absorbIndicatorScale, "BOTTOM", 0, -15)

    local absorbIndicatorYPos = CreateSlider(contentFrame, "y offset", -100, 100, 1, "playerAbsorbYPos", "Y")
    absorbIndicatorYPos:SetPoint("TOP", absorbIndicatorXPos, "BOTTOM", 0, -15)

    local playerAbsorbAnchorDropdown = CreateAnchorDropdown(
        "playerAbsorbAnchorDropdown",
        contentFrame,
        "Select Anchor Point",
        "playerAbsorbAnchor",
        function(arg1)
        BBF.AbsorbCaller()
    end,
        { anchorFrame = absorbIndicatorYPos, x = -16, y = -35, label = "Anchor" }
    )

    local absorbIndicatorTestMode = CreateCheckbox("absorbIndicatorTestMode", "Test", contentFrame, nil, BBF.AbsorbCaller)
    absorbIndicatorTestMode:SetPoint("TOPLEFT", playerAbsorbAnchorDropdown, "BOTTOMLEFT", 10, pixelsBetweenBoxes)

    local absorbIndicatorFlipIconText = CreateCheckbox("absorbIndicatorFlipIconText", "Flip Icon & Text", contentFrame, nil, BBF.AbsorbCaller)
    absorbIndicatorFlipIconText:SetPoint("LEFT", absorbIndicatorTestMode.text, "RIGHT", 5, 0)




--[[
    local absorbIndicatorEnemyOnly = CreateCheckbox("absorbIndicatorEnemyOnly", "Enemy only", contentFrame)
    absorbIndicatorEnemyOnly:SetPoint("TOPLEFT", absorbIndicatorTestMode, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local absorbIndicatorOnPlayersOnly = CreateCheckbox("absorbIndicatorOnPlayersOnly", "Players only", contentFrame)
    absorbIndicatorOnPlayersOnly:SetPoint("TOPLEFT", absorbIndicatorEnemyOnly, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

]]


    --
    local playerAbsorbAmount = CreateCheckbox("playerAbsorbAmount", "Player", contentFrame, nil, BBF.AbsorbCaller)
    playerAbsorbAmount:SetPoint("TOPLEFT", absorbIndicatorTestMode, "BOTTOMLEFT", -5, -14)
    CreateTooltip(playerAbsorbAmount, "Show absorb indicator on PlayerFrame")

    local playerAbsorbIcon = CreateCheckbox("playerAbsorbIcon", "Icon", contentFrame, nil, BBF.AbsorbCaller)
    playerAbsorbIcon:SetPoint("TOPLEFT", playerAbsorbAmount, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(playerAbsorbIcon, "Show icon of the largest absorb spell")

    local targetAbsorbAmount = CreateCheckbox("targetAbsorbAmount", "Target", contentFrame, nil, BBF.AbsorbCaller)
    targetAbsorbAmount:SetPoint("LEFT", playerAbsorbAmount.Text, "RIGHT", 5, 0)
    CreateTooltip(targetAbsorbAmount, "Show absorb indicator on TargetFrame")

    local targetAbsorbIcon = CreateCheckbox("targetAbsorbIcon", "Icon", contentFrame, nil, BBF.AbsorbCaller)
    targetAbsorbIcon:SetPoint("TOPLEFT", targetAbsorbAmount, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetAbsorbIcon, "Show icon of the largest absorb spell")

    local focusAbsorbAmount = CreateCheckbox("focusAbsorbAmount", "Focus", contentFrame, nil, BBF.AbsorbCaller)
    focusAbsorbAmount:SetPoint("LEFT", targetAbsorbAmount.Text, "RIGHT", 5, 0)
    CreateTooltip(focusAbsorbAmount, "Show absorb indicator on FocusFrame")

    local focusAbsorbIcon = CreateCheckbox("focusAbsorbIcon", "Icon", contentFrame, nil, BBF.AbsorbCaller)
    focusAbsorbIcon:SetPoint("TOPLEFT", focusAbsorbAmount, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusAbsorbIcon, "Show icon of the largest absorb spell")










    --------------------------
    -- Combat indicator
    ----------------------
    local anchorSubOutOfCombat = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubOutOfCombat:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX-145, firstLineY)
    anchorSubOutOfCombat:SetText("Combat Indicator")

    --CreateBorderBox(anchorSubOutOfCombat)
    CreateBorderedFrame(anchorSubOutOfCombat, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local combatIconSub = contentFrame:CreateTexture(nil, "ARTWORK")
    combatIconSub:SetTexture("Interface\\Icons\\ABILITY_DUALWIELD")
    combatIconSub:SetSize(34, 34)
    combatIconSub:SetPoint("BOTTOM", anchorSubOutOfCombat, "TOP", 0, 1)
    CreateTooltip(combatIconSub, "Show combat status on target/focus frame. Enable on the General page.")

    local combatIndicatorScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.01, "combatIndicatorScale")
    combatIndicatorScale:SetPoint("TOP", anchorSubOutOfCombat, "BOTTOM", 0, -15)

    local combatIndicatorXPos = CreateSlider(contentFrame, "x offset", -50, 50, 1, "combatIndicatorXPos", "X")
    combatIndicatorXPos:SetPoint("TOP", combatIndicatorScale, "BOTTOM", 0, -15)

    local combatIndicatorYPos = CreateSlider(contentFrame, "y offset", -50, 50, 1, "combatIndicatorYPos", "Y")
    combatIndicatorYPos:SetPoint("TOP", combatIndicatorXPos, "BOTTOM", 0, -15)

    local combatIndicatorDropdown = CreateAnchorDropdown(
        "combatIndicatorDropdown",
        contentFrame,
        "Select Anchor Point",
        "combatIndicatorAnchor",
        function(arg1) 
            BBF.CombatIndicatorCaller()
        end,
        { anchorFrame = combatIndicatorYPos, x = -16, y = -35, label = "Anchor" }
    )

    local combatIndicatorArenaOnly = CreateCheckbox("combatIndicatorArenaOnly", "Arena only", contentFrame)
    combatIndicatorArenaOnly:SetPoint("TOPLEFT", combatIndicatorDropdown, "BOTTOMLEFT", 5, pixelsBetweenBoxes)
    combatIndicatorArenaOnly:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltip(combatIndicatorArenaOnly, "Only show Combat Indicator during arena")

    local combatIndicatorShowSap = CreateCheckbox("combatIndicatorShowSap", "No combat", contentFrame)
    combatIndicatorShowSap:SetPoint("TOPLEFT", combatIndicatorArenaOnly, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    combatIndicatorShowSap:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltip(combatIndicatorShowSap, "Show sap icon when not in combat")

    local combatIndicatorShowSwords = CreateCheckbox("combatIndicatorShowSwords", "In combat", contentFrame)
    combatIndicatorShowSwords:SetPoint("LEFT", combatIndicatorShowSap.Text, "RIGHT", 5, 0)
    combatIndicatorShowSwords:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltip(combatIndicatorShowSwords, "Show swords icon when in combat")

    local combatIndicatorPlayersOnly = CreateCheckbox("combatIndicatorPlayersOnly", "Players only", contentFrame)
    combatIndicatorPlayersOnly:SetPoint("LEFT", combatIndicatorArenaOnly.Text, "RIGHT", 5, 0)
    combatIndicatorPlayersOnly:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)
    CreateTooltip(combatIndicatorPlayersOnly, "Only show on players and not npcs")

    local playerCombatIndicator = CreateCheckbox("playerCombatIndicator", "Player", contentFrame)
    playerCombatIndicator:SetPoint("TOPLEFT", combatIndicatorShowSap, "BOTTOMLEFT", -5, -10)
    playerCombatIndicator:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)

    local targetCombatIndicator = CreateCheckbox("targetCombatIndicator", "Target", contentFrame)
    targetCombatIndicator:SetPoint("LEFT", playerCombatIndicator.Text, "RIGHT", 5, 0)
    targetCombatIndicator:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)

    local focusCombatIndicator = CreateCheckbox("focusCombatIndicator", "Focus", contentFrame)
    focusCombatIndicator:SetPoint("LEFT", targetCombatIndicator.Text, "RIGHT", 5, 0)
    focusCombatIndicator:HookScript("OnClick", function(self)
        BBF.CombatIndicatorCaller()
    end)


    --------------------------
    -- Healer Indicator
    ----------------------
    local anchorSubHealerIndicator = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubHealerIndicator:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX+81, firstLineY)
    anchorSubHealerIndicator:SetText("Healer Indicator")

    --CreateBorderBox(anchorSubHealerIndicator)
    CreateBorderedFrame(anchorSubHealerIndicator, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local healerIconSub = contentFrame:CreateTexture(nil, "ARTWORK")
    healerIconSub:SetAtlas("bags-icon-addslots")
    healerIconSub:SetSize(34, 34)
    healerIconSub:SetPoint("BOTTOM", anchorSubHealerIndicator, "TOP", 0, 1)
    CreateTooltip(healerIconSub, "Show Healer Icon on Target/FocusFrame. Enable on the General page.")

    local healerIndicatorScale = CreateSlider(contentFrame, "Size", 0.8, 2.5, 0.01, "healerIndicatorScale")
    healerIndicatorScale:SetPoint("TOP", anchorSubHealerIndicator, "BOTTOM", 0, -15)

    local healerIndicatorXPos = CreateSlider(contentFrame, "x offset", -50, 50, 1, "healerIndicatorXPos", "X")
    healerIndicatorXPos:SetPoint("TOP", healerIndicatorScale, "BOTTOM", 0, -15)

    local healerIndicatorYPos = CreateSlider(contentFrame, "y offset", -50, 50, 1, "healerIndicatorYPos", "Y")
    healerIndicatorYPos:SetPoint("TOP", healerIndicatorXPos, "BOTTOM", 0, -15)

    local healerIndicatorDropdown = CreateAnchorDropdown(
        "healerIndicatorDropdown",
        contentFrame,
        "Select Anchor Point",
        "healerIndicatorAnchor",
        function(arg1) 
            BBF.HealerIndicatorCaller()
        end,
        { anchorFrame = healerIndicatorYPos, x = -16, y = -35, label = "Anchor" }
    )

    local healerIndicatorIcon = CreateCheckbox("healerIndicatorIcon", "Icon", contentFrame)
    healerIndicatorIcon:SetPoint("TOPLEFT", healerIndicatorDropdown, "BOTTOMLEFT", 24, pixelsBetweenBoxes)
    healerIndicatorIcon:HookScript("OnClick", function(self)
        if self:GetChecked() and not BetterBlizzFramesDB.healerIndicator then
            BetterBlizzFramesDB.healerIndicator = true
        end
        BBF.HealerIndicatorCaller()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(healerIndicatorIcon, "Show an Icon on Target & Focus Frame for Healers.")

    local healerIndicatorPortrait = CreateCheckbox("healerIndicatorPortrait", "Portrait", contentFrame)
    healerIndicatorPortrait:SetPoint("LEFT", healerIndicatorIcon.Text, "RIGHT", 5, 0)
    healerIndicatorPortrait:HookScript("OnClick", function(self)
        if self:GetChecked() and not BetterBlizzFramesDB.healerIndicator then
            BetterBlizzFramesDB.healerIndicator = true
        end
        BBF.HealerIndicatorCaller()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(healerIndicatorPortrait, "Change Portraits for Healers on Target & FocusFrame to a Healer Icon.")



    --------------------------
    -- Racial indicator
    ----------------------
    local anchorSubracialIndicator = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubracialIndicator:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX-145, secondLineY - 15)
    anchorSubracialIndicator:SetText("PvP Racial Indicator")

    --CreateBorderBox(anchorSubracialIndicator)
    CreateBorderedFrame(anchorSubracialIndicator, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local racialIndicatorIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    racialIndicatorIcon:SetTexture("Interface\\Icons\\ability_ambush")
    racialIndicatorIcon:SetSize(34, 34)
    racialIndicatorIcon:SetPoint("BOTTOM", anchorSubracialIndicator, "TOP", 0, 1)
    CreateTooltip(racialIndicatorIcon, "Show racial icon on target/focus. Enable on the General page.")

    local racialIndicatorScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.01, "racialIndicatorScale")
    racialIndicatorScale:SetPoint("TOP", anchorSubracialIndicator, "BOTTOM", 0, -15)

    local racialIndicatorXPos = CreateSlider(contentFrame, "x offset", -50, 50, 1, "racialIndicatorXPos", "X")
    racialIndicatorXPos:SetPoint("TOP", racialIndicatorScale, "BOTTOM", 0, -15)

    local racialIndicatorYPos = CreateSlider(contentFrame, "y offset", -50, 50, 1, "racialIndicatorYPos", "Y")
    racialIndicatorYPos:SetPoint("TOP", racialIndicatorXPos, "BOTTOM", 0, -15)

    local racialIndicatorOrc = CreateCheckbox("racialIndicatorOrc", "Orc", contentFrame)
    racialIndicatorOrc:SetPoint("TOPLEFT", racialIndicatorYPos, "BOTTOMLEFT", 5, -5)
    racialIndicatorOrc:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorOrc, "Show for Orc")

    local racialIndicatorHuman = CreateCheckbox("racialIndicatorHuman", "Human", contentFrame)
    racialIndicatorHuman:SetPoint("TOPLEFT", racialIndicatorOrc, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicatorHuman:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorHuman, "Show for Human")

    local racialIndicatorDwarf = CreateCheckbox("racialIndicatorDwarf", "Dwarf", contentFrame)
    racialIndicatorDwarf:SetPoint("TOPLEFT", racialIndicatorHuman, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicatorDwarf:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorDwarf, "Show for Dwarf")

    local racialIndicatorNelf = CreateCheckbox("racialIndicatorNelf", "Night Elf", contentFrame)
    racialIndicatorNelf:SetPoint("LEFT", racialIndicatorOrc.Text, "RIGHT", 25, 0)
    racialIndicatorNelf:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorNelf, "Show for Night Elf")

    local racialIndicatorUndead = CreateCheckbox("racialIndicatorUndead", "Undead", contentFrame)
    racialIndicatorUndead:SetPoint("TOPLEFT", racialIndicatorNelf, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicatorUndead:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorUndead, "Show for Undead")

    local racialIndicatorDarkIronDwarf = CreateCheckbox("racialIndicatorDarkIronDwarf", "D.I.Dwarf", contentFrame)
    racialIndicatorDarkIronDwarf:SetPoint("TOPLEFT", racialIndicatorUndead, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    racialIndicatorDarkIronDwarf:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorDarkIronDwarf, "Show for Dark Iron Dwarf")

    local targetRacialIndicator = CreateCheckbox("targetRacialIndicator", "Target", contentFrame)
    targetRacialIndicator:SetPoint("TOPLEFT", racialIndicatorDwarf, "BOTTOMLEFT", 0, -10)
    targetRacialIndicator:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(targetRacialIndicator, "Show on TargetFrame")

    local focusRacialIndicator = CreateCheckbox("focusRacialIndicator", "Focus", contentFrame)
    focusRacialIndicator:SetPoint("LEFT", targetRacialIndicator.Text, "RIGHT", 12, 0)
    focusRacialIndicator:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(focusRacialIndicator, "Show on FocusFrame")

    local racialIndicatorRaceIcons = CreateCheckbox("racialIndicatorRaceIcons", "Race Icon", contentFrame)
    racialIndicatorRaceIcons:SetPoint("TOPLEFT", targetRacialIndicator, "BOTTOMLEFT", 12, pixelsBetweenBoxes)
    racialIndicatorRaceIcons:HookScript("OnClick", function(self)
        BBF.RacialIndicatorCaller()
    end)
    CreateTooltip(racialIndicatorRaceIcons, "Show race icon instead of the racial spell icon")

    ----------------------
    -- Castbar Interrupt Icon
    ----------------------
    local anchorSubInterruptIcon = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorSubInterruptIcon:SetPoint("CENTER", mainGuiAnchor2, "CENTER", secondLineX+81, secondLineY-15)
    anchorSubInterruptIcon:SetText("Interrupt Icon")

    --CreateBorderBox(anchorSubInterruptIcon)
    CreateBorderedFrame(anchorSubInterruptIcon, 200, 293, 0, -98, BetterBlizzFramesSubPanel)

    local castBarInterruptIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    castBarInterruptIcon:SetTexture("Interface\\Icons\\ability_kick")
    castBarInterruptIcon:SetSize(34, 34)
    castBarInterruptIcon:SetPoint("BOTTOM", anchorSubInterruptIcon, "TOP", 0, 0)
    CreateTooltip(castBarInterruptIcon, "Show interrupt icon next to castbar")

    local castBarInterruptIconScale = CreateSlider(contentFrame, "Size", 0.1, 1.9, 0.01, "castBarInterruptIconScale")
    castBarInterruptIconScale:SetPoint("TOP", anchorSubInterruptIcon, "BOTTOM", 0, -15)

    local castBarInterruptIconXPos = CreateSlider(contentFrame, "x offset", -100, 100, 1, "castBarInterruptIconXPos", "X")
    castBarInterruptIconXPos:SetPoint("TOP", castBarInterruptIconScale, "BOTTOM", 0, -15)

    local castBarInterruptIconYPos = CreateSlider(contentFrame, "y offset", -100, 100, 1, "castBarInterruptIconYPos", "Y")
    castBarInterruptIconYPos:SetPoint("TOP", castBarInterruptIconXPos, "BOTTOM", 0, -15)

    local castBarInterruptIconAnchorDropdown = CreateAnchorDropdown(
        "castBarInterruptIconAnchorDropdown",
        contentFrame,
        "Select Anchor Point",
        "castBarInterruptIconAnchor",
        function(arg1)
        BBF.UpdateInterruptIconSettings()
    end,
        { anchorFrame = castBarInterruptIconYPos, x = -16, y = -35, label = "Anchor" }
    )

    local castBarInterruptIconTarget = CreateCheckbox("castBarInterruptIconTarget", "Target", contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarInterruptIconTarget:SetPoint("TOPLEFT", castBarInterruptIconAnchorDropdown, "BOTTOMLEFT", 24, pixelsBetweenBoxes)
    CreateTooltipTwo(castBarInterruptIconTarget, "Show on Target")

    local castBarInterruptIconFocus = CreateCheckbox("castBarInterruptIconFocus", "Focus", contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarInterruptIconFocus:SetPoint("LEFT", castBarInterruptIconTarget.text, "RIGHT", 5, 0)
    CreateTooltipTwo(castBarInterruptIconFocus, "Show on Focus")

    local castBarInterruptIconShowActiveOnly = CreateCheckbox("castBarInterruptIconShowActiveOnly", "Only show icon if available", contentFrame, nil, BBF.UpdateInterruptIconSettings)
    castBarInterruptIconShowActiveOnly:SetPoint("TOPLEFT", castBarInterruptIconTarget, "BOTTOMLEFT", -28, pixelsBetweenBoxes)
    CreateTooltipTwo(castBarInterruptIconShowActiveOnly, "Only show icon if available", "Hides the icon if interrupt is on cooldown")

    local interruptIconBorder = CreateCheckbox("interruptIconBorder", "Border Status Color", contentFrame, nil, BBF.UpdateInterruptIconSettings)
    interruptIconBorder:SetPoint("TOPLEFT", castBarInterruptIconShowActiveOnly, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(interruptIconBorder, "Border Status Color", "Colors the border on the icon after interrupt status.\nBy default red if on cooldown, purple if will be ready before cast ends and green if ready.")

    local reloadUiButton2 = CreateFrame("Button", nil, BetterBlizzFramesSubPanel, "UIPanelButtonTemplate")
    reloadUiButton2:SetText("Reload UI")
    reloadUiButton2:SetWidth(85)
    reloadUiButton2:SetPoint("TOP", BetterBlizzFramesSubPanel, "BOTTOMRIGHT", -140, -9)
    reloadUiButton2:SetScript("OnClick", function()
        BetterBlizzFramesDB.reopenOptions = true
        ReloadUI()
    end)

    local resetBBFButton = CreateFrame("Button", nil, BetterBlizzFramesSubPanel, "UIPanelButtonTemplate")
    resetBBFButton:SetText("Reset BetterBlizzFrames")
    resetBBFButton:SetWidth(165)
    resetBBFButton:SetPoint("RIGHT", reloadUiButton2, "LEFT", -533, 0)
    resetBBFButton:SetScript("OnClick", function()
        StaticPopup_Show("CONFIRM_RESET_BETTERBLIZZFRAMESDB")
    end)
    CreateTooltip(resetBBFButton, "Reset ALL BetterBlizzFrames settings.")

    BetterBlizzFramesSubPanel.rightClickTip = BetterBlizzFramesSubPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    BetterBlizzFramesSubPanel.rightClickTip:SetPoint("RIGHT", reloadUiButton2, "LEFT", -80, -2)
    BetterBlizzFramesSubPanel.rightClickTip:SetText("|A:smallquestbang:20:20|aTip:  Right-click sliders to enter a specific value")
end

local function guiFrameLook()
    ----------------------
    -- Frame Auras
    ----------------------
    local guiFrameLook = CreateFrame("Frame")
    guiFrameLook.name = "Font & Texture"
    guiFrameLook.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiFrameAuras)
    local aurasSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiFrameLook, guiFrameLook.name, guiFrameLook.name)
    aurasSubCategory.ID = guiFrameLook.name;
    CreateTitle(guiFrameLook)

    local bgImg = guiFrameLook:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiFrameLook, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local mainGuiAnchor = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainGuiAnchor:SetPoint("TOPLEFT", 15, -15)
    mainGuiAnchor:SetText(" ")

    local settingsText = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsText:SetPoint("TOPLEFT", mainGuiAnchor, "BOTTOMLEFT", 0, 30)
    settingsText:SetText("Font & Texture (WIP)")
    local generalSettingsIcon = guiFrameLook:CreateTexture(nil, "ARTWORK")
    generalSettingsIcon:SetAtlas("optionsicon-brown")
    generalSettingsIcon:SetSize(22, 22)
    generalSettingsIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)

    local howToImport = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    howToImport:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\Expressway_Free.ttf", 16)
    howToImport:SetPoint("CENTER", mainGuiAnchor, "BOTTOMLEFT", 420, -260)
    howToImport:SetText("How to import a custom font/texture:")

    local howStepOne = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    howStepOne:SetJustifyH("LEFT")
    howStepOne:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 12)
    howStepOne:SetPoint("TOPLEFT", howToImport, "BOTTOMLEFT", -20, -10)
    howStepOne:SetText("1) Create a new folder in your AddOns folder called CustomMedia\n2) Put your fonts and textures in this folder\n3) Add these lines to the Custom Code section in BBF:\n\nFor each FONT write:")

    local fontEditBox = CreateFrame("EditBox", nil, guiFrameLook, "InputBoxTemplate")
    fontEditBox:SetSize(330, 20)
    fontEditBox:SetPoint("TOPLEFT", howStepOne, "BOTTOMLEFT", 5, -5)
    fontEditBox:SetAutoFocus(false)
    fontEditBox:SetText("BBF.LSM:Register(\"font\", \"My Font Name\", [[Interface\\AddOns\\CustomMedia\\MyFontFile]], BBF.allLocales)")
    fontEditBox:HighlightText()
    fontEditBox:SetCursorPosition(0)
    fontEditBox:SetScript("OnTextChanged", function(self)
        fontEditBox:SetText("BBF.LSM:Register(\"font\", \"My Font Name\", [[Interface\\AddOns\\CustomMedia\\MyFontFile]], BBF.allLocales)")
    end)
    fontEditBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    local howStepTwo = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    howStepTwo:SetJustifyH("LEFT")
    howStepTwo:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 12)
    howStepTwo:SetPoint("TOPLEFT", fontEditBox, "BOTTOMLEFT", -5, -13)
    howStepTwo:SetText("For each TEXTURE write:")

    local textureEditBox = CreateFrame("EditBox", nil, guiFrameLook, "InputBoxTemplate")
    textureEditBox:SetSize(330, 20)
    textureEditBox:SetPoint("TOPLEFT", howStepTwo, "BOTTOMLEFT", 5, -5)
    textureEditBox:SetAutoFocus(false)
    textureEditBox:SetText("BBF.LSM:Register(\"statusbar\", \"My Texture Name\", [[Interface\\AddOns\\CustomMedia\\MyTextureFile]])")
    textureEditBox:HighlightText()
    textureEditBox:SetCursorPosition(0)
    textureEditBox:SetScript("OnTextChanged", function(self)
        textureEditBox:SetText("BBF.LSM:Register(\"statusbar\", \"My Texture Name\", [[Interface\\AddOns\\CustomMedia\\MyTextureFile]])")
    end)
    textureEditBox:SetScript("OnMouseUp", function(self)
        self:SetFocus()
        self:HighlightText()
    end)

    local howStepThree = guiFrameLook:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    howStepThree:SetJustifyH("LEFT")
    howStepThree:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 12)
    howStepThree:SetPoint("TOPLEFT", textureEditBox, "BOTTOMLEFT", -5, -13)
    howStepThree:SetText("Remember to rename \"My Texture Name\" to whatever name you want\nand \"MyTextureFile\" to exactly what your texture file is named in the folder.")

    local changeUnitFrameFont = CreateCheckbox("changeUnitFrameFont", "Change UnitFrame Font", guiFrameLook)
    changeUnitFrameFont:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", -4, pixelsOnFirstBox)
    CreateTooltipTwo(changeUnitFrameFont, "Change UnitFrame Font","Changes the font on Player, Target & Focus etc.")

    local unitFrameFontColor = CreateCheckbox("unitFrameFontColor", "Color", guiFrameLook)
    unitFrameFontColor:SetPoint("LEFT", changeUnitFrameFont.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(unitFrameFontColor, "UnitFrame Font Color","Change the font color on UnitFrames.\n\nRight-click to change color.")
    unitFrameFontColor:HookScript("OnClick", function()
        BBF.FontColors()
    end)
    unitFrameFontColor:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenColorOptions(BetterBlizzFramesDB.unitFrameFontColorRGB,  BBF.FontColors)
        end
    end)

    local unitFrameFontColorLvl = CreateCheckbox("unitFrameFontColorLvl", "Lvl", guiFrameLook)
    unitFrameFontColorLvl:SetPoint("LEFT", unitFrameFontColor.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(unitFrameFontColorLvl, "Color Level Font", "Also color the level font")
    unitFrameFontColorLvl:HookScript("OnClick", function()
        BBF.FontColors()
    end)

    local unitFrameFont = CreateFontDropdown(
        "unitFrameFont",
        guiFrameLook,
        "Select Font",
        "unitFrameFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changeUnitFrameFont, x = 55, y = 1, label = "Font" }
    )

    -- For font outline
    local unitFrameFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, "Outline", "unitFrameFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = unitFrameFont, x = 0, y = -5 }, 155)

    -- For font size
    local fontSizeOptions = {}
    for i = 6, 24 do
        table.insert(fontSizeOptions, tostring(i))
    end

    local unitFrameFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "Size", "unitFrameFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = unitFrameFontOutline, x = 0, y = -5 }, 155)

    changeUnitFrameFont:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            unitFrameFont:Disable()
            unitFrameFontOutline:Disable()
            unitFrameFontSize:Disable()
        else
            unitFrameFont:Enable()
            unitFrameFontOutline:Enable()
            unitFrameFontSize:Enable()
        end
    end)

    if not changeUnitFrameFont:GetChecked() then
        unitFrameFont:Disable()
        unitFrameFontOutline:Disable()
        unitFrameFontSize:Disable()
    end





    local changeUnitFrameValueFont = CreateCheckbox("changeUnitFrameValueFont", "Change UnitFrame Number Font", guiFrameLook)
    changeUnitFrameValueFont:SetPoint("TOPLEFT", changeUnitFrameFont, "BOTTOMLEFT", 0, -100)
    CreateTooltipTwo(changeUnitFrameValueFont, "Change UnitFrame Number Font","Changes the font on numbers on Player, Target & Focus etc.")

    local unitFrameValueFontColor = CreateCheckbox("unitFrameValueFontColor", "Color", guiFrameLook)
    unitFrameValueFontColor:SetPoint("LEFT", changeUnitFrameValueFont.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(unitFrameValueFontColor, "UnitFrame Numbers Font Color","Change the font color on UnitFrames numbers.\n\nRight-click to change color.")
    unitFrameValueFontColor:HookScript("OnClick", function()
        BBF.FontColors()
    end)
    unitFrameValueFontColor:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenColorOptions(BetterBlizzFramesDB.unitFrameValueFontColorRGB,  BBF.FontColors)
        end
    end)

    local unitFrameValueFont = CreateFontDropdown(
        "unitFrameValueFont",
        guiFrameLook,
        "Select Font",
        "unitFrameValueFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changeUnitFrameValueFont, x = 55, y = 1, label = "Font" }
    )

    -- For font outline
    local unitFrameValueFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, "Outline", "unitFrameValueFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = unitFrameValueFont, x = 0, y = -5 }, 155)

    local unitFrameValueFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "Size", "unitFrameValueFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = unitFrameValueFontOutline, x = 0, y = -5 }, 155)

    changeUnitFrameValueFont:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            unitFrameValueFont:Disable()
            unitFrameValueFontOutline:Disable()
            unitFrameValueFontSize:Disable()
        else
            unitFrameValueFont:Enable()
            unitFrameValueFontOutline:Enable()
            unitFrameValueFontSize:Enable()
        end
    end)

    if not changeUnitFrameValueFont:GetChecked() then
        unitFrameValueFont:Disable()
        unitFrameValueFontOutline:Disable()
        unitFrameValueFontSize:Disable()
    end





    local changePartyFrameFont = CreateCheckbox("changePartyFrameFont", "Change Party Font", guiFrameLook)
    changePartyFrameFont:SetPoint("TOPLEFT", changeUnitFrameValueFont, "BOTTOMLEFT", 0, -100)
    CreateTooltipTwo(changePartyFrameFont, "Change Party Font","Changes the font on PartyFrames")

    local partyFrameFontColor = CreateCheckbox("partyFrameFontColor", "Color", guiFrameLook)
    partyFrameFontColor:SetPoint("LEFT", changePartyFrameFont.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(partyFrameFontColor, "Party Frame Font Color","Change the font color on Party Frames.\n\nRight-click to change color.")
    partyFrameFontColor:HookScript("OnClick", function()
        BBF.FontColors()
    end)
    partyFrameFontColor:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenColorOptions(BetterBlizzFramesDB.partyFrameFontColorRGB,  BBF.FontColors)
        end
    end)

    local partyFrameFont = CreateFontDropdown(
        "partyFrameFont",
        guiFrameLook,
        "Select Font",
        "partyFrameFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changePartyFrameFont, x = 55, y = 1, label = "Font" }
    )

    -- For font outline
    local partyFrameFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, "Outline", "partyFrameFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = partyFrameFont, x = 0, y = -5 }, 155)

    local partyFrameFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "Size", "partyFrameFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = partyFrameFontOutline, x = 0, y = -5 }, 77.5)
    CreateTooltipTwo(partyFrameFontSize, "Name Size")

    local partyFrameStatusFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "", "partyFrameStatusFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = partyFrameFontSize, x = 77.5, y = 25 }, 77.5)
    CreateTooltipTwo(partyFrameStatusFontSize, "Status Text Size")

    changePartyFrameFont:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            partyFrameFont:Disable()
            partyFrameFontOutline:Disable()
            partyFrameFontSize:Disable()
            partyFrameStatusFontSize:Disable()
        else
            partyFrameFont:Enable()
            partyFrameFontOutline:Enable()
            partyFrameFontSize:Enable()
            partyFrameStatusFontSize:Enable()
        end
    end)

    if not changePartyFrameFont:GetChecked() then
        partyFrameFont:Disable()
        partyFrameFontOutline:Disable()
        partyFrameFontSize:Disable()
        partyFrameStatusFontSize:Disable()
    end


    local changeActionBarFont = CreateCheckbox("changeActionBarFont", "Change ActionBar Font", guiFrameLook)
    changeActionBarFont:SetPoint("TOPLEFT", changePartyFrameFont, "BOTTOMLEFT", 0, -100)
    CreateTooltipTwo(changeActionBarFont, "Change ActionBar Font","Changes the font on Player, Target & Focus etc.")

    local actionBarFontColor = CreateCheckbox("actionBarFontColor", "Color", guiFrameLook)
    actionBarFontColor:SetPoint("LEFT", changeActionBarFont.Text, "RIGHT", 0, 0)
    CreateTooltipTwo(actionBarFontColor, "Action Bar Font Color","Change the font color on ActionBars.\n\nRight-click to change color.")
    actionBarFontColor:HookScript("OnClick", function()
        BBF.FontColors()
    end)
    actionBarFontColor:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            OpenColorOptions(BetterBlizzFramesDB.actionBarFontColorRGB,  BBF.FontColors)
        end
    end)

    local actionBarFont = CreateFontDropdown(
        "actionBarFont",
        guiFrameLook,
        "Select Font",
        "actionBarFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changeActionBarFont, x = 55, y = 1, label = "Font" }
    )

    -- For font outline
    local actionBarFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, "Outline", "actionBarFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFont, x = 0, y = -5 }, 77.5)
    CreateTooltipTwo(actionBarFontOutline, "Macro Text Outline")

    local actionBarKeyFontOutline = CreateSimpleDropdown("FontOutlineDropdown", guiFrameLook, "", "actionBarKeyFontOutline", {
        "THICKOUTLINE", "THINOUTLINE", "NONE"
    }, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFontOutline, x = 77.5, y = 25 }, 77.5)
    CreateTooltipTwo(actionBarKeyFontOutline, "Keybinding Text Outline")

    local actionBarFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "Size", "actionBarFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFontOutline, x = 0, y = -5 }, 77.5)
    CreateTooltipTwo(actionBarFontSize, "Macro Text Size")

    local actionBarKeyFontSize = CreateSimpleDropdown("FontSizeDropdown", guiFrameLook, "", "actionBarKeyFontSize", fontSizeOptions, function(selectedSize)
        BBF.SetCustomFonts()
    end, { anchorFrame = actionBarFontSize, x = 77.5, y = 25 }, 77.5)
    CreateTooltipTwo(actionBarKeyFontSize, "Keybinding Text Size")



    local function ToggleDropdowns(enable)
        for _, dd in ipairs({
            actionBarFont,
            actionBarFontOutline,
            actionBarKeyFontOutline,
            actionBarFontSize,
            actionBarKeyFontSize
        }) do
            dd:SetEnabled(enable)
        end
    end

    changeActionBarFont:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
        ToggleDropdowns(self:GetChecked())
    end)

    ToggleDropdowns(changeActionBarFont:GetChecked())










    local changeAllFontsIngame = CreateCheckbox("changeAllFontsIngame", "One font for all text ingame", guiFrameLook)
    changeAllFontsIngame:SetPoint("TOPLEFT", changeActionBarFont, "BOTTOMLEFT", 0, -115)
    CreateTooltipTwo(changeAllFontsIngame, "One font for all text ingame","Changes the font on all* text ingame.", "*Some text in the game world, like damage numbers, can not be changed with an addon. It's possible by editing the game files though.")

    local allIngameFont = CreateFontDropdown(
        "allIngameFont",
        guiFrameLook,
        "Select Font",
        "allIngameFont",
        function(arg1)
            BBF.SetCustomFonts()
        end,
        { anchorFrame = changeAllFontsIngame, x = 55, y = 1, label = "Font" }
    )

    changeAllFontsIngame:HookScript("OnClick", function(self)
        BBF.SetCustomFonts()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
        allIngameFont:SetEnabled(self:GetChecked())
    end)
    allIngameFont:SetEnabled(changeAllFontsIngame:GetChecked())







    local changeUnitFrameHealthbarTexture = CreateCheckbox("changeUnitFrameHealthbarTexture", "Change UnitFrame Healthbar Texture", guiFrameLook)
    changeUnitFrameHealthbarTexture:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", 260, pixelsOnFirstBox)
    if not BetterBlizzFramesDB.classicFrames then
        CreateTooltipTwo(changeUnitFrameHealthbarTexture, "Change UnitFrame Healthbar Texture","Changes the healthbar texture on Player, Target & Focus etc.")
    else
        CreateTooltipTwo(changeUnitFrameHealthbarTexture, "Change UnitFrame Healthbar Texture","Changes the healthbar texture on Player, Target & Focus etc.\n\n|cff32f795Right-click to also change the texture behind name.|r")
            changeUnitFrameHealthbarTexture:HookScript("OnMouseDown", function(self, button)
            if button == "RightButton" then
                if not BetterBlizzFramesDB.changeUnitFrameHealthbarTextureRepColor then
                    BetterBlizzFramesDB.changeUnitFrameHealthbarTextureRepColor = true
                else
                    BetterBlizzFramesDB.changeUnitFrameHealthbarTextureRepColor = nil
                end
                local function retexture(tex)
                    if not tex then return end
                    tex:SetTexture((BetterBlizzFramesDB.changeUnitFrameHealthbarTextureRepColor and LSM:Fetch(LSM.MediaType.STATUSBAR, BetterBlizzFramesDB.unitFrameHealthbarTexture) or "Interface\\TargetingFrame\\UI-TargetingFrame-LevelBackground"))
                end
                retexture(PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ReputationColor)
                retexture(TargetFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor)
                retexture(FocusFrame.TargetFrameContent.TargetFrameContentMain.ReputationColor)
            end
        end)
    end

    if BetterBlizzFramesDB.classicFrames then
        local text = guiFrameLook:CreateFontString(nil, "OVERLAY")
        text:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 12)
        text:SetText("*Classic Frames!")
        text:SetTextColor(1,0,0)
        CreateTooltipTwo(text, "Classic Frames Healthbar", "Due to the original healthbar only showing 50% of its texture with Classic Frames enabled not all textures are suitable.\n\nI have made an exception for \"Blizzard CF\" and \"Blizzard DF\" but it does require a reload between swapping to and from these textures for full effect.\n\nPlease use \"Blizzard CF\" or \"Blizzard DF\" over \"Blizzard\" if you are looking for the classic texture.\n\nIf you have a custom texture in your Interface folder then please add this via the method mentioned below as well and select it here if needed.", nil, "ANCHOR_BOTTOMRIGHT")
        text:SetPoint("LEFT", changeUnitFrameHealthbarTexture.Text, "RIGHT", 5, 0)
    end

    local unitFrameHealthbarTexture = CreateTextureDropdown(
        "unitFrameHealthbarTexture",
        guiFrameLook,
        "Select Texture",
        "unitFrameHealthbarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeUnitFrameHealthbarTexture, x = 5, y = 1, label = "Texture" }
    )

    changeUnitFrameHealthbarTexture:HookScript("OnClick", function(self)
        unitFrameHealthbarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
    end)
    unitFrameHealthbarTexture:SetEnabled(changeUnitFrameHealthbarTexture:GetChecked())

    local changeUnitFrameManabarTexture = CreateCheckbox("changeUnitFrameManabarTexture", "Change UnitFrame Manabar Texture", guiFrameLook)
    changeUnitFrameManabarTexture:SetPoint("TOPLEFT", changeUnitFrameHealthbarTexture, "BOTTOMLEFT", 0, -25)
    CreateTooltipTwo(changeUnitFrameManabarTexture, "Change UnitFrame Manabar Texture","Changes the manabar texture on Player, Target & Focus etc. This is more cpu heavy than it should be.")

    local unitFrameManabarTexture = CreateTextureDropdown(
        "unitFrameManabarTexture",
        guiFrameLook,
        "Select Texture",
        "unitFrameManabarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeUnitFrameManabarTexture, x = 5, y = 1, label = "Texture" }
    )
    changeUnitFrameManabarTexture:HookScript("OnClick", function(self)
        unitFrameManabarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
    end)
    unitFrameManabarTexture:SetEnabled(changeUnitFrameManabarTexture:GetChecked())


    local changeRaidFrameHealthbarTexture = CreateCheckbox("changeRaidFrameHealthbarTexture", "Change RaidFrame Healthbar Texture", guiFrameLook)
    changeRaidFrameHealthbarTexture:SetPoint("TOPLEFT", changeUnitFrameManabarTexture, "BOTTOMLEFT", 0, -40)
    CreateTooltipTwo(changeRaidFrameHealthbarTexture, "Change RaidFrame Healthbar Texture","Changes the healthbar texture on the RaidFrames")

    local raidFrameHealthbarTexture = CreateTextureDropdown(
        "raidFrameHealthbarTexture",
        guiFrameLook,
        "Select Texture",
        "raidFrameHealthbarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeRaidFrameHealthbarTexture, x = 5, y = 1, label = "Texture" }
    )

    changeRaidFrameHealthbarTexture:HookScript("OnClick", function(self)
        raidFrameHealthbarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
    end)
    raidFrameHealthbarTexture:SetEnabled(changeRaidFrameHealthbarTexture:GetChecked())

    local changeRaidFrameManabarTexture = CreateCheckbox("changeRaidFrameManabarTexture", "Change RaidFrame Manabar Texture", guiFrameLook)
    changeRaidFrameManabarTexture:SetPoint("TOPLEFT", changeRaidFrameHealthbarTexture, "BOTTOMLEFT", 0, -25)
    CreateTooltipTwo(changeRaidFrameManabarTexture, "Change RaidFrame Manabar Texture","Changes the manabar texture on the RaidFrames. This is more cpu heavy than it should be.")

    local raidFrameManabarTexture = CreateTextureDropdown(
        "raidFrameManabarTexture",
        guiFrameLook,
        "Select Texture",
        "raidFrameManabarTexture",
        function(arg1)
            BBF.UpdateCustomTextures()
        end,
        { anchorFrame = changeRaidFrameManabarTexture, x = 5, y = 1, label = "Texture" }
    )

    changeRaidFrameManabarTexture:HookScript("OnClick", function(self)
        raidFrameManabarTexture:SetEnabled(self:GetChecked())
        BBF.UpdateCustomTextures()
    end)
    raidFrameManabarTexture:SetEnabled(changeRaidFrameManabarTexture:GetChecked())














end

local function guiFrameAuras()
    ----------------------
    -- Frame Auras
    ----------------------
    local guiFrameAuras = CreateFrame("Frame")
    guiFrameAuras.name = "Buffs & Debuffs"
    guiFrameAuras.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiFrameAuras)
    local aurasSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiFrameAuras, guiFrameAuras.name, guiFrameAuras.name)
    aurasSubCategory.ID = guiFrameAuras.name;
    BBF.aurasSubCategory = aurasSubCategory.ID
    CreateTitle(guiFrameAuras)

    local bgImg = guiFrameAuras:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiFrameAuras, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local scrollFrame = CreateFrame("ScrollFrame", nil, guiFrameAuras, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(700, 612)
    scrollFrame:SetPoint("CENTER", guiFrameAuras, "CENTER", -20, 3)

    local contentFrame = CreateFrame("Frame", nil, scrollFrame)
    contentFrame.name = guiFrameAuras.name
    contentFrame:SetSize(680, 520)
    scrollFrame:SetScrollChild(contentFrame)

    local auraWhitelistFrame = CreateFrame("Frame", nil, contentFrame)
    auraWhitelistFrame:SetSize(322, 390)
    auraWhitelistFrame:SetPoint("TOPLEFT", 346, -15)

    local auraBlacklistFrame = CreateFrame("Frame", nil, contentFrame)
    auraBlacklistFrame:SetSize(322, 390)
    auraBlacklistFrame:SetPoint("TOPLEFT", 6, -15)

    local whitelist = CreateList(auraBlacklistFrame, "auraBlacklist", BetterBlizzFramesDB.auraBlacklist, BBF.RefreshAllAuraFrames, nil, nil, 265)

    local blacklistText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    blacklistText:SetPoint("BOTTOM", auraBlacklistFrame, "TOP", -20, -5)
    blacklistText:SetText("Blacklist")

    local blacklist = CreateList(auraWhitelistFrame, "auraWhitelist", BetterBlizzFramesDB.auraWhitelist, BBF.RefreshAllAuraFrames, true, true, 379, true)

    local whitelistText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    whitelistText:SetPoint("BOTTOM", auraWhitelistFrame, "TOP", -60, -5)
    whitelistText:SetText("Whitelist")

    if not BetterBlizzFramesDB.playerAuraFiltering then
        auraWhitelistFrame:SetAlpha(0.3)
        auraBlacklistFrame:SetAlpha(0.3)
    end

    local onlyMeTexture = contentFrame:CreateTexture(nil, "OVERLAY")
    onlyMeTexture:SetAtlas("UI-HUD-UnitFrame-Player-Group-FriendOnlineIcon")
    onlyMeTexture:SetPoint("RIGHT", whitelist, "TOPRIGHT", 296, 9)
    onlyMeTexture:SetSize(18,20)
    CreateTooltip(onlyMeTexture, "Only My Aura Checkboxes")

    local enlargeAuraTexture = contentFrame:CreateTexture(nil, "OVERLAY")
    enlargeAuraTexture:SetAtlas("ui-hud-minimap-zoom-in")
    enlargeAuraTexture:SetPoint("LEFT", onlyMeTexture, "RIGHT", 4, 0)
    enlargeAuraTexture:SetSize(18,18)
    CreateTooltip(enlargeAuraTexture, "Enlarged Aura Checkboxes")

    local compactAuraTexture = contentFrame:CreateTexture(nil, "OVERLAY")
    compactAuraTexture:SetAtlas("ui-hud-minimap-zoom-out")
    compactAuraTexture:SetPoint("LEFT", enlargeAuraTexture, "RIGHT", 3, 0)
    compactAuraTexture:SetSize(18,18)
    CreateTooltip(compactAuraTexture, "Compact Aura Checkboxes")

    local importantAuraTexture = contentFrame:CreateTexture(nil, "OVERLAY")
    importantAuraTexture:SetAtlas("importantavailablequesticon")
    importantAuraTexture:SetPoint("LEFT", compactAuraTexture, "RIGHT", 2, 0)
    importantAuraTexture:SetSize(17,16)
    importantAuraTexture:SetDesaturated(true)
    importantAuraTexture:SetVertexColor(0,1,0)
    CreateTooltip(importantAuraTexture, "Important Aura Checkboxes")

    local pandemicAuraTexture = contentFrame:CreateTexture(nil, "OVERLAY")
    pandemicAuraTexture:SetAtlas("elementalstorm-boss-air")
    pandemicAuraTexture:SetPoint("LEFT", importantAuraTexture, "RIGHT", -1, 1)
    pandemicAuraTexture:SetSize(26,26)
    pandemicAuraTexture:SetDesaturated(true)
    pandemicAuraTexture:SetVertexColor(1,0,0)
    CreateTooltip(pandemicAuraTexture, "Pandemic Aura Checkboxes")






    local playerAuraFiltering = CreateCheckbox("playerAuraFiltering", "Enable Aura Settings", contentFrame)
    playerAuraFiltering.name = guiFrameAuras.name
    CreateTooltipTwo(playerAuraFiltering, "Enable Buff Filtering & Aura settings", "Enables all the buff filtering settings.\nThis setting is cpu heavy and un-optimized so use at your own risk.", nil, nil, nil, 5)
    playerAuraFiltering:SetPoint("TOPLEFT", contentFrame, "BOTTOMLEFT", 50, 190)
    playerAuraFiltering:HookScript("OnClick", function (self)
        if self:GetChecked() then
            if BetterBlizzFramesDB.targetToTXPos == 0 then
                StaticPopup_Show("BBF_TOT_MESSAGE")
                BetterBlizzFramesDB.targetToTXPos = 31
                BBF.targetToTXPos:SetValue(31)
                BetterBlizzFramesDB.focusToTXPos = 31
                BBF.focusToTXPos:SetValue(31)
                BBF.MoveToTFrames()
                BBF.UpdateFilteredBuffsIcon()
            else
                StaticPopup_Show("BBF_CONFIRM_RELOAD")
            end
            auraWhitelistFrame:SetAlpha(1)
            auraBlacklistFrame:SetAlpha(1)
        else
            if BetterBlizzFramesDB.targetToTXPos == 31 then
                DEFAULT_CHAT_FRAME:AddMessage("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Aura Settings Off. Target of Target Frame changed back to its default position.")
                BetterBlizzFramesDB.targetToTXPos = 0
                BBF.targetToTXPos:SetValue(0)
                BetterBlizzFramesDB.focusToTXPos = 0
                BBF.focusToTXPos:SetValue(0)
                BBF.MoveToTFrames()
            end
            auraWhitelistFrame:SetAlpha(0.3)
            auraBlacklistFrame:SetAlpha(0.3)
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local enableMasque = CreateCheckbox("enableMasque", "Add Masque Support", contentFrame)
    enableMasque:SetPoint("LEFT", playerAuraFiltering.Text, "RIGHT", 5, 0)
    CreateTooltipTwo(enableMasque, "Enable Masque Support for Auras", "Add Masque support for all auras.\nHigh CPU usage, not recommended. Might try optimize in the future.", "Does not require Aura Settings to be enabled.", nil, nil, 4)
    enableMasque:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local printAuraSpellIds = CreateCheckbox("printAuraSpellIds", "Print Spell ID", playerAuraFiltering)
    printAuraSpellIds:SetPoint("LEFT", enableMasque.Text, "RIGHT", 5, 0)
    CreateTooltip(printAuraSpellIds, "Show aura spell id in chat when mousing over the aura.\n\nUsecase: Find spell ID to filter by ID, some spells have identical names.")

    local importPVPWhitelist = CreateFrame("Button", nil, playerAuraFiltering, "UIPanelButtonTemplate")
    importPVPWhitelist:SetSize(138, 22)
    importPVPWhitelist:SetPoint("LEFT", printAuraSpellIds.text, "RIGHT", 3, 1)
    importPVPWhitelist:SetText("Import PvP Whitelist")
    importPVPWhitelist:SetScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_PVP_WHITELIST")
    end)
    local coloredText = "|cff00FF00Important/Immunity|r\n" ..
                    "|cffFF8000Offensive Buff|r\n" ..
                    "|cffFFA9F1Defensive Buffs|r\n" ..
                    "|cff00FFFFFreedom/Speed|r\n" ..
                    "|cffEFFF33Fear Immunity|r"

    CreateTooltipTwo(importPVPWhitelist, "Import PvP Whitelist", "Import a color coded Whitelist with most important Offensives, Defensives & Freedoms for TWW added.\n\n"..coloredText.."\n\nThis will only add NEW entries and not mess with existing ones in your current whitelist.\n\nWill tweak this as time goes on probably.")
    importPVPWhitelist.Middle:SetDesaturated(true)
    importPVPWhitelist.Left:SetDesaturated(true)
    importPVPWhitelist.Right:SetDesaturated(true)

    local importPVPBlacklist = CreateFrame("Button", nil, playerAuraFiltering, "UIPanelButtonTemplate")
    importPVPBlacklist:SetSize(138, 22)
    importPVPBlacklist:SetPoint("LEFT", importPVPWhitelist, "RIGHT", 0, 0)
    importPVPBlacklist:SetText("Import PvP Blacklist")
    importPVPBlacklist:SetScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_PVP_BLACKLIST")
    end)
    CreateTooltipTwo(importPVPBlacklist, "Import PvP Blacklist", "Import a Blacklist with A LOT (750+) of trash buffs blacklisted.\n\nThis will only add NEW entries and not mess with existing ones already in your blacklist.")
    importPVPBlacklist.Middle:SetDesaturated(true)
    importPVPBlacklist.Left:SetDesaturated(true)
    importPVPBlacklist.Right:SetDesaturated(true)

    -- local tipText = playerAuraFiltering:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- tipText:SetPoint("LEFT", printAuraSpellIds.Text, "RIGHT", 5, 0)
    -- tipText:SetText("Tip")

    --------------------------
    -- Target Frame
    --------------------------
    -- Target Buffs
    local targetBuffEnable = CreateCheckbox("targetBuffEnable", "Show BUFFS", playerAuraFiltering)
    targetBuffEnable:SetPoint("TOPLEFT", contentFrame, "BOTTOMLEFT", 64, 140)
    targetBuffEnable:HookScript("OnClick", function ()
        CheckAndToggleCheckboxes(targetBuffEnable)
        TargetFrame:UpdateAuras()
        if BBF.HidingAllTargetAuras then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local bigEnemyBorderText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bigEnemyBorderText:SetPoint("LEFT", targetBuffEnable, "CENTER", 35, 25)
    bigEnemyBorderText:SetText("Target Frame")
    local targetFrameIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    targetFrameIcon:SetAtlas("groupfinder-icon-friend")
    targetFrameIcon:SetSize(28, 28)
    targetFrameIcon:SetPoint("RIGHT", bigEnemyBorderText, "LEFT", -3, 0)
    targetFrameIcon:SetDesaturated(1)
    targetFrameIcon:SetVertexColor(1, 0, 0)

    local targetAuraBorder = CreateBorderedFrame(targetBuffEnable, 185, 400, 65, -186, contentFrame)

    local targetBuffFilterWatchList = CreateCheckbox("targetBuffFilterWatchList", "Whitelist", targetBuffEnable)
    CreateTooltipTwo(targetBuffFilterWatchList, "Whitelist", "Only show whitelisted auras.\n(Plus other filters)", "You can have spells whitelisted to add settings such as \"Only Mine\" and \"Important\" etc without needing to enable the whitelist filter here.\n\nOnly check this if you only want whitelisted auras here or the addition of them.\n(Plus other filters)")
    targetBuffFilterWatchList:SetPoint("TOPLEFT", targetBuffEnable, "BOTTOMLEFT", 15, pixelsBetweenBoxes)

    local targetBuffFilterBlacklist = CreateCheckbox("targetBuffFilterBlacklist", "Blacklist", targetBuffEnable)
    targetBuffFilterBlacklist:SetPoint("TOPLEFT", targetBuffFilterWatchList, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetBuffFilterBlacklist, "Filter out blacklisted auras.")

    local targetBuffFilterLessMinite = CreateCheckbox("targetBuffFilterLessMinite", "Under one min", targetBuffEnable)
    targetBuffFilterLessMinite:SetPoint("TOPLEFT", targetBuffFilterBlacklist, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetBuffFilterLessMinite, "Only show buffs that are 60sec or shorter.")

    local targetBuffFilterOnlyMe = CreateCheckbox("targetBuffFilterOnlyMe", "Only mine", targetBuffEnable)
    targetBuffFilterOnlyMe:SetPoint("TOPLEFT", targetBuffFilterLessMinite, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetBuffFilterOnlyMe, "If the target is friendly only show your own buffs on them")

    local targetBuffFilterPurgeable = CreateCheckbox("targetBuffFilterPurgeable", "Purgeable", targetBuffEnable)
    targetBuffFilterPurgeable:SetPoint("TOPLEFT", targetBuffFilterOnlyMe, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local targetBuffFilterMount = CreateCheckbox("targetBuffFilterMount", "Mount", targetBuffEnable)
    targetBuffFilterMount:SetPoint("TOPLEFT", targetBuffFilterPurgeable, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(targetBuffFilterMount, "Mount", "Show all mounts.\n(Needs testing, please report if you see a mount that is not displayed by this filter)")


--[[targetBuffPurgeGlow
    local otherNpBuffBlueBorder = CreateCheckbox("otherNpBuffBlueBorder", "Blue border on buffs", targetBuffEnable)
    otherNpBuffBlueBorder:SetPoint("TOPLEFT", targetBuffFilterOnlyMe, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local otherNpBuffEmphasisedBorder = CreateCheckbox("otherNpBuffEmphasisedBorder", "Red glow on whitelisted buffs", targetBuffEnable)
    otherNpBuffEmphasisedBorder:SetPoint("TOPLEFT", otherNpBuffBlueBorder, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

]]


    -- Target Debuffs
    local targetdeBuffEnable = CreateCheckbox("targetdeBuffEnable", "Show DEBUFFS", playerAuraFiltering)
    targetdeBuffEnable:SetPoint("TOPLEFT", targetBuffFilterMount, "BOTTOMLEFT", -15, 0)
    targetdeBuffEnable:HookScript("OnClick", function ()
        CheckAndToggleCheckboxes(targetdeBuffEnable)
        if BBF.HidingAllTargetAuras then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local targetdeBuffFilterBlizzard = CreateCheckbox("targetdeBuffFilterBlizzard", "Blizzard Default Filter", targetdeBuffEnable)
    targetdeBuffFilterBlizzard:SetPoint("TOPLEFT", targetdeBuffEnable, "BOTTOMLEFT", 15, pixelsBetweenBoxes)

    local targetdeBuffFilterWatchList = CreateCheckbox("targetdeBuffFilterWatchList", "Whitelist", targetdeBuffEnable)
    CreateTooltipTwo(targetdeBuffFilterWatchList, "Whitelist", "Only show whitelisted auras.\n(Plus other filters)", "You can have spells whitelisted to add settings such as \"Only Mine\" and \"Important\" etc without needing to enable the whitelist filter here.\n\nOnly check this if you only want whitelisted auras here or the addition of them.\n(Plus other filters)")
    targetdeBuffFilterWatchList:SetPoint("TOPLEFT", targetdeBuffFilterBlizzard, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local targetdeBuffFilterBlacklist = CreateCheckbox("targetdeBuffFilterBlacklist", "Blacklist", targetdeBuffEnable)
    targetdeBuffFilterBlacklist:SetPoint("TOPLEFT", targetdeBuffFilterWatchList, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetdeBuffFilterBlacklist, "Filter out blacklisted auras.")

    local targetdeBuffFilterLessMinite = CreateCheckbox("targetdeBuffFilterLessMinite", "Under one min", targetdeBuffEnable)
    targetdeBuffFilterLessMinite:SetPoint("TOPLEFT", targetdeBuffFilterBlacklist, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetdeBuffFilterLessMinite, "Only show debuffs that are 60sec or shorter.")

    local targetdeBuffFilterOnlyMe = CreateCheckbox("targetdeBuffFilterOnlyMe", "Only mine", targetdeBuffEnable)
    targetdeBuffFilterOnlyMe:SetPoint("TOPLEFT", targetdeBuffFilterLessMinite, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local targetAuraGlows = CreateCheckbox("targetAuraGlows", "Extra Aura Settings", playerAuraFiltering)
    targetAuraGlows:SetPoint("TOPLEFT", targetdeBuffFilterOnlyMe, "BOTTOMLEFT", -15, 0)
    targetAuraGlows:HookScript("OnClick", function ()
        CheckAndToggleCheckboxes(targetAuraGlows)
    end)

    local targetEnlargeAura = CreateCheckbox("targetEnlargeAura", "Enlarge Aura", targetAuraGlows)
    targetEnlargeAura:SetPoint("TOPLEFT", targetAuraGlows, "BOTTOMLEFT", 15, pixelsBetweenBoxes)
    CreateTooltip(targetEnlargeAura, "Enlarge checked whitelisted auras.")

    local targetEnlargeAuraEnemy = CreateCheckbox("targetEnlargeAuraEnemy", "", targetAuraGlows, nil, BBF.UpdateUserAuraSettings)
    targetEnlargeAuraEnemy:SetPoint("LEFT", targetEnlargeAura.Text, "RIGHT", 0, 0)
    CreateTooltip(targetEnlargeAuraEnemy, "Enable on Enemy")
    targetEnlargeAuraEnemy:SetSize(22,22)

    targetEnlargeAuraEnemy.texture = targetEnlargeAuraEnemy:CreateTexture(nil, "ARTWORK", nil, 1)
    targetEnlargeAuraEnemy.texture:SetTexture(BBF.squareGreenGlow)
    targetEnlargeAuraEnemy.texture:SetSize(46, 46)
    targetEnlargeAuraEnemy.texture:SetDesaturated(true)
    targetEnlargeAuraEnemy.texture:SetVertexColor(1,0,0)
    targetEnlargeAuraEnemy.texture:SetPoint("CENTER", targetEnlargeAuraEnemy, "CENTER", -0.5, 0)

    local targetEnlargeAuraFriendly = CreateCheckbox("targetEnlargeAuraFriendly", "", targetAuraGlows, nil, BBF.UpdateUserAuraSettings)
    targetEnlargeAuraFriendly:SetPoint("LEFT", targetEnlargeAuraEnemy, "RIGHT", 0, 0)
    CreateTooltip(targetEnlargeAuraFriendly, "Enable on Friendly")
    targetEnlargeAuraFriendly:SetSize(22,22)

    targetEnlargeAuraFriendly.texture = targetEnlargeAuraFriendly:CreateTexture(nil, "ARTWORK", nil, 1)
    targetEnlargeAuraFriendly.texture:SetTexture(BBF.squareGreenGlow)
    targetEnlargeAuraFriendly.texture:SetSize(46, 46)
    --targetEnlargeAuraFriendly.texture:SetDesaturated(true)
    targetEnlargeAuraFriendly.texture:SetPoint("CENTER", targetEnlargeAuraFriendly, "CENTER", -0.5, 0)

    local targetCompactAura = CreateCheckbox("targetCompactAura", "Compact Aura", targetAuraGlows)
    targetCompactAura:SetPoint("TOPLEFT", targetEnlargeAura, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetCompactAura, "Decrease the size of checked whitelisted auras.")

    local targetdeBuffPandemicGlow = CreateCheckbox("targetdeBuffPandemicGlow", "Pandemic Glow", targetAuraGlows)
    targetdeBuffPandemicGlow:SetPoint("TOPLEFT", targetCompactAura, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetdeBuffPandemicGlow, "Red glow on whitelisted auras with less than 5 seconds left.")

    local targetBuffPurgeGlow = CreateCheckbox("targetBuffPurgeGlow", "Purge Glow", targetAuraGlows)
    targetBuffPurgeGlow:SetPoint("TOPLEFT", targetdeBuffPandemicGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetBuffPurgeGlow, "Bright blue glow on all dispellable/purgeable buffs.\n\nReplaces the standard yellow glow.")

    local targetImportantAuraGlow = CreateCheckbox("targetImportantAuraGlow", "Important Glow", targetAuraGlows)
    targetImportantAuraGlow:SetPoint("TOPLEFT", targetBuffPurgeGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(targetImportantAuraGlow, "Green glow on whitelisted auras marked as important")



    --------------------------
    -- Focus Frame
    --------------------------
    -- Focus Buffs
    local focusBuffEnable = CreateCheckbox("focusBuffEnable", "Show BUFFS", playerAuraFiltering)
    focusBuffEnable:SetPoint("TOPLEFT", contentFrame, "BOTTOMLEFT", 285, 140)
    focusBuffEnable:HookScript("OnClick", function ()
        CheckAndToggleCheckboxes(focusBuffEnable)
        if BBF.HidingAllFocusAuras then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local friendlyFramesText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    friendlyFramesText:SetPoint("LEFT", focusBuffEnable, "CENTER", 35, 25)
    friendlyFramesText:SetText("Focus Frame")
    local focusFrameIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    focusFrameIcon:SetAtlas("groupfinder-icon-friend")
    focusFrameIcon:SetSize(28, 28)
    focusFrameIcon:SetPoint("RIGHT", friendlyFramesText, "LEFT", -3, 0)
    focusFrameIcon:SetDesaturated(1)
    focusFrameIcon:SetVertexColor(0, 1, 0)

    CreateBorderedFrame(focusBuffEnable, 185, 400, 65, -186, contentFrame)

    local focusBuffFilterWatchList = CreateCheckbox("focusBuffFilterWatchList", "Whitelist", focusBuffEnable)
    CreateTooltipTwo(focusBuffFilterWatchList, "Whitelist", "Only show whitelisted auras.\n(Plus other filters)", "You can have spells whitelisted to add settings such as \"Only Mine\" and \"Important\" etc without needing to enable the whitelist filter here.\n\nOnly check this if you only want whitelisted auras here or the addition of them.\n(Plus other filters)")
    focusBuffFilterWatchList:SetPoint("TOPLEFT", focusBuffEnable, "BOTTOMLEFT", 15, pixelsBetweenBoxes)

    local focusBuffFilterBlacklist = CreateCheckbox("focusBuffFilterBlacklist", "Blacklist", focusBuffEnable)
    focusBuffFilterBlacklist:SetPoint("TOPLEFT", focusBuffFilterWatchList, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusBuffFilterBlacklist, "Filter out blacklisted auras.")

    local focusBuffFilterLessMinite = CreateCheckbox("focusBuffFilterLessMinite", "Under one min", focusBuffEnable)
    focusBuffFilterLessMinite:SetPoint("TOPLEFT", focusBuffFilterBlacklist, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusBuffFilterLessMinite, "Only show buffs that are 60sec or shorter.")

    local focusBuffFilterOnlyMe = CreateCheckbox("focusBuffFilterOnlyMe", "Only mine", focusBuffEnable)
    focusBuffFilterOnlyMe:SetPoint("TOPLEFT", focusBuffFilterLessMinite, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusBuffFilterOnlyMe, "If the unit is friendly show your buffs")

    local focusBuffFilterPurgeable = CreateCheckbox("focusBuffFilterPurgeable", "Purgeable", focusBuffEnable)
    focusBuffFilterPurgeable:SetPoint("TOPLEFT", focusBuffFilterOnlyMe, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local focusBuffFilterMount = CreateCheckbox("focusBuffFilterMount", "Mount", focusBuffEnable)
    focusBuffFilterMount:SetPoint("TOPLEFT", focusBuffFilterPurgeable, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(focusBuffFilterMount, "Mount", "Show all mounts.\n(Needs testing, please report if you see a mount that is not displayed by this filter)")

    -- Focus Debuffs
    local focusdeBuffEnable = CreateCheckbox("focusdeBuffEnable", "Show DEBUFFS", playerAuraFiltering)
    focusdeBuffEnable:SetPoint("TOPLEFT", focusBuffFilterMount, "BOTTOMLEFT", -15, 0)
    focusdeBuffEnable:HookScript("OnClick", function ()
        CheckAndToggleCheckboxes(focusdeBuffEnable)
        if BBF.HidingAllFocusAuras then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local focusdeBuffFilterBlizzard = CreateCheckbox("focusdeBuffFilterBlizzard", "Blizzard Default Filter", focusdeBuffEnable)
    focusdeBuffFilterBlizzard:SetPoint("TOPLEFT", focusdeBuffEnable, "BOTTOMLEFT", 15, pixelsBetweenBoxes)

    local focusdeBuffFilterWatchList = CreateCheckbox("focusdeBuffFilterWatchList", "Whitelist", focusdeBuffEnable)
    focusdeBuffFilterWatchList:SetPoint("TOPLEFT", focusdeBuffFilterBlizzard, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(focusdeBuffFilterWatchList, "Whitelist", "Only show whitelisted auras.\n(Plus other filters)", "You can have spells whitelisted to add settings such as \"Only Mine\" and \"Important\" etc without needing to enable the whitelist filter here.\n\nOnly check this if you only want whitelisted auras here or the addition of them.\n(Plus other filters)")

    local focusdeBuffFilterBlacklist = CreateCheckbox("focusdeBuffFilterBlacklist", "Blacklist", focusdeBuffEnable)
    focusdeBuffFilterBlacklist:SetPoint("TOPLEFT", focusdeBuffFilterWatchList, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusdeBuffFilterBlacklist, "Filter out blacklisted auras.")

    local focusdeBuffFilterLessMinite = CreateCheckbox("focusdeBuffFilterLessMinite", "Under one min", focusdeBuffEnable)
    focusdeBuffFilterLessMinite:SetPoint("TOPLEFT", focusdeBuffFilterBlacklist, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusdeBuffFilterLessMinite, "Only show debuffs that are 60sec or shorter.")

    local focusdeBuffFilterOnlyMe = CreateCheckbox("focusdeBuffFilterOnlyMe", "Only mine", focusdeBuffEnable)
    focusdeBuffFilterOnlyMe:SetPoint("TOPLEFT", focusdeBuffFilterLessMinite, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local focusAuraGlows = CreateCheckbox("focusAuraGlows", "Extra Aura Settings", playerAuraFiltering)
    focusAuraGlows:SetPoint("TOPLEFT", focusdeBuffFilterOnlyMe, "BOTTOMLEFT", -15, 0)
    focusAuraGlows:HookScript("OnClick", function ()
        CheckAndToggleCheckboxes(focusAuraGlows)
    end)

    local focusEnlargeAura = CreateCheckbox("focusEnlargeAura", "Enlarge Aura", focusAuraGlows)
    focusEnlargeAura:SetPoint("TOPLEFT", focusAuraGlows, "BOTTOMLEFT", 15, pixelsBetweenBoxes)
    CreateTooltip(focusEnlargeAura, "Enlarge checked whitelisted auras.")

    local focusEnlargeAuraEnemy = CreateCheckbox("focusEnlargeAuraEnemy", "", focusAuraGlows, nil, BBF.UpdateUserAuraSettings)
    focusEnlargeAuraEnemy:SetPoint("LEFT", focusEnlargeAura.Text, "RIGHT", 0, 0)
    CreateTooltip(focusEnlargeAuraEnemy, "Enable on Enemy")
    focusEnlargeAuraEnemy:SetSize(22,22)

    focusEnlargeAuraEnemy.texture = focusEnlargeAuraEnemy:CreateTexture(nil, "ARTWORK", nil, 1)
    focusEnlargeAuraEnemy.texture:SetTexture(BBF.squareGreenGlow)
    focusEnlargeAuraEnemy.texture:SetSize(46, 46)
    focusEnlargeAuraEnemy.texture:SetDesaturated(true)
    focusEnlargeAuraEnemy.texture:SetVertexColor(1,0,0)
    focusEnlargeAuraEnemy.texture:SetPoint("CENTER", focusEnlargeAuraEnemy, "CENTER", -0.5, 0)

    local focusEnlargeAuraFriendly = CreateCheckbox("focusEnlargeAuraFriendly", "", focusAuraGlows, nil, BBF.UpdateUserAuraSettings)
    focusEnlargeAuraFriendly:SetPoint("LEFT", focusEnlargeAuraEnemy, "RIGHT", 0, 0)
    CreateTooltip(focusEnlargeAuraFriendly, "Enable on Friendly")
    focusEnlargeAuraFriendly:SetSize(22,22)

    focusEnlargeAuraFriendly.texture = focusEnlargeAuraFriendly:CreateTexture(nil, "ARTWORK", nil, 1)
    focusEnlargeAuraFriendly.texture:SetTexture(BBF.squareGreenGlow)
    focusEnlargeAuraFriendly.texture:SetSize(46, 46)
    --focusEnlargeAuraFriendly.texture:SetDesaturated(true)
    focusEnlargeAuraFriendly.texture:SetPoint("CENTER", focusEnlargeAuraFriendly, "CENTER", -0.5, 0)

    local focusCompactAura = CreateCheckbox("focusCompactAura", "Compact Aura", focusAuraGlows)
    focusCompactAura:SetPoint("TOPLEFT", focusEnlargeAura, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusCompactAura, "Decrease the size of checked whitelisted auras.")

    local focusdeBuffPandemicGlow = CreateCheckbox("focusdeBuffPandemicGlow", "Pandemic Glow", focusAuraGlows)
    focusdeBuffPandemicGlow:SetPoint("TOPLEFT", focusCompactAura, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusdeBuffPandemicGlow, "Red glow on whitelisted auras with less than 5 seconds left.")

    local focusBuffPurgeGlow = CreateCheckbox("focusBuffPurgeGlow", "Purge Glow", focusAuraGlows)
    focusBuffPurgeGlow:SetPoint("TOPLEFT", focusdeBuffPandemicGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusBuffPurgeGlow, "Bright blue glow on all dispellable/purgeable buffs.\n\nReplaces the standard yellow glow.")

    local focusImportantAuraGlow = CreateCheckbox("focusImportantAuraGlow", "Important Glow", focusAuraGlows)
    focusImportantAuraGlow:SetPoint("TOPLEFT", focusBuffPurgeGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(focusImportantAuraGlow, "Green glow on auras marked as important in whitelist")

    --------------------------
    -- Player Auras
    --------------------------
    -- Player Auras

    local enablePlayerBuffFiltering = CreateCheckbox("enablePlayerBuffFiltering", "Enable Buff Filtering", playerAuraFiltering)
    enablePlayerBuffFiltering:SetPoint("TOPLEFT", contentFrame, "BOTTOMLEFT", 503, 140)
    enablePlayerBuffFiltering:HookScript("OnClick", function (self)
        CheckAndToggleCheckboxes(enablePlayerBuffFiltering)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local PlayerAuraFrameBuffEnable = CreateCheckbox("PlayerAuraFrameBuffEnable", "Show BUFFS", enablePlayerBuffFiltering)
    PlayerAuraFrameBuffEnable:SetPoint("TOPLEFT", enablePlayerBuffFiltering, "BOTTOMLEFT", 15, pixelsBetweenBoxes)
    PlayerAuraFrameBuffEnable:HookScript("OnClick", function (self)
        CheckAndToggleCheckboxes(PlayerAuraFrameBuffEnable)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltipTwo(PlayerAuraFrameBuffEnable, "Show Player Buffs", "Show Player Buffs (Top Right)", "If disabled all filtering will be skipped and instead just hide the BuffFrame entirely.")

    local personalBarText = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    personalBarText:SetPoint("LEFT", enablePlayerBuffFiltering, "CENTER", 35, 25)
    personalBarText:SetText("Player Auras")
    local personalBarIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    personalBarIcon:SetAtlas("groupfinder-icon-friend")
    personalBarIcon:SetSize(28, 28)
    personalBarIcon:SetPoint("RIGHT", personalBarText, "LEFT", -3, 0)

    local PlayerAuraBorder = CreateBorderedFrame(enablePlayerBuffFiltering, 185, 400, 65, -186, contentFrame)

    local PlayerAuraFrameBuffFilterWatchList = CreateCheckbox("PlayerAuraFrameBuffFilterWatchList", "Whitelist", PlayerAuraFrameBuffEnable)
    CreateTooltipTwo(PlayerAuraFrameBuffFilterWatchList, "Whitelist", "Only show whitelisted auras.\n(Plus other filters)", "You can have spells whitelisted to add settings such as \"Only Mine\" and \"Important\" etc without needing to enable the whitelist filter here.\n\nOnly check this if you only want whitelisted auras here or the addition of them.\n(Plus other filters)")
    PlayerAuraFrameBuffFilterWatchList:SetPoint("TOPLEFT", PlayerAuraFrameBuffEnable, "BOTTOMLEFT", 15, pixelsBetweenBoxes)

    local playerBuffFilterBlacklist = CreateCheckbox("playerBuffFilterBlacklist", "Blacklist", PlayerAuraFrameBuffEnable)
    playerBuffFilterBlacklist:SetPoint("TOPLEFT", PlayerAuraFrameBuffFilterWatchList, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(playerBuffFilterBlacklist, "Filter out blacklisted auras.")

    local PlayerAuraFrameBuffFilterLessMinite = CreateCheckbox("PlayerAuraFrameBuffFilterLessMinite", "Under one min", PlayerAuraFrameBuffEnable)
    PlayerAuraFrameBuffFilterLessMinite:SetPoint("TOPLEFT", playerBuffFilterBlacklist, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(PlayerAuraFrameBuffFilterLessMinite, "Only show buffs that are 60sec or shorter.")

    local showHiddenAurasIcon = CreateCheckbox("showHiddenAurasIcon", "Filtered Buffs Icon", PlayerAuraFrameBuffEnable)
    showHiddenAurasIcon:SetPoint("TOPLEFT", PlayerAuraFrameBuffFilterLessMinite, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(showHiddenAurasIcon, "Show an icon next to the buff frame displaying\nthe amount of auras filtered out.\nClick icon to show which auras are filtered.")

    -- Create a button next to the checkbox
    local changeIconButton = CreateFrame("Button", "ChangeIconButton", showHiddenAurasIcon, "UIPanelButtonTemplate")
    changeIconButton:SetPoint("RIGHT", showHiddenAurasIcon, "LEFT", 0, 0)
    changeIconButton:SetSize(37, 20)  -- Adjust size as needed
    changeIconButton:SetText("Icon")
    local iconChangeWindow

    changeIconButton:SetScript("OnClick", function()
        if not iconChangeWindow then
            iconChangeWindow = CreateIconChangeWindow()
        end
        iconChangeWindow:Show()
    end)

    showHiddenAurasIcon:HookScript("OnClick", function(self)
        if self:GetChecked() then
            changeIconButton:SetAlpha(1)
            changeIconButton:Enable()
        else
            changeIconButton:SetAlpha(0)
            changeIconButton:Disable()
        end
    end)

    if not BetterBlizzFramesDB.showHiddenAurasIcon then
        changeIconButton:SetAlpha(0)
        changeIconButton:Disable()
    end

    local playerBuffFilterMount = CreateCheckbox("playerBuffFilterMount", "Mount", PlayerAuraFrameBuffEnable)
    playerBuffFilterMount:SetPoint("TOPLEFT", showHiddenAurasIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(playerBuffFilterMount, "Mount", "Show all mounts.\n(Needs testing, please report if you see a mount that is not displayed by this filter)")

    -- Personal Bar Debuffs
    local enablePlayerDebuffFiltering = CreateCheckbox("enablePlayerDebuffFiltering", "Enable Debuff Filtering", playerAuraFiltering)
    enablePlayerDebuffFiltering:SetPoint("TOPLEFT", playerBuffFilterMount, "BOTTOMLEFT", -30, 0)
    enablePlayerDebuffFiltering:HookScript("OnClick", function (self)
        CheckAndToggleCheckboxes(enablePlayerDebuffFiltering)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(enablePlayerDebuffFiltering, "Enables Debuff Filtering.\nThis boy is a bit too heavy to run for my liking so I've turned it off by default.\nUntil I manage to optimize it use at your own risk.\n(It's probably fine, I'm just too cautious)")

    local PlayerAuraFramedeBuffEnable = CreateCheckbox("PlayerAuraFramedeBuffEnable", "Show DEBUFFS", enablePlayerDebuffFiltering)
    PlayerAuraFramedeBuffEnable:SetPoint("TOPLEFT", enablePlayerDebuffFiltering, "BOTTOMLEFT", 15, pixelsBetweenBoxes)
    PlayerAuraFramedeBuffEnable:HookScript("OnClick", function (self)
        CheckAndToggleCheckboxes(PlayerAuraFramedeBuffEnable)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltipTwo(PlayerAuraFramedeBuffEnable, "Show Player Debuffs", "Show Player Debuffs (Top Right)", "If disabled all filtering will be skipped and instead just hide the DebuffFrame entirely.")

    local PlayerAuraFramedeBuffFilterWatchList = CreateCheckbox("PlayerAuraFramedeBuffFilterWatchList", "Whitelist", PlayerAuraFramedeBuffEnable)
    CreateTooltipTwo(PlayerAuraFramedeBuffFilterWatchList, "Whitelist", "Only show whitelisted auras.\n(Plus other filters)", "You can have spells whitelisted to add settings such as \"Only Mine\" and \"Important\" etc without needing to enable the whitelist filter here.\n\nOnly check this if you only want whitelisted auras here or the addition of them.\n(Plus other filters)")
    PlayerAuraFramedeBuffFilterWatchList:SetPoint("TOPLEFT", PlayerAuraFramedeBuffEnable, "BOTTOMLEFT", 15, pixelsBetweenBoxes)

    local playerdeBuffFilterBlacklist = CreateCheckbox("playerdeBuffFilterBlacklist", "Blacklist", PlayerAuraFramedeBuffEnable)
    playerdeBuffFilterBlacklist:SetPoint("TOPLEFT", PlayerAuraFramedeBuffFilterWatchList, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(playerdeBuffFilterBlacklist, "Filter out blacklisted auras.")

    local PlayerAuraFramedeBuffFilterLessMinite = CreateCheckbox("PlayerAuraFramedeBuffFilterLessMinite", "Under one min", PlayerAuraFramedeBuffEnable)
    PlayerAuraFramedeBuffFilterLessMinite:SetPoint("TOPLEFT", playerdeBuffFilterBlacklist, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(PlayerAuraFramedeBuffFilterLessMinite, "Only show debuffs that are 60sec or shorter.")

--[=[
    local debuffDotChecker = CreateCheckbox("debuffDotChecker", "DoT Indicator", PlayerAuraFramedeBuffEnable)
    debuffDotChecker:SetPoint("TOPLEFT", PlayerAuraFramedeBuffFilterLessMinite, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(debuffDotChecker, "Adds an icon next to the player\ndebuffs if one of them is a DoT.")

]=]



    local playerAuraGlows = CreateCheckbox("playerAuraGlows", "Extra Aura Settings", playerAuraFiltering)
    playerAuraGlows:SetPoint("TOPLEFT", PlayerAuraFramedeBuffFilterLessMinite, "BOTTOMLEFT", -30, -20)
    playerAuraGlows:HookScript("OnClick", function ()
        CheckAndToggleCheckboxes(playerAuraGlows)
    end)
    --playerAuraGlows:Disable()
    --playerAuraGlows:SetAlpha(0.5)

--[=[
    local playerAuraPandemicGlow = CreateCheckbox("playerAuraPandemicGlow", "Pandemic Glow", playerAuraGlows)
    playerAuraPandemicGlow:SetPoint("TOPLEFT", playerAuraGlows, "BOTTOMLEFT", 15, pixelsBetweenBoxes)
    CreateTooltip(playerAuraPandemicGlow, "Red glow on whitelisted auras with less than 5 seconds left.")

]=]


    local playerAuraImportantGlow = CreateCheckbox("playerAuraImportantGlow", "Important Glow", playerAuraGlows)
    playerAuraImportantGlow:SetPoint("TOPLEFT", playerAuraGlows, "BOTTOMLEFT", 15, pixelsBetweenBoxes)
    CreateTooltip(playerAuraImportantGlow, "Green glow on auras marked as important in whitelist")

    local addCooldownFramePlayerBuffs = CreateCheckbox("addCooldownFramePlayerBuffs", "Buff Cooldown", playerAuraGlows)
    addCooldownFramePlayerBuffs:SetPoint("TOPLEFT", playerAuraImportantGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(addCooldownFramePlayerBuffs, "Buff Cooldown", "Add a cooldown spiral to player buffs similar to other aura icons.")

    local addCooldownFramePlayerDebuffs = CreateCheckbox("addCooldownFramePlayerDebuffs", "Debuff Cooldown", playerAuraGlows)
    addCooldownFramePlayerDebuffs:SetPoint("TOPLEFT", addCooldownFramePlayerBuffs, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(addCooldownFramePlayerDebuffs, "Debuff Cooldown", "Add a cooldown spiral to player debuffs similar to other aura icons.")

    local hideDefaultPlayerAuraDuration = CreateCheckbox("hideDefaultPlayerAuraDuration", "Hide Duration Text", playerAuraGlows)
    hideDefaultPlayerAuraDuration:SetPoint("TOPLEFT", addCooldownFramePlayerDebuffs, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideDefaultPlayerAuraDuration, "Hide Duration Text", "Hide the default duration text if Buff Cooldown or Debuff Cooldown is on.")

    local hideDefaultPlayerAuraCdText = CreateCheckbox("hideDefaultPlayerAuraCdText", "Hide CD Duration Text", playerAuraGlows)
    hideDefaultPlayerAuraCdText:SetPoint("TOPLEFT", hideDefaultPlayerAuraDuration, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideDefaultPlayerAuraCdText, "Hide CD Duration Text", "Hide the cd text on the new cooldown frame from Buff & Debuff Cooldown.", "This setting will get overwritten by OmniCC unless you make a rule for it.")


    local personalAuraSettings = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    personalAuraSettings:SetPoint("TOP", PlayerAuraBorder, "BOTTOM", 0, -5)
    personalAuraSettings:SetText("Player Aura Settings:")



    local targetAndFocusAuraSettings = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    targetAndFocusAuraSettings:SetPoint("TOP", targetAuraBorder, "BOTTOMRIGHT", 20, -5)
    targetAndFocusAuraSettings:SetText("Target & Focus Aura Settings:")

    --------------------------
    -- Frame settings
    --------------------------






    local targetAndFocusAuraScale = CreateSlider(playerAuraFiltering, "All Aura size", 0.7, 2, 0.01, "targetAndFocusAuraScale")
    targetAndFocusAuraScale:SetPoint("TOP", targetAndFocusAuraSettings, "BOTTOM", 0, -20)
    CreateTooltip(targetAndFocusAuraScale, "Adjusts the size of ALL auras")

    local targetAndFocusSmallAuraScale = CreateSlider(playerAuraFiltering, "Small Aura size", 0.7, 2, 0.01, "targetAndFocusSmallAuraScale")
    targetAndFocusSmallAuraScale:SetPoint("TOP", targetAndFocusAuraScale, "BOTTOM", 0, -20)
    CreateTooltip(targetAndFocusSmallAuraScale, "Adjusts the size of small auras / auras that are not yours.")

    local sameSizeAuras = CreateCheckbox("sameSizeAuras", "Same Size", playerAuraFiltering)
    sameSizeAuras:SetPoint("LEFT", targetAndFocusSmallAuraScale, "RIGHT", 3, 0)
    CreateTooltipTwo(sameSizeAuras, "Same Size", "Enable same sized auras.\n\nBy default your own auras are a little bigger than others. This makes them same size.")
    sameSizeAuras:HookScript("OnClick", function(self)
        if self:GetChecked() then
            DisableElement(targetAndFocusSmallAuraScale)
        else
            EnableElement(targetAndFocusSmallAuraScale)
        end
    end)
    if BetterBlizzFramesDB.sameSizeAuras then
        DisableElement(targetAndFocusSmallAuraScale)
    end

    local enlargedAuraSize = CreateSlider(playerAuraFiltering, "Enlarged Aura Scale", 1, 2, 0.01, "enlargedAuraSize")
    enlargedAuraSize:SetPoint("TOP", targetAndFocusSmallAuraScale, "BOTTOM", 0, -20)
    CreateTooltip(enlargedAuraSize, "The scale of how much bigger you want enlarged auras to be")

    local compactedAuraSize = CreateSlider(playerAuraFiltering, "Compacted Aura Scale", 0.3, 1.5, 0.01, "compactedAuraSize")
    compactedAuraSize:SetPoint("TOP", enlargedAuraSize, "BOTTOM", 0, -20)
    CreateTooltip(compactedAuraSize, "The scale of how much smaller you want compacted auras to be")

    local targetAndFocusAurasPerRow = CreateSlider(playerAuraFiltering, "Max auras per row", 1, 12, 1, "targetAndFocusAurasPerRow")
    targetAndFocusAurasPerRow:SetPoint("TOPLEFT", compactedAuraSize, "BOTTOMLEFT", 0, -17)

    local targetAndFocusAuraOffsetX = CreateSlider(playerAuraFiltering, "x offset", -50, 50, 1, "targetAndFocusAuraOffsetX", "X")
    targetAndFocusAuraOffsetX:SetPoint("TOPLEFT", targetAndFocusAurasPerRow, "BOTTOMLEFT", 0, -17)

    local targetAndFocusAuraOffsetY = CreateSlider(playerAuraFiltering, "y offset", -50, 50, 1, "targetAndFocusAuraOffsetY", "Y")
    targetAndFocusAuraOffsetY:SetPoint("TOPLEFT", targetAndFocusAuraOffsetX, "BOTTOMLEFT", 0, -17)

    local targetAndFocusHorizontalGap = CreateSlider(playerAuraFiltering, "Horizontal gap", 0, 18, 0.5, "targetAndFocusHorizontalGap", "X")
    targetAndFocusHorizontalGap:SetPoint("TOPLEFT", targetAndFocusAuraOffsetY, "BOTTOMLEFT", 0, -17)

    local targetAndFocusVerticalGap = CreateSlider(playerAuraFiltering, "Vertical gap", 0, 18, 0.5, "targetAndFocusVerticalGap", "Y")
    targetAndFocusVerticalGap:SetPoint("TOPLEFT", targetAndFocusHorizontalGap, "BOTTOMLEFT", 0, -17)

    local auraTypeGap = CreateSlider(playerAuraFiltering, "Aura Type Gap", 0, 30, 1, "auraTypeGap", "Y")
    auraTypeGap:SetPoint("TOPLEFT", targetAndFocusVerticalGap, "BOTTOMLEFT", 0, -17)
    CreateTooltip(auraTypeGap, "The gap size between buffs & debuffs")

    local auraStackSize = CreateSlider(playerAuraFiltering, "Aura Stack Size", 0.4, 2, 0.01, "auraStackSize")
    auraStackSize:SetPoint("TOPLEFT", auraTypeGap, "BOTTOMLEFT", 0, -17)
    CreateTooltipTwo(auraStackSize, "Aura Stack Size", "Size of the stack number on auras.")

--[=[
    local maxTargetBuffs = CreateSlider(playerAuraFiltering, "Max Buffs", 1, 32, 1, "maxTargetBuffs")
    maxTargetBuffs:SetPoint("TOPLEFT", targetAndFocusVerticalGap, "BOTTOMLEFT", 0, -17)
    maxTargetBuffs:Disable()
    maxTargetBuffs:SetAlpha(0.5)

    local maxTargetDebuffs = CreateSlider(playerAuraFiltering, "Max Debuffs", 1, 32, 1, "maxTargetDebuffs")
    maxTargetDebuffs:SetPoint("TOPLEFT", maxTargetBuffs, "BOTTOMLEFT", 0, -17)
    maxTargetDebuffs:Disable()
    maxTargetDebuffs:SetAlpha(0.5)

]=]



    local playerAuraSpacingX = CreateSlider(playerAuraFiltering, "Horizontal Padding", 0, 10, 1, "playerAuraSpacingX", "X")
    playerAuraSpacingX:SetPoint("TOP", PlayerAuraBorder, "BOTTOM", 0, -35)
    CreateTooltip(playerAuraSpacingX, "Horizontal padding for aura icons.\nAllows you to set gap to 0 (Blizz limit is 5 in EditMode).", "ANCHOR_LEFT")

    local playerAuraSpacingY = CreateSlider(playerAuraFiltering, "Vertical Padding", -10, 10, 1, "playerAuraSpacingY", "Y")
    playerAuraSpacingY:SetPoint("TOP", playerAuraSpacingX, "BOTTOM", 0, -15)

    local useEditMode = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    useEditMode:SetPoint("TOP", PlayerAuraBorder, "BOTTOM", 0, -90)
    useEditMode:SetText("Use Edit Mode for other settings.")

    local moreAuraSettings = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    moreAuraSettings:SetPoint("TOP", PlayerAuraBorder, "BOTTOM", -100, -125)
    moreAuraSettings:SetText("More Aura Settings:")

    local displayDispelGlowAlways = CreateCheckbox("displayDispelGlowAlways", "Always show purge texture", playerAuraFiltering)
    displayDispelGlowAlways:SetPoint("TOPLEFT", moreAuraSettings, "BOTTOMLEFT", -10, -3)
    CreateTooltip(displayDispelGlowAlways, "Always display the purge/steal texture on auras\nregardless if you have a dispel/purge/steal ability or not.")

    local changePurgeTextureColor = CreateCheckbox("changePurgeTextureColor", "Change Purge Texture Color", playerAuraFiltering)
    changePurgeTextureColor:SetPoint("TOPLEFT", displayDispelGlowAlways, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(changePurgeTextureColor, "Change Purge Texture Color")

    local showPurgeTextureOnSelf = CreateCheckbox("showPurgeTextureOnSelf", "Show Purge Texture on Player Auras", playerAuraFiltering)
    showPurgeTextureOnSelf:SetPoint("TOPLEFT", changePurgeTextureColor, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(showPurgeTextureOnSelf, "Show Purge Texture on Player Auras", "Show Purge Texture on Player Auras (Top Right).")

    local onlyPandemicAuraMine = CreateCheckbox("onlyPandemicAuraMine", "Only Pandemic Mine", playerAuraFiltering)
    onlyPandemicAuraMine:SetPoint("TOPLEFT", showPurgeTextureOnSelf, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(onlyPandemicAuraMine, "Only show the red pandemic aura glow on my own auras", "ANCHOR_LEFT")

    local increaseAuraStrata = CreateCheckbox("increaseAuraStrata", "Increase Aura Frame Strata", playerAuraFiltering)
    increaseAuraStrata:SetPoint("TOPLEFT", onlyPandemicAuraMine, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(increaseAuraStrata, "Increase Aura Frame Strata", "Increase the strata of auras in order to make them appear above the Target & ToT Frames so they are not covered.")
    increaseAuraStrata:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local clickthroughAuras = CreateCheckbox("clickthroughAuras", "Clickthrough Auras", playerAuraFiltering)
    clickthroughAuras:SetPoint("TOPLEFT", increaseAuraStrata, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(clickthroughAuras, "Clickthrough Auras", "Makes auras on target and focus frame clickthrough.\n\nNote: This setting will make it so can no longer click auras to whitelist & blacklist them.")
    clickthroughAuras:HookScript("OnClick", function(self)
        if self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local auraImportantDispelIcon = CreateCheckbox("auraImportantDispelIcon", "Important Glow: Dispel Icon", playerAuraFiltering)
    auraImportantDispelIcon:SetPoint("TOPLEFT", clickthroughAuras, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(auraImportantDispelIcon, "Important Glow: Dispel Icon", "If an aura is marked as Important and has a glow, this setting adds a blue exclamation mark in the bottom left corner if the aura is dispellable.\n\nSince the Important Glow hides the default dispellable glow, this helps you quickly see if an aura can be dispelled (especially for auras that have both dispellable and non-dispellable versions).")

    local function OpenColorPicker(entryColors)
        local colorData = entryColors or {0, 1, 0, 1}
        local r, g, b = colorData[1] or 1, colorData[2] or 1, colorData[3] or 1
        local a = colorData[4] or 1

        local function updateColors(newR, newG, newB, newA)
            entryColors[1] = newR
            entryColors[2] = newG
            entryColors[3] = newB
            entryColors[4] = newA or 1

            BBF.RefreshAllAuraFrames()
        end

        local function swatchFunc()
            r, g, b = ColorPickerFrame:GetColorRGB()
            updateColors(r, g, b, a)
        end

        local function opacityFunc()
            a = ColorPickerFrame:GetColorAlpha()
            updateColors(r, g, b, a)
        end

        local function cancelFunc(previousValues)
            if previousValues then
                r, g, b, a = previousValues.r, previousValues.g, previousValues.b, previousValues.a
                updateColors(r, g, b, a)
            end
        end

        ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }

        ColorPickerFrame:SetupColorPickerAndShow({
            r = r, g = g, b = b, opacity = a, hasOpacity = true,
            swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
        })
    end

    local dispelGlowButton = CreateFrame("Button", nil, playerAuraFiltering, "UIPanelButtonTemplate")
    dispelGlowButton:SetText("Color")
    dispelGlowButton:SetPoint("LEFT", changePurgeTextureColor.text, "RIGHT", -1, 0)
    dispelGlowButton:SetSize(43, 18)
    dispelGlowButton:SetScript("OnClick", function()
        OpenColorPicker(BetterBlizzFramesDB.purgeTextureColorRGB)
    end)
    CreateTooltip(dispelGlowButton, "Dispel/Purge Glow Color.")

    local sortingSettings = contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sortingSettings:SetPoint("TOPLEFT", auraImportantDispelIcon, "BOTTOMLEFT", 10, -4)
    sortingSettings:SetText("Sorting:")

    local customImportantAuraSorting = CreateCheckbox("customImportantAuraSorting", "Sort Important Auras", playerAuraFiltering)
    customImportantAuraSorting:SetPoint("TOPLEFT", auraImportantDispelIcon, "BOTTOMLEFT", 0, -20)
    CreateTooltip(customImportantAuraSorting, "Show Important Auras first in the list\n\n(Remember to enable Important Auras on\nTarget/Focus Frame and check checkbox in whitelist)")

    local customLargeSmallAuraSorting = CreateCheckbox("customLargeSmallAuraSorting", "Sort Enlarged & Compact Auras", playerAuraFiltering)
    customLargeSmallAuraSorting:SetPoint("TOPLEFT", customImportantAuraSorting, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(customLargeSmallAuraSorting, "Show Enlarged Auras first in the list and Compact Auras last.\n\n(Remember to enable Enlarged Auras on\nTarget/Focus Frame and check checkbox in whitelist)")

    local allowLargeAuraFirst = CreateCheckbox("allowLargeAuraFirst", "Sort Enlarged before Important", playerAuraFiltering)
    allowLargeAuraFirst:SetPoint("TOPLEFT", customLargeSmallAuraSorting, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(allowLargeAuraFirst, "If there are both Enlarged and Important auras\nthen show the Enlarged ones first.")

    local purgeableBuffSorting = CreateCheckbox("purgeableBuffSorting", "Sort Purgeable Auras", playerAuraFiltering)
    purgeableBuffSorting:SetPoint("TOPLEFT", allowLargeAuraFirst, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(purgeableBuffSorting, "Sort Purgeable Auras", "Sort purgeable auras before normal auras.\nEnlarged and Important auras will still be prioritized over Purgeable ones unless \"Sort Purgeable before Enlarged/Important\" is checked.")

    local purgeableBuffSortingFirst = CreateCheckbox("purgeableBuffSortingFirst", "Sort Purgeable before Enlarged/Important", purgeableBuffSorting)
    purgeableBuffSortingFirst:SetPoint("TOPLEFT", purgeableBuffSorting, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(purgeableBuffSortingFirst, "Sort Purgeable before Enlarged/Important", "Sort Purgeable before Enlarged and Important auras.")
    purgeableBuffSorting:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(purgeableBuffSorting)
    end)

    -- local customPandemicAuraSorting = CreateCheckbox("customPandemicAuraSorting", "Sort Pandemic Auras before all", playerAuraFiltering)
    -- customPandemicAuraSorting:SetPoint("TOPLEFT", allowLargeAuraFirst, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    -- CreateTooltip(customPandemicAuraSorting, "Sort Pandemic Auras before all other auras during their pandemic window.")




    playerAuraFiltering:HookScript("OnClick", function (self)
        if self:GetChecked() then
            --asd
        else
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end

        CheckAndToggleCheckboxes(playerAuraFiltering)
    end)

    local betaHighlightIcon = playerAuraFiltering:CreateTexture(nil, "BACKGROUND")
    betaHighlightIcon:SetAtlas("CharacterCreate-NewLabel")
    betaHighlightIcon:SetSize(42, 34)
    betaHighlightIcon:SetPoint("RIGHT", playerAuraFiltering, "LEFT", 8, 0)
end

local function guiMisc()
    local guiMisc = CreateFrame("Frame")
    guiMisc.name = "Misc"--"|A:GarrMission_CurrencyIcon-Material:19:19|a Misc"
    guiMisc.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiMisc)
    local guiMiscSubcategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiMisc, guiMisc.name, guiMisc.name)
    guiMiscSubcategory.ID = guiMisc.name;
    CreateTitle(guiMisc)

    local bgImg = guiMisc:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiMisc, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local settingsText = guiMisc:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsText:SetPoint("TOPLEFT", guiMisc, "TOPLEFT", 20, 0)
    settingsText:SetText("Misc settings")
    local miscSettingsIcon = guiMisc:CreateTexture(nil, "ARTWORK")
    miscSettingsIcon:SetAtlas("optionsicon-brown")
    miscSettingsIcon:SetSize(22, 22)
    miscSettingsIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)

    local normalizeGameMenu = CreateCheckbox("normalizeGameMenu", "Normal Size Game Menu", guiMisc)
    normalizeGameMenu:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", -4, pixelsOnFirstBox)
    CreateTooltipTwo(normalizeGameMenu, "Normal Size Game Menu", "Enable to make the Game Menu (Escape) normal size again.\nWe're old boomers but we're not that old jesus.")
    normalizeGameMenu:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.NormalizeGameMenu(true)
        else
            BBF.NormalizeGameMenu(false)
        end
    end)

    local minimizeObjectiveTracker = CreateCheckbox("minimizeObjectiveTracker", "Minimize Objective Frame Better", guiMisc, nil, BBF.MinimizeObjectiveTracker)
    minimizeObjectiveTracker:SetPoint("TOPLEFT", normalizeGameMenu, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(minimizeObjectiveTracker, "Minimize Objective Frame Better", "Also minimize the objectives header when clicking the -+ button |A:UI-QuestTrackerButton-Collapse-All:19:19|a")

    local hideUiErrorFrame = CreateCheckbox("hideUiErrorFrame", "Hide UI Error Frame", guiMisc, nil, BBF.HideFrames)
    hideUiErrorFrame:SetPoint("TOPLEFT", minimizeObjectiveTracker, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideUiErrorFrame, "Hide UI Error Frame", "Hides the UI Error Frame (The red text displaying \"Not enough mana\" etc)")

    local fadeMicroMenu = CreateCheckbox("fadeMicroMenu", "Fade Micro Menu", guiMisc, nil, BBF.FadeMicroMenu)
    fadeMicroMenu:SetPoint("TOPLEFT", hideUiErrorFrame, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(fadeMicroMenu, "Fade Micro Menu", "Fade out the Micro Menu bottom right and only show on mouseover.")

    local fadeMicroMenuExceptQueue = CreateCheckbox("fadeMicroMenuExceptQueue", "Except Queue Eye", fadeMicroMenu, nil, BBF.FadeMicroMenu)
    fadeMicroMenuExceptQueue:SetPoint("LEFT", fadeMicroMenu.text, "RIGHT", 0, 0)
    CreateTooltipTwo(fadeMicroMenuExceptQueue, "Except Queue Eye", "Do not fade Queue Status Eye together with the Micro Menu.")

    fadeMicroMenu:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local moveQueueStatusEye = CreateCheckbox("moveQueueStatusEye", "Move Queue Status Eye", guiMisc, nil, BBF.MoveQueueStatusEye)
    moveQueueStatusEye:SetPoint("TOPLEFT", fadeMicroMenu, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(moveQueueStatusEye, "Move Queue Status Eye", "Makes the Queue Status Eye movable. Default position on Minimap but can also be dragged with Ctrl + Leftclick.")

    moveQueueStatusEye:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local reduceEditModeSelectionAlpha = CreateCheckbox("reduceEditModeSelectionAlpha", "Reduce Edit Mode Glow", guiMisc)
    reduceEditModeSelectionAlpha:SetPoint("TOPLEFT", moveQueueStatusEye, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(reduceEditModeSelectionAlpha, "Reduce Edit Mode Selection Glow", "Reduces the alpha of the edit mode selection so you can actually see the changes you are making.")
    reduceEditModeSelectionAlpha:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BetterBlizzFramesDB.editModeSelectionAlpha = 0.15
            BBF.ReduceEditModeAlpha()
            if BBF.EditModeAlphaSlider then
                BBF.EditModeAlphaSlider:SetValue(0.15)
            end
        else
            BetterBlizzFramesDB.editModeSelectionAlpha = 1
            BBF.ReduceEditModeAlpha(true)
            if BBF.EditModeAlphaSlider then
                BBF.EditModeAlphaSlider:SetValue(1)
            end
        end
    end)

    local hideBagsBar = CreateCheckbox("hideBagsBar", "Hide Bags Bar", guiMisc, nil, BBF.HideFrames)
    hideBagsBar:SetPoint("TOPLEFT", reduceEditModeSelectionAlpha, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideBagsBar, "Hide Bags Bar", "Hide the default Bag Bar showing your bags bottom right.")

    hideBagsBar:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local showLastNameNpc = CreateCheckbox("showLastNameNpc", "Only show last name of NPCs", guiMisc, nil, BBF.AllNameChanges)
    showLastNameNpc:SetPoint("TOPLEFT", hideBagsBar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(showLastNameNpc, "Only show last name of NPCs", "Hides the first names/words of npc names and only shows the last part.")


    local moveableFPSCounter = CreateCheckbox("moveableFPSCounter", "Moveable FPS Counter", guiMisc, nil, BBF.MoveableFPSCounter)
    moveableFPSCounter:SetPoint("TOPLEFT", showLastNameNpc, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(moveableFPSCounter, "Moveable FPS Counter", "Make the default Blizzard FPS Counter (Ctrl+R) moveable.\n\n|cff32f795Right-click to reset position.|r\n|cff32f795Shift+Right-click to toggle font outline on/off.|r")
    moveableFPSCounter:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if IsShiftKeyDown() then
                BetterBlizzFramesDB.fpsCounterFontOutline = true
                BBF.MoveableFPSCounter(false, true)
            else
                BetterBlizzFramesDB.fpsCounterFontOutline = nil
                BBF.MoveableFPSCounter(true)
            end
        end
    end)

    local removeAddonListCategories = CreateCheckbox("removeAddonListCategories", "Improved AddonList", guiMisc, nil, BBF.RemoveAddonCategories)
    removeAddonListCategories:SetPoint("TOPLEFT", moveableFPSCounter, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(removeAddonListCategories, "Improved AddonList", "Remove all categories from the AddonList and sort enabled addons at the top and disabled addons at the bottom for better organization.")

    local hideMinimap = CreateCheckbox("hideMinimap", "Hide Minimap", guiMisc, nil, BBF.MinimapHider)
    hideMinimap:SetPoint("TOPLEFT", removeAddonListCategories, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local hideMinimapButtons = CreateCheckbox("hideMinimapButtons", "Hide Minimap Buttons (still shows on mouseover)", guiMisc, nil, BBF.HideFrames)
    hideMinimapButtons:SetPoint("TOPLEFT", hideMinimap, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    hideMinimapButtons:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideMinimapAuto = CreateCheckbox("hideMinimapAuto", "Hide Minimap during Arena", guiMisc)
    hideMinimapAuto:SetPoint("TOPLEFT", hideMinimapButtons, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideMinimapAuto, "Automatically hide Minimap during arena games.")
    hideMinimapAuto:HookScript("OnClick", function()
        CheckAndToggleCheckboxes(hideMinimapAuto)
        BBF.MinimapHider()
    end)

    local hideMinimapAutoQueueEye = CreateCheckbox("hideMinimapAutoQueueEye", "Hide Queue Status Eye during Arena", guiMisc)
    hideMinimapAutoQueueEye:SetPoint("TOPLEFT", hideMinimapAuto, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideMinimapAutoQueueEye, "Automatically hide Queue Status Eye during arena games.")
    hideMinimapAutoQueueEye:HookScript("OnClick", function()
        BBF.MinimapHider()
    end)

    local hideObjectiveTracker = CreateCheckbox("hideObjectiveTracker", "Hide Objective Tracker during Arena", guiMisc)
    hideObjectiveTracker:SetPoint("TOPLEFT", hideMinimapAutoQueueEye, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideObjectiveTracker, "Automatically hide Objective Tracker during arena games.")
    hideObjectiveTracker:HookScript("OnClick", function()
        BBF.MinimapHider()
    end)

    local recolorTempHpLoss = CreateCheckbox("recolorTempHpLoss", "Recolor Temp Max HP Loss", guiMisc)
    recolorTempHpLoss:SetPoint("TOPLEFT", hideObjectiveTracker, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(recolorTempHpLoss, "Recolor Temp Max HP Loss", "Recolor the temp max hp loss on Player/Target/Focus/Party frame to a softer red color.")
    recolorTempHpLoss:HookScript("OnClick", function()
        BBF.RecolorHpTempLoss()
    end)

    local hideActionBarHotKey = CreateCheckbox("hideActionBarHotKey", "Hide ActionBar Keybinds", guiMisc, nil, BBF.HideFrames)
    hideActionBarHotKey:SetPoint("TOPLEFT", recolorTempHpLoss, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideActionBarHotKey, "Hides the keybind on default actionbars")

    local hideActionBarMacroName = CreateCheckbox("hideActionBarMacroName", "Hide ActionBar Macro Name", guiMisc, nil, BBF.HideFrames)
    hideActionBarMacroName:SetPoint("TOPLEFT", hideActionBarHotKey, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideActionBarMacroName, "Hides the macro name on default actionbars")

    local hideActionBarQualityIcon = CreateCheckbox("hideActionBarQualityIcon", "Hide ActionBar Quality Icon", guiMisc, nil, BBF.HideFrames)
    hideActionBarQualityIcon:SetPoint("TOPLEFT", hideActionBarMacroName, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideActionBarQualityIcon, "Hides the crafting quality icon for items on default actionbars")

    local hideStanceBar = CreateCheckbox("hideStanceBar", "Hide StanceBar (ActionBar)", guiMisc, nil, BBF.HideFrames)
    hideStanceBar:SetPoint("TOPLEFT", hideActionBarQualityIcon, "BOTTOMLEFT", 0, pixelsBetweenBoxes)

    local hideDragonFlying = CreateCheckbox("hideDragonFlying", "Auto-hide Dragonriding (Temporary)", guiMisc)
    hideDragonFlying:SetPoint("TOPLEFT", hideStanceBar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(hideDragonFlying, "Automatically hide the dragon riding thing\nin zones where it shouldnt be showing.\n\n(Blizzard pls fix ur shit)")

    local stealthIndicatorPlayer = CreateCheckbox("stealthIndicatorPlayer", "Stealth Indicator (Temporary?)", guiMisc, nil, BBF.StealthIndicator)
    stealthIndicatorPlayer:SetPoint("TOPLEFT", hideDragonFlying, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    stealthIndicatorPlayer:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)
    CreateTooltip(stealthIndicatorPlayer, "Add a blue border texture around the\nplayer frame during stealth abilities")

    local addUnitFrameBgTexture = CreateCheckbox("addUnitFrameBgTexture", "UnitFrame Background Color", guiMisc)
    addUnitFrameBgTexture:SetPoint("TOPLEFT", stealthIndicatorPlayer, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(addUnitFrameBgTexture, "UnitFrame Background Color", "Enables background color behind health and mana on UnitFrames.\n\n|cff32f795Right-click to change color.|r")
    addUnitFrameBgTexture:HookScript("OnClick", function(self)
        BBF.UnitFrameBackgroundTexture()
    end)
    addUnitFrameBgTexture:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            local function OpenColorPicker(entryColors)
                local colorData = entryColors or {0, 1, 0, 1}
                local r, g, b = colorData[1] or 1, colorData[2] or 1, colorData[3] or 1
                local a = colorData[4] or 1

                local function updateColors(newR, newG, newB, newA)
                    entryColors[1] = newR
                    entryColors[2] = newG
                    entryColors[3] = newB
                    entryColors[4] = newA or 1

                    BBF.UnitFrameBackgroundTexture()
                end

                local function swatchFunc()
                    r, g, b = ColorPickerFrame:GetColorRGB()
                    updateColors(r, g, b, a)
                end

                local function opacityFunc()
                    a = ColorPickerFrame:GetColorAlpha()
                    updateColors(r, g, b, a)
                end

                local function cancelFunc(previousValues)
                    if previousValues then
                        r, g, b, a = previousValues.r, previousValues.g, previousValues.b, previousValues.a
                        updateColors(r, g, b, a)
                    end
                end

                ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }

                ColorPickerFrame:SetupColorPickerAndShow({
                    r = r, g = g, b = b, opacity = a, hasOpacity = true,
                    swatchFunc = swatchFunc, opacityFunc = opacityFunc, cancelFunc = cancelFunc
                })
            end
            OpenColorPicker(BetterBlizzFramesDB.unitFrameBgTextureColor)
        end
    end)

    local useMiniPlayerFrame = CreateCheckbox("useMiniPlayerFrame", "Mini-PlayerFrame", guiMisc)
    useMiniPlayerFrame:SetPoint("TOPLEFT", addUnitFrameBgTexture, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(useMiniPlayerFrame, "Removes healthbar and manabar from the PlayerFrame\nand just leaves Portrait and name.\n\nMove castbar and/or disable auras to your liking.")
    useMiniPlayerFrame:HookScript("OnClick", function(self)
        BBF.MiniFrame(PlayerFrame)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local useMiniTargetFrame = CreateCheckbox("useMiniTargetFrame", "Mini-TargetFrame", guiMisc)
    useMiniTargetFrame:SetPoint("LEFT", useMiniPlayerFrame.Text, "RIGHT", 0, 0)
    CreateTooltip(useMiniTargetFrame, "Removes healthbar and manabar from the TargetFrame\nand just leaves Portrait and name.\n\nMove castbar and/or disable auras to your liking.")
    useMiniTargetFrame:HookScript("OnClick", function(self)
        BBF.MiniFrame(TargetFrame)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local useMiniFocusFrame = CreateCheckbox("useMiniFocusFrame", "Mini-FocusFrame", guiMisc)
    useMiniFocusFrame:SetPoint("LEFT", useMiniTargetFrame.Text, "RIGHT", 0, 0)
    CreateTooltip(useMiniFocusFrame, "Removes healthbar and manabar from the FocusFrame\nand just leaves Portrait and name.\n\nMove castbar and/or disable auras to your liking.")
    useMiniFocusFrame:HookScript("OnClick", function(self)
        BBF.MiniFrame(FocusFrame)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local surrenderArena = CreateCheckbox("surrenderArena", "Surrender over Leaving Arena", guiMisc)
    surrenderArena:SetPoint("TOPLEFT", useMiniPlayerFrame, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(surrenderArena, "Surrender over Leave", "Makes typing /afk in arena Surrender instead of Leaving so you don't lose honor/conquest gain.")

    local druidOverstacks = CreateCheckbox("druidOverstacks", "Druid: Color Berserk Overstack Combo Points Blue", guiMisc)
    druidOverstacks:SetPoint("TOPLEFT", surrenderArena, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(druidOverstacks, "Druid: Color Berserk Overstack Combo Points Blue", "Color the Druid Berserk Overstack Combo Points blue similar to Rogue's Echoing Reprimand.")
    druidOverstacks:HookScript("OnClick", function(self)
        BBF.DruidBlueComboPoints()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local druidAlwaysShowCombos = CreateCheckbox("druidAlwaysShowCombos", "Druid: Always show active Combo Points", guiMisc)
    druidAlwaysShowCombos:SetPoint("TOPLEFT", druidOverstacks, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(druidAlwaysShowCombos, "Druid: Always show active Combo Points", "Always show active combo points regardless of which form you are in.")
    druidAlwaysShowCombos:HookScript("OnClick", function(self)
        BBF.DruidAlwaysShowCombos()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local createAltManaBarDruid = CreateCheckbox("createAltManaBarDruid", "Druid: Show Manabar while in Cat/Bear (as resto)", guiMisc)
    createAltManaBarDruid:SetPoint("TOPLEFT", druidAlwaysShowCombos, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(createAltManaBarDruid, "Druid: Show Manabar while in Cat/Bear (as resto)", "Show Manabar as secondary AlternativePowerBar while in Cat/Bear as Resto. Energy/Rage will still also be shown.")
        createAltManaBarDruid:HookScript("OnClick", function(self)
        BBF.CreateAltManaBar()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideTalkingHeads = CreateCheckbox("hideTalkingHeads", "Hide Talking Heads Frame", guiMisc, nil, BBF.HideTalkingHeads)
    hideTalkingHeads:SetPoint("TOPLEFT", createAltManaBarDruid, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideTalkingHeads, "Hide Talking Heads Frame", "Hide the frame showing npcs talking during quests etc.")
    hideTalkingHeads:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local hideExpAndHonorBar = CreateCheckbox("hideExpAndHonorBar", "Hide XP & Honor Bar", guiMisc, nil, BBF.HideFrames)
    hideExpAndHonorBar:SetPoint("TOPLEFT", hideTalkingHeads, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideExpAndHonorBar, "Hide XP & Honor Bar", "Hide XP & Honor Bar. Still shows when opening Character Panel.")
    hideExpAndHonorBar:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    -- local disableAddonProfiling = CreateCheckbox("disableAddonProfiling", "Disable AddOn Profiler", guiMisc)
    -- disableAddonProfiling:SetPoint("TOPLEFT", hideExpAndHonorBar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    -- CreateTooltipTwo(disableAddonProfiling, "Disable AddOn Profiler", "Turn off AddOn Profiler for a slight bump in performance.\n\nYou will no longer see CPU stats on AddonList and other benchmark AddOns might not work properly until setting is turned back off.")
    -- disableAddonProfiling:HookScript("OnClick", function(self)
    --     StaticPopup_Show("BBF_CONFIRM_RELOAD")
    -- end)

    local arenaOptimizer = CreateCheckbox("arenaOptimizer", "Arena Optimizer", guiMisc)
    arenaOptimizer:SetPoint("TOPLEFT", hideExpAndHonorBar, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(arenaOptimizer, "Arena Optimizer", "Increase performance slightly by lowering non-essential graphics CVars during Arena matches and restoring your original values when leaving.\n\n(Re-check to update saved CVars)\n\nCVars:\nView distance\nShadows\nWater effects\nSSAO\nWeather")
    arenaOptimizer:HookScript("OnClick", function(self)
        BBF.ArenaOptimizer(not self:GetChecked(), true)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local uiWidgetPowerBarScale = CreateSlider(guiMisc, "UIWidgetPowerBarFrame Scale", 0.4, 1.8, 0.01, "uiWidgetPowerBarScale")
    uiWidgetPowerBarScale:SetPoint("TOPLEFT", arenaOptimizer, "BOTTOMLEFT", 5, -15)
    CreateTooltipTwo(uiWidgetPowerBarScale, "UIWidgetPowerBarFrame Scale", "Changes the scale of UIWidgetPowerBarFrame, the frame with Dragonflying charges on it. Also has things like achievements etc I believe idk.")

    local hideActionBar1 = CreateCheckbox("hideActionBar1", "Hide ActionBar1", guiMisc, nil, BBF.HideFrames)
    hideActionBar1:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", 310, pixelsOnFirstBox)
    CreateTooltipTwo(hideActionBar1, "Hide ActionBar1", "Hide ActionBar1. Default UI does not allow this so heres a setting for it.")

    local hideActionBarBigProcGlow = CreateCheckbox("hideActionBarBigProcGlow", "Hide ActionBar Big Proc Glow", guiMisc, nil, BBF.ActionBarMods)
    hideActionBarBigProcGlow:SetPoint("TOPLEFT", hideActionBar1, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideActionBarBigProcGlow, "Hide Actionbar Big Proc Glow", "Hide the big proc glow on default actionbars.\n\nIt will still glow on procs etc but the giant animation when you get the proc will not appear.")

    local hideActionBarCastAnimation = CreateCheckbox("hideActionBarCastAnimation", "Hide ActionBar Cast Animation", guiMisc, nil, BBF.ActionBarMods)
    hideActionBarCastAnimation:SetPoint("TOPLEFT", hideActionBarBigProcGlow, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(hideActionBarCastAnimation, "Hide ActionBar Cast Animation", "Hide the cast animation on default ActionBar buttons.")

    local fixActionBarCDs = CreateCheckbox("fixActionBarCDs", "Fix ActionBar Cooldowns During CC", guiMisc, nil, BBF.ShowCooldownDuringCC)
    fixActionBarCDs:SetPoint("TOPLEFT", hideActionBarCastAnimation, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(fixActionBarCDs, "Fix ActionBar Cooldowns During CC", "Always show ability cooldowns when you're CC'ed.\n\nBy default if the CC is longer than the ability cooldown it gets hidden. You've probably been in situations where you Trinket to interrupt someone only for interrupt to still be on a few seconds CD. No more!")

    local fixActionBarCDsAlwaysHideCD = CreateCheckbox("fixActionBarCDsAlwaysHideCD", "Hide CC Duration", fixActionBarCDs, nil, BBF.ShowCooldownDuringCC)
    fixActionBarCDsAlwaysHideCD:SetPoint("LEFT", fixActionBarCDs.text, "RIGHT", 0, 0)
    CreateTooltipTwo(fixActionBarCDsAlwaysHideCD, "Always Hide CC Duration", "Always hide the CC duration on ActionBars and only show real CDs and just have the bars darkened instead.")
    fixActionBarCDsAlwaysHideCD:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    fixActionBarCDs:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    local raiseTargetFrameLevel = CreateCheckbox("raiseTargetFrameLevel", "Raise TargetFrame Layer", guiMisc, nil, BBF.RaiseTargetFrameLevel)
    raiseTargetFrameLevel:SetPoint("TOPLEFT", fixActionBarCDs, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(raiseTargetFrameLevel, "Raise TargetFrame Layer", "Raise the frame level of TargetFrame so it is above FocusFrame.\n\nThis makes it so if you have TargetFrame positioned above FocusFrame and the Target has so many auras that the castbar goes down to the FocusFrame the castbar will not be hidden behind the FocusFrame.")

    local raiseTargetCastbarStrata = CreateCheckbox("raiseTargetCastbarStrata", "Raise Castbar Stratas", guiMisc, nil, BBF.RaiseTargetCastbarStratas)
    raiseTargetCastbarStrata:SetPoint("TOPLEFT", raiseTargetFrameLevel, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(raiseTargetCastbarStrata, "Raise Castbar Stratas", "Raise the Strata of Target & Focus frame so it does not appear behind the frames.\n\nNote that this will NOT make the TargetFrame castbar appear above the FocusFrame, the setting above is required for that behaviour.")

    local enableLegacyComboPoints = CreateCheckbox("enableLegacyComboPoints", "Legacy Combo Points", guiMisc)
    enableLegacyComboPoints:SetPoint("TOPLEFT", raiseTargetCastbarStrata, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(enableLegacyComboPoints, "Legacy Combo Points", "Enable the old Classic Combo Points and fix their position to work with the new UnitFrames.\n\n|cff32f795Right-Click to adjust position and size.|r")
    enableLegacyComboPoints:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        if not self:GetChecked() then
            BetterBlizzFramesDB.legacyCombosTurnedOff = true
        else
            BetterBlizzFramesDB.legacyCombosTurnedOff = nil
        end
        if not InCombatLockdown() then
            BBF.FixLegacyComboPointsLocation()
        end
        CheckAndToggleCheckboxes(self)
    end)

    function BBF.OpenLegacyComboSliderWindow(launch)
        if not BBF.ComboSliderWindow then
            local f = CreateFrame("Frame", "BBFComboSliderWindow", UIParent, "BasicFrameTemplateWithInset")
            f:SetSize(210, 165)
            f:SetPoint("RIGHT", enableLegacyComboPoints, "LEFT", -10, 0)
            f:SetMovable(true)
            f:EnableMouse(true)
            f:RegisterForDrag("LeftButton")
            f:SetScript("OnDragStart", f.StartMoving)
            f:SetScript("OnDragStop", f.StopMovingOrSizing)
            f:SetFrameStrata("DIALOG")
            f:SetClampedToScreen(true)
            f:SetToplevel(true)

            f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            f.title:SetPoint("TOP", f, "TOP", 0, -6)
            f.title:SetText("Legacy Combo Position")

            BBF.ComboSliderWindow = f

            local sizeSlider = CreateSlider(f, "Size", 0.6, 1.3, 0.01, "legacyComboScale", nil, 140)
            sizeSlider:SetPoint("TOP", f, "TOP", 0, -45)
            CreateTooltipTwo(sizeSlider, "Legacy Combo Points Size")

            local xOffsetSlider = CreateSlider(f, "x offset", -60, 10, 0.5, "legacyComboXPos", true, 140)
            xOffsetSlider:SetPoint("TOP", sizeSlider, "TOP", 0, -30)
            CreateTooltipTwo(xOffsetSlider, "Legacy Combo Points X Offset")

            local yOffsetSlider = CreateSlider(f, "y offset", -60, 10, 0.5, "legacyComboYPos", true, 140)
            yOffsetSlider:SetPoint("TOP", xOffsetSlider, "TOP", 0, -30)
            CreateTooltipTwo(yOffsetSlider, "Legacy Combo Points Y Offset")

            local defaultButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
            defaultButton:SetSize(80, 22)
            defaultButton:SetText("Default")
            defaultButton:SetPoint("BOTTOM", f, "BOTTOM", 0, 10)

            defaultButton:SetScript("OnClick", function()
                BetterBlizzFramesDB.legacyComboXPos = -28
                BetterBlizzFramesDB.legacyComboYPos = -25
                BetterBlizzFramesDB.legacyComboScale = 0.85
                BBF.UpdateLegacyComboPosition()
                sizeSlider:SetValue(0.85)
                xOffsetSlider:SetValue(-28)
                yOffsetSlider:SetValue(-25)
            end)

            f:Hide()
        end

        if launch then
            BBF.ComboSliderWindow:Hide()
            return
        end

        if BBF.ComboSliderWindow:IsShown() then
            BBF.ComboSliderWindow:Hide()
        else
            BBF.ComboSliderWindow:Show()
        end
    end
    BBF.OpenLegacyComboSliderWindow(true)

    enableLegacyComboPoints:SetScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            BBF.OpenLegacyComboSliderWindow()
        end
    end)

    local legacyBlueComboPoints = CreateCheckbox("legacyBlueComboPoints", "Blue Combos", enableLegacyComboPoints)
    legacyBlueComboPoints:SetPoint("LEFT", enableLegacyComboPoints.text, "RIGHT", 0, 0)
    legacyBlueComboPoints:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)
    CreateTooltipTwo(legacyBlueComboPoints, "Blue Legacy Combo Points", "Show blue combo point on Supercharged/Berserk combo points.")

    local alwaysShowLegacyComboPoints = CreateCheckbox("alwaysShowLegacyComboPoints", "Show Always", enableLegacyComboPoints)
    alwaysShowLegacyComboPoints:SetPoint("LEFT", legacyBlueComboPoints.text, "RIGHT", 0, 0)
    alwaysShowLegacyComboPoints:HookScript("OnClick", function()
        BBF.AlwaysShowLegacyComboPoints()
    end)
    CreateTooltipTwo(alwaysShowLegacyComboPoints, "Show Always", "Alway show legacy combo points background regardless if you have active combos or not.")

    local enableLegacyComboPointsMulticlass = CreateCheckbox("enableLegacyComboPointsMulticlass", "Legacy Combo Points: More Classes", enableLegacyComboPoints)
    enableLegacyComboPointsMulticlass:SetPoint("TOPLEFT", enableLegacyComboPoints, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(enableLegacyComboPointsMulticlass, "Legacy Combo Points: More Classes","Enable the old Classic Combo Points for more Classes.\n\n" .."|cFF00FF96Monk|r\n" .."|cFF3FC7EBMage|r\n" .."|cFFF58CBAPaladin|r\n" .."|cFF8788EEWarlock|r\n" .."|cFFC41F3BDeath Knight|r")
    enableLegacyComboPointsMulticlass:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        BBF.GenericLegacyComboSupport()
    end)

    local legacyMulticlassComboClassColor = CreateCheckbox("legacyMulticlassComboClassColor", "Class Color", enableLegacyComboPointsMulticlass)
    legacyMulticlassComboClassColor:SetPoint("LEFT", enableLegacyComboPointsMulticlass.text, "RIGHT", 0, 0)
    legacyMulticlassComboClassColor:HookScript("OnClick", function()
        BBF.ClassColorLegacyCombos()
    end)
    CreateTooltipTwo(legacyMulticlassComboClassColor, "Class Color Legacy Combos", "Class color the legacy combo points.")


    local instantComboPoints = CreateCheckbox("instantComboPoints", "Instant Combo Points", guiMisc, nil, BBF.InstantComboPoints)
    instantComboPoints:SetPoint("TOPLEFT", enableLegacyComboPointsMulticlass, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(instantComboPoints, "Instant Combo Points",
    "Remove the combo point animations for instant feedback.\n\nCurrently works for:\n|cFFFFF569Rogue|r\n|cFFFF7D0ADruid|r\n|cFF00FF96Monk|r\n|cFF3FC7EBMage|r\n|cFFF58CBAPaladin|r\n|cFFAAAAAALegacy Combos (Rogue & Druid)|r")
    instantComboPoints:HookScript("OnClick", function(self)
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
            if BetterBlizzPlatesDB then
                BetterBlizzPlatesDB.instantComboPoints = false
            end
        end
    end)

    local moveResource = CreateCheckbox("moveResource", "Move Resource", guiMisc)
    moveResource:SetPoint("TOPLEFT", instantComboPoints, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(moveResource, "Move Resource", "Move resource (Combo points etc) freely by holding |cff32f795Ctrl + Left Click|r to drag.\n\nToggle off/on to unlock them and reload to save.\n\n|cff32f795Right-click to reset positions and scale for " .. playerClass .. ".|r", "This setting is class specific to the class you are on.")
    moveResource:HookScript("OnClick", function(self)
        if self:GetChecked() then
            BBF.EnableResourceMovement()
        end
    end)
    if BetterBlizzFramesDB.moveResourceStackPos and not BetterBlizzFramesDB.moveResourceStackPos[playerClass] then
        moveResource:SetChecked(false)
    elseif not BetterBlizzFramesDB.moveResourceStackPos then
        moveResource:SetChecked(false)
    end

    local moveResourceToTarget = CreateCheckbox("moveResourceToTarget", "Move Resource to TargetFrame", guiMisc)
    moveResourceToTarget:SetPoint("TOPLEFT", moveResource, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTarget, "Move resource (Combo points, Warlock shards etc) to the TargetFrame.")

    local moveResourceToTargetCustom = CreateCheckbox("moveResourceToTargetCustom", "Free-Move", moveResourceToTarget)
    moveResourceToTargetCustom:SetPoint("LEFT", moveResourceToTarget.text, "RIGHT", 0, 0)
    moveResourceToTargetCustom:HookScript("OnClick", function(self)
        if self:GetChecked() then
            if BBF.ToggleEditMode then
                BBF.ToggleEditMode(true)
            end
            BBF.UpdateClassComboPoints()
        else
            if BBF.ToggleEditMode then
                BBF.ToggleEditMode(false)
            end
            BBF.UpdateClassComboPoints()
        end
    end)
    CreateTooltipTwo(moveResourceToTargetCustom, "Free-Move Resource", "Drag and drop each individual resource/combo points to where you want them.\nWhile moving you can do half pixel adjustments with arrow keys.\n\nToggle off/on to unlock them and reload to save.\n\n" .. "|cff32f795Right-click to reset positions and scale for " .. playerClass .. ".|r", "This will unchain them from TargetFrame so they will no longer move with the TargetFrame if you move the TargetFrame.")

    local moveResourceToTargetRogue = CreateCheckbox("moveResourceToTargetRogue", "Rogue: Combo Points", moveResourceToTarget)
    moveResourceToTargetRogue:SetPoint("TOPLEFT", moveResourceToTarget, "BOTTOMLEFT", 12, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetRogue, "Move Rogue Combo Points to TargetFrame.")
    moveResourceToTargetRogue:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetDruid = CreateCheckbox("moveResourceToTargetDruid", "Druid: Combo Points", moveResourceToTarget)
    moveResourceToTargetDruid:SetPoint("TOPLEFT", moveResourceToTargetRogue, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetDruid, "Move Druid Combo Points to TargetFrame.")
    moveResourceToTargetDruid:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetMonk = CreateCheckbox("moveResourceToTargetMonk", "Monk: Chi Points", moveResourceToTarget)
    moveResourceToTargetMonk:SetPoint("TOPLEFT", moveResourceToTargetDruid, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetMonk, "Move Monk Chi Points to TargetFrame.")
    moveResourceToTargetMonk:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetWarlock = CreateCheckbox("moveResourceToTargetWarlock", "Warlock: Shards", moveResourceToTarget)
    moveResourceToTargetWarlock:SetPoint("TOPLEFT", moveResourceToTargetMonk, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetWarlock, "Move Warlock Shards to TargetFrame.")
    moveResourceToTargetWarlock:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetEvoker = CreateCheckbox("moveResourceToTargetEvoker", "Evoker: Essence", moveResourceToTarget)
    moveResourceToTargetEvoker:SetPoint("TOPLEFT", moveResourceToTargetWarlock, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetEvoker, "Move Evoker Essence to TargetFrame.")
    moveResourceToTargetEvoker:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetMage = CreateCheckbox("moveResourceToTargetMage", "Mage: Arcane Charges", moveResourceToTarget)
    moveResourceToTargetMage:SetPoint("TOPLEFT", moveResourceToTargetEvoker, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetMage, "Move Mage Arcane Charges to TargetFrame.")
    moveResourceToTargetMage:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetDK = CreateCheckbox("moveResourceToTargetDK", "Death Knight: Runes", moveResourceToTarget)
    moveResourceToTargetDK:SetPoint("TOPLEFT", moveResourceToTargetMage, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetDK, "Move Death Knight Runes to TargetFrame.")
    moveResourceToTargetDK:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetPaladin = CreateCheckbox("moveResourceToTargetPaladin", "Paladin: Holy Charges", moveResourceToTarget)
    moveResourceToTargetPaladin:SetPoint("TOPLEFT", moveResourceToTargetDK, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltip(moveResourceToTargetPaladin, "Move Paladin Holy Charges to TargetFrame.")
    moveResourceToTargetPaladin:HookScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local moveResourceToTargetPaladinBG = CreateCheckbox("moveResourceToTargetPaladinBG", "BG", moveResourceToTargetPaladin)
    moveResourceToTargetPaladinBG:SetPoint("LEFT", moveResourceToTargetPaladin.text, "RIGHT", 0, 0)
    CreateTooltipTwo(moveResourceToTargetPaladinBG, "Background", "Show background for unfilled charges.")

    moveResourceToTargetPaladinBG:HookScript("OnClick", function(self)
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    moveResourceToTargetPaladin:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
    end)

    local key = "classResource" .. playerClass .. "Scale"
    local classResourceScale = CreateSlider(guiMisc, "Class Resource Scale", 0.4, 2, 0.01, key)
    classResourceScale:SetPoint("TOPLEFT", moveResourceToTargetPaladin, "BOTTOMLEFT", 5, -15)
    CreateTooltipTwo(classResourceScale, "Class Resource Scale", "Changes the scale of Resource/ComboPoints.", "This setting is class specific to the class you are logged in on.")

    moveResource:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if BetterBlizzFramesDB.moveResourceStackPos then
                BetterBlizzFramesDB.moveResourceStackPos[playerClass] = nil
            end
            classResourceScale:SetValue(1)
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Combo point positions for " .. playerClass .. " have been reset.")
            BBF.ResetResourcePosition()
        end
    end)

    moveResourceToTargetCustom:HookScript("OnMouseDown", function(self, button)
        if button == "RightButton" then
            if BetterBlizzFramesDB.customComboPositions then
                BetterBlizzFramesDB.customComboPositions[playerClass] = nil
            end
            classResourceScale:SetValue(1)
            print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Combo point positions for " .. playerClass .. " have been reset.")
            BBF.UpdateClassComboPoints()
        end
    end)

    moveResourceToTarget:HookScript("OnClick", function(self)
        if self:GetChecked() then
            classResourceScale:SetValue(1)
        end
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
        CheckAndToggleCheckboxes(moveResourceToTarget)
    end)



    local rpNames = CreateCheckbox("rpNames", "Roleplay Names (TRP3)", guiMisc)
    rpNames:SetPoint("BOTTOMRIGHT", guiMisc, "BOTTOMRIGHT", -220, 60)
    CreateTooltipTwo(rpNames, "Roleplay Names", "Enable for support for Total RP3 Roleplay Names and color.")

    local rpNamesFirst = CreateCheckbox("rpNamesFirst", "First", rpNames)
    rpNamesFirst:SetPoint("LEFT", rpNames.text, "RIGHT", 0, 0)
    CreateTooltipTwo(rpNamesFirst, "First Name (TRP3)", "Show RP First Name")

    local rpNamesLast = CreateCheckbox("rpNamesLast", "Last", rpNames)
    rpNamesLast:SetPoint("LEFT", rpNamesFirst.text, "RIGHT", 0, 0)
    CreateTooltipTwo(rpNamesLast, "Last Name (TRP3)", "Show RP Last Name")

    local rpNamesColor = CreateCheckbox("rpNamesColor", "RP Name Text Color (TRP3)", guiMisc)
    rpNamesColor:SetPoint("TOPLEFT", rpNames, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(rpNamesColor, "Roleplay Name Text Color", "Color names in their Total RP3 Roleplay Color.")

    rpNames:HookScript("OnClick", function(self)
        CheckAndToggleCheckboxes(self)
        BBF.AllNameChanges()
    end)

    rpNamesFirst:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
    end)

    rpNamesLast:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
    end)

    rpNamesColor:HookScript("OnClick", function(self)
        BBF.AllNameChanges()
    end)

    local rpNamesHealthbarColor = CreateCheckbox("rpNamesHealthbarColor", "RP Healthbar Color (TRP3)", guiMisc)
    rpNamesHealthbarColor:SetPoint("TOPLEFT", rpNamesColor, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(rpNamesHealthbarColor, "Roleplay Healthbar Color", "Color healthbars in their Total RP3 Roleplay Color.")

    rpNamesHealthbarColor:HookScript("OnClick", function(self)
        BBF.HookHealthbarColors()
        StaticPopup_Show("BBF_CONFIRM_RELOAD")
    end)

    local rpNamesFrameTextureColor = CreateCheckbox("rpNamesFrameTextureColor", "RP FrameTexture Color (TRP3)", guiMisc)
    rpNamesFrameTextureColor:SetPoint("TOPLEFT", rpNamesHealthbarColor, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(rpNamesFrameTextureColor, "Roleplay FrameTexture Color", "Color the FrameTexture of Player/Target/Focus in their Total RP3 Roleplay Color.")

    rpNamesFrameTextureColor:HookScript("OnClick", function(self)
        BBF.HookFrameTextureColor()
        if not self:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

end

local function guiChatFrame()

    local guiChatFrame = CreateFrame("Frame")
    guiChatFrame.name = "ChatFrame"
    guiChatFrame.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiChatFrame)

    local bgImg = guiChatFrame:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiChatFrame, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local playerAuraGlows = CreateCheckbox("playerAuraGlows", "Extra Aura Glow", guiChatFrame)
    playerAuraGlows:SetPoint("TOPLEFT", debuffDotChecker, "BOTTOMLEFT", -15, -22)
end

local function guiCooldownManager()
    local guiCdManager = CreateFrame("Frame")
    guiCdManager.name = "CD Manager"--"|A:GarrMission_CurrencyIcon-Material:19:19|a Misc"
    guiCdManager.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiCdManager)
    local guiCdManagerSubcategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiCdManager, guiCdManager.name, guiCdManager.name)
    guiCdManagerSubcategory.ID = guiCdManager.name;
    CreateTitle(guiCdManager)

    local bgImg = guiCdManager:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiCdManager, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local settingsText = guiCdManager:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    settingsText:SetPoint("TOPLEFT", guiCdManager, "TOPLEFT", 20, 0)
    settingsText:SetText("Cooldown Manager")
    local cdIcon = guiCdManager:CreateTexture(nil, "ARTWORK")
    cdIcon:SetAtlas("questlog-questtypeicon-clockorange")
    cdIcon:SetSize(22, 22)
    cdIcon:SetPoint("RIGHT", settingsText, "LEFT", -3, -1)

    local cdNote = guiCdManager:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cdNote:SetPoint("BOTTOMLEFT", bgImg, "BOTTOMLEFT", 10, 5)
    cdNote:SetFont("Interface\\AddOns\\BetterBlizzFrames\\media\\arialn.TTF", 11)
    cdNote:SetText("WIP: Early version. Reloads between changes might be needed. Expect this to get many tweaks in the next few weeks. Please report any bugs.")

    local list = CreateCDManagerList(guiCdManager)

    local cooldownViewerEnabled = CreateCheckbox("cooldownViewerEnabled", "Enable Cooldown Manager", guiCdManager, "cooldownViewerEnabled")
    cooldownViewerEnabled:SetPoint("TOPLEFT", settingsText, "BOTTOMLEFT", -4, pixelsOnFirstBox)
    cooldownViewerEnabled:HookScript("OnClick", function(self)
        local enabled = self:GetChecked()
        if not InCombatLockdown() then
            C_CVar.SetCVar("cooldownViewerEnabled", enabled and "1" or "0")
        end
    end)
    CreateTooltipTwo(cooldownViewerEnabled, "Enable Cooldown Manager", "Enable Blizzard's new Cooldown Manager introduced in 11.1.5")
    cooldownViewerEnabled:SetChecked(C_CVar.GetCVarBool("cooldownViewerEnabled"))

    local cdManagerSorting = CreateCheckbox("cdManagerSorting", "Filter & Sort Icons", guiCdManager, nil, BBF.HookCooldownManagerTweaks)
    cdManagerSorting:SetPoint("TOPLEFT", cooldownViewerEnabled, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(cdManagerSorting, "Filter & Sort Icons", "Filter and sort icons on the Cooldown Manager.")
    list:SetAlpha(BetterBlizzFramesDB.cdManagerSorting and 1 or 0.3)


    local cdManagerCenterIcons = CreateCheckbox("cdManagerCenterIcons", "Center Icons", guiCdManager, nil, BBF.HookCooldownManagerTweaks)
    cdManagerCenterIcons:SetPoint("TOPLEFT", cdManagerSorting, "BOTTOMLEFT", 0, pixelsBetweenBoxes)
    CreateTooltipTwo(cdManagerCenterIcons, "Center Icons", "Center icons on the Cooldown Manager")
    cdManagerCenterIcons:HookScript("OnClick", function(self)
        if not self:GetChecked() and not cdManagerCenterIcons:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
    end)

    cdManagerSorting:HookScript("OnClick", function(self)
        local enabled = self:GetChecked()
        if not enabled and not cdManagerCenterIcons:GetChecked() then
            StaticPopup_Show("BBF_CONFIRM_RELOAD")
        end
        list:SetAlpha(enabled and 1 or 0.3)
    end)
end

local function guiImportAndExport()
    local guiImportAndExport = CreateFrame("Frame")
    guiImportAndExport.name = "Import & Export"--"|A:GarrMission_CurrencyIcon-Material:19:19|a Misc"
    guiImportAndExport.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiImportAndExport)
    local guiImportSubcategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiImportAndExport, guiImportAndExport.name, guiImportAndExport.name)
    guiImportSubcategory.ID = guiImportAndExport.name;
    CreateTitle(guiImportAndExport)

    local bgImg = guiImportAndExport:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiImportAndExport, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local fullProfile = CreateImportExportUI(guiImportAndExport, "Full Profile", BetterBlizzFramesDB, 20, -20, "fullProfile")

    local auraWhitelist = CreateImportExportUI(fullProfile, "Aura Whitelist", BetterBlizzFramesDB.auraWhitelist, 0, -100, "auraWhitelist")
    local auraBlacklist = CreateImportExportUI(auraWhitelist, "Aura Blacklist", BetterBlizzFramesDB.auraBlacklist, 210, 0, "auraBlacklist")

    local importPVPWhitelist = CreateFrame("Button", nil, guiImportAndExport, "UIPanelButtonTemplate")
    importPVPWhitelist:SetSize(150, 35)
    importPVPWhitelist:SetPoint("TOP", auraWhitelist, "BOTTOM", 0, -25)
    importPVPWhitelist:SetText("Import PvP Whitelist")
    importPVPWhitelist:SetScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_PVP_WHITELIST")
    end)
    local coloredText = "|cff00FF00Important/Immunity|r\n" ..
                    "|cffFF8000Offensive Buff|r\n" ..
                    "|cffFFA9F1Defensive Buffs|r\n" ..
                    "|cff00FFFFFreedom/Speed|r\n" ..
                    "|cffEFFF33Fear Immunity|r"

    CreateTooltipTwo(importPVPWhitelist, "Import PvP Whitelist", "Import a color coded Whitelist with most important Offensives, Defensives & Freedoms for TWW added.\n\n"..coloredText.."\n\nThis will only add NEW entries and not mess with existing ones in your current whitelist.\n\nWill tweak this as time goes on probably.")

    local importPVPBlacklist = CreateFrame("Button", nil, guiImportAndExport, "UIPanelButtonTemplate")
    importPVPBlacklist:SetSize(150, 35)
    importPVPBlacklist:SetPoint("TOP", auraBlacklist, "BOTTOM", 0, -25)
    importPVPBlacklist:SetText("Import PvP Blacklist")
    importPVPBlacklist:SetScript("OnClick", function()
        StaticPopup_Show("BBF_CONFIRM_PVP_BLACKLIST")
    end)
    CreateTooltipTwo(importPVPBlacklist, "Import PvP Blacklist", "Import a Blacklist with A LOT (750+) of trash buffs blacklisted.\n\nThis will only add NEW entries and not mess with existing ones already in your blacklist.")

end

local function guiCustomCode()
    local guiCustomCode = CreateFrame("Frame")
    guiCustomCode.name = "Custom Code"
    guiCustomCode.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiCustomCode)
    local guiCustomCodeSubCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiCustomCode, guiCustomCode.name, guiCustomCode.name)
    guiCustomCodeSubCategory.ID = guiCustomCode.name;
    BBF.guiCustomCode = guiCustomCode.name
    CreateTitle(guiCustomCode)

    local bgImg = guiCustomCode:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiCustomCode, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local discordLinkEditBox = CreateFrame("EditBox", nil, guiCustomCode, "InputBoxTemplate")
    discordLinkEditBox:SetPoint("TOPLEFT", guiCustomCode, "TOPLEFT", 25, -45)
    discordLinkEditBox:SetSize(180, 20)
    discordLinkEditBox:SetAutoFocus(false)
    discordLinkEditBox:SetFontObject("ChatFontSmall")
    discordLinkEditBox:SetText("https://discord.gg/cjqVaEMm25")
    discordLinkEditBox:SetCursorPosition(0) -- Places cursor at start of the text
    discordLinkEditBox:ClearFocus() -- Removes focus from the EditBox
    discordLinkEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    discordLinkEditBox:SetScript("OnTextChanged", function(self)
        self:SetText("https://discord.gg/cjqVaEMm25")
    end)
    --discordLinkEditBox:HighlightText() -- Highlights the text for easy copying
    discordLinkEditBox:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    discordLinkEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    discordLinkEditBox:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local discordText = guiCustomCode:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    discordText:SetPoint("BOTTOM", discordLinkEditBox, "TOP", 18, 8)
    discordText:SetText("Join the Discord for info\nand help with BBP/BBF")

    local joinDiscord = guiCustomCode:CreateTexture(nil, "ARTWORK")
    joinDiscord:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\discord.tga")
    joinDiscord:SetSize(52, 52)
    joinDiscord:SetPoint("RIGHT", discordText, "LEFT", 0, 1)

    local boxOne = CreateFrame("EditBox", nil, guiCustomCode, "InputBoxTemplate")
    boxOne:SetPoint("LEFT", discordLinkEditBox, "RIGHT", 50, 0)
    boxOne:SetSize(180, 20)
    boxOne:SetAutoFocus(false)
    boxOne:SetFontObject("ChatFontSmall")
    boxOne:SetText("https://patreon.com/bodifydev")
    boxOne:SetCursorPosition(0) -- Places cursor at start of the text
    boxOne:ClearFocus() -- Removes focus from the EditBox
    boxOne:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    boxOne:SetScript("OnTextChanged", function(self)
        self:SetText("https://patreon.com/bodifydev")
    end)
    --boxOne:HighlightText() -- Highlights the text for easy copying
    boxOne:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    boxOne:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    boxOne:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local boxOneTex = guiCustomCode:CreateTexture(nil, "ARTWORK")
    boxOneTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\patreon.tga")
    boxOneTex:SetSize(58, 58)
    boxOneTex:SetPoint("BOTTOMLEFT", boxOne, "TOPLEFT", 3, -2)

    local patText = guiCustomCode:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    patText:SetPoint("LEFT", boxOneTex, "RIGHT", 14, -1)
    patText:SetText("Patreon")

    local boxTwo = CreateFrame("EditBox", nil, guiCustomCode, "InputBoxTemplate")
    boxTwo:SetPoint("LEFT", boxOne, "RIGHT", 35, 0)
    boxTwo:SetSize(180, 20)
    boxTwo:SetAutoFocus(false)
    boxTwo:SetFontObject("ChatFontSmall")
    boxTwo:SetText("https://paypal.me/bodifydev")
    boxTwo:SetCursorPosition(0) -- Places cursor at start of the text
    boxTwo:ClearFocus() -- Removes focus from the EditBox
    boxTwo:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    boxTwo:SetScript("OnTextChanged", function(self)
        self:SetText("https://paypal.me/bodifydev")
    end)
    --boxTwo:HighlightText() -- Highlights the text for easy copying
    boxTwo:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    boxTwo:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    boxTwo:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local boxTwoTex = guiCustomCode:CreateTexture(nil, "ARTWORK")
    boxTwoTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\paypal.tga")
    boxTwoTex:SetSize(58, 58)
    boxTwoTex:SetPoint("BOTTOMLEFT", boxTwo, "TOPLEFT", 3, -2)

    local palText = guiCustomCode:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    palText:SetPoint("LEFT", boxTwoTex, "RIGHT", 14, -1)
    palText:SetText("Paypal")







    -- Implementing the code editor inside the guiCustomCode frame
    local FAIAP = BBF.indent

    -- Define your color table for syntax highlighting
    local colorTable = {
        [FAIAP.tokens.TOKEN_SPECIAL] = "|c00F1D710",
        [FAIAP.tokens.TOKEN_KEYWORD] = "|c00BD6CCC",
        [FAIAP.tokens.TOKEN_COMMENT_SHORT] = "|c00999999",
        [FAIAP.tokens.TOKEN_COMMENT_LONG] = "|c00999999",
        [FAIAP.tokens.TOKEN_STRING] = "|c00E2A085",
        [FAIAP.tokens.TOKEN_NUMBER] = "|c00B1FF87",
        [FAIAP.tokens.TOKEN_ASSIGNMENT] = "|c0055ff88",
        [FAIAP.tokens.TOKEN_WOW_API] = "|c00ff8000",
        [FAIAP.tokens.TOKEN_WOW_EVENTS] = "|c004ec9b0",
        [0] = "|r",  -- Reset color
    }

    -- Add a scroll frame for the code editor
    local scrollFrame = CreateFrame("ScrollFrame", nil, guiCustomCode, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP", guiCustomCode, "TOP", -10, -110)
    scrollFrame:SetSize(620, 440)  -- Fixed size for the entire editor box

    -- Label for the custom code box
    local customCodeText = guiCustomCode:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    customCodeText:SetPoint("BOTTOM", scrollFrame, "TOP", 0, 5)
    customCodeText:SetText("Enter Custom Lua Code (Executes at Login)")

    -- Create the code editor
    local codeEditBox = CreateFrame("EditBox", nil, scrollFrame)
    codeEditBox:SetMultiLine(true)
    codeEditBox:SetFontObject("ChatFontSmall")
    codeEditBox:SetSize(600, 370)  -- Smaller than the scroll frame to allow scrolling
    codeEditBox:SetAutoFocus(false)
    codeEditBox:SetCursorPosition(0)
    codeEditBox:SetText(BetterBlizzFramesDB.customCode or "")
    codeEditBox:ClearFocus()

    -- Attach the EditBox to the scroll frame
    scrollFrame:SetScrollChild(codeEditBox)

    -- Add a static custom background to the scroll frame
    local bg = scrollFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.6)  -- Semi-transparent black background
    bg:SetAllPoints(scrollFrame)  -- Apply the background to the entire scroll frame

    -- Add a static custom border around the scroll frame
    local border = CreateFrame("Frame", nil, scrollFrame, BackdropTemplateMixin and "BackdropTemplate")
    border:SetPoint("TOPLEFT", scrollFrame, -2, 2)
    border:SetPoint("BOTTOMRIGHT", scrollFrame, 2, -2)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
    })
    border:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)  -- Light gray border

    -- Optional: Set padding or insets if needed
    codeEditBox:SetTextInsets(6, 10, 4, 10)

    -- Track changes to detect unsaved edits
    local unsavedChanges = false
    codeEditBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            -- Compare current text with saved code
            local currentText = self:GetText()
            if currentText ~= BetterBlizzFramesDB.customCode then
                unsavedChanges = true
            else
                unsavedChanges = false
            end
        end
    end)

    -- Enable syntax highlighting and indentation with FAIAP
    FAIAP.enable(codeEditBox, colorTable, 4)  -- Assuming a tab width of 4

    local customCodeSaved = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Custom code has been saved."

    -- Create Save Button
    local saveButton = CreateFrame("Button", nil, guiCustomCode, "UIPanelButtonTemplate")
    saveButton:SetSize(120, 30)
    saveButton:SetPoint("TOP", scrollFrame, "BOTTOM", 0, -10)
    saveButton:SetText("Save")
    saveButton:SetScript("OnClick", function()
        BetterBlizzFramesDB.customCode = codeEditBox:GetText()
        unsavedChanges = false
        print(customCodeSaved)
    end)

    -- Flag to prevent double triggering of the prompt
    local promptShown = false

    -- Function to show the save prompt if needed
    local function showSavePrompt()
        if unsavedChanges and not promptShown then
            promptShown = true
            StaticPopup_Show("UNSAVED_CHANGES_PROMPT")
        end
    end

    -- Prevent the EditBox from clearing focus with ESC if there are unsaved changes
    codeEditBox:SetScript("OnEscapePressed", function(self)
        if unsavedChanges then
            showSavePrompt()
        else
            self:ClearFocus()
        end
    end)

    StaticPopupDialogs["UNSAVED_CHANGES_PROMPT"] = {
        text = "|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames \n\nYou have unsaved changes to the custom code.\n\nDo you want to save them?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            BetterBlizzFramesDB.customCode = codeEditBox:GetText()
            unsavedChanges = false
            codeEditBox:ClearFocus()
            print(customCodeSaved)
            if BetterBlizzFramesDB.reopenOptions then
                ReloadUI()
            end
        end,
        OnCancel = function()
            unsavedChanges = false
            codeEditBox:ClearFocus()
            if BetterBlizzFramesDB.reopenOptions then
                ReloadUI()
            end
        end,
        timeout = 0,
        whileDead = true,
    }

    local reloadUiButton = CreateFrame("Button", nil, guiCustomCode, "UIPanelButtonTemplate")
    reloadUiButton:SetText("Reload UI")
    reloadUiButton:SetWidth(85)
    reloadUiButton:SetPoint("TOP", guiCustomCode, "BOTTOMRIGHT", -140, -9)
    reloadUiButton:SetScript("OnClick", function()
        if unsavedChanges then
            showSavePrompt()
            BetterBlizzFramesDB.reopenOptions = true
            return
        end
        BetterBlizzFramesDB.reopenOptions = true
        ReloadUI()
    end)
end

local function guiSupport()
    local guiSupport = CreateFrame("Frame")
    guiSupport.name = "|A:GarrisonTroops-Health:10:10|a Support"
    guiSupport.parent = BetterBlizzFrames.name
    --InterfaceOptions_AddCategory(guiSupport)
    local guiSupportCategory = Settings.RegisterCanvasLayoutSubcategory(BBF.category, guiSupport, guiSupport.name, guiSupport.name)
    guiSupportCategory.ID = guiSupport.name;
    BBF.guiSupport = guiSupport.name
    BBF.category.guiSupportCategory = guiSupportCategory.ID
    CreateTitle(guiSupport)

    local bgImg = guiSupport:CreateTexture(nil, "BACKGROUND")
    bgImg:SetAtlas("professions-recipe-background")
    bgImg:SetPoint("CENTER", guiSupport, "CENTER", -8, 4)
    bgImg:SetSize(680, 610)
    bgImg:SetAlpha(0.4)
    bgImg:SetVertexColor(0,0,0)

    local discordLinkEditBox = CreateFrame("EditBox", nil, guiSupport, "InputBoxTemplate")
    discordLinkEditBox:SetPoint("TOP", guiSupport, "TOP", 0, -170)
    discordLinkEditBox:SetSize(180, 20)
    discordLinkEditBox:SetAutoFocus(false)
    discordLinkEditBox:SetFontObject("ChatFontNormal")
    discordLinkEditBox:SetText("https://discord.gg/cjqVaEMm25")
    discordLinkEditBox:SetCursorPosition(0) -- Places cursor at start of the text
    discordLinkEditBox:ClearFocus() -- Removes focus from the EditBox
    discordLinkEditBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    discordLinkEditBox:SetScript("OnTextChanged", function(self)
        self:SetText("https://discord.gg/cjqVaEMm25")
    end)
    --discordLinkEditBox:HighlightText() -- Highlights the text for easy copying
    discordLinkEditBox:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    discordLinkEditBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    discordLinkEditBox:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local discordText = guiSupport:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    discordText:SetPoint("BOTTOM", discordLinkEditBox, "TOP", 18, 8)
    discordText:SetText("Join the Discord for info\nand help with BBP/BBF")

    local joinDiscord = guiSupport:CreateTexture(nil, "ARTWORK")
    joinDiscord:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\discord.tga")
    joinDiscord:SetSize(52, 52)
    joinDiscord:SetPoint("RIGHT", discordText, "LEFT", 0, 1)

    local supportText = guiSupport:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    supportText:SetPoint("TOP", guiSupport, "TOP", 0, -230)
    supportText:SetText("If you wish to support me and my projects\nit would be greatly appreciated |A:GarrisonTroops-Health:10:10|a")

    local boxOne = CreateFrame("EditBox", nil, guiSupport, "InputBoxTemplate")
    boxOne:SetPoint("TOP", guiSupport, "TOP", -110, -360)
    boxOne:SetSize(180, 20)
    boxOne:SetAutoFocus(false)
    boxOne:SetFontObject("ChatFontNormal")
    boxOne:SetText("https://patreon.com/bodifydev")
    boxOne:SetCursorPosition(0) -- Places cursor at start of the text
    boxOne:ClearFocus() -- Removes focus from the EditBox
    boxOne:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    boxOne:SetScript("OnTextChanged", function(self)
        self:SetText("https://patreon.com/bodifydev")
    end)
    --boxOne:HighlightText() -- Highlights the text for easy copying
    boxOne:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    boxOne:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    boxOne:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local boxOneTex = guiSupport:CreateTexture(nil, "ARTWORK")
    boxOneTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\patreon.tga")
    boxOneTex:SetSize(58, 58)
    boxOneTex:SetPoint("BOTTOM", boxOne, "TOP", 0, 1)

    local boxTwo = CreateFrame("EditBox", nil, guiSupport, "InputBoxTemplate")
    boxTwo:SetPoint("TOP", guiSupport, "TOP", 110, -360)
    boxTwo:SetSize(180, 20)
    boxTwo:SetAutoFocus(false)
    boxTwo:SetFontObject("ChatFontNormal")
    boxTwo:SetText("https://paypal.me/bodifydev")
    boxTwo:SetCursorPosition(0) -- Places cursor at start of the text
    boxTwo:ClearFocus() -- Removes focus from the EditBox
    boxTwo:SetScript("OnEscapePressed", function(self)
        self:ClearFocus() -- Allows user to press escape to unfocus the EditBox
    end)

    -- Make the EditBox text selectable and readonly
    boxTwo:SetScript("OnTextChanged", function(self)
        self:SetText("https://paypal.me/bodifydev")
    end)
    --boxTwo:HighlightText() -- Highlights the text for easy copying
    boxTwo:SetScript("OnCursorChanged", function() end) -- Prevents cursor changes
    boxTwo:SetScript("OnEditFocusGained", function(self) self:HighlightText() end) -- Re-highlights text when focused
    boxTwo:SetScript("OnMouseUp", function(self)
        if not self:IsMouseOver() then
            self:ClearFocus()
        end
    end)

    local boxTwoTex = guiSupport:CreateTexture(nil, "ARTWORK")
    boxTwoTex:SetTexture("Interface\\AddOns\\BetterBlizzFrames\\media\\logos\\paypal.tga")
    boxTwoTex:SetSize(58, 58)
    boxTwoTex:SetPoint("BOTTOM", boxTwo, "TOP", 0, 1)
end
------------------------------------------------------------
-- GUI Setup
------------------------------------------------------------
local function CombatOnGUICreation()
    if InCombatLockdown() then
        print("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames: Waiting for combat to drop before opening settings for the first time.")
        if not BBF.waitingCombat then
            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_REGEN_ENABLED")
            f:SetScript("OnEvent", function(self)
                self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                BBF.LoadGUI()
            end)
            BBF.waitingCombat = true
        end
        return true
    end
end

function BBF.InitializeOptions()
    if not BetterBlizzFrames then
        BetterBlizzFrames = CreateFrame("Frame")
        BetterBlizzFrames.name = "Better|cff00c0ffBlizz|rFrames |A:gmchat-icon-blizz:16:16|a"
        --InterfaceOptions_AddCategory(BetterBlizzFrames)
        BBF.category = Settings.RegisterCanvasLayoutCategory(BetterBlizzFrames, BetterBlizzFrames.name, BetterBlizzFrames.name)
        BBF.category.ID = BetterBlizzFrames.name
        Settings.RegisterAddOnCategory(BBF.category)

        local titleText = BetterBlizzFrames:CreateFontString(nil, "OVERLAY", "GameFont_Gigantic")
        titleText:SetPoint("CENTER", BetterBlizzFrames, "CENTER", -15, 33)
        titleText:SetText("|A:gmchat-icon-blizz:16:16|a Better|cff00c0ffBlizz|rFrames")
        BetterBlizzFrames.titleText = titleText

        local loadGUI = CreateFrame("Button", nil, BetterBlizzFrames, "UIPanelButtonTemplate")
        loadGUI:SetText("Load Settings")
        loadGUI:SetWidth(100)
        loadGUI:SetPoint("CENTER", BetterBlizzFrames, "CENTER", -18, 6)
        BetterBlizzFrames.loadGUI = loadGUI
        loadGUI:SetScript("OnClick", function(self)
            if CombatOnGUICreation() then return end
            titleText:Hide()
            self:Hide()
            BBF.LoadGUI()
        end)
    end
end

function BBF.LoadGUI()
    if BetterBlizzFrames.guiLoaded then return end
    if BetterBlizzFramesDB.hasNotOpenedSettings then
        BBF.CreateIntroMessageWindow()
        BetterBlizzFramesDB.hasNotOpenedSettings = nil
        return
    end
    if CombatOnGUICreation() then return end

    guiGeneralTab()
    guiPositionAndScale()
    guiFrameAuras()
    guiCooldownManager()
    guiFrameLook()
    guiCastbars()
    guiImportAndExport()
    guiMisc()
    --guiChatFrame()
    guiCustomCode()
    guiSupport()
    BetterBlizzFrames.guiLoaded = true

    Settings.OpenToCategory(BBF.category.ID)
    Settings.OpenToCategory(BBF.guiCustomCode)
    Settings.OpenToCategory(BBF.category.ID)
end


function BBF.CreateIntroMessageWindow()
    if BBF.IntroMessageWindow then
        BBF.IntroMessageWindow:ClearAllPoints()
        if BBP and BBP.IntroMessageWindow and BBP.IntroMessageWindow:IsShown() then
            BBP.IntroMessageWindow:ClearAllPoints()
            BBP.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", 240, 45)
            BBF.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", -240, 45)
        else
            BBF.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 45)
        end
        BBF.IntroMessageWindow:Show()
        return
    end

    BBF.IntroMessageWindow = CreateFrame("Frame", "BBFIntro", UIParent, "PortraitFrameTemplate")
    BBF.IntroMessageWindow:SetSize(470, 550)
    BBF.IntroMessageWindow.Bg:SetDesaturated(true)
    BBF.IntroMessageWindow.Bg:SetVertexColor(0.5,0.5,0.5, 0.98)
    if BBP and BBP.IntroMessageWindow and BBP.IntroMessageWindow:IsShown() then
        BBP.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", 240, 45)
        BBF.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", -240, 45)
    else
        BBF.IntroMessageWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 45)
    end
    BBF.IntroMessageWindow:SetMovable(true)
    BBF.IntroMessageWindow:EnableMouse(true)
    BBF.IntroMessageWindow:RegisterForDrag("LeftButton")
    BBF.IntroMessageWindow:SetScript("OnDragStart", BBF.IntroMessageWindow.StartMoving)
    BBF.IntroMessageWindow:SetScript("OnDragStop", BBF.IntroMessageWindow.StopMovingOrSizing)
    BBF.IntroMessageWindow:SetTitle("Better|cff00c0ffBlizz|rFrames v"..BBF.VersionNumber)
    BBF.IntroMessageWindow:SetFrameStrata("HIGH")

    -- Add background texture
    BBF.IntroMessageWindow.textureTest = BBF.IntroMessageWindow:CreateTexture(nil, "BACKGROUND")
    BBF.IntroMessageWindow.textureTest:SetAtlas("communities-widebackground")
    BBF.IntroMessageWindow.textureTest:SetSize(465, 150)
    BBF.IntroMessageWindow.textureTest:SetPoint("TOP", BBF.IntroMessageWindow, "TOP", 0, -15)

    -- Create a mask texture
    local maskTexture = BBF.IntroMessageWindow:CreateMaskTexture()
    maskTexture:SetAtlas("Azerite-CenterBG-ChannelGlowBar-FillingMask")
    maskTexture:SetSize(665, 300)
    maskTexture:SetPoint("CENTER", BBF.IntroMessageWindow.textureTest, "CENTER", 0, 50)
    BBF.IntroMessageWindow.textureTest:AddMaskTexture(maskTexture)

    BBF.IntroMessageWindow:SetPortraitToAsset(135724)

    local welcomeText = BBF.IntroMessageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge2")
    welcomeText:SetPoint("TOP", BBF.IntroMessageWindow, "TOP", 0, -45)
    welcomeText:SetText("Welcome to Better|cff00c0ffBlizz|rFrames!")
    welcomeText:SetJustifyH("CENTER")

    local description1 = BBF.IntroMessageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    description1:SetPoint("TOP", welcomeText, "BOTTOM", 0, -10)
    description1:SetText("Thank you for trying out my addon!\n\nBelow you can pick a profile to start with or you can exit and customize everything by yourself.\n\nI highly recommend the minimal |A:newplayerchat-chaticon-newcomer:16:16|a|cff32cd32Starter Profile|r if you just\nwant a quick start with only the essentials!")
    description1:SetJustifyH("CENTER")
    description1:SetWidth(410)

    local btnWidth, btnHeight, btnGap = 150, 30, -3

    local function ShowProfileConfirmation(profileName, class, profileFunction, additionalNote)
        local noteText = additionalNote or ""
        local color = CLASS_COLORS[class] or "|cffffffff"
        local icon = CLASS_ICONS[class] or "groupfinder-icon-role-leader"
        local profileText = string.format("|A:%s:16:16|a %s%s|r", icon, color, profileName.." Profile")
        local confirmationText = titleText .. "Are you sure you want to go\nwith the " .. profileText .. "?\n\n" .. noteText .. "Click yes to apply and Reload UI."
        StaticPopupDialogs["BBF_CONFIRM_PROFILE"].text = confirmationText
        StaticPopup_Show("BBF_CONFIRM_PROFILE", nil, nil, { func = profileFunction })
    end

    local starterButton = CreateClassButton(BBF.IntroMessageWindow, "STARTER", "Starter", nil, function()
        ShowProfileConfirmation("Starter", "STARTER", BBF.StarterProfile)
    end)
    starterButton:SetPoint("TOP", description1, "BOTTOM", 0, -20)

    local orText = BBF.IntroMessageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    orText:SetPoint("CENTER", starterButton, "BOTTOM", 0, -20)
    orText:SetText("OR")
    orText:SetJustifyH("CENTER")

    local aeghisButton = CreateClassButton(BBF.IntroMessageWindow, "MAGE", "Aeghis", "aeghis", function()
        ShowProfileConfirmation("Aeghis", "MAGE", BBF.AeghisProfile)
    end)
    aeghisButton:SetPoint("TOP", starterButton, "BOTTOM", 0, -40)

    local kalvishButton = CreateClassButton(BBF.IntroMessageWindow, "ROGUE", "Kalvish", "kalvish", function()
        ShowProfileConfirmation("Kalvish", "ROGUE", BBF.KalvishProfile)
    end)
    kalvishButton:SetPoint("TOP", aeghisButton, "BOTTOM", 0, btnGap)

    local magnuszButton = CreateClassButton(BBF.IntroMessageWindow, "WARRIOR", "Magnusz", "magnusz", function()
        ShowProfileConfirmation("Magnusz", "WARRIOR", BBF.MagnuszProfile)
    end)
    magnuszButton:SetPoint("TOP", kalvishButton, "BOTTOM", 0, btnGap)

    local nahjButton = CreateClassButton(BBF.IntroMessageWindow, "ROGUE", "Nahj", "nahj", function()
        ShowProfileConfirmation("Nahj", "ROGUE", BBF.NahjProfile)
    end)
    nahjButton:SetPoint("TOP", magnuszButton, "BOTTOM", 0, btnGap)

    local snupyButton = CreateClassButton(BBF.IntroMessageWindow, "DRUID", "Snupy", "snupy", function()
        ShowProfileConfirmation("Snupy", "DRUID", BBF.SnupyProfile)
    end)
    snupyButton:SetPoint("TOP", nahjButton, "BOTTOM", 0, btnGap)

    local orText2 = BBF.IntroMessageWindow:CreateFontString(nil, "OVERLAY", "GameFontNormalMed2")
    orText2:SetPoint("CENTER", snupyButton, "BOTTOM", 0, -20)
    orText2:SetText("OR")
    orText2:SetJustifyH("CENTER")

    local buttonLast = CreateFrame("Button", nil, BBF.IntroMessageWindow, "GameMenuButtonTemplate")
    buttonLast:SetSize(btnWidth, btnHeight)
    buttonLast:SetText("Exit, No Profile.")
    buttonLast:SetPoint("TOP", snupyButton, "BOTTOM", 0, -40)
    buttonLast:SetNormalFontObject("GameFontNormal")
    buttonLast:SetHighlightFontObject("GameFontHighlight")
    buttonLast:SetScript("OnClick", function()
        BBF.IntroMessageWindow:Hide()
        if not BetterBlizzFrames.guiLoaded then
            BBF.LoadGUI()
        else
            Settings.OpenToCategory(BBF.category.ID)
        end
    end)
    CreateTooltipTwo(buttonLast, "Exit, No Profile", "Exit and customize everything yourself.", nil, "ANCHOR_TOP")
    local f,s,o = buttonLast.Text:GetFont()
    buttonLast.Text:SetFont(f,s,"OUTLINE")

    BBF.IntroMessageWindow.CloseButton:HookScript("OnClick", function()
        if not BetterBlizzFrames.guiLoaded then
            BBF.LoadGUI()
        else
            Settings.OpenToCategory(BBF.category.ID)
        end
    end)

    local function AdjustWindowHeight()
        local baseHeight = 334
        local perButtonHeight = 29
        local buttonCount = -1
        for _, child in ipairs({BBF.IntroMessageWindow:GetChildren()}) do
            if child and child:IsObjectType("Button") then
                buttonCount = buttonCount + 1
            end
        end
        local newHeight = baseHeight + (buttonCount * perButtonHeight)
        BBF.IntroMessageWindow:SetSize(470, newHeight)
    end
    AdjustWindowHeight()
end