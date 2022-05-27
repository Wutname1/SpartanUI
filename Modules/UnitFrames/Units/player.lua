local UF = SUI.UF

local function builder(frame)
	local elementDB = frame.elementDB
	for elementName, _ in pairs(UF.Elements.List) do
		if not elementDB[elementName] then
			SUI:Error('MISSING: ' .. elementName .. ' Type:' .. type(elementName))
		else
			UF.Elements:Build(frame, elementName, elementDB[elementName])
		end
	end
end

UF.Frames.Add('player', builder)
