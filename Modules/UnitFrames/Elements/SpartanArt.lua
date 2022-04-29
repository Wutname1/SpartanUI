local UF = SUI.UF
local ArtPositions = {'top', 'bg', 'bottom', 'full'}

local function Build(frame, DB)
	local unitName = frame.unitOnCreate

	local SpartanArt = CreateFrame('Frame', nil, frame)
	SpartanArt:SetFrameStrata('BACKGROUND')
	SpartanArt:SetFrameLevel(2)
	SpartanArt:SetAllPoints()
	SpartanArt.PostUpdate = function(self, unit)
		for _, pos in ipairs(ArtPositions) do
			local ArtSettings = UF.CurrentSettings[unitName].artwork[pos]
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

		self.ArtSettings = UF.CurrentSettings[unitName].artwork
		for _, pos in ipairs(ArtPositions) do
			local ArtSettings = self.ArtSettings[pos]
			if ArtSettings and ArtSettings.enabled and ArtSettings.graphic ~= '' and UF.Artwork[ArtSettings.graphic] then
				self[pos].ArtData = UF.Artwork[ArtSettings.graphic][pos]
				--Grab the settings for the frame specifically if defined (classic skin)
				if self[pos].ArtData.perUnit and self[pos].ArtData[unitName] then
					self[pos].ArtData = self[pos].ArtData[unitName]
				end
			end
		end
	end
	SpartanArt.top = SpartanArt:CreateTexture(nil, 'BORDER')
	SpartanArt.bg = SpartanArt:CreateTexture(nil, 'BACKGROUND')
	SpartanArt.bottom = SpartanArt:CreateTexture(nil, 'BORDER')
	SpartanArt.full = SpartanArt:CreateTexture(nil, 'BACKGROUND')

	frame.SpartanArt = SpartanArt
end

local function Update(frame)
	local DB = frame.SpartanArt.DB
end

local function Options(unit)
end

UF:RegisterElement('SpartanArt', Build, nil, Options)
