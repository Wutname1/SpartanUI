--[[
    Author: darcey.lloyd@gmail.com

    Scale 1: H:100, Top y = 0
    Scale 1: H:100, Btm y = -803.52944
    Scale 0.5: H:100, Top y = 903.5294189
    Scale 0.5: H:100, Btm y = -803.52944
--]]
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #




-- Vars
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
local BetterObjectives = {};
BetterObjectives.name = "BetterObjectives";
BetterObjectives.version = "1.0.1";
BetterObjectives.debug = false;

BetterObjectives.ready = {}
BetterObjectives.ready.variablesLoaded = false;
BetterObjectives.ready.objectiveFrameExists = false;
BetterObjectives.ready.initComplete = false;

BetterObjectives.settingsVisible = false;

BetterObjectives.eventFrame = nil;
BetterObjectives.frame = nil;
BetterObjectives.dragStarted = false;


BetterObjectives.t = 20;
BetterObjectives.updateTickLimit = 10;

BetterObjectives.positionChanged = true;
BetterObjectives.updateCount = 0;
BetterObjectives.updateTryLimit = 10; -- No of times to try and set position of objective frame
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #





-- Libs
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
-- NOTE: These libs rely on quite a lot of includes, see embeds.xml
local addon = LibStub("AceAddon-3.0"):NewAddon(BetterObjectives.name, "AceConsole-3.0")
local icon = LibStub("LibDBIcon-1.0")
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #




-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BetterObjectives.ToggleSettings = function()
    -- Toggles minimap icon
    -- self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    -- if self.db.profile.minimap.hide then
    --     icon:Hide(BetterObjectives.name)
    -- else
    --     icon:Show(BetterObjectives.name)
    -- end

    if (DTools.isInCombat() == true) then
        return
    end

    if (BetterObjectives.ready.initComplete) then
        if (BetterObjectives.settingsVisible == false) then
            BetterObjectives.editFrame:Show();
            BetterObjectives.settingsVisible = true;
        else
            BetterObjectives.editFrame:Hide();
            BetterObjectives.settingsVisible = false;
        end
    end
end
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #






-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BetterObjectives.initPresistentVars = function()

    -- Presistent variables
    if ( not BetterDB ) then 
        BetterDB = {};
    end

    if (BetterDB["hide"] == nil) then
        BetterDB["hide"] = false;
    end

    if (BetterDB["BackgroundAlpha"] == nil) then
        BetterDB["BackgroundAlpha"] = 0.2;
    end


    if (BetterDB["x"] == nil) then
        BetterDB["x"] = 0;
    end

    if (BetterDB["y"] == nil) then
        BetterDB["y"] = 0;
    end

    if (BetterDB["w"] == nil) then
        BetterDB["w"] = 250;
    end

    if (BetterDB["h"] == nil) then
        BetterDB["h"] = 200;
    end

    if (BetterDB["scale"] == nil) then
        BetterDB["scale"] = 0.85;
    end

    if (BetterDB["alpha"] == nil) then
        BetterDB["alpha"] = 0.9;
    end

    if (BetterDB["anchor"] == nil) then
        BetterDB["anchor"] = "TOPLEFT";
    end

    if (BetterDB["bg"] == nil) then
        BetterDB["bg"] = true;
    end
end
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #











-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BetterObjectives.onUpdate = function()
    



    -- 1. We do not init till the objectives frame exists, vars are loaded and ObjectiveTrackerFrame reference is not nil or not
    -- 
    -- if (BetterObjectives.ready.variablesLoaded == true and BetterObjectives.ready.objectiveFrameExists == false) then
    if (ObjectiveTrackerFrame and BetterObjectives.ready.variablesLoaded == true and BetterObjectives.ready.objectiveFrameExists == false) then
        BetterObjectives.ready.objectiveFrameExists = true;
        BetterObjectives.init();
    end



    

    



    -- There's an issue with dragging the frame which causes errors (bad build by bliz)
    -- There's also an issue with setting the position of the frame on addon load, as in it dont move or resize!

    if (BetterObjectives.ready.initComplete == true and BetterObjectives.positionChanged == true) then
        -- Set the position n times
        BetterObjectives.updateCount = BetterObjectives.updateCount + 1;
        -- print("BetterObjectives.updateCount = " .. BetterObjectives.updateCount);

        ObjectiveTrackerFrame:ClearAllPoints()

        if (BetterDB["hide"] == true) then
            ObjectiveTrackerFrame:Hide();
        else
            -- ObjectiveTrackerFrame.ClearAllPoints = function() end
            ObjectiveTrackerFrame:SetPoint("TOPLEFT",BetterDB["x"],BetterDB["y"]);
            ObjectiveTrackerFrame:SetWidth(BetterDB["w"]);
            ObjectiveTrackerFrame:SetHeight(BetterDB["h"]);

            ObjectiveTrackerFrame.texture:SetColorTexture(0.0, 0.0, 0.0, BetterDB["BackgroundAlpha"])
            ObjectiveTrackerFrame:SetAlpha(BetterDB["alpha"])
            ObjectiveTrackerFrame:SetScale(BetterDB["scale"])

            ObjectiveTrackerFrame:Show();
        end

        -- ObjectiveTrackerFrame:SetPoint("TOPLEFT",UIParent,BetterDB["x"],BetterDB["y"]);
        -- ObjectiveTrackerFrame.SetPoint = function() end

        if (BetterObjectives.updateCount >= BetterObjectives.updateTryLimit) then
            BetterObjectives.positionChanged = false
            BetterObjectives.updateCount = 0;
        end
    end


    -- 2. The objectives tracker has a tendancy to move by itself! so we need to poll to update it's x and y but not too often so that it doesn't impact the game
    -- Update frequency
    BetterObjectives.t = BetterObjectives.t + 1;

    if (BetterObjectives.t >= BetterObjectives.updateTickLimit) then
        BetterObjectives.t = 0;
        
        -- Trying to ensure position when character starts moving causes the text inside the objectives tracker to dissapear!
        -- if (ObjectiveTrackerFrame) then
        --     print("PING")
        --     ObjectiveTrackerFrame:SetPoint("TOPLEFT",UIParent,BetterDB["x"],BetterDB["y"]);
        --     ObjectiveTrackerFrame:ClearAllPoints(true)
        -- end
    end

end
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #







-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BetterObjectives.setupEditFrame = function()
    -- Setup edit frame
    BetterObjectives.editFrame = CreateFrame("Frame", "BetterObjectivesEditFrame", UIParent)
    BetterObjectives.editFrame:SetFrameStrata("HIGH");
    --BetterObjectives.editFrame:SetFrameStrata("BACKGROUND")
    BetterObjectives.editFrame:SetWidth(330)
    BetterObjectives.editFrame:SetHeight(380)
    BetterObjectives.editFrame:SetMovable(true);
    BetterObjectives.editFrame:SetScale(0.9)
    DTools.setFrameBackground(BetterObjectives.editFrame,0,0,0,0.75);
    BetterObjectives.editFrame:SetPoint("TOP",0,-20)

    BetterObjectives.editFrame:EnableMouse(true);
    --BetterObjectives.editFrame:SetClampedToScreen(true);
    BetterObjectives.editFrame:SetMovable(true);
    BetterObjectives.editFrame:SetResizable(true);
    
    if (BetterObjectives.debug == true) then
        BetterObjectives.editFrame:Show();
    else
        BetterObjectives.editFrame:Hide();
    end

    BetterObjectives.editFrame.isMoving = false;

    BetterObjectives.editFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and not self.isMoving then
            self:StartMoving();
            self.isMoving = true;
        end
    end)

    BetterObjectives.editFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and self.isMoving then
            self:StopMovingOrSizing();
            self.isMoving = false;
            
            
            print("x:" .. BetterDB["x"] .. "   y:" .. BetterDB["y"] .. "   -   w:" .. BetterDB["w"] .. "   h:" .. BetterDB["h"])
        end
    end)



    local x = 10;
    local y = -10;

    -- Title
    -- DTools.createText(frame,label,fontSize,justify,x,y,r,g,b,font)
    DTools.createText(BetterObjectives.editFrame,"Better Objectives v" .. BetterObjectives.version,20,"left",x,y)
    y = y - 30;


    -- function(name,frame,label,x,y,checked,clickHandler,font,fontSize)
	local cbHideClickHandler = function(checked)
        BetterDB["hide"] = checked;

        if (BetterDB["hide"] == true) then
            ObjectiveTrackerFrame:Hide();
        else 
            ObjectiveTrackerFrame:Show();
        end

        -- BetterObjectives.editFrame:Hide();
        -- BetterObjectives.settingsVisible = false;
	end
    DTools.createCheckbox("cbHideOB",BetterObjectives.editFrame,"Hide Objective Tracker?",x,y,BetterDB["hide"],cbHideClickHandler)
    y = y - 50;


    -- Slider transparency
    -- function(frame,min,max,step,label,default,width,decimalPrecision,x,y,changeHandler,showEditBox)
    local sliderAlphaChangeHandler = function(val)
        BetterDB["alpha"] = val;
        ObjectiveTrackerFrame:SetAlpha(BetterDB["alpha"])
    end
    DTools.createSlider(BetterObjectives.editFrame,0.1,1,0.1,"Transparency",BetterDB["alpha"],310,1,x,y,sliderAlphaChangeHandler,true)
    y = y - 60;



    -- slider bg alpha
    local sliderBgAlphaChangeHandler = function(val)
        BetterDB["BackgroundAlpha"] = val;
        ObjectiveTrackerFrame.texture:SetColorTexture(0.0, 0.0, 0.0, val)
    end
    DTools.createSlider(BetterObjectives.editFrame,0,1,0.01,"Background Transparency",BetterDB["BackgroundAlpha"],310,2,x,y,sliderBgAlphaChangeHandler,true)
    y = y - 60;



    -- Slider width
    -- NOTE: Doesn't actually resize the text inside, must be frames inside frames and unable to get names
    -- local sliderWidthChangeHandler = function(val)
    --     BetterDB["w"] = val;
    --     ObjectiveTrackerFrame:SetWidth(val)
    -- end
    -- DTools.createSlider(BetterObjectives.editFrame,100,2000,1,"Width",BetterDB["w"],310,1,x,y,sliderWidthChangeHandler,true)
    -- y = y - 60;


    -- Slider height
    local sliderHeightChangeHandler = function(val)
        BetterDB["h"] = val;
        ObjectiveTrackerFrame:SetHeight(BetterDB["h"])
    end
    DTools.createSlider(BetterObjectives.editFrame,100,2000,1,"Height",BetterDB["h"],310,1,x,y,sliderHeightChangeHandler,true)
    y = y - 60;


    -- slider scale
    local sliderScaleChangeHandler = function(val)
        BetterDB["scale"] = val;
        ObjectiveTrackerFrame:SetScale(BetterDB["scale"])
    end
    DTools.createSlider(BetterObjectives.editFrame,0.5,1.2,0.01,"Scale",BetterDB["scale"],310,2,x,y,sliderScaleChangeHandler,true)
    y = y - 60;

    
    
    -- -- slider x
    -- local sliderXChangeHandler = function(val)
    --     BetterDB["x"] = val;
    --     -- BetterObjectives.positionChanged = true
    --     -- BetterObjectives.updateCount = 0;
    --     ObjectiveTrackerFrame:SetPoint("BOTTOMLEFT",BetterDB["x"],BetterDB["y"]);
    -- end
    -- DTools.createSlider(BetterObjectives.editFrame,1,3000,0.01,"Position X",BetterDB["x"],310,2,x,y,sliderXChangeHandler,true)
    -- y = y - 60;


    -- -- slider y
    -- local slideYXChangeHandler = function(val)
    --     val = -val;
    --     BetterDB["y"] = val;
    --     -- BetterObjectives.positionChanged = true
    --     -- BetterObjectives.updateCount = 0;
    --     ObjectiveTrackerFrame:SetPoint("BOTTOMLEFT",BetterDB["x"],BetterDB["y"]);
    -- end
    -- DTools.createSlider(BetterObjectives.editFrame,0,3000,0.01,"Position Y",-BetterDB["y"],310,2,x,y,slideYXChangeHandler,true)
    -- y = y - 50;


    -- Button - close
	-- createButton(frame,label,width,x,y,clickHandler,fontSize);
	local btnCloseClickHandler = function()
        BetterObjectives.editFrame:Hide();
        BetterObjectives.settingsVisible = false;
	end
	local btn1 = DTools.createButton(BetterObjectives.editFrame,"CLOSE",100,114,y,btnCloseClickHandler,20);



end
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #





-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BetterObjectives.setupObjectiveTrackerFrame = function()
    ObjectiveTrackerFrame:SetScale(1)
    --ObjectiveTrackerFrame:SetClampedToScreen(true);
    ObjectiveTrackerFrame:EnableMouse(true);
    ObjectiveTrackerFrame:SetResizable(true);
    ObjectiveTrackerFrame:SetMovable(true);
    -- ObjectiveTrackerFrame:ClearAllPoints(true)
    -- ObjectiveTrackerFrame.ClearAllPoints = function() end
    
    -- hooksecurefunc(ObjectiveTrackerFrame,"SetPoint", function(self,anchorPoint,relativeTo,x,y) 
    --         self:SetPoint("TOPLEFT",UIParent,BetterDB["x"],BetterDB["y"])
    --         -- self:SetPoint("TOPLEFT",UIParent,0,0)
    --     end        
    -- );


    ObjectiveTrackerFrame.texture = ObjectiveTrackerFrame:CreateTexture(nil, "BACKGROUND")
    ObjectiveTrackerFrame.texture:SetAllPoints(true)
    ObjectiveTrackerFrame.texture:SetColorTexture(0.0, 0.0, 0.0, BetterDB["BackgroundAlpha"])

    -- WARNING
    -- Most of the Setting wont work, this is hammered into the game in the onUpdate function
    -- ObjectiveTrackerFrame:SetWidth(BetterDB["w"])
    -- ObjectiveTrackerFrame:SetHeight(BetterDB["h"])
    -- ObjectiveTrackerFrame:SetAlpha(BetterDB["alpha"])
    -- ObjectiveTrackerFrame:SetScale(BetterDB["scale"])
    -- ObjectiveTrackerFrame:SetPoint("TOPLEFT",BetterDB["x"],BetterDB["y"]);
    -- ObjectiveTrackerFrame:ClearAllPoints(true)
    -- ObjectiveTrackerFrame:SetPoint("TOPLEFT",UIParent,BetterDB["x"],BetterDB["y"]);
    


    -- Dragging causes taints randomly
    -- -- Drag start
    -- ObjectiveTrackerFrame:RegisterForDrag("LeftButton");
    -- ObjectiveTrackerFrame:SetScript("OnDragStart", function(self)
    --     if (IsShiftKeyDown()) then 
    --         BetterObjectives.dragStarted = true;
    --         self:StartMoving();
    --     end 
    -- end);

    -- -- Drag end
    -- ObjectiveTrackerFrame:SetScript("OnDragStop", function(self)

    --     local screenH = GetScreenHeight();
    --     local oHeight = ObjectiveTrackerFrame:GetHeight()
    --     local h = BetterDB["h"];
    --     local top = ObjectiveTrackerFrame:GetTop();
    --     local scaleMultiplier = 1 + (1 - BetterDB["scale"]);
    --     print("screenH:" .. screenH .. "   oHeight:" .. oHeight .. "   top:" .. top .. "   h:"  .. h .. "   scaleM:" .. scaleMultiplier)       

    --     BetterDB["x"] = ObjectiveTrackerFrame:GetLeft();
    --     BetterDB["y"] = - (screenH - top) -- doesn't handle scale
    --     -- BetterDB["y"] = - ((screenH - top) * scaleMultiplier)

    --     print( "x:" .. BetterDB["x"] .. "   y:" .. BetterDB["y"] )

    --     self:StopMovingOrSizing()
    --     BetterObjectives.dragStarted = false;
    -- end);

end
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #










-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BetterObjectives.init = function()
    -- Init persistent vars
    BetterObjectives.initPresistentVars();

    -- Setup edit / menu frame
    BetterObjectives.setupEditFrame();

    -- Setup / Adjust Objectives Tracker frame
    BetterObjectives.setupObjectiveTrackerFrame();


   
    -- Setup slash commands
    SlashCmdList["BetterObjectivesCOMMAND"] = BetterObjectives.slashCommandHandler;
    SLASH_BetterObjectivesCOMMAND1 = "/bo";
    

    
    -- Welcome message
    if (BetterObjectives.debug) then
        print(" ");
        DTools.log("Better Objectives v" .. BetterObjectives.version .. ": DEBUG MODE!","FF0000");
        print(" ");
    else
        print(" ");
        DTools.log("Better Objectives v" .. BetterObjectives.version .. ": : Type /bo to show/hide menu.","FFFF00");
        print(" ");
    end


    BetterObjectives.init3();

    -- initial state
    BetterObjectives.ready.initComplete = true;
end
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #














-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
BetterObjectives.slashCommandHandler = function(cmd)
    if (BetterObjectives.settingsVisible == false) then
        BetterObjectives.editFrame:Show();
        BetterObjectives.settingsVisible = true;
    else
        BetterObjectives.editFrame:Hide();
        BetterObjectives.settingsVisible = false;
    end
end
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #




BetterObjectives.init3 = function()
    
    -- BetterDB["x"] = 0;
    -- BetterDB["y"] = 0;

    if (ObjectiveTrackerFrame) then
		ObjectiveTrackerFrame:EnableMouse(true);
		ObjectiveTrackerFrame:SetResizable(true);
        ObjectiveTrackerFrame:SetMovable(true);
        ObjectiveTrackerFrame:SetClampedToScreen(true)

        ObjectiveTrackerFrame:ClearAllPoints()
        ObjectiveTrackerFrame.ClearAllPoints = function() end
        ObjectiveTrackerFrame:SetScale(BetterDB["scale"])
        ObjectiveTrackerFrame:SetHeight(BetterDB["h"])
		ObjectiveTrackerFrame:SetPoint("BOTTOMLEFT",BetterDB["x"],BetterDB["y"]);
		ObjectiveTrackerFrame.SetPoint = function() end

		ObjectiveTrackerFrame:RegisterForDrag("LeftButton");
		ObjectiveTrackerFrame:SetScript("OnDragStart", function(self)
            if (IsShiftKeyDown()) then 
                self:StartMoving();
            end 
		end);

		ObjectiveTrackerFrame:SetScript("OnDragStop", function(self)
            BetterDB["x"] = ObjectiveTrackerFrame:GetLeft();
            BetterDB["y"] = ObjectiveTrackerFrame:GetTop()-ObjectiveTrackerFrame:GetHeight();
            self:StopMovingOrSizing()
        end);
        

        if (BetterDB["hide"] == true) then
            ObjectiveTrackerFrame:Hide();
        else 
            ObjectiveTrackerFrame:Show();
        end

    end
end





-- NEW PATH (REMOVE Original Objectives Tracker and make my own)
-- https://wow.gamepedia.com/World_of_Warcraft_API
-- https://wowwiki.fandom.com/wiki/API_GetNumQuestLogEntries
-- https://wowwiki.fandom.com/wiki/API_GetQuestLogTitle
-- https://wow.gamepedia.com/API_GetQuestObjectiveInfo
-- https://wow.gamepedia.com/index.php?title=Category:World_of_Warcraft_API&pagefrom=GetPlayerBuffTimeLeft%0AAPI+GetPlayerBuffTimeLeft#mw-pages
-- IsQuestWatched(questIndex) - Determine if the specified quest is watched.
-- IsWorldQuestHardWatched(questID)
-- IsWorldQuestWatched(questId) - Determine if the world quest id is tracked.

BetterObjectives.init2 = function()
    print("HERE");

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
	testFrame:SetPoint("TOP",0,0);

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
    

    local name, texture, active, category = GetTrackingInfo(1); DEFAULT_CHAT_FRAME:AddMessage(name.." ("..category..")");


    local i = 1
    while GetQuestLogTitle(i) do
        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete,
        frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI,
        isTask, isStory = GetQuestLogTitle(i);
        
        if ( not isHeader ) then
            local info = IsQuestWatched(questID);
            DEFAULT_CHAT_FRAME:AddMessage(title.. " [" .. level .. "] " .. questID)
            print(info)
            -- print(title, level, suggestedGroup, isHeader, isCollapsed, isComplete,
            -- frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI,
            -- isTask, isStory)
        end
        i = i + 1
 end

end







-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
-- BetterObjectives
-- Ensure this is last as certain things will not be ready
-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
-- Event frame
BetterObjectives.eventFrame = CreateFrame("Frame", "BetterObjectives", UIParent)
BetterObjectives.eventFrame:SetFrameStrata("BACKGROUND");
BetterObjectives.eventFrame:RegisterEvent("VARIABLES_LOADED");
BetterObjectives.eventFrame:SetScript("OnEvent", function(self,event,addonName)
    -- print("EVENT = " .. event);
    if (event == "VARIABLES_LOADED") then
        -- BetterObjectives.ready.variablesLoaded = true;
        print("VARIABLES_LOADED");
        BetterObjectives.init();
    end
end);
-- BetterObjectives.eventFrame:SetScript("OnUpdate", BetterObjectives.onUpdate );


-- Setup minimap icon
local BetterObjectivesLDB = LibStub("LibDataBroker-1.1"):NewDataObject(BetterObjectives.name, {
    type = "data source",
    text = BetterObjectives.name,
    --icon = "Interface\\Icons\\INV_Chest_Cloth_17",
    icon = "Interface\\AddOns\\BetterObjectives\\images\\logo.tga";
    OnClick = BetterObjectives.ToggleSettings, -- Ensure function code is before this code
})

function addon:OnInitialize()
    -- Obviously you'll need a ## SavedVariables: BunniesDB line in your TOC, duh!
    self.db = LibStub("AceDB-3.0"):New("BetterObjectivesAceDB", {
        profile = {
            minimap = {
                hide = false,
            },
        },
    })
    -- Setup slash command to hide/show minimap icon
    icon:Register(BetterObjectives.name, BetterObjectivesLDB, self.db.profile.minimap)
    self:RegisterChatCommand("boicon", "ToggleMinimapIcon")
end


-- # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
