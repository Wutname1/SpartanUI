local _G, SUI, L = _G, SUI, SUI.L
local module = SUI:NewModule('Module_UnitFrames', 'AceTimer-3.0')
module.DisplayName = L['Unit frames']
local DB = SUI.DB.Unitframes
local loadstring = loadstring
module.frames = {
	arena = {},
	boss = {},
	party = {}
}
----------------------------------------------------------------------------------------------------
-- New Unitframe workflow
--
-- 1.  Styles are initalized and calls AddStyleSettings to pass the styles config into the unitframes module
-- 2.  A table is created with all of the settings from all the styles
-- 3.  UnitFrames OnEnable is called
-- 4.  Frames are spawned
--
-- Player Customization DB format:
-- PlayerCustomizations.STYLE.FRAME
--
-- Styles DB Format
-- Style = {
--		id = 'MYSTYLE', -- One word, used in backend.
-- 		name = 'My Style', -- Human Readable
--		artskin = 'Artwork Skin Name',
--		FrameOptions = { Settings defined here override anything set in the default FrameOptions }
--	}
--
----------------------------------------------------------------------------------------------------
local FrameList = {
	'raid',
	'player',
	'pet',
	'target',
	'targettarget',
	'focus',
	'focustarget'
}
local DefaultSettings = {
	FrameOptions = {
		['**'] = {
			width = 180,
			height = 60,
			moved = false,
			anchor = {
				point = 'BOTTOM',
				relativePoint = 'BOTTOM',
				xOfs = 0,
				yOfs = 0
			},
			elements = {
				['**'] = {
					enabled = false,
					Scale = 1,
					bgTexture = false,
					AllPoints = false,
					points = false,
					alpha = 1
				},
				Health = {
					enabled = true,
					width = 'full',
					height = 60,
					points = {
						{point = 'TOPRIGHT', relativePoint = 'frame'}
					},
					Text = {
						enabled = true,
						Size = 12,
						AllPoints = 'Health'
					}
				},
				Mana = {
					enabled = true,
					width = 'full',
					height = 15,
					points = {
						{point = 'TOPRIGHT', relativeTo = 'BOTTOMRIGHT', relativePoint = 'Health', x = 0, y = 0}
					},
					Text = {
						enabled = true,
						Size = 12,
						AllPoints = 'Mana'
					}
				},
				Castbar = {
					enabled = false,
					width = 'full',
					height = 15,
					points = {
						{point = 'BOTTOMRIGHT', relativePoint = 'Health', relativeTo = 'TOPRIGHT'}
					},
					Text = {
						enabled = true,
						AllPoints = 'Castbar'
					}
				},
				Name = {
					enabled = true,
					height = 12,
					size = 12,
					width = 'full',
					points = {
						{point = 'RIGHT', relativePoint = 'Name', relativeTo = 'LEFT'}
					}
				},
				LeaderIndicator = {
					enabled = true,
					height = 12,
					width = 12,
					points = {
						{point = 'RIGHT', relativePoint = 'Name', relativeTo = 'LEFT'}
					}
				},
				RestingIndicator = {
					enabled = true,
					height = 20,
					width = 20,
					points = {
						{point = 'CENTER', relativePoint = 'frame', relativeTo = 'LEFT'}
					}
				},
				GroupRoleIndicator = {
					enabled = true,
					height = 18,
					width = 18,
					alpha = .75,
					points = {
						{point = 'CENTER', relativePoint = 'frame', relativeTo = 'LEFT'}
					}
				},
				CombatIndicator = {
					enabled = true,
					height = 20,
					width = 20,
					points = {
						{point = 'CENTER', relativePoint = 'GroupRoleIndicator', relativeTo = 'CENTER'}
					}
				},
				RaidTargetIndicator = {
					enabled = true,
					height = 20,
					width = 20,
					points = {
						{point = 'LEFT', relativePoint = 'RestingIndicator', relativeTo = 'RIGHT'}
					}
				},
				SUI_ClassIcon = {
					enabled = true,
					height = 20,
					width = 20,
					points = {
						{point = 'CENTER', relativePoint = 'RestingIndicator', relativeTo = 'CENTER'}
					}
				},
				ReadyCheckIndicator = {
					enabled = true,
					width = 25,
					height = 25,
					points = {
						{point = 'LEFT', relativeTo = 'LEFT'}
					}
				},
				PvPIndicator = {
					width = 25,
					height = 25,
					points = {
						{point = 'CENTER', relativeTo = 'BOTTOMRIGHT'}
					}
				},
				StatusText = {
					size = 22,
					SetJustifyH = 'CENTER',
					SetJustifyV = 'MIDDLE',
					points = {
						{point = 'CENTER', relativeTo = 'CENTER'}
					}
				}
			}
		},
		player = {
			anchor = {
				point = 'BOTTOMRIGHT',
				relativePoint = 'BOTTOM',
				xOfs = -60,
				yOfs = 250
			}
		},
		target = {
			anchor = {
				point = 'BOTTOMLEFT',
				relativePoint = 'BOTTOM',
				xOfs = 60,
				yOfs = 250
			}
		}
	},
	PlayerCustomizations = {
		['**'] = {
			['**'] = {
				elements = {
					['**'] = {}
				}
			}
		}
	},
	Styles = {}
}
local CurrentSettings = {}

