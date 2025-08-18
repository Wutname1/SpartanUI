local cdManagerFrames = {
    EssentialCooldownViewer,
    UtilityCooldownViewer,
    BuffIconCooldownViewer,
    BuffBarCooldownViewer,
}

-- Essential = 0
-- Utility = 1
-- BuffIcon = 2
-- BuffBar = 3

function BBF.RefreshCooldownManagerIcons()
    for _, frame in ipairs(cdManagerFrames) do
        local center = frame ~= BuffBarCooldownViewer
        BBF.SortCooldownManagerIcons(frame, center)
    end
end

function BBF.ResetCooldownManagerIcons()
    for _, frame in ipairs(cdManagerFrames) do
        if frame:GetNumChildren() > 0 then
            for i = 1, frame:GetNumChildren() do
                local child = select(i, frame:GetChildren())
                if child and child.Show then
                    child:Show()
                end
            end
        end
    end
end

function BBF.SortCooldownManagerIcons(frame, center)
    if not frame or not frame.GetItemFrames then return end

    local sorting = BetterBlizzFramesDB.cdManagerSorting
    local centering = BetterBlizzFramesDB.cdManagerCenterIcons

    if not sorting and not centering then return end

    local icons = frame:GetItemFrames()
    if not icons or #icons == 0 then return end

    local iconPadding = frame.iconPadding or 5
    local iconWidth = icons[1] and icons[1]:GetWidth() or 32
    local iconHeight = icons[1] and icons[1]:GetHeight() or 32
    local rowLimit = (frame == BuffIconCooldownViewer and frame.stride) or frame.iconLimit or 8
    local isVertical = frame.layoutFramesGoingUp

    -- Local helper to place icon at specific index (row/col based)
    local function PlaceIcon(icon, index)
        local row, col

        if isVertical then
            row = (index - 1) % rowLimit
            col = math.floor((index - 1) / rowLimit)
        else
            row = math.floor((index - 1) / rowLimit)
            col = (index - 1) % rowLimit
        end

        local x = col * (iconWidth + iconPadding)
        local y = -row * (iconHeight + iconPadding)

        icon._bbfOriginalX = x
        icon._bbfOriginalY = y

        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    end

    if sorting then
        local sortedIcons = {}
        local visibleIcons = 0

        for i, icon in ipairs(icons) do
            local spellID = icon.GetSpellID and icon:GetSpellID()
            if spellID and not BetterBlizzFramesDB.cdManagerBlacklist[spellID] then
                table.insert(sortedIcons, {
                    frame = icon,
                    spellID = spellID,
                    priority = BetterBlizzFramesDB.cdManagerPriorityList[spellID] or 0,
                    originalIndex = i,
                })
                visibleIcons = visibleIcons + 1
            else
                if frame == UtilityCooldownViewer or frame == BuffBarCooldownViewer then
                    icon:SetAlpha(0)
                else
                    icon:Hide()
                end
            end
        end

        table.sort(sortedIcons, function(a, b)
            if a.priority ~= b.priority then
                return a.priority > b.priority
            end
            return a.originalIndex < b.originalIndex
        end)

        for i, data in ipairs(sortedIcons) do
            local icon = data.frame
            if frame == UtilityCooldownViewer or frame == BuffBarCooldownViewer then
                if icon.isActive then
                    icon:SetAlpha(1)
                end
            else
                -- if frame == BuffIconCooldownViewer then
                --     if icon.isActive then
                --         icon:Show()
                --     end
                -- else
                --     icon:Show()
                -- end
                if icon.isActive then
                    icon:Show()
                end
            end
            PlaceIcon(icon, i)
        end

        if center and centering and not isVertical then
            local originalCount = #icons
            local shownCount = #sortedIcons
            local lastRowCount = shownCount % rowLimit

            if shownCount <= rowLimit then
                lastRowCount = shownCount
            end

            if frame == BuffIconCooldownViewer then
                local activeIcons = {}
                for _, data in ipairs(sortedIcons) do
                    local icon = data.frame
                    if icon.isActive then
                        tinsert(activeIcons, icon)
                    end
                end


                local activeCount = #activeIcons
                if activeCount > 0 then
                    local rowWidth = (iconWidth * activeCount) + (iconPadding * (activeCount - 1))
                    local containerWidth = (iconWidth * rowLimit) + (iconPadding * (rowLimit - 1))
                    local startX = (containerWidth - rowWidth) / 2

                    for i, icon in ipairs(activeIcons) do
                        local x = (i - 1) * (iconWidth + iconPadding)
                        local y = 0 -- Single row
                        icon:ClearAllPoints()
                        icon:SetPoint("TOPLEFT", frame, "TOPLEFT", startX + x, y)
                    end
                end
            else
                if lastRowCount > 0 then
                    local rowWidth = (iconWidth * lastRowCount) + (iconPadding * (lastRowCount - 1))
                    local isOneRow = originalCount <= rowLimit
                    local fullRowCount = isOneRow and originalCount or rowLimit
                    local fullRowWidth = (iconWidth * fullRowCount) + (iconPadding * (fullRowCount - 1))
                    local shiftX = (fullRowWidth - rowWidth) / 2

                    for i = shownCount - lastRowCount + 1, shownCount do
                        local icon = sortedIcons[i].frame
                        if icon and icon:IsShown() and icon:GetAlpha() == 1 then
                            local x = icon._bbfOriginalX or 0
                            local y = icon._bbfOriginalY or 0
                            icon:ClearAllPoints()
                            icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x + shiftX, y)
                        end
                    end
                end
            end
        end

    elseif center and centering and not isVertical then
        if frame == BuffIconCooldownViewer then
            local activeIcons = {}
            for _, icon in ipairs(icons) do
                if icon:IsShown() and icon:GetAlpha() == 1 then
                    tinsert(activeIcons, icon)
                end
            end


            local activeCount = #activeIcons
            if activeCount > 0 then
                local rowWidth = (iconWidth * activeCount) + (iconPadding * (activeCount - 1))
                local containerWidth = (iconWidth * rowLimit) + (iconPadding * (rowLimit - 1))
                local startX = (containerWidth - rowWidth) / 2

                for i, icon in ipairs(activeIcons) do
                    local x = (i - 1) * (iconWidth + iconPadding)
                    local y = 0 -- Single row
                    icon:ClearAllPoints()
                    icon:SetPoint("TOPLEFT", frame:GetItemContainerFrame(), "TOPLEFT", startX + x, y)
                end
            end
        else
            local totalIcons = #icons
            local iconsPerRow = rowLimit
            if totalIcons <= iconsPerRow then return end

            local lastRowCount = totalIcons % iconsPerRow
            if lastRowCount == 0 then return end

            local rowWidth = (iconWidth * lastRowCount) + (iconPadding * (lastRowCount - 1))
            local fullRowWidth = (iconWidth * iconsPerRow) + (iconPadding * (iconsPerRow - 1))
            local shiftX = (fullRowWidth - rowWidth) / 2

            for i, icon in ipairs(icons) do
                local row = math.floor((i - 1) / rowLimit)
                local col = (i - 1) % rowLimit

                local x = col * (iconWidth + iconPadding)
                local y = -row * (iconHeight + iconPadding)

                icon._bbfOriginalX = x
                icon._bbfOriginalY = y

                icon:ClearAllPoints()
                icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
            end

            for i = totalIcons - lastRowCount + 1, totalIcons do
                local icon = icons[i]
                if icon and icon:IsShown() then
                    local x = icon._bbfOriginalX or 0
                    local y = icon._bbfOriginalY or 0
                    icon:ClearAllPoints()
                    icon:SetPoint("TOPLEFT", frame, "TOPLEFT", x + shiftX, y)
                end
            end
        end
    end
