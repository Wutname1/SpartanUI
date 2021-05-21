local SUI, L = SUI, SUI.L
local Artwork_Core = SUI:GetModule('Component_Artwork')
local module = SUI:GetModule('Style_Classic')
local artFrame = CreateFrame('Frame', 'SUI_Art_Classic', SpartanUI)
----------------------------------------------------------------------------------------------------
local SkinnedFrames = {}

local function CreateArtwork()
	local plate = CreateFrame('Frame', 'Classic_ActionBarPlate', artFrame)
	plate:SetSize(1002, 139)
	plate:SetFrameStrata('BACKGROUND')
	plate:SetFrameLevel(1)
	plate:SetAllPoints(SUI_BottomAnchor)

	-- Create actionbar BG's
	local BarBGSettings = {
		name = 'Classic',
		height = 37,
		TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\bar-backdrop1',
		TexCoord = {0.107421875, 0.896484375, 0.25, 0.765625}
	}

	local BarBGSettings2 = {
		name = 'Classic',
		width = 140,
		height = 110,
		TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\bar-backdrop3',
		TexCoord = {0.23828125, 0.76171875, 0.09375, 0.8828125}
	}

	local BarBGSettings3 = {
		name = 'Classic',
		-- height = 32,
		point = 'BOTTOM',
		TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\bar-backdrop0'
		-- TexCoord = {0.23828125, 0.76171875, 0.09375, 0.8828125}
	}

	local PopupMask = {
		name = 'Classic',
		height = 34,
		point = 'BOTTOMRIGHT',
		TexturePath = 'Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\bar-popup1'
		-- TexCoord = {0.23828125, 0.76171875, 0.09375, 0.8828125}
	}

	for i = 1, 4 do
		plate['BG' .. i] = Artwork_Core:CreateBarBG(BarBGSettings, i, Classic_ActionBarPlate)
	end
	plate.BG5 = Artwork_Core:CreateBarBG(BarBGSettings2, 5, Classic_ActionBarPlate)
	plate.BG6 = Artwork_Core:CreateBarBG(BarBGSettings2, 6, Classic_ActionBarPlate)

	for i = 1, 6 do
		plate['BG' .. i]:SetFrameLevel(3)
	end

	plate.POP1 = Artwork_Core:CreateBarBG(BarBGSettings3, 'Stance', Classic_ActionBarPlate)
	plate.POP2 = Artwork_Core:CreateBarBG(BarBGSettings3, 'MenuBar', Classic_ActionBarPlate)
	plate.POP1:SetFrameLevel(3)
	plate.POP2:SetFrameLevel(3)

	plate.mask1 = Artwork_Core:CreateBarBG(PopupMask, 9, Classic_ActionBarPlate)
	plate.mask1:SetFrameStrata('MEDIUM')
	plate.mask1:SetFrameLevel(50)
	plate.mask1:SetPoint('BOTTOMRIGHT', plate.POP1, 'BOTTOMRIGHT')

	plate.mask2 = Artwork_Core:CreateBarBG(PopupMask, 10, Classic_ActionBarPlate)
	plate.mask2.BG:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\bar-popup2')
	plate.mask2:SetFrameStrata('MEDIUM')
	plate.mask2:SetFrameLevel(50)
	plate.mask2.BG:ClearAllPoints()
	plate.mask2.BG:SetPoint('BOTTOMLEFT', plate.mask2)
	plate.mask2:SetPoint('BOTTOMLEFT', plate.POP2, 'BOTTOMLEFT')

	-- Position Actionbar BG's
	plate.BG1:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -100, 70)
	plate.BG2:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -100, 31)

	plate.BG3:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 100, 70)
	plate.BG4:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 100, 31)

	plate.BG5:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -502, 5)
	plate.BG6:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 502, 5)

	plate.POP1:SetPoint('BOTTOMRIGHT', plate, 'BOTTOM', -100, 105)
	plate.POP2:SetPoint('BOTTOMLEFT', plate, 'BOTTOM', 100, 105)

	--Setup the Bottom Artwork
	artFrame:SetFrameStrata('BACKGROUND')
	artFrame:SetFrameLevel(1)
	artFrame:SetSize(2, 2)
	artFrame:SetPoint('BOTTOM', SUI_BottomAnchor)

	artFrame.Center = artFrame:CreateTexture('SUI_Art_Classic_Center', 'BACKGROUND')
	artFrame.Center:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\base-center')
	artFrame.Center:SetPoint('BOTTOM', artFrame, 'BOTTOM')

	artFrame.Left = artFrame:CreateTexture('SUI_Art_Classic_Left', 'BACKGROUND')
	artFrame.Left:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\base-left1')
	artFrame.Left:SetPoint('BOTTOMRIGHT', artFrame.Center, 'BOTTOMLEFT', 0, 0)
	artFrame.FarLeft = artFrame:CreateTexture('SUI_Art_Classic_FarLeft', 'BACKGROUND')
	artFrame.FarLeft:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\base-left2')
	artFrame.FarLeft:SetPoint('BOTTOMRIGHT', artFrame.Left, 'BOTTOMLEFT', 0, 0)
	artFrame.FarLeft:SetPoint('BOTTOMLEFT', SpartanUI, 'BOTTOMLEFT', 0, 0)

	artFrame.Right = artFrame:CreateTexture('SUI_Art_Classic_Right', 'BACKGROUND')
	artFrame.Right:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\base-right1')
	artFrame.Right:SetPoint('BOTTOMLEFT', artFrame.Center, 'BOTTOMRIGHT')
	artFrame.FarRight = artFrame:CreateTexture('SUI_Art_Classic_FarRight', 'BACKGROUND')
	artFrame.FarRight:SetTexture('Interface\\AddOns\\SpartanUI\\Themes\\Classic\\Images\\base-right2')
	artFrame.FarRight:SetPoint('BOTTOMLEFT', artFrame.Right, 'BOTTOMRIGHT')
	artFrame.FarRight:SetPoint('BOTTOMRIGHT', SpartanUI, 'BOTTOMRIGHT')

	if SUI.DB.Artwork.VehicleUI then
		RegisterStateDriver(SUI_Art_Classic, 'visibility', '[petbattle][overridebar][vehicleui] hide; show')
	end

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
					if not MouseIsOver(plate.mask1) and not MouseIsOver(plate.POP1) and SUI.DB.ActionBars['popup1'].anim then -- popup1 animation
						plate.mask1:Show()
					else
						plate.mask1:Hide()
					end
					if not MouseIsOver(plate.mask2) and not MouseIsOver(plate.POP2) and SUI.DB.ActionBars['popup2'].anim then -- popup2 animation
						plate.mask2:Show()
					else
						plate.mask2:Hide()
					end
					self.TimeSinceLastUpdate = 0
				end
			end
		)
	end
