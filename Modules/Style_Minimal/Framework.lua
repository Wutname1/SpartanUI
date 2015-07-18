local spartan = LibStub("AceAddon-3.0"):GetAddon("SpartanUI");
local L = LibStub("AceLocale-3.0"):GetLocale("SpartanUI", true);
local Artwork_Core = spartan:GetModule("Artwork_Core");
local module = spartan:GetModule("Style_Minimal");
----------------------------------------------------------------------------------------------------
local anchor, frame = Minimal_AnchorFrame, Minimal_SpartanUI, CurScale

function module:updateViewport() -- handles viewport offset based on settings
	if not InCombatLockdown() then
		WorldFrame:ClearAllPoints();
		WorldFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0);
		WorldFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0);
	end
end;

function module:updateScale() -- scales SpartanUI based on setting or screen size
	if (not DB.scale) then -- make sure the variable exists, and auto-configured based on screen size
		local width, height = string.match(GetCVar("gxResolution"),"(%d+).-(%d+)");
		if (tonumber(width) / tonumber(height) > 4/3) then DB.scale = 0.92;
		else DB.scale = 0.78; end
	end
	if DB.scale ~= CurScale then
		module:updateViewport();
		if (DB.scale ~= Artwork_Core:round(Minimal_SpartanUI:GetScale())) then
			frame:SetScale(DB.scale);
		end
		
		-- Minimal_SpartanUI_Base3:ClearAllPoints();
		-- Minimal_SpartanUI_Base5:ClearAllPoints();
		-- Minimal_SpartanUI_Base3:SetPoint("RIGHT", Minimal_SpartanUI_Base2, "LEFT");
		-- Minimal_SpartanUI_Base5:SetPoint("LEFT", Minimal_SpartanUI_Base4, "RIGHT");
		
		CurScale = DB.scale
	end
end;

function module:updateOffset() -- handles SpartanUI offset based on setting or fubar / titan
	local fubar,ChocolateBar,titan,offset = 0,0,0;

	if not DB.yoffsetAuto then
		offset = max(DB.yoffset,1);
	else
		for i = 1,4 do -- FuBar Offset
			if (_G["FuBarFrame"..i] and _G["FuBarFrame"..i]:IsVisible()) then
				local bar = _G["FuBarFrame"..i];
				local point = bar:GetPoint(1);
				if point == "BOTTOMLEFT" then fubar = fubar + bar:GetHeight(); end
			end
		end
		for i = 1,100 do -- Chocolate Bar Offset
			if (_G["ChocolateBar"..i] and _G["ChocolateBar"..i]:IsVisible()) then
				local bar = _G["ChocolateBar"..i];
				local point = bar:GetPoint(1);
				--if point == "TOPLEFT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end--top bars
				if point == "RIGHT" then ChocolateBar = ChocolateBar + bar:GetHeight(); 	end-- bottom bars
			end
		end
		TitanBarOrder = {[1]="AuxBar2", [2]="AuxBar"} -- Bottom 2 Bar names
		for i=1,2 do -- Titan Bar Offset
			if (_G["Titan_Bar__Display_"..TitanBarOrder[i]] and TitanPanelGetVar(TitanBarOrder[i].."_Show")) then
				local PanelScale = TitanPanelGetVar("Scale") or 1
				local bar = _G["Titan_Bar__Display_"..TitanBarOrder[i]]
				titan = titan + (PanelScale * bar:GetHeight());
			end
		end
		
		offset = max(fubar + titan + ChocolateBar,1);
	end
	if (Artwork_Core:round(offset) ~= Artwork_Core:round(anchor:GetHeight())) then anchor:SetHeight(offset); end
	DB.yoffset = offset
end;