function module:AddStyleSettings(settings)
	DB.Styles[style.id] = settings
end

function module:SpawnFrames()
end

function module:UpdatePosition()
end

function module:OnInitalize()
	--First merge in all the default information
	DB = SUI:MergeData(DB, DefaultSettings, false)

	--Ensure the default FrameOptions are proper
	DB.FrameOptions = DefaultSettings.FrameOptions
end

function module:OnEnable()
end

function module:OnEnable()
	module:SpawnFrames()

	-- Add mover to standard frames
	for _, b in pairs(FrameList) do
		if module.frames[b] then
			module:AddMover(module.frames[b], b)
		end
	end

	-- Party, Raid, and boss mover
	if FrameList.arena[1] then
		module:AddMover(FrameList.arena[1], 'arena')
	end
	if FrameList.boss[1] then
		module:AddMover(FrameList.boss[1], 'boss')
	end
	if FrameList.party[1] then
		module:AddMover(FrameList.party[1], 'party')
	end
	-- if FrameList.raid[1] then
	-- 	module:AddMover(frame, 'raid')
	-- end
	

	module:UpdatePosition()
end

function module:AddMover(frame, framename)
	if frame == nil then
		SUI:Err('PlayerFrames', DB.UnitFrames.Style .. ' did not spawn ' .. framename)
	else
		frame.mover = CreateFrame('Frame')
		frame.mover:SetSize(20, 20)

		if framename == 'boss' then
			frame.mover:SetPoint('TOPLEFT', PlayerFrames.boss[1], 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', PlayerFrames.boss[MAX_BOSS_FRAMES], 'BOTTOMRIGHT')
		elseif framename == 'arena' then
			frame.mover:SetPoint('TOPLEFT', PlayerFrames.boss[1], 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', PlayerFrames.boss[MAX_BOSS_FRAMES], 'BOTTOMRIGHT')
		else
			frame.mover:SetPoint('TOPLEFT', frame, 'TOPLEFT')
			frame.mover:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT')
		end

		frame.mover:EnableMouse(true)
		frame.mover:SetFrameStrata('LOW')

		frame:EnableMouse(enable)
		frame:SetScript(
			'OnMouseDown',
			function(self, button)
				if button == 'LeftButton' and IsAltKeyDown() then
					frame.mover:Show()
					DB.UnitFrames[framename].moved = true
					frame:SetMovable(true)
					frame:StartMoving()
				end
			end
		)
		frame:SetScript(
			'OnMouseUp',
			function(self, button)
				frame.mover:Hide()
				frame:StopMovingOrSizing()
				local Anchors = {}
				Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = frame:GetPoint()
				Anchors.relativeTo = 'UIParent'
				for k, v in pairs(Anchors) do
					DB.UnitFrames[framename].Anchors[k] = v
				end
			end
		)

		frame.mover.bg = frame.mover:CreateTexture(nil, 'BACKGROUND')
		frame.mover.bg:SetAllPoints(frame.mover)
		frame.mover.bg:SetTexture('Interface\\BlackMarket\\BlackMarketBackground-Tile')
		frame.mover.bg:SetVertexColor(1, 1, 1, 0.5)

		frame.mover:SetScript(
			'OnEvent',
			function()
				PlayerFrames.locked = 1
				frame.mover:Hide()
			end
		)
		frame.mover:RegisterEvent('VARIABLES_LOADED')
		frame.mover:RegisterEvent('PLAYER_REGEN_DISABLED')
		frame.mover:Hide()

		--Set Position if moved
		if DB.UnitFrames[framename].moved then
			frame:SetMovable(true)
			frame:SetUserPlaced(false)
			local Anchors = {}
			for k, v in pairs(DB.UnitFrames[framename].Anchors) do
				Anchors[k] = v
			end
			frame:ClearAllPoints()
			frame:SetPoint(Anchors.point, UIParent, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
		else
			frame:SetMovable(false)
		end
	end
end