end


function BBF.UpdateCooldownManagerSpellList(bypass)
    if SettingsPanel:IsShown() or bypass then
        local categories = {
            Enum.CooldownViewerCategory.Essential,
            Enum.CooldownViewerCategory.Utility,
            --Enum.CooldownViewerCategory.BuffIcons,
            --Enum.CooldownViewerCategory.BuffBars,
        }

        local seen = {}
        BBF.cooldownManagerSpells = {}

        for _, category in ipairs(categories) do
            local entries = C_CooldownViewer.GetCooldownViewerCategorySet(category)
            for _, id in ipairs(entries or {}) do
                local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(id)
                if info and info.spellID and not seen[info.spellID] then
                    seen[info.spellID] = true
                    table.insert(BBF.cooldownManagerSpells, info.spellID)
                end
            end
        end

        table.sort(BBF.cooldownManagerSpells, function(a, b)
            local pa = BetterBlizzFramesDB.cdManagerPriorityList[a] or 0
            local pb = BetterBlizzFramesDB.cdManagerPriorityList[b] or 0
            return pa > pb
        end)
        BBF.cdManagerNeedsUpdate = nil
    else
        BBF.cdManagerNeedsUpdate = true
    end
end

function BBF.HookCooldownManagerTweaks()
    local cdTweaksEnabled = BetterBlizzFramesDB.cdManagerCenterIcons or BetterBlizzFramesDB.cdManagerSorting
    if not cdTweaksEnabled then return end

    for _, frame in ipairs(cdManagerFrames) do
        if frame and frame.RefreshLayout then

            -- Override Cooldown Sorting
            if cdTweaksEnabled and not frame.bbfSortingHooked then
                local center = frame ~= BuffBarCooldownViewer
                hooksecurefunc(frame, "Layout", function(self)
                    BBF.SortCooldownManagerIcons(self, center)
                end)
                if frame == BuffIconCooldownViewer then
                    local f = CreateFrame("Frame")
                    f:RegisterUnitEvent("UNIT_AURA", "player")
                    f:SetScript("OnEvent", function(_, _, unit, updateInfo)
                        if not updateInfo then return end

                        local triggered = false

                        if updateInfo.isFullUpdate then
                            AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(aura)
                                if aura.auraInstanceID then
                                    triggered = true
                                end
                            end)
                        else
                            -- Handle added auras
                            if updateInfo.addedAuras then
                                for _, aura in ipairs(updateInfo.addedAuras) do
                                    if aura.isHelpful and aura.auraInstanceID then
                                        triggered = true
                                        break
                                    end
                                end
                            end

                            -- Handle updated auras
                            if updateInfo.updatedAuraInstanceIDs then
                                for _, id in ipairs(updateInfo.updatedAuraInstanceIDs) do
                                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, id)
                                    if aura and aura.isHelpful then
                                        triggered = true
                                        break
                                    end
                                end
                            end

                            -- Handle removed auras
                            if updateInfo.removedAuraInstanceIDs then
                                triggered = true
                            end
                        end

                        if triggered then
                            BBF.SortCooldownManagerIcons(frame, center)
                        end
                    end)
                end
                frame.bbfSortingHooked = true
            end

        end
    end

    BBF.RefreshCooldownManagerIcons()

    if not BBF.CDManagerTweaks then
        BBF.CDManagerTweaks = CreateFrame("Frame")
        BBF.CDManagerTweaks:RegisterEvent("SPELLS_CHANGED")
        BBF.CDManagerTweaks:SetScript("OnEvent", function()
            --if InCombatLockdown() then return end
            BBF.RefreshCooldownManagerIcons()
            BBF.UpdateCooldownManagerSpellList()
        end)
        BBF.UpdateCooldownManagerSpellList(true)

        SettingsPanel:HookScript("OnShow", function()
            if BBF.cdManagerNeedsUpdate and BBF.RefreshCdManagerList then
                BBF.RefreshCdManagerList()
            end
        end)
    end
end