function module:updateXOffset() -- handles SpartanUI offset based on setting or fubar / titan
	if not DB.xOffset then return 0; end
	local offset = DB.xOffset
	if Artwork_Core:round(offset) <= -300 then
		Minimal_SpartanUI_Base5:ClearAllPoints();
		Minimal_SpartanUI_Base5:SetPoint("LEFT", Minimal_SpartanUI_Base4, "RIGHT");
		Minimal_SpartanUI_Base5:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT");
	elseif Artwork_Core:round(offset) >= 300 then
		Minimal_SpartanUI_Base3:ClearAllPoints();
		Minimal_SpartanUI_Base3:SetPoint("RIGHT", Minimal_SpartanUI_Base2, "LEFT");
		Minimal_SpartanUI_Base3:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT");
	end
	Minimal_SpartanUI:SetPoint("LEFT", Minimal_AnchorFrame, "LEFT", offset, 0)
	if (Artwork_Core:round(offset) ~= Artwork_Core:round(anchor:GetWidth())) then anchor:SetWidth(offset); end
	DB.xOffset = offset
end;

----------------------------------------------------------------------------------------------------

function module:SetColor()
	local r = 0.6156862745098039
	local b = 0.1215686274509804
	local g = 0.1215686274509804
	local a = .9
	
	for i = 1,2 do
		_G["Minimal_Top_Bar" ..i.. "BG"]:SetVertexColor(r,b,g,a)
	end
	for i = 1,5 do
		_G["Minimal_SpartanUI_Base" ..i]:SetVertexColor(r,b,g,a)
	end
	-- Minimal_SpartanUI:SetVertexColor(0,.8,.9,.1)
end

function module:InitFramework()
	do -- default interface modifications
		SUI_FramesAnchor:SetFrameStrata("BACKGROUND");
		SUI_FramesAnchor:SetFrameLevel(1);
		SUI_FramesAnchor:SetParent(Minimal_SpartanUI);
		SUI_FramesAnchor:ClearAllPoints();
		SUI_FramesAnchor:SetPoint("BOTTOMLEFT", "Minimal_AnchorFrame", "TOPLEFT", 0, 0);
		SUI_FramesAnchor:SetPoint("TOPRIGHT", "Minimal_AnchorFrame", "TOPRIGHT", 0, 155);
		
		FramerateLabel:ClearAllPoints();
		FramerateLabel:SetPoint("TOP", "WorldFrame", "TOP", -15, -50);
		
		MainMenuBar:Hide();
		hooksecurefunc(Minimal_SpartanUI,"Hide",function() module:updateViewport(); end);
		hooksecurefunc(Minimal_SpartanUI,"Show",function() module:updateViewport(); end);
		--Minimal_SpartanUI:SetAlpha(.5);
		--Minimal_SpartanUI:SetVertexColor(0,.8,.9,.1)
		
		hooksecurefunc("UpdateContainerFrameAnchors",function() -- fix bag offsets
			local frame, xOffset, yOffset, screenHeight, freeScreenHeight, leftMostPoint, column
			local screenWidth = GetScreenWidth()
			local containerScale = 1
			local leftLimit = 0
			if ( BankFrame:IsShown() ) then
				leftLimit = BankFrame:GetRight() - 25
			end
			while ( containerScale > CONTAINER_SCALE ) do
				screenHeight = GetScreenHeight() / containerScale
				-- Adjust the start anchor for bags depending on the multibars
				xOffset = 1 / containerScale
				yOffset = 155;
				-- freeScreenHeight determines when to start a new column of bags
				freeScreenHeight = screenHeight - yOffset
				leftMostPoint = screenWidth - xOffset
				column = 1
				local frameHeight
				for index, frameName in ipairs(ContainerFrame1.bags) do
					frameHeight = getglobal(frameName):GetHeight()
					if ( freeScreenHeight < frameHeight ) then
						-- Start a new column
						column = column + 1
						leftMostPoint = screenWidth - ( column * CONTAINER_WIDTH * containerScale ) - xOffset
						freeScreenHeight = screenHeight - yOffset
					end
					freeScreenHeight = freeScreenHeight - frameHeight - VISIBLE_CONTAINER_SPACING
				end
				if ( leftMostPoint < leftLimit ) then
					containerScale = containerScale - 0.01
				else
					break
				end
			end
			if ( containerScale < CONTAINER_SCALE ) then
				containerScale = CONTAINER_SCALE
			end
			screenHeight = GetScreenHeight() / containerScale
			-- Adjust the start anchor for bags depending on the multibars
			xOffset = 1 / containerScale
			yOffset = 154
			-- freeScreenHeight determines when to start a new column of bags
			freeScreenHeight = screenHeight - yOffset
			column = 0
			for index, frameName in ipairs(ContainerFrame1.bags) do
				frame = getglobal(frameName)
				frame:SetScale(containerScale)
				if ( index == 1 ) then
					-- First bag
					frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -xOffset, (yOffset + (DB.yoffset or 1)) * (DB.scale or 1) )
				elseif ( freeScreenHeight < frame:GetHeight() ) then
					-- Start a new column
					column = column + 1
					freeScreenHeight = screenHeight - yOffset
					frame:SetPoint("BOTTOMRIGHT", frame:GetParent(), "BOTTOMRIGHT", -(column * CONTAINER_WIDTH) - xOffset, yOffset )
				else
					-- Anchor to the previous bag
					frame:SetPoint("BOTTOMRIGHT", ContainerFrame1.bags[index - 1], "TOPRIGHT", 0, CONTAINER_SPACING)
				end
				freeScreenHeight = freeScreenHeight - frame:GetHeight() - VISIBLE_CONTAINER_SPACING
			end
		end);
		hooksecurefunc(GameTooltip,"SetPoint",function(tooltip,point,parent,rpoint) -- fix GameTooltip offset
			if (point == "BOTTOMRIGHT" and parent == "UIParent" and rpoint == "BOTTOMRIGHT") then
				tooltip:ClearAllPoints();
				tooltip:SetPoint("BOTTOMRIGHT",Minimal_SpartanUI,"BOTTOMRIGHT",-20,20);
			end
		end);
	end
