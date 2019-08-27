local _G, SUI = _G, SUI
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_Classic')
----------------------------------------------------------------------------------------------------

local plate

function module:SetupProfile()
	Artwork_Core:SetupProfile()
end

function module:CreateProfile()
	Artwork_Core:CreateProfile()
end

function module:InitActionBars()
	--if (Bartender4.db:GetCurrentProfile() == SUI.DB.Styles.Classic.BartenderProfile) then
	Artwork_Core:ActionBarPlates('SUI_ActionBarPlate')
	--end

	do -- create bar plate and masks
		plate = CreateFrame('Frame', 'SUI_ActionBarPlate', SpartanUI, 'SUI_ActionBarsTemplate')
		plate:SetFrameStrata('BACKGROUND')
		plate:SetFrameLevel(1)
		plate:SetPoint('BOTTOM')

		plate.mask1 = CreateFrame('Frame', 'SUI_Popup1Mask', SpartanUI, 'SUI_Popup1MaskTemplate')
		plate.mask1:SetFrameStrata('MEDIUM')
		plate.mask1:SetFrameLevel(0)
		plate.mask1:SetPoint('BOTTOM', SUI_Popup1, 'BOTTOM')

		plate.mask2 = CreateFrame('Frame', 'SUI_Popup2Mask', SpartanUI, 'SUI_Popup2MaskTemplate')
		plate.mask2:SetFrameStrata('MEDIUM')
		plate.mask2:SetFrameLevel(0)
		plate.mask2:SetPoint('BOTTOM', SUI_Popup2, 'BOTTOM')
	end
end

function module:EnableActionBars()
	do -- create base module frames
		-- Fix CPU leak, use UpdateInterval
		plate.UpdateInterval = 0.5
		plate.TimeSinceLastUpdate = 0
		plate:HookScript(
			'OnUpdate',
			function(self, ...) -- backdrop and popup visibility changes (alpha, animation, hide/show)
				local elapsed = select(1, ...)
				self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed
				if (self.TimeSinceLastUpdate > self.UpdateInterval) then
					-- Debug
					--				print(self.TimeSinceLastUpdate)
					if (SUI.DB.ActionBars.bar1) then
						for b = 1, 6 do -- for each backdrop
							if SUI.DB.ActionBars['bar' .. b].enable then -- backdrop enabled
								-- _G["SUI_Bar"..b]:SetAlpha(SUI.DB.ActionBars["bar"..b].alpha/100 or 1); -- apply alpha
								_G['SUI_Bar' .. b]:Show() -- apply alpha
							else -- backdrop disabled
								_G['SUI_Bar' .. b]:Hide()
							end
						end
						for p = 1, 2 do -- for each popup
							if (SUI.DB.ActionBars['popup' .. p].enable) then -- popup enabled
								_G['SUI_Popup' .. p]:SetAlpha(SUI.DB.ActionBars['popup' .. p].alpha / 100 or 1) -- apply alpha
								if SUI.DB.ActionBars['popup' .. p].anim == true then --- animation enabled
									_G['SUI_Popup' .. p .. 'MaskBG']:Show()
								else -- animation disabled
									_G['SUI_Popup' .. p .. 'MaskBG']:Hide()
								end
							else -- popup disabled
								_G['SUI_Popup' .. p]:Hide()
								_G['SUI_Popup' .. p .. 'MaskBG']:Hide()
							end
						end
						if not MouseIsOver(SUI_Popup1Mask) and not MouseIsOver(SUI_Popup1) and SUI.DB.ActionBars['popup1'].anim then -- popup1 animation
							SUI_Popup1MaskBG:Show()
						else
							SUI_Popup1MaskBG:Hide()
						end
						if not MouseIsOver(SUI_Popup2Mask) and not MouseIsOver(SUI_Popup2) and SUI.DB.ActionBars['popup2'].anim then -- popup2 animation
							SUI_Popup2MaskBG:Show()
						else
							SUI_Popup2MaskBG:Hide()
						end
					end
					self.TimeSinceLastUpdate = 0
				end
			end
		)
	end
	do -- modify strata / levels of backdrops
		for i = 1, 6 do
			_G['SUI_Bar' .. i]:SetFrameStrata('BACKGROUND')
			_G['SUI_Bar' .. i]:SetFrameLevel(3)
		end
		for i = 1, 2 do
			_G['SUI_Popup' .. i]:SetFrameStrata('BACKGROUND')
			_G['SUI_Popup' .. i]:SetFrameLevel(3)
		end
	end
	--module:SetupProfile();
	-- Do what Bartender isn't - Make the Bag buttons the same size
	do -- modify CharacterBag(0-3) Scale
		for i = 1, 4 do
			_G['CharacterBag' .. (i - 1) .. 'Slot']:SetScale(1.25)
		end
	end
end
