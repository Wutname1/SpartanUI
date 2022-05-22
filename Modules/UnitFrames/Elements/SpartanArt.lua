local _G, SUI, L, UF = _G, SUI, SUI.L, SUI.UF
local ArtPositions = {'top', 'bg', 'bottom', 'full'}

local function Build(frame, DB)
	local unitName = frame.unitOnCreate

	local SpartanArt = CreateFrame('Frame', nil, frame)
	SpartanArt:SetFrameStrata('BACKGROUND')
	SpartanArt:SetFrameLevel(2)
	SpartanArt:SetAllPoints()
	SpartanArt.top = SpartanArt:CreateTexture(nil, 'BORDER')
	SpartanArt.bg = SpartanArt:CreateTexture(nil, 'BACKGROUND')
	SpartanArt.bottom = SpartanArt:CreateTexture(nil, 'BORDER')
	SpartanArt.full = SpartanArt:CreateTexture(nil, 'BACKGROUND')
	SpartanArt.ArtSettings = UF.CurrentSettings[unitName].elements.SpartanArt

	SpartanArt.PostUpdate = function(self, unit)
		for _, pos in ipairs(ArtPositions) do
			local ArtSettings = UF.CurrentSettings[unitName].elements.SpartanArt[pos]
			if
				ArtSettings and ArtSettings.enabled and ArtSettings.graphic ~= '' and
					UF.Artwork[ArtSettings.graphic][pos].UnitFrameCallback
			 then
				UF.Artwork[ArtSettings.graphic][pos].UnitFrameCallback(self:GetParent(), unit)
			end
		end
	end
	SpartanArt.PreUpdate = function(self, unit)
		if not unit or unit == 'vehicle' then
			return
		end
		-- Party frame shows 'player' instead of party 1-5
		if not UF.CurrentSettings[unitName] then
			SUI:Error(unitName .. ' - NO SETTINGS FOUND')
			return
		end

		for _, pos in ipairs(ArtPositions) do
			local ArtSettings = UF.CurrentSettings[unitName].elements.SpartanArt[pos]
			if ArtSettings and ArtSettings.enabled and ArtSettings.graphic ~= '' and UF.Artwork[ArtSettings.graphic] then
				self[pos].ArtData = UF.Artwork[ArtSettings.graphic][pos]
				--Grab the settings for the frame specifically if defined (classic skin)
				if self[pos].ArtData.perUnit and self[pos].ArtData[unitName] then
					self[pos].ArtData = self[pos].ArtData[unitName]
				end
			end
		end
	end

	frame.SpartanArt = SpartanArt
end

local function Update(frame)
	frame.SpartanArt:ForceUpdate()
	-- local DB = frame.SpartanArt.DB
end

local function Options(unitName, OptionSet)
	local Positions = {['full'] = 'Full frame skin', ['top'] = 'Top', ['bg'] = 'Background', ['bottom'] = 'Bottom'}
	local function ArtUpdate(pos, option, val)
		--Update memory
		UF.CurrentSettings[unitName].artwork[pos][option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].artwork[pos][option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('SpartanArt')
	end
	SUI.opt.args.UnitFrames.args[unitName].args['artwork'] = {
		name = L['Artwork'],
		type = 'group',
		order = 20,
		args = {}
	}
	local i = 1
	for position, DisplayName in pairs(Positions) do
		SUI.opt.args.UnitFrames.args[unitName].args.artwork.args[position] = {
			name = DisplayName,
			type = 'group',
			order = i,
			disabled = true,
			get = function(info)
				return UF.CurrentSettings[unitName].elements.SpartanArt[position][info[#info]]
			end,
			args = {
				enabled = {
					name = L['Enabled'],
					type = 'toggle',
					order = 1,
					set = function(info, val)
						ArtUpdate(position, 'enabled', val)
					end
				},
				graphic = {
					name = L['Current Style'],
					type = 'select',
					order = 2,
					values = {[''] = 'None'},
					set = function(info, val)
						ArtUpdate(position, 'graphic', val)
					end
				},
				style = {
					name = L['Style'],
					type = 'group',
					order = 3,
					inline = true,
					args = {}
				},
				settings = {
					name = L['Settings'],
					type = 'group',
					inline = true,
					order = 500,
					args = {
						alpha = {
							name = L['Custom alpha'],
							desc = "This setting will override your art's default settings. Set to 0 to disable custom Alpha.",
							type = 'range',
							width = 'double',
							min = 0,
							max = 1,
							step = .01,
							get = function(info)
								return UF.CurrentSettings[unitName].elements.SpartanArt[position].alpha
							end,
							set = function(info, val)
								if val == 0 then
									val = false
								end

								ArtUpdate(position, 'alpha', val)
							end
						}
					}
				}
			}
		}
		i = i + 1
	end

	for Name, data in pairs(UF.Artwork) do
		for position, _ in pairs(Positions) do
			if data[position] then
				local options = SUI.opt.args.UnitFrames.args[unitName].args.artwork.args[position].args
				local dataObj = data[position]
				if dataObj.perUnit and data[unitName] then
					dataObj = data[unitName]
				end

				if dataObj then
					--Enable art option
					SUI.opt.args.UnitFrames.args[unitName].args.artwork.args[position].disabled = false
					--Add to dropdown
					options.graphic.values[Name] = (data.name or Name)
					--Create example
					options.style.args[Name] = {
						name = (data.name or Name),
						width = 'normal',
						type = 'description',
						image = function()
							if type(dataObj.path) == 'function' then
								local path = dataObj.path(nil, position)
								if path then
									return path, (dataObj.exampleWidth or 160), (dataObj.exampleHeight or 40)
								end
							else
								return dataObj.path, (dataObj.exampleWidth or 160), (dataObj.exampleHeight or 40)
							end
						end,
						imageCoords = function()
							if type(dataObj.TexCoord) == 'function' then
								local cords = dataObj.TexCoord(nil, position)
								if cords then
									return cords
								end
							else
								return dataObj.TexCoord
							end
						end
					}
				end
			end
		end
	end
end

UF.Elements:Register('SpartanArt', Build, Update, Options)
