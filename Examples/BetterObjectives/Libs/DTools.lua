--[[
	Utils: DTools
	Version: 2.1
	Author: Darcey.Lloyd@gmail.com
	NOTE: To prevent version conflict and cross addon usage issues, rename DTools to DT<AddonName>

	USAGE EXAMPLES:
	-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	-- Create A frame to play with
	local DToolTestFrame = DTools.createTestFrame(400,400,"TOPLEFT",0,0);

	-- List version of DTools you are using
	DTools.version();

	-- Text label
	-- DTools.createText(frame,label,fontSize,justify,x,y,r,g,b,font)
	DTools.createText(DToolTestFrame,"Hello",20,0,0)

	-- Checkbox
	-- function(name,frame,label,x,y,checked,clickHandler,font,fontSize)
	local f1 = function(checked)
		print("f1(checked:" .. boolToString(checked) ..")");
	end
	DTools.createCheckbox("CB1",DToolTestFrame,"Test 1",0,-30,false,f1)

	-- Slider
	-- function(frame,min,max,step,label,default,width,decimalPrecision,x,y,changeHandler,showEditBox)
	local f2 = function(val)
		print("f2(val:" .. val ..")");
	end
	DTools.createSlider(DToolTestFrame,0,1,0.1,"Test 1",0.1,200,1,0,-80,f2,true)

	-- DropDown
	local list = {}; -- WARNING: LUA Tables / Arrays start at index 1
	list[1] = "Option 1";
	list[2] = "Option 2";
	list[3] = "Option 3";
	local selectedIndex = 1;
	local f3 = function(index,value)
		print("f3(index:" .. index ..",value:"..value..")");
	end

	-- function(frame,selectText,list,selectedIndex,width,x,y,onChangeHandler)
	local dp1 = DTools.createDropDown(DToolTestFrame,"You selected: ",list,2,200,0,-120,f3)

	-- Button
	-- createButton(frame,label,width,x,y,clickHandler,fontSize);
	local f4 = function()
		print("f4: Button click registered!");
	end
	local btn1 = DTools.createButton(DToolTestFrame,"CLICK ME",100,0,-160,f4,20);

	-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


--]]




-- ------------------------------------------------------------------------------------------------
-- Global scope function utilities
-- ------------------------------------------------------------------------------------------------
function roundTo(val,decimalPrecision)
	if (val == nil) then
		val = 0;
	end

	local precision = "%.".. decimalPrecision .."f";
	local newVal = string.format(precision, val);
	return newVal;
end
function toFixed(val,decimalPrecision)
	return roundTo(val,decimalPrecision)
end
if (math) then
	math.round = function(val,decimalPrecision)
		return roundTo(val,decimalPrecision)
	end
end

function boolToString(b)
	if (b) then
		return "true";
	else
		return "false";
	end
end

function boolToYesNo(b)
	if (b) then
		return "yes";
	else
		return "no";
	end
end

function boolToNumber(bool)
	if (bool) then
		return 1;
	else
		return 0;
	end
end
function boolToInt(b) return boolToNumber(b); end

function degToRad(deg)
    return deg * (math.pi / 180);
end

function radToDeg(rad)
	return rad * (180 / math.pi)
end
-- ------------------------------------------------------------------------------------------------









-- ------------------------------------------------------------------------------------------------
DTools = {}
DTools.v = "2.0";
DTools.ready = false;
DTools.inCombat = false;
DTools.isInCombat = function() return DTools.inCombat; end -- Getter
DTools.inVehicle = false;
DTools.isInVehicle = function() return DTools.inVehicle; end -- Getter
DTools.version = function() print("DTools v" .. tostring(DTools.v)); end
-- http://wowprogramming.com/docs/widgets/FontInstance/SetFont
DTools.defaultFont = "Fonts\\FRIZQT__.TTF"; -- Fonts\\FRIZQT__.TTF Fonts\\ARIALN.TTF Fonts\\skurri.ttf Fonts\\MORPHEUS.ttf
DTools.defaultFontSize = 12;
-- ------------------------------------------------------------------------------------------------









-- ------------------------------------------------------------------------------------------------
-- Extend the DTools object
-- ------------------------------------------------------------------------------------------------





-- ------------------------------------------------------------------------------------------------
DTools.log = function(arg,color)
	if (not color) then
		color = "ffffff";
	end

	local t = type(arg);

	if (t == "string") then
		print("|cff" .. color .. arg .. "|r");
	elseif (t == "boolean") then
		print("|cff" .. color .. tostring(arg) .. "|r");
	elseif (t == "number") then
		print("|cff" .. color .. tostring(arg) .. "|r");
	elseif (t == "table") then
		print("|cff" .. color .. "TABLE" .. "|r");
	elseif (t == "function") then
		print("|cff" .. color .. "FUNCTION" .. "|r");
	end
