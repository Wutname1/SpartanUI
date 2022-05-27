local UF, L = SUI.UF, SUI.L

---@param frame table
---@param DB table
local function Build(frame, DB)
	frame.Range = {
		insideAlpha = DB.insideAlpha,
		outsideAlpha = DB.outsideAlpha
	}
end

---@param frame table
local function Update(frame)
	local DB = UF.CurrentSettings[frame.unitOnCreate].elements.Range
	frame.Range.insideAlpha = DB.insideAlpha
	frame.Range.outsideAlpha = DB.outsideAlpha
end

---@param unitName string
---@param OptionSet AceConfigOptionsTable
local function Options(unitName, OptionSet)
	if unitName == 'player' then
		OptionSet.hidden = true
		return
	end
	local function OptUpdate(option, val)
		--Update memory
		UF.CurrentSettings[unitName].elements.Range[option] = val
		--Update the DB
		UF.DB.UserSettings[UF.DB.Style][unitName].elements.Range[option] = val
		--Update the screen
		UF.frames[unitName]:ElementUpdate('Range')
	end
	--local DB = UF.CurrentSettings[unitName].elements.Range
	SUI.opt.args.UnitFrames.args[unitName].args.indicators.args.Range = {
		name = L['Range'],
		type = 'group',
		get = function(info)
			return UF.CurrentSettings[unitName].elements.Range[info[#info]]
		end,
		set = function(info, val)
			OptUpdate(info[#info], val)
		end,
		args = {
			enabled = {
				name = L['Enabled'],
				type = 'toggle',
				order = 10,
				set = function(info, val)
					--Update memory
					UF.CurrentSettings[unitName].elements.Range.enabled = val
					--Update the DB
					UF.DB.UserSettings[UF.DB.Style][unitName].elements.Range.enabled = val
					--Update the screen
					if val then
						UF.frames[unitName]:EnableElement('Range')
					else
						UF.frames[unitName]:DisableElement('Range')
					end
				end
			},
			insideAlpha = {
				name = L['In range alpha'],
				type = 'range',
				min = 0,
				max = 1,
				step = .1
			},
			outsideAlpha = {
				name = L['Out of range alpha'],
				type = 'range',
				min = 0,
				max = 1,
				step = .1
			}
		}
	}
end

UF.Elements:Register('Range', Build, Update, Options, {NoBulkUpdate = true})
