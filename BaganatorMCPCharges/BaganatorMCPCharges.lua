local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
-- frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= "BaganatorMCPCharges" then return end

        -- Clean up ADDON_LOADED event after initial load
        self:UnregisterEvent("ADDON_LOADED")

        -- Get client version for debugging
        local gameVersion, buildVersion, buildDate, tocVersion = GetBuildInfo()
        print("BaganatorMCPCharges loaded, Version:", gameVersion, "TOC:", tocVersion)

        -- Check if Baganator is loaded
        if not Baganator or not Baganator.API then
            print("Error: Baganator or its API not found!")
            return
        end

        -- Register the MCP Charges widget with Baganator
        Baganator.API.RegisterCornerWidget(
            "MCP Charges", -- label: User-facing text
            "MCP_CHARGES", -- id: Unique identifier
            function(cornerFrame, itemDetails)
                -- Check if the item is Manual Crowd Pummeler (Item ID 9449)
                if not itemDetails or not itemDetails.itemID or itemDetails.itemID ~= 9449 then
                    cornerFrame:SetText("")
                    return false -- Hide widget for non-matching items
                end

                if not itemDetails.itemLink then
                    return nil
                end
                if not itemDetails.tooltipInfo then
                    itemDetails.tooltipInfo = itemDetails.tooltipGetter()
                end
                if itemDetails.tooltipInfo then
                    local hasCounterweight = false
                    local charges = 0
                    -- Scan all tooltip lines to gather information
                    for _, row in ipairs(itemDetails.tooltipInfo.lines) do
                        local text = row.leftText
                        if text then
                            -- Check for Counterweight
                            if text:find("Counterweight") then
                                hasCounterweight = true
                            end
                            -- Check for charges
                            if text:find("charges") or text:find("Charge") then
                                charges = tonumber(text:match("%d+") or 0)
                            end
                        end
                    end
                    -- Build display text
                    local displayText = tostring(charges)
                    if hasCounterweight then
                        displayText = displayText .. "+"
                    end
                    cornerFrame:SetText(displayText)
                    cornerFrame:SetTextColor(unpack(({
                        [0] = {0.65, 0.65, 0.65}, -- Gray for 0 charges
                        [1] = {1, 0.3, 0.3},   -- Bright red
                        [2] = {1, 1, 0.3},     -- Bright yellow
                        [3] = {0.3, 1, 0.3}    -- Bright green
                    })[charges] or {0.65, 0.65, 0.65}))
                    return true
                end
                cornerFrame:SetText("")
                return false
            end,
            function(itemButton)
                if not itemButton.chargesText then
                    local chargesText = itemButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    chargesText:SetPoint("TOPLEFT", itemButton, "TOPLEFT", 2, -2) -- Adjust position as needed
                    chargesText:SetFont("Fonts\\FRIZQT__.TTF", 20, "THICKOUTLINE") -- Font settings
                    itemButton.chargesText = chargesText
                end
                return itemButton.chargesText
            end,
            {corner = "top_left", priority = 1} -- Default position
        )
--     elseif event == "BAG_UPDATE_DELAYED" then
--         Baganator.API.RequestItemButtonsRefresh({Baganator.Constants.RefreshReason.ItemWidgets})
--     end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        local slot = ...
        -- Trigger refresh on equipment changes in slot 16 (Main Hand)
        if slot == 16 then
            Baganator.API.RequestItemButtonsRefresh({Baganator.Constants.RefreshReason.ItemWidgets})
        end
    end

end)