end
-- ------------------------------------------------------------------------------------------------



-- ------------------------------------------------------------------------------------------------
DTools.dumpTable = function(t)
	DTools.log("TABLE DUMP:","FFFF00");
	for i, v in ipairs(t) do
		local ty = type(v)
		if (ty == "string" or ty == "number") then
			DTools.log("[" .. i .. "] type[" .. type(v) .. "] = " .. v,"FFCC00")
		elseif (ty == "function" or ty == "table") then
			DTools.log("[" .. i .. "] type[" .. type(v) .. "]","FFCC00")
		elseif (ty == "boolean") then
			DTools.log("[" .. i .. "] type[" .. type(v) .. "] = " .. boolToString(v),"FFCC00")
		end
	end
end
-- ------------------------------------------------------------------------------------------------



-- ------------------------------------------------------------------------------------------------
DTools.createButton = function(frame,label,width,x,y,clickHandler,fontSize,font)
	if ( not font ) then font = DTools.defaultFont; end
	if (font == nil) then font = DTools.defaultFont; end
	if (not fontSize) then fontSize = DTools.defaultFontSize; end
	if (not x) then x = 0; end
	if (not y) then y = 0; end

	local r1 = math.random(0, 999999);
	local frameName = "DToolsBtn" .. r1;
	local btn = CreateFrame("button",frameName, frame, "UIPanelButtonTemplate")
	btn:SetHeight(18)
	btn:SetWidth(width)
	btn:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
	btn:SetText(label)
	-- cfs:SetFont(font, fontSize,"OUTLINE");
	btn:SetScript("OnClick", function()
		--playClick();
		clickHandler();
	end)
	return btn;
end
-- ------------------------------------------------------------------------------------------------








-- ------------------------------------------------------------------------------------------------
DTools.createText = function(frame,label,fontSize,justify,x,y,r,g,b,font)
	if ( not font ) then font = DTools.defaultFont; end
	if (font == nil) then font = DTools.defaultFont; end
	if (not fontSize) then fontSize = DTools.defaultFontSize; end
	if (not x) then x = 0; end
	if (not y) then y = 0; end
	if (not r) then r = 1; end
	if (not g) then g = 1; end
	if (not b) then b = 1; end
	if ( not justify ) then justify = "LEFT"; end

	local cfs = frame:CreateFontString(nil, 'ARTWORK');
	cfs:SetPoint("TOPLEFT",frame,"TOPLEFT", x, y);
    cfs:SetFont(font, fontSize,"OUTLINE");
    cfs:SetShadowOffset(1, -1);
    cfs:SetTextColor(r, g, b);
    cfs:SetNonSpaceWrap(false);
	cfs:SetText(label);
	cfs:SetJustifyH(justify);
    return cfs;
end
-- ------------------------------------------------------------------------------------------------



-- ------------------------------------------------------------------------------------------------
DTools.createCheckbox = function(name,frame,label,x,y,checked,clickHandler,font,fontSize)
	if ( not font ) then font = DTools.defaultFont; end
	if (font == nil) then font = DTools.defaultFont; end

	if ( not fontSize ) then fontSize = DTools.defaultFontSize; end
	if (fontSize == nil) then fontSize = DTools.defaultFontSize; end

	if ( not checked ) then checked = false; end
	if (checked == nil) then checked = false; end

	local checkbox = CreateFrame("CheckButton", name, frame);
	checkbox:SetWidth(22);
	checkbox:SetHeight(24);
	checkbox:SetPoint("TOPLEFT",frame,"TOPLEFT", x, y);
	
	checkbox:SetHitRectInsets(0, -200, 0, 0);
	checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
	checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
	checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
	checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
	
	local description = checkbox:CreateFontString(name.."Label", "ARTWORK", "GameFontHighlight");
	description:SetPoint("LEFT", checkbox, "RIGHT", 1, 1);
	description:SetText(label);
	description:SetTextColor(1,1,1);
	description:SetShadowOffset(1, -1);
	description:SetFont(font, fontSize,"OUTLINE");
	description:SetJustifyH("LEFT");
    local txtW = description:GetStringWidth();
    checkbox:SetHitRectInsets(0, -txtW, 0, 0);
	
	-- Defaults
	checkbox:SetChecked(checked);
	
	if ( clickHandler ) then 
		if (clickHandler ~= nil) then
			checkbox:SetScript("OnClick", function(frame)
				clickHandler(frame:GetChecked());
				checked = frame:GetChecked();
				local tick = frame:GetChecked();
				if tick then
					--playClick();
				else
					--playClick();
				end
			end)
		end
	end

	return checkbox;
	