end

local function UnitFrameCallback(self, unit)
	if InCombatLockdown() then
		return
	end
	unit = self.unitOnCreate

	local Skined = {['player'] = true, ['target'] = true}
	if not Skined[unit] then
		return
	end

	if not self.Art_Classic then
		local base_ring1 = 'Interface\\AddOns\\SpartanUI\\images\\classic\\base_ring1' -- Player and Target
		local circle = 'Interface\\AddOns\\SpartanUI\\images\\circle'
		local ring = CreateFrame('Frame', nil, self)
		ring:SetFrameStrata('BACKGROUND')
		ring:SetAllPoints(self.Portrait)
		ring:SetFrameLevel(4)

		ring.bg = ring:CreateTexture(nil, 'BACKGROUND')
		ring.bg:SetParent(ring)
		ring.bg:SetTexture(base_ring1)
		if unit == 'target' then
			ring.bg:SetTexCoord(1, 0, 0, 1)
		end

		self.Art_Classic = ring
		SkinnedFrames[unit] = self
	end
	if unit == 'player' then
		--Aiming for a 62x62 Portrait
		self.Portrait:ClearAllPoints()
		self.Portrait:SetPoint('TOPRIGHT', self, 'TOPRIGHT', 72, 15)
		self.Portrait:SetPoint('BOTTOMLEFT', self, 'BOTTOMRIGHT', 10, 0)

		self.Art_Classic.bg:SetPoint('CENTER', self.Art_Classic, 'CENTER', -80, 0)
	elseif unit == 'target' then
		self.Portrait:ClearAllPoints()
		self.Portrait:SetPoint('TOPLEFT', self, 'TOPLEFT', -72, 15)
		self.Portrait:SetPoint('BOTTOMRIGHT', self, 'BOTTOMLEFT', -10, 0)

		self.Art_Classic.bg:SetPoint('CENTER', self.Art_Classic, 'CENTER', 80, 0)
	end
	self:SetFrameLevel(5)
end