end

function module:SetupVehicleUI()
	if DBMod.Artwork.VehicleUI thenö´#éâ°çÆÃÇdét¢P   [o9ÑÌ—õ÷ß İÆŒ¼Bu	   ÷
Ã¤áe43†ÆĞ‹?ÆüÂ   +9ˆ‚„~¤mı6¾Aä›­½_   ÑBï•İöÑînôñõ×µyèõ   -Rø¶M˜æùlBÜã4ç   Ø^»iUÿ±¤$RKâu®   Œ?Ï×=º#yâoçâ}ú    d¬¶³s¥#ô5P÷áe„   ZŞ«Ú}CÔIÀ³§Túæ€
  %Ç@’¹­\™ÜŸpö=  ‘éµ´q¡›°Ø„yŸyÉ×   QkpÉÈ$@JA{j ¢p³p   êKLíâÜd¥9 ®Ù§fL   )ç¹ç¼­*Úò¹.‡¤ °–'ad   Y?°¢Äe«"v— Ğ|Œ^‚  Â¢q¨Å«lÆëËÖ¡‡7×±   ^İ¦¹q°’ŠŒÿ¤q¡?)Š)   seİªÍˆë«Ì¡šrŠ8  "Â‹ÇeuìÁQjïÜ¡¢}2š   =°²¡¥]ÔÉs7«·¢"Š;`          ÉõÔàÙï÷eĞnÃ£`ù9À  ‚ù¾iš7ëWŠí¤˜-G{  Ì…»I”R;A€¤µ