end
-- ------------------------------------------------------------------------------------------------



-- ------------------------------------------------------------------------------------------------
DTools.createSlider = function(frame,min,max,step,label,default,width,decimalPrecision,x,y,changeHandler,showEditBox,font,fontSize)
	local r1 = math.random(0, 999999);
	if (not min) then min = 0; end
	if (not max) then max = 1; end
	if (not step) then step = 0.1; end
	if (not default) then default = 0; end
	if (not width) then width = 200; end
	if (not decimalPrecision) then decimalPrecision = 1; end
	if (not x) then x = 0; end
	if (not y) then y = 0; end

	if ( not font ) then font = DTools.defaultFont; end
	if (font == nil) then font = DTools.defaultFont; end
	if (not fontSize) then fontSize = DTools.defaultFontSize; end

    local x = x+5;
	
	if (showEditBox == nil) then
		showEditBox = false;
	end
	
	local formattedDefaultValue = string.format("%."..decimalPrecision.."f",default);

	local frameName = "SliderFrame" .. r1;
	
	
	
	-- WARNING: ORDER HERE IS IMPORTANT ON CREATE FRAME (if slider is created 1st then clicks will not register on edit box)
	local slider = CreateFrame("Slider", frameName, frame, "OptionsSliderTemplate");
	slider:ClearAllPoints();
	slider:SetPoint("TOPLEFT", x-5, y);
	slider:SetMinMaxValues(min,max);
	slider:SetValue(default);
    slider:SetOrientation('HORIZONTAL')
    slider:SetWidth(width);
    slider:SetHeight(20);
    slider:SetObeyStepOnDrag(true);
	slider:SetValueStep(step);

	-- Vars
	local sliderLabel = getglobal(slider:GetName() .. 'Text')
	local minLabel = getglobal(frameName .. 'Low');
	local maxLabel = getglobal(frameName .. 'High');

	
	-- Set min max slide labels and positions
	-- print(slider:GetName());
	minLabel:SetText(min);
	minLabel:SetPoint("TOPLEFT", 0, -17);
	maxLabel:SetText(max);
	-- maxLabel:SetPoint("TOPLEFT", 0, -17); -- Already in correct location
	
	-- Set label above slider
	if (label) then
		sliderLabel:SetText(label);
	end

	-- Set fonts and font sizes of min, max and top label
    minLabel:SetFont(font,fontSize-3,"OUTLINE")
    maxLabel:SetFont(font,fontSize-3,"OUTLINE")
    sliderLabel:SetFont(font,fontSize,"OUTLINE")
	
	
	
	-- if (showEditBox == false) then
	-- 	if (label ~= "") then
	-- 		txt:SetText( label .. " " .. string.format("%."..decimalPrecision.."f",default) );
	-- 	else   
	-- 		txt:SetText( string.format("%."..decimalPrecision.."f",default) );
	-- 	end
	-- else 
	-- 	txt:SetText( label );
	-- end
	
	local editBox;
	local editBoxName = "EditBox" .. r1;
	local editBoxWidth = width*0.6;
	
	if (showEditBox == true) then
		-- Setup edit box
		editBox = CreateFrame("EditBox",editBoxName,slider,"InputBoxTemplate");
		editBox:SetWidth(editBoxWidth);
		editBox:SetHeight(14);
		editBox:SetScale(0.6);
		editBox:SetPoint("CENTER", 0,-22);
		editBox:SetMaxLetters(6);
		editBox:SetMultiLine(false);
		editBox:SetAutoFocus(false);
		editBox:SetFont(DTools.defaultFont,12,"NONE");
		-- editBox:SetText("AFTC");
		editBox:ClearFocus();
		editBox:SetText("");
		editBox:SetJustifyH("CENTER");
		editBox:SetText(formattedDefaultValue);
		editBox:HighlightText(0,0); 
		editBox:SetCursorPosition(0);
		editBox:ClearFocus();
		editBox.sliderRef = slider; -- So we can get access to the slider within editbox functions
		
		-- Edit box enter pressed value change
		editBox:SetScript("OnEnterPressed", function(self)
			--playClick();
			self:ClearFocus();
			if (changeHandler) then
				changeHandler(self:GetNumber());
			end
			if (self.sliderRef ~= nil) then
				self.sliderRef:SetValue(self:GetNumber());
			end
		end);
	end

	-- Slider change
	slider:SetScript("OnValueChanged", function(self, value)	
		local formattedValue = string.format("%."..decimalPrecision.."f",value);
		
		if (changeHandler) then
			changeHandler(value);
		end
		
		if (showEditBox == true) then
			editBox:SetText(formattedValue);
			editBox:HighlightText(0,0); 
			editBox:ClearFocus();
			--editBox:SetCursorPosition(0);
		end
	end)

	return slider;
	