function module:OnInitialize()
	local BarHandler = SUI:GetModule('Component_BarHandler')
	BarHandler.BarPosition.BT4.Classic = {
		['BT4Bar1'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-359,82',
		['BT4Bar2'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-359,35',
		--
		['BT4Bar3'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,358,81',
		['BT4Bar4'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,358,35',
		--
		['BT4Bar5'] = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOMLEFT,-5,7',
		['BT4Bar6'] = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOMRIGHT,5,7',
		--
		['BT4BarExtraActionBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,130',
		['BT4BarZoneAbilityBar'] = 'BOTTOM,SUI_BottomAnchor,TOP,0,130',
		--
		['BT4BarStanceBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-240,138',
		['BT4BarPetBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,-570,165',
		--
		['BT4BarMicroMenu'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,297,133',
		['BT4BarBagBar'] = 'BOTTOM,SUI_BottomAnchor,BOTTOM,628,168'
	}
	BarHandler.BarScale.BT4.Classic = {
		['BT4Bar1'] = 0.77,
		['BT4Bar2'] = 0.77,
		['BT4Bar3'] = 0.77,
		['BT4Bar4'] = 0.77,
		['BT4Bar5'] = 0.75,
		['BT4Bar6'] = 0.75,
		['BT4BarBagBar'] = 0.6,
		['BT4BarStanceBar'] = 0.7,
		-- ['BT4BarPetBar'] = 0.7,
		['BT4BarMicroMenu'] = 0.7
	}

	local UnitFrames = SUI:GetModule('Component_UnitFrames')
	UnitFrames.Artwork.Classic = {
		full = {
			perUnit = true,
			UnitFrameCallback = UnitFrameCallback,
			player = {
				path = 'Interface\\AddOns\\SpartanUI\\Images\\Classic\\base_plate1',
				height = 80,
				widthScale = 2.2,
				TexCoord = {0.19140625, 0.810546875, 0.1796875, 0.8203125},
				position = {
					anchor = 'CENTER',
					x = 34,
					y = 7
				}
			},
			target = {
				path = 'Interface\\AddOns\\SpartanUI\\Images\\Classic\\base_plate1',
				height = 80,
				widthScale = 2.2,
				TexCoord = {0.810546875, 0.19140625, 0.1796875, 0.8203125},
				position = {
					anchor = 'CENTER',
					x = -34,
					y = 7
				}
			},
			pet = {
				path = 'Interface\\AddOns\\SpartanUI\\Images\\Classic\\base_2_dual',
				height = 53,
				widthScale = 1.6,
				TexCoord = {0.9453125, .25, 0, 0.78125},
				position = {
					anchor = 'BOTTOMRIGHT',
					x = 10,
					y = -1
				}
			},
			targettarget = {
				path = 'Interface\\AddOns\\SpartanUI\\Images\\Classic\\base_2_dual',
				height = 53,
				widthScale = 1.6,
				TexCoord = {0.25, 0.9453125, 0, 0.78125},
				position = {
					anchor = 'BOTTOMLEFT',
					x = -10,
					y = -1
				}
			}
		}
	}

	UnitFrames.FramePos.Classic = {
		['player'] = 'BOTTOMRIGHT,SUI_BottomAnchor,BOTTOM,-182,160',
		['pet'] = 'BOTTOMRIGHT,SUI_UF_player,BOTTOMLEFT,-50,-4',
		['target'] = 'BOTTOMLEFT,SUI_BottomAnchor,BOTTOM,182,160',
		['targettarget'] = 'BOTTOMLEFT,SUI_UF_target,BOTTOMRIGHT,50,-5'
	}

	CreateArtwork()

	local UF = SUI:GetModule('Component_UnitFrames')
	local function StyleChange()
		for unit, frame in pairs(SkinnedFrames) do
			if UF.DB.Style ~= 'Classic' then
				frame.Art_Classic:Hide()
			elseif UF.DB.Style == 'Classic' and not frame.Art_Classic:IsVisible() then
				frame.Art_Classic:Show()
			end
		end
	end
	SUI.Event:RegisterEvent('UNITFRAME_STYLE_CHANGED', StyleChange)
end

function module:OnEnable()
	if (SUI.DB.Artwork.Style == 'Classic') then
		module:SetupMenus()

		SUI_FramesAnchor:SetFrameStrata('BACKGROUND')
		SUI_FramesAnchor:SetFrameLevel(1)
		SUI_FramesAnchor:ClearAllPoints()
		SUI_FramesAnchor:SetPoint('BOTTOMLEFT', 'Classic_AnchorFrame', 'TOPLEFT', 0, 0)
		SUI_FramesAnchor:SetPoint('TOPRIGHT', 'Classic_AnchorFrame', 'TOPRIGHT', 0, 153)

		hooksecurefunc(
			SUI_Art_Classic,
			'Hide',
			function()
				Artwork_Core:updateViewport()
			end
		)
		hooksecurefunc(
			SUI_Art_Classic,
			'Show',
			function()
				Artwork_Core:updateViewport()
			end
		)

		module:SetupVehicleUI()
		if SUI.DB.Styles.Classic.Color.Art then
			module:SetColor()
		end
	else
		module:Disable()
	end
end

function module:SetupMenus()
	SUI.opt.args['Artwork'].args['ActionBar'] = {
		name = L['ActionBar Settings'],
		type = 'group',
		desc = L['ActionBarConfDesc'],
		args = {
			header1 = {name = '', type = 'header', order = 1.1},
			Allenable = {
				name = L['AllBarEnable'],
				type = 'toggle',
				order = 2,
				get = function(info)
					return SUI.DB.ActionBars.Allenable
				end,
				set = function(info, val)
					SUI.DB.ActionBars.Allenable = val
					for i = 1, 6 do
						SUI.DB.ActionBars['bar' .. i].enable = val
					end
				end
			},
			Allalpha = {
				name = L['AllBarAlpha'],
				type = 'range',
				order = 2.1,
				width = 'double',
				min = 0,
				max = 100,
				step = 1,
				get = function(info)
					return SUI.DB.ActionBars.Allalpha
				end,
				set = function(info, val)
					for i = 1, 6 do
						SUI.DB.ActionBars['bar' .. i].alpha, SUI.DB.ActionBars.Allalpha = val, val
					end
				end
			},
			Bar1 = {
				name = L['Bar'] .. '1',
				type = 'group',
				inline = true,
				args = {
					bar1alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar1.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar1.enable == true then
								SUI.DB.ActionBars.bar1.alpha = val
							end
						end
					},
					bar1enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar1.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar1.enable = val
						end
					}
				}
			},
			Bar2 = {
				name = L['Bar'] .. '2',
				type = 'group',
				inline = true,
				args = {
					bar2alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar2.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar2.enable == true then
								SUI.DB.ActionBars.bar2.alpha = val
							end
						end
					},
					bar2enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar2.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar2.enable = val
						end
					}
				}
			},
			Bar3 = {
				name = L['Bar'] .. '3',
				type = 'group',
				inline = true,
				args = {
					bar3alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar3.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar3.enable == true then
								SUI.DB.ActionBars.bar3.alpha = val
							end
						end
					},
					bar3enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar3.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar3.enable = val
						end
					}
				}
			},
			Bar4 = {
				name = L['Bar'] .. '4',
				type = 'group',
				inline = true,
				args = {
					bar4alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar4.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar4.enable == true then
								SUI.DB.ActionBars.bar4.alpha = val
							end
						end
					},
					bar4enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar4.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar4.enable = val
						end
					}
				}
			},
			Bar5 = {
				name = L['Bar'] .. '5',
				type = 'group',
				inline = true,
				args = {
					bar5alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar5.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar5.enable == true then
								SUI.DB.ActionBars.bar5.alpha = val
							end
						end
					},
					bar5enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar5.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar5.enable = val
						end
					}
				}
			},
			Bar6 = {
				name = L['Bar'] .. '6',
				type = 'group',
				inline = true,
				args = {
					bar6alpha = {
						name = L['Alpha'],
						type = 'range',
						min = 0,
						max = 100,
						step = 1,
						width = 'double',
						get = function(info)
							return SUI.DB.ActionBars.bar6.alpha
						end,
						set = function(info, val)
							if SUI.DB.ActionBars.bar6.enable == true then
								SUI.DB.ActionBars.bar6.alpha = val
							end
						end
					},
					bar6enable = {
						name = L['Enabled'],
						type = 'toggle',
						get = function(info)
							return SUI.DB.ActionBars.bar6.enable
						end,
						set = function(info, val)
							SUI.DB.ActionBars.bar6.enable = val
						end
					}
				}
			}
		}
	}
	SUI.opt.args['Artwork'].args['popup'] = {
		name = L['Popup Animations'],
		type = 'group',
		desc = L['Toggle popup bar animations'],
		args = {
			popup1anim = {
				name = L['Animate left popup'],
				type = 'toggle',
				order = 1,
				width = 'full',
				get = function(info)
					return SUI.DB.ActionBars.popup1.anim
				end,
				set = function(info, val)
					SUI.DB.ActionBars.popup1.anim = val
				end
			},
			popup1alpha = {
				name = L['Alpha left popup'],
				type = 'range',
				order = 2,
				min = 0,
				max = 100,
				step = 1,
				get = function(info)
					return SUI.DB.ActionBars.popup1.alpha
				end,
				set = function(info, val)
					if SUI.DB.ActionBars.popup1.enable == true then
						SUI.DB.ActionBars.popup1.alpha = val
					end
				end
			},
			popup1enable = {
				name = L['Enable left popup'],
				type = 'toggle',
				order = 3,
				get = function(info)
					return SUI.DB.ActionBars.popup1.enable
				end,
				set = function(info, val)
					SUI.DB.ActionBars.popup1.enable = val
				end
			},
			popup2anim = {
				name = L['Animate right popup'],
				type = 'toggle',
				order = 4,
				width = 'full',
				get = function(info)
					return SUI.DB.ActionBars.popup2.anim
				end,
				set = function(info, val)
					SUI.DB.ActionBars.popup2.anim = val
				end
			},
			popup2alpha = {
				name = L['Alpha right popup'],
				type = 'range',
				order = 5,
				min = 0,
				max = 100,
				step = 1,
				get = function(info)
					return SUI.DB.ActionBars.popup2.alpha
				end,
				set = function(info, val)
					if SUI.DB.ActionBars.popup2.enable == true then
						SUI.DB.ActionBars.popup2.alpha = val
					end
				end
			},
			popup2enable = {
				name = L['Enable right popup'],
				type = 'toggle',
				order = 6,
				get = function(info)
					return SUI.DB.ActionBars.popup2.enable
				end,
				set = function(info, val)
					SUI.DB.ActionBars.popup2.enable = val
				end
			}
		}
	}
	SUI.opt.args['Artwork'].args['Artwork'] = {
		name = L['Artwork Options'],
		type = 'group',
		order = 10,
		args = {
			Color = {
				name = L['Artwork Color'],
				type = 'color',
				hasAlpha = true,
				order = .5,
				get = function(info)
					if not SUI.DB.Styles.Classic.Color.Art then
						return {1, 1, 1, 1}
					end
					return unpack(SUI.DB.Styles.Classic.Color.Art)
				end,
				set = function(info, r, b, g, a)
					SUI.DB.Styles.Classic.Color.Art = {r, b, g, a}
					module:SetColor()
				end
			},
			ColorEnabled = {
				name = L['Color enabled'],
				type = 'toggle',
				order = .6,
				get = function(info)
					if SUI.DB.Styles.Classic.Color.Art then
						return true
					else
						return false
					end
				end,
				set = function(info, val)
					if val then
						SUI.DB.Styles.Classic.Color.Art = {1, 1, 1, 1}
						module:SetColor()
					else
						SUI.DB.Styles.Classic.Color.Art = false
						module:SetColor()
					end
				end
			},
			alpha = {
				name = L['Transparency'],
				type = 'range',
				order = 1,
				width = 'full',
				min = 0,
				max = 100,
				step = 1,
				desc = L['XP and Rep Bars are known issues and need a redesign to look right'],
				get = function(info)
					return (SUI.DB.alpha * 100)
				end,
				set = function(info, val)
					SUI.DB.alpha = (val / 100)
					module:updateSpartanAlpha()
					module:AddNotice()
				end
			},
			TransparencyNotice = {
				name = L['TransparencyNotice'],
				order = 1.1,
				type = 'description',
				fontSize = 'small',
				hidden = true
			},
			offset = {
				name = L['Configure Offset'],
				type = 'range',
				width = 'normal',
				order = 3,
				desc = L['Offsets the bottom bar automatically, or set value'],
				min = 0,
				max = 200,
				step = .1,
				get = function(info)
					return SUI.DB.yoffset
				end,
				set = function(info, val)
					if (InCombatLockdown()) then
						SUI:Print(ERR_NOT_IN_COMBAT)
					else
						if SUI.DB.yoffsetAuto then
							SUI:Print(L['Offset is set AUTO'])
						else
							val = tonumber(val)
							SUI.DB.yoffset = val
						end
					end
				end
			},
			offsetauto = {
				name = L['Auto Offset'],
				type = 'toggle',
				desc = L['Offsets the bottom bar automatically'],
				order = 3.1,
				get = function(info)
					return SUI.DB.yoffsetAuto
				end,
				set = function(info, val)
					SUI.DB.yoffsetAuto = val
				end
			}
		}
	}

	if (SUI.DB.alpha ~= 1) then
		module:AddNotice()
	end
end

function module:AddNotice()
	if (SUI.DB.alpha == 1) then
		SUI.opt.args['Artwork'].args['Artwork'].args['TransparencyNotice'].hidden = true
	else
		SUI.opt.args['Artwork'].args['Artwork'].args['TransparencyNotice'].hidden = false
	end
end

function module:OnDisable()
	SUI_Art_Classic:Hide()
	UnregisterStateDriver(SUI_Art_Classic, 'visibility')
end