øÑ   ğPG‡„‰Ä“n ¹¤ºcøñ    c\`ég½s{êÂ-¤àÁ)/­   =âË‰mğˆŒ0Ãgš‹¤ä®©âß  AQœ‰iŒk®Ã~¤ë´Qî   nÖ®Yá©)à´¶a¤óNÿ…Z   ÕŞ“ÍÇeÙ6à/éô¥z4ß  (¿}˜µ¿_¤Gk]Ì¥ş:Ú    ­ZéòfÛÇZ÷ß¥¨·i   ‰oªó¡lé‹úV¥•,’=Ñ   IaSëá*ŠmÆĞ&;¥ÅNm   ¾(ƒÒ`1²İÂ›1w¥Æ¼›m   5ë­ÄÏ—=D­¥ó/½/   /=OœëîÏƒ_´ş4Ş¦0«8ï  ÀPí+©E ‹Ê¦7Tú   º –Õô]5Ö	Î	¦K–L$   /­ÏG[ú­(?'`¦k S#:   _œ‰¤"Ï¨ŸÇ„’¦¯X¯òú  TŒ	¤ø|DA0epb¦ËÁUg4           ‘6bêRV,C+“8Ù§5¦Ï  è‚¹v1Ó¬—÷í§>tœ¯  ¼®MKSÓ„ûZ
§¨,Zúb  ZØ5Ñœİræ¤0§´×òœ   =Ãk±ºo[1-GQİ§Õvî‡;  ÒhÙ—ïækPzıÃ¨&™K%š  ewOÍ%’¾öÒŒ„¨1^>f   ŠØê¾Ñ÷©EBŠäµ¨Z‚¦ğ   šç6Ê6ß—SüWî¨d<+¼U   ³É—zÄ1Ç£_xt¨o¶/   i?D¢ı×ÔÖ<¨oy¶'   	à¬ÿ˜İLÜ…Á›¨cæiı   mÙÏÄpÊéUü‘ê•¨©óBQ   B7öÙw@ß,¢¬Ùë×¨²^<a7    ?¢MˆwÛ¨²•(T   ù<€ÔË„mí}¨¿Ì¤Ş%   ¾iŞ¥c·G—@e0a¨ÁR@à5   #„/ÎìÂÒïÅé¨Å™kªA   çô>T£…ºë{a¨Ê9È   †İ}Á1şI'Ì‚«A¨××Í9   ]òãó1ó/g#ÜH‹©&”g=F           Jh¨µIÃW Í¶Ç[©-Ol   ?óúñÓwT(2PEö©-tcp)   BªÑçÀåŞHØRr©.1ÛV1   VR/Ÿµà•wLU4Ú¿Õ)"Îc  1ı¶x¬Ök¨ñ¿Ü¹²*  C[ÿÓzİøĞ¤üR³¿óª)ÿ¸   z€¡ÆŒé+ºU¿÷
ûw  Y«7ævÖešÇmÌX¿úbŒrÎ   vÊchNkåå°¿û0şA„   ‹ÕĞ¼² ¤…Ø¨bÃ¾šCË  ²”£÷çGãgf}×tÔiğF   ê	é~ì¥^o›XÆ[Ôk—KT   Â‡A®®c?XRvEãøÔ}_°È6  ¯7ÊÑLÀÑôåCÔ€_Äy   ÆZûº.‚Œ­s²$¦ÔƒÄœSM   ¥ƒYÅªI0Ùµ×§?Ô‹â%ïn   ~ŒÒX
ÈÚ«´EWÔÑŸí>   ™Ü¬ãa$.Ç¿Ÿ8òiÕ`í  j…«2k%Û'áÕ:i‹ˆ   :3„ıyÈ°¦¬6ÕW4ù|A   Ê“´‘Wİ+ú.HVpÕbÍi¿,           tJ°86qÅügÕek3   \	ô¾\`\ùÆ@KÕh!Úm   'û›ûg‰gşŞÛ7Õi…t   áSm¯.À³Üé_ñÕjİßC   Rò“lóˆ7ÜÔŒÔÕo¡2š     jƒÛ3ãe¤“vÕpÜ$   PÔîÉ’8˜#ÎŒv-ÕTïŠF   q¸¿ vq{Â`«ÜÓÕ‘bâp7   ï{ş¾`ScêğeL·Õ‘ìÔ>   Ú¼ZÁª¯»÷$¡|æ,Õ’JíŒ   ­×ô™YGy*ÃCwy¨ÕšDŠL   yA•àˆ‰i‰FoÕThK{   «¦iÁÀ†…½jˆÕ¥Å¢   °ğıãş7~pÚŞÕ¦ !   9×h‹—›Q÷ILõåÕ¦ÚvæU   Ì’ƒ«Te3ó¨¤Õ»{C8,   ˆ‹›Âæ9œQŒ@cÕ¾I5   >¨±œÕN‘Ñh7ÕŞË±ş  â­ƒœØˆn§Ö,Ë(ĞÅ  ‡W—+B™ÒjäŠ=Ö‚Å²5:   N y¼úğE•`Æ	8ÖÜrP3ÿ          şÀ4·Úóí¾©ªm*ª×/F€¨,   Æ]·„õÆGKóAÒ×RA_0   Š3˜SØs^Š:)øŸ×R’€0   ë´ÁÃ0CşáÂWa]ê×WäÉL0   î®Ù¸™2QZXL8¹×v ^Çë  p‡Ò½ØğŒ}Ó‡×ºı^ŞO   ¬æç®ãÂ™vB„;l×¿@[‰Ü   óOröºoÍ»¦éğ8|Ø&^!   Î¹­‘~f@+;R™Ø*JzMd   áëõ´’ø>xÇ.Ø,(bÜ(   ƒXÁy¸(\Ä–×Ø.bZ  µ&ù›Lmñhj¤ØE´à:   [çFÖ€^W†ØUûN·}  ß•ò¯t¬yš§uØ×úØe˜ ¼   =€4ÀÂ¥œğ!w«ØfU/#   ÑãZ–œµmŞ$¸Øï-Øˆ²ˆÁl   §Åô¯Vgb*½¡¯[Øÿ×0{Ï  Ó…¤¦-çÇ*Æ£ÙvÙàDå˜W  šÚ©jfÔ'h¿ÓcÙúto~  MS8Ï»Üµ§#N†ÚŞšœ   r fƒ…•Ç03î#ÚuF_Ø            2ÏÅ“7X·ÖD:Ú‚ÿc   YdH»Ù/§!ƒd¤QMÚ„SæeJ   èÓ£ƒçV\QlÚ„K˜I   ½KäØ\¿oV“-e³Ú‹˜÷‘H   5PŒ`¯y¥g*$ÚmK l   |­š
—ØlÊÏèÚ“œ®06   Ì´ÄÕ	 pÀtÉÚ”)za%   IYD€+÷İ&«î§ë2Ú”s.   Wòõ»E‚×7´˜¯­sÚ•Ÿö$   S"S÷~©»ôH›ãÏÀÚ˜¾   §IV™u=¤Ã=Q–Ú›K‘/   itL§b°I*ÁA}±ğÚ£ gæ%   ?ü)QD•´$a%CÚ¦¼“±ê   ×Z—Â&6üİ}Ú«:
Y   Æ #ÌÇ)øíáª~Â#Ú´Ad§w   B†»Í÷nm—Ü<7íÚµ×³±5   K€+¼£¢_Ã‚à
%3Ú·´X¬c   «[J½áL¸œO.Y@üÚ¸Ÿ{#   Ö8ŞúÉ¼%§Æ³Ø¤Ú»4ö5   5r‹…mÙ>5,uAÚÔ25 W   ”½Ò5ª¿$İ˜`Œ×ÚÕÅ8ğš           ˆîú½Ô	Ö’­ñ¬ÚñÊ£E	   ˆİ­è¿/æ-h‹›b*Úıñtë:   ø«q±¢Dí¡
;:(ÛK‰·-   0¯Ô„··[yKQgÛ$Ä`…w   ²‚ÿ˜tº ú°ÔökÛ&½+Ä<   ·ìÍ¶jø”ÒÄAxƒÛuı¨B   NóA„0>™;JÑ?ºêÛy/   °.æ¹ƒ  ohPíÛ{:1°g   ¦ï9¬ ‡{/aÎŞ¦Û’*—ZE   ŠÓºU¥[yKzÂ}Û•¡#F   8±‡W%}y/2à4ÛšvF@   ®äƒï¶®;;ÍÍ=åÛœj8À   Ê»ÿs¬Íô[ƒ¯ÛœÜ¢e   İ¬¢—›;Q:ÎØ6„Û¡§åM   fñÎşÈÓ