end
-- ------------------------------------------------------------------------------------------------



-- ------------------------------------------------------------------------------------------------
-- https://wow.gamepedia.com/Using_UIDropDownMenu
DTools.createDropDown = function(frame,selectText,list,selectedIndex,width,x,y,onChangeHandler)

	-- Attempt to prevent a taint (happens in raid only)
	if (DTools.isInCombat() == false) then

		-- vars
		if (not selectText) then
			selectText = "";
		end
		if (not selectedIndex) then
			selectedIndex = -1;
		end

		local r1 = math.random(0, 999999);
		local frameName = "DropDown" .. r1;
		local selectedLabel = "";

		-- DropDown object
		local dp = {};
		dp.list = list;
		dp.selectedLabel = "";
		dp.selectedIndex = selectedIndex;
		
		-- Create dropdown main frame
		dp.dropDown = CreateFrame("FRAME", frameName, frame, "UIDropDownMenuTemplate")
		dp.dropDown:SetPoint("TOPLEFT",x-15,y)
		dp.dropDown:SetScale(1)
		UIDropDownMenu_SetWidth(dp.dropDown, width-20)
		

		-- Drop down flyout creation
		UIDropDownMenu_Initialize(dp.dropDown, function(self, level, menuList)
			-- NOTE: Opening the drop down actually creates the frame
			for i, label in ipairs(dp.list) do
				-- print ("ADDING: " .. i .. " = " .. label)
				local info = UIDropDownMenu_CreateInfo(); -- Oddly only need 1 info object but adds info each step in loop
				info.text = label;
				info.value = label;
				info.func = self.onClick
				info.arg1 = i
				info.arg2 = label
				UIDropDownMenu_AddButton(info, level)

			end
		end)

		-- Click handler
		dp.dropDown.onClick = function(self, arg1, arg2, checked)
			-- print("index = " .. arg1);
			-- print("value = " .. arg2);
			
			-- Select new index
			dp.selectedIndex = arg1;
			dp.selectedLabel = arg2;
			UIDropDownMenu_SetText(dp.dropDown, selectText .. dp.selectedLabel)

			-- onChangeHandler
			if (onChangeHandler) then
				onChangeHandler(arg1,arg2);
			end
		end

		-- Set selected
		local indexSelected = false;
		for i, label in ipairs(dp.list) do
			if (i == dp.selectedIndex) then
				indexSelected = true;
				dp.selectedLabel = label;
			end
		end

		if (indexSelected == false) then
			-- NOTE: Auto selection of 1st item in array, index 1 (lua index's start at 1)
			print("DTools.createDropDown(): Usage error: Selected index not available!");
			dp.selectedLabel = dp.list[1];
		end

		-- UIDropDownMenu_SetText(dp.dropDown, selectText .. selectedLabel)
		UIDropDownMenu_SetText(dp.dropDown, selectText .. dp.selectedLabel)
		
		return dp
	else
		return nil;
	end

end
-- ------------------------------------------------------------------------------------------------




-- ------------------------------------------------------------------------------------------------
DTools.createAddonMenu = function(addonName,version,author,welcomeFrame)
	-- print("---------------------------");
	local r1 = math.random(0, 999999);

	local DMenu = {};
	DMenu.addonName = addonName;
	DMenu.version = version;
	DMenu.author = author;
	DMenu.welcomeFrame = welcomeFrame;
	DMenu.welcomeFrame.name = addonName;
	InterfaceOptions_AddCategory(DMenu.welcomeFrame);

	DMenu.addPage = function(pageName,pageFrame)
		local error = 0;
		-- if (not pageName) then
		-- 	error = 1;
		-- 	DTools.log("DMenu.addPage(): Usage error: pageName is nil or empty!","FF0000");
		-- end
		-- if (not pageFrame) then
		-- 	error = 1;
		-- 	DTools.log("DMenu.addPage(): Usage error: pageFrame is nil or empty!","FF0000");
		-- end

		if (error == 0) then
			local MyAddon = {};
			-- works
			-- MyAddon.childpanel = CreateFrame( "Frame", "MyAddonChild", MyAddon.panel);
			-- MyAddon.childpanel.name = "MyChild";
			-- MyAddon.childpanel.parent = DMenu.welcomeFrame.name;
			-- InterfaceOptions_AddCategory(MyAddon.childpanel);
			MyAddon.childpanel = pageFrame;
			MyAddon.childpanel.name = pageName;
			MyAddon.childpanel.parent = DMenu.welcomeFrame.name;
			InterfaceOptions_AddCategory(MyAddon.childpanel);
		end
	end

	return DMenu;
end
-- ------------------------------------------------------------------------------------------------





-- ------------------------------------------------------------------------------------------------
DTools.createTestFrame = function(w,h,anchor,x,y)
	local r1 = math.random(0, 999999);
	local frameName = "TestFrame" .. r1;
	local testFrame = CreateFrame("Frame", frameName, UIParent)
	testFrame:SetFrameStrata("low"); -- background, low, medium, high, dialog, fullscreen, tooltip
	testFrame:SetWidth(200)
	testFrame:SetHeight(200)
	testFrame:SetMovable(true);

	testFrame.texture = testFrame:CreateTexture(nil, "BACKGROUND")
	testFrame.texture:SetAllPoints(true)
	testFrame.texture:SetColorTexture(0.0, 0.0, 0.5, 0.5)

	testFrame:ClearAllPoints(true);
	testFrame:SetPoint(anchor,x,y);

	testFrame:EnableMouse(true);
	testFrame:SetClampedToScreen(true);
	testFrame:SetMovable(true);
	testFrame:SetResizable(true);

	testFrame.isMoving = false;

	testFrame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" and not self.isMoving then
			self:StartMoving();
			self.isMoving = true;
		end
	end)

	testFrame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and self.isMoving then
			self:StopMovingOrSizing();
			self.isMoving = false;
		end
	end)

	testFrame:Show();
	return testFrame;
