local UF = SUI.UF

---@param frame table
local function Build(frame)
	frame.PvPRoleIndicator = frame.raised:CreateTexture(nil, 'BORDER')
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
local function Options(unitName, OptionSet)
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.PvPRoleIndicator[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.PvPRoleIndicator[option] = val
		--Update the screen
		UF.Unit[unitName]:ElementUpdate('PvPRoleIndicator')
	end

	OptionSet.args.visibility = {
		name = 'Role visibility',
		type = 'group',
		inline = true,
		get = function(info)
			return UF.CurrentSettings[unitName].elements.PvPRoleIndicator[info[#info]]
		end,
		set = function(info, val)
			OptUpdate(info[#info], val)
		end,
		args = {
			ShowTank = {
				name = 'Show tank',
				type = 'toggle'
			},
			ShowFriendly = {
				name = 'Show friendly',
				type = 'toggle'
			}
		}
	}
end

---@param previewFrame table
---@param DB table
---@param frameName string
---@return number
local function Preview(previewFrame, DB, frameName)
	if not previewFrame.PvPRoleIndicator then
		previewFrame.PvPRoleIndicator = previewFrame:CreateTexture(nil, 'BORDER')
	end

	local element = previewFrame.PvPRoleIndicator
	element:SetSize(DB.size, DB.size)
	element:SetAlpha(DB.alpha or 0.75)
	element:SetPoint(DB.position.anchor, previewFrame, DB.position.anchor, DB.position.x or 0, DB.position.y or 40)

	-- Show tank icon texture coords as preview
	element:SetAtlas('nameplates-icon-role-tank')
	element:Show()

	return 0
end

---@type SUI.UF.Elements.Settings
local Settings = {
	enabled = true,
	size = 40,
	alpha = 0.75,
	position = {
		anchor = 'TOP',
		relativeTo = 'Frame',
		x = 0,
		y = 40
	},
	config = {
		type = 'Indicator',
		DisplayName = 'PVP Role Indicator'
	},
	showInPreview = false
}

UF.Elements:Register('PvPRoleIndicator', Build, nil, Options, Settings, Preview)
