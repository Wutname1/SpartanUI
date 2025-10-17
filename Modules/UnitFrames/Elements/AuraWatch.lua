local UF = SUI.UF

---@param frame table
---@param DB table
local function Build(frame, DB)
	local element = CreateFrame('Frame', '$parent_AuraWatch', frame)
	element.PostUpdateIcon = function(_, unit, button, index, position, duration, expiration, debuffType, isStealable)
		if not button.spellID then
			return
		end
		local settings = button.setting
		local SpellKnown = C_SpellBook.IsSpellInSpellBook(button.spellID)
		if settings.onlyIfCastable and not SpellKnown then
			button:Hide()
		end
		if InCombatLockdown() and not settings.displayInCombat then
			button:Hide()
		end
	end
	frame.AuraWatch = element
end

---@param frame table
---@param data? table
local function Update(frame, data)
	local element = frame.AuraWatch
	local DB = data or element.DB
	element.size = DB.size or 20
	element.watched = DB.watched
end

---@param unitName string
---@param OptionSet AceConfig.OptionsTable
---@param DB? table
local function Options(unitName, OptionSet, DB)
	local ElementSettings = UF.CurrentSettings[unitName].elements.AuraWatch
	local UserSetting = UF.DB.UserSettings[UF.DB.Style][unitName].elements.AuraWatch

	-- Remove Basic Filters
	OptionSet.args.Filters = nil
	-- Remove Blacklist
	OptionSet.args.whitelist = nil
	OptionSet.args.blacklist = nil
	-- Remove Layout Configuration
	OptionSet.args.Layout = nil
	local buildItemList

	local spellLabel = {
		type = 'description',
		width = 'double',
		fontSize = 'medium',
		order = function(info)
			return tonumber(string.match(info[#info], '(%d+)'))
		end,
		name = function(info)
			local id = tonumber(string.match(info[#info], '(%d+)'))
			local name = 'unknown'
			if id then
				local spellInfo = C_Spell.GetSpellInfo(id)
				if spellInfo then
					name = string.format('|T%s:14:14:0:0|t %s (#%i)', spellInfo.iconID or 'Interface\\Icons\\Inv_misc_questionmark', spellInfo.name or SUI.L['Unknown'], id)
				end
			end
			return name
		end
	}

	local spellDelete = {
		type = 'execute',
		name = SUI.L['Delete'],
		width = 'half',
		order = function(info)
			return tonumber(string.match(info[#info], '(%d+)')) + 0.5
		end,
		func = function(info)
			local id = tonumber(info[#info])

			-- Remove Setting
			ElementSettings.rules[info[#info - 2]][id] = nil
			UserSetting.rules[info[#info - 2]][id] = nil

			-- Update Screen
			buildItemList(info[#info - 2])
			UF.Unit[unitName]:ElementUpdate('AuraWatch')
		end
	}

	buildItemList = function(mode)
		local spellsOpt = OptionSet.args[mode].args.spells.args
		table.wipe(spellsOpt)

		for spellID, _ in pairs(ElementSettings.rules[mode]) do
			spellsOpt[spellID .. 'label'] = spellLabel
			spellsOpt[tostring(spellID)] = spellDelete
		end
	end

	local additem = function(info, input)
		local spellId
		if type(input) == 'string' then
			-- See if we got a spell link
			if input:find('|Hspell:%d+') then
				spellId = tonumber(input:match('|Hspell:(%d+)'))
			elseif input:find('%[(.-)%]') then
				local spellInfo = C_Spell.GetSpellInfo(input:match('%[(.-)%]'))
				spellId = spellInfo and spellInfo.spellID
			else
				local spellInfo = C_Spell.GetSpellInfo(input)
				spellId = spellInfo and spellInfo.spellID
			end
			if not spellId then
				SUI:Print('Invalid spell name or ID')
				return
			end
		end

		ElementSettings.rules[info[#info - 1]][spellId] = true
		UserSetting.rules[info[#info - 1]][spellId] = true

		UF.Unit[unitName]:ElementUpdate('AuraWatch')
		buildItemList(info[#info - 1])
	end

	OptionSet.args.watched = {
		name = 'Tracked Auras',
		type = 'group',
		order = 4,
		args = {
			soon = {
				type = 'description',
				name = 'Options Coming soon, Right now Priest, Mage, and Druid raid buffs tracked by default IF the current character is one of those classes.',
				order = 0.5
			},
			create = {
				name = SUI.L['Add spell name or ID'],
				type = 'input',
				order = 1,
				width = 'full',
				set = additem
			},
			spells = {
				order = 2,
				type = 'group',
				inline = true,
				name = 'Auras list',
				args = {}
			}
		}
	}

	OptionSet.args.watched.args.create.disabled = true
end

---@class SUI.UF.Unit.Settings.AuraWatch.Watched
---@field anyUnit? boolean
---@field onlyShowMissing? boolean
---@field point? string
---@field xOffset? number
---@field yOffset? number
local watched = {}

---@class SUI.UF.Unit.Settings.AuraWatch : SUI.UF.Unit.Settings
---@field watched table<integer, SUI.UF.Unit.Settings.AuraWatch.Watched>
local a = {}

---@class SUI.UF.Unit.Settings.AuraWatch
local Settings = {
	size = 20,
	watched = {
		['**'] = {onlyIfCastable = true, anyUnit = true, onlyShowMissing = true, point = 'BOTTOM', xOffset = 0, yOffset = 0, displayInCombat = false},
		[1126] = {}, -- Mark of the wild
		[1459] = {}, -- Arcane Intellect
		[21562] = {} -- Power Word: Fortitude
	},
	config = {
		type = 'Auras'
	}
}

UF.Elements:Register('AuraWatch', Build, Update, Options, Settings)