end
-- ------------------------------------------------------------------------------------------------


-- ------------------------------------------------------------------------------------------------
DTools.createTextureFrame = function(parent,texturePath,w,h)
	local r1 = math.random(0, 999999);
	local frameName = "TextureFrame" .. r1;

	local f = CreateFrame("Frame", "DMouseCircleFrame",parent)
    f:SetWidth(w)
    f:SetHeight(h)
    f:EnableMouse(false);

    local tex1 = f:CreateTexture(nil,"BACKGROUND")
    tex1:SetTexture(texturePath)
    tex1:SetAllPoints(f)

    f.texture = tex1
    f:SetPoint("CENTER",0,0)
    f:Show()

    return f;
end
-- ------------------------------------------------------------------------------------------------




-- ------------------------------------------------------------------------------------------------
DTools.setFrameBg = function(frame,r,g,b,a)
	frame.texture = frame:CreateTexture(nil, "BACKGROUND")
	frame.texture:SetAllPoints(true)
	frame.texture:SetColorTexture(r, g, b, a)
end
DTools.setFrameBackground = DTools.setFrameBg;
-- ------------------------------------------------------------------------------------------------




-- ------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------
-- WARNING: Ensure DTools.eventFrame is done last!
-- ------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------
DTools.eventFrame = CreateFrame("Frame")
DTools.eventFrame:SetScript("OnEvent",function(self,event,...)
	if event=="PLAYER_ENTERING_WORLD" then
		-- print("entering the world")
	elseif event=="PLAYER_REGEN_DISABLED" then
		-- print("entering in combat")
		DTools.inCombat = true;
	elseif event=="PLAYER_REGEN_ENABLED" then
		-- print("leaving combat")
		DTools.inCombat = false;
	elseif event=="UNIT_ENTERED_VEHICLE" then
		-- print("VEHICLE ENTERED!");
		DTools.inVehicle = true;
	elseif event=="UNIT_EXITED_VEHICLE" then
		-- print("VEHICLE EXITED!");
		DTools.inVehicle = false;
	elseif event=="VARIABLES_LOADED" then
		-- print("VARIABLES_LOADED!");
		DTools.ready = true;
	end
end)
-- https://wowwiki.fandom.com/wiki/Events_A-Z_(full_list)
DTools.eventFrame:RegisterEvent("VARIABLES_LOADED");
DTools.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
DTools.eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
DTools.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
DTools.eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
DTools.eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
-- ------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------