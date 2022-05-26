local UF = SUI.UF
local PostCreateAura = UF.PostCreateAura
local PostUpdateAura = UF.PostUpdateAura
local InverseAnchor = UF.InverseAnchor

---@param frame table
---@param DB table
local function Build(frame, DB)
	--Buff Icons
	local Buffs = CreateFrame('Frame', frame.unitOnCreate .. 'Buffs', frame)
	-- Buffs.PostUpdate = PostUpdateAura
	-- Buffs.CustomFilter = customFilter
	frame.Buffs = Buffs
end

---@param frame table
local function Update(frame)
	local DB = frame.Buffs.DB
	if (DB.enabled) then
		frame.Buffs:Show()
	else
		frame.Buffs:Hide()
	end

	local Buffs = frame.Buffs
	Buffs.size = DB.size
	Buffs.initialAnchor = DB.initialAnchor
	Buffs['growth-x'] = DB.growthx
	Buffs['growth-y'] = DB.growthy
	Buffs.spacing = DB.spacing
	Buffs.showType = DB.showType
	Buffs.num = DB.number
	Buffs.onlyShowPlayer = DB.onlyShowPlayer
	Buffs.PostCreateIcon = PostCreateAura
	Buffs.PostUpdateIcon = PostUpdateAura
	Buffs:SetPoint(InverseAnchor(DB.position.anchor), frame, DB.position.anchor, DB.position.x, DB.position.y)
	local w = (DB.number / DB.rows)
	if w < 1.5 then
		w = 1.5
	end
	Buffs:SetSize((DB.size + DB.spacing) * w, (DB.spacing + DB.size) * DB.rows)

	frame:UpdateAllElements('ForceUpdate')
end

---@param frame table
local function UpdateSize(frame)
	if not frame.Buffs then
		return
	end
	local DB = frame.Buffs.DB
	--frame.Buffs:SetSize(DB.size, DB.size)
	--frame.Buffs:SetSize(DB.width, DB.height)
	--frame.Buffs:SetSize(frame:GetWitdth(), DB.height)
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.Buffs[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Buffs[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('Buffs')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Buffs
end

UF.Elements:Register('Buffs', Build, Update, Options)