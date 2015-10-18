local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local AceHook = LibStub("AceHook-3.0")
local module = spartan:NewModule("Component_Buffs");
----------------------------------------------------------------------------------------------------
local RuleList = {"Rule1", "Rule2", "Rule3"}

function module:OnInitialize()
	if DB.Buffs == nil then
		DB.Buffs = 
		{
			Override = {}
		}
	end
	
	if DB.Buffs.Rule1 == nil then
		for k,v in ipairs(RuleList) do
			DB.Buffs[v] = {
				Status = "Disabled",
				Combat = false,
				OverrideLoc=false,
				Anchor = {onMouse=false,Moved = false,AnchorPos = {}}
				}
		end
		if DB.Buffs.OverrideLoc then
			DB.Buffs.Rule1 = {
				Status = "All",
				Combat = false,
				OverrideLoc=DB.Buffs.OverrideLoc,
				Anchor = {onMouse=DB.Buffs.Anchor.onMouse,Moved = DB.Buffs.Anchor.Moved,AnchorPos = DB.Buffs.Anchor.AnchorPos}
			}
			DB.Buffs.Anchor = nil
		else
			DB.Buffs.Rule1 = {
				Status = "All",
				Combat = false,
				OverrideLoc=false,
				Anchor = {onMouse=false,Moved = false,AnchorPos = {}}
			}
		end
	end
end

function module:OnEnable()
	module:BuildOptions()
	if not DB.EnabledComponents.Buffs then module:HideOptions() return end
	for k,v in ipairs(RuleList) do
		local anchor = CreateFrame("Frame",nil)
		anchor:SetSize(150, 20)
		anchor:EnableMouse(enable)
		anchor.bg = anchor:CreateTexture(nil, "OVERLAY")
		anchor.bg:SetAllPoints(anchor)
		anchor.bg:SetTexture(0,0,0)
		anchor.lbl = anchor:CreateFontString(nil,"OVERLAY", "SUI_Font10")
		anchor.lbl:SetText("Anchor for Rule " .. k);
		anchor.lbl:SetAllPoints(anchor)
		
		anchor:SetScript("OnMouseDown",function(self,button)
			if button == "LeftButton" then
				DB.Buffs[v].Anchor.Moved = true;
				module[v].anchor:SetMovable(true);
				module[v].anchor:StartMoving();
			end
		end);
		
		anchor:SetScript("OnMouseUp",function(self,button)
			module[v].anchor:Hide();
			module[v].anchor:StopMovingOrSizing();
			local Anchors = {}
			Anchors.point, Anchors.relativeTo, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs = module[v].anchor:GetPoint()
			for k,val in pairs(Anchors) do
				DB.Buffs[v].Anchor.AnchorPos[k] = val
			end
		end);
		
		anchor:SetScript("OnShow", function(self)
			if DB.Buffs[v].Anchor.Moved then
				local Anchors = {}
				for key,val in pairs(DB.Buffs[v].Anchor.AnchorPos) do
					Anchors[key] = val
				end
				self:ClearAllPoints();
				self:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
			else
				self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 20)
			end
		end)
		
		anchor:SetScript("OnEvent",function(self, event, ...)
			module[v].anchor:Hide();
		end);
		anchor:RegisterEvent("PLAYER_REGEN_DISABLED");
		
		module[v] = {anchor = anchor}
		module[v].anchor:Hide()
	end
end

local function ActiveRule()
	for k,v in ipairs(RuleList) do
		
		if DB.Buffs[v].Status ~= "Disabled" then
			local CombatRule = false
			if InCombatLockdown() and DB.Buffs[v].Combat then
				CombatRule = true
			elseif not InCombatLockdown() and not DB.Buffs[v].Combat then
				CombatRule = true
			end
			
			if DB.Buffs[v].Status == "Group" and (IsInGroup() and not IsInRaid()) and CombatRule then
				return v
			elseif DB.Buffs[v].Status == "Raid" and IsInRaid() and CombatRule then
				return v
			elseif DB.Buffs[v].Status == "Instance" and IsInInstance() then
				return v
			elseif DB.Buffs[v].Status == "All" and CombatRule then
				return v
			end
		end
	end
	--Failback of Rule1
	if not DB.Buffs.SuppressNoMatch then
		spartan:Print("|cffff0000Error detected")
		spartan:Print("None of your custom Tooltip contidions have been meet. Defaulting to what is specified for Rule 1")
	end
	return "Rule1"
end

local setPoint = function(self, parent)
	if parent then
		if(DB.Buffs[ActiveRule()].Anchor.onMouse) then
			self:SetOwner(parent, "ANCHOR_CURSOR")
			return
		else
			self:SetOwner(parent, "ANCHOR_NONE")
		end
	
		--See If the theme has an anchor and if we are allowed to use it
		if DB.Styles[DBMod.Artwork.Style].TooltipLoc and not DB.Buffs[ActiveRule()].OverrideLoc then
			spartan:GetModule("Style_" .. DBMod.Artwork.Style):TooltipLoc(self, parent);
		else
			self:ClearAllPoints();
			if DB.Buffs[ActiveRule()].Anchor.Moved then
				local Anchors = {}
				for key,val in pairs(DB.Buffs[ActiveRule()].Anchor.AnchorPos) do
					Anchors[key] = val
				end
				-- self:ClearAllPoints();
				if Anchors.point == nil then 
					--Error Catch
					self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 20)
					DB.Buffs[ActiveRule()].Anchor.Moved = false
				else
					self:SetPoint(Anchors.point, nil, Anchors.relativePoint, Anchors.xOfs, Anchors.yOfs)
				end
			else
				self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -20, 20)
			end
		end
	end
end

local OptMode = function(v)
	-- if DB.Tooltips[v].Anchor.onMouse or not DB.Styles[DBMod.Artwork.Style].TooltipLoc then
		-- spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].args["DisplayLocation"..v].args["OverrideTheme"].disabled = true
	-- else
		-- spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].args["DisplayLocation"..v].args["OverrideTheme"].disabled = false
	-- end
	
	-- spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].args["DisplayLocation"..v].args["MoveAnchor"].disabled = DB.Tooltips[v].Anchor.onMouse
	-- spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].args["DisplayLocation"..v].args["ResetAnchor"].disabled = DB.Tooltips[v].Anchor.onMouse
end

function module:BuildOptions()
	spartan.opt.args["General"].args["ModSetting"].args["Buffs"] = {type="group",name="Buffs",
		args = {
		
		}
	}
	
	for k,v in ipairs(RuleList) do
		spartan.opt.args["General"].args["ModSetting"].args["Buffs"].args["DisplayLocation"..v] = {
			name="Display Location " .. v,type="group",inline=true,order=k + 20.1,width="full", args = {
			Condition = {name ="Condition", type="select",order=k + 20.2,
				values = {["Group"]="In a Group",["Raid"]="In a Raid Group",["Instance"]="In a instance",["All"]="All the time",["Disabled"]="Disabled"},
				get = function(info) return DB.Buffs[v].Status; end,
				set = function(info,val) DB.Buffs[v].Status = val;  OptMode(v) end
			},
			Combat = {name="only if in combat",type="toggle",order=k + 20.3,
			get = function(info) return DB.Buffs[v].Combat end,
			set = function(info,val) DB.Buffs[v].Combat = val; end
			},
			OverrideTheme = {name=L["OverrideTheme"],type="toggle",order=k + 20.5,
					get = function(info) return DB.Buffs[v].OverrideLoc end,
					set = function(info,val) DB.Buffs[v].OverrideLoc = val; end
			},
			MoveAnchor = {name="Move anchor",type="execute",order=k + 20.6,width="half",func = function(info,val) module[v].anchor:Show() end},
			ResetAnchor = {name="Reset anchor",type="execute",order=k + 20.7,width="half",func = function(info,val) DB.Buffs[v].Anchor.Moved = false end}
		}
		}
	end
end

function module:HideOptions()
	spartan.opt.args["General"].args["ModSetting"].args["Tooltips"].disabled = true
end