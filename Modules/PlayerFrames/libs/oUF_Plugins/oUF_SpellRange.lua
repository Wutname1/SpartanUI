local parent, ns = ...
local oUF = ns.oUF or oUF

local UpdateRate = 0.1;
local UpdateFrame;
local Objects = {};
local ObjectRanges = {};
local HelpIDs, HelpName; -- Array of possible spell IDs in order of priority, and the name of the highest known priority spell
local HarmIDs, HarmName;
local IsInRange;
do
	local UnitIsConnected = UnitIsConnected;
	local UnitCanAssist = UnitCanAssist;
	local UnitCanAttack = UnitCanAttack;
	local UnitIsUnit = UnitIsUnit;
	local UnitPlayerOrPetInRaid = UnitPlayerOrPetInRaid;
	local UnitIsDead = UnitIsDead;
	local UnitOnTaxi = UnitOnTaxi;
	local UnitInRange = UnitInRange;
	local IsSpellInRange = IsSpellInRange;
	local CheckInteractDistance = CheckInteractDistance;
	function IsInRange ( UnitID )
		if ( UnitIsConnected( UnitID ) ) then
			if ( UnitCanAssist( "player", UnitID ) ) then
				if ( HelpName and not UnitIsDead( UnitID ) ) then
					return IsSpellInRange( HelpName, UnitID ) == 1;
				elseif ( not UnitOnTaxi( "player" ) -- UnitInRange always returns nil while on flightpaths
					and ( UnitIsUnit( UnitID, "player" ) or UnitIsUnit( UnitID, "pet" )
						or UnitPlayerOrPetInParty( UnitID ) or UnitPlayerOrPetInRaid( UnitID ) )
				) then
					return UnitInRange( UnitID ); -- Fast checking for self and party members (38 yd range)
				end
			elseif ( HarmName and not UnitIsDead( UnitID ) and UnitCanAttack( "player", UnitID ) ) then
				return IsSpellInRange( HarmName, UnitID ) == 1;
			end
			return CheckInteractDistance( UnitID, 4 ); -- Follow distance (28 yd range)
		end
	end
end

local function UpdateRange ( self )
	local InRange = not not IsInRange( self.unit ); -- Cast to boolean
	if ( ObjectRanges[ self ] ~= InRange ) then -- Range state changed
		ObjectRanges[ self ] = InRange;

		local SpellRange = self.SpellRange;
		if ( SpellRange.Update ) then
			SpellRange.Update( self, InRange );
		else
			self:SetAlpha( SpellRange[ InRange and "insideAlpha" or "outsideAlpha" ] );
		end
	end
end

local OnUpdate;
do
	local NextUpdate = 0;
	function OnUpdate ( self, Elapsed )
		NextUpdate = NextUpdate - Elapsed;
		if ( NextUpdate <= 0 ) then
			NextUpdate = UpdateRate;

			for Object in pairs( Objects ) do
				if ( Object:IsVisible() ) then
					UpdateRange( Object );
				end
			end
		end
	end
end

local OnSpellsChanged;
do
	local IsSpellKnown = IsSpellKnown;
	local GetSpellInfo = GetSpellInfo;
	local function GetSpellName ( IDs )
		if ( IDs ) then
			for _, ID in ipairs( IDs ) do
				if ( IsSpellKnown( ID ) ) then
					return GetSpellInfo( ID );
				end
			end
		end
	end
	function OnSpellsChanged ()
		HelpName, HarmName = GetSpellName( HelpIDs ), GetSpellName( HarmIDs );
	end
end

local function Update ( self, Event, UnitID )
	if ( Event ~= "OnTargetUpdate" ) then -- OnTargetUpdate is fired on a timer for *target units that don't have real events
		ObjectRanges[ self ] = nil; -- Force update to fire
		UpdateRange( self ); -- Update range immediately
	end
end

local function ForceUpdate ( self )
	return Update( self.__owner, "ForceUpdate", self.__owner.unit );
end

local function Enable ( self, UnitID )
	local SpellRange = self.SpellRange;
	if ( SpellRange ) then
		assert( type( SpellRange ) == "table", "oUF layout addon using invalid SpellRange element." );
		assert( type( SpellRange.Update ) == "function"
			or ( tonumber( SpellRange.insideAlpha ) and tonumber( SpellRange.outsideAlpha ) ),
			"oUF layout addon omitted required SpellRange properties." );
		if ( self.Range ) then -- Disable default range checking
			self:DisableElement( "Range" );
			self.Range = nil; -- Prevent range element from enabling, since enable order isn't stable
		end
		SpellRange.__owner = self;
		SpellRange.ForceUpdate = ForceUpdate;
		if ( not UpdateFrame ) then
			UpdateFrame = CreateFrame( "Frame" );
			UpdateFrame:SetScript( "OnUpdate", OnUpdate );
			UpdateFrame:SetScript( "OnEvent", OnSpellsChanged );
		end
		if ( not next( Objects ) ) then -- First object
			UpdateFrame:Show();
			UpdateFrame:RegisterEvent( "SPELLS_CHANGED" );
			OnSpellsChanged(); -- Recheck spells immediately
		end
		Objects[ self ] = true;
		return true;
	end
end

local function Disable ( self )
	Objects[ self ] = nil;
	ObjectRanges[ self ] = nil;
	if ( not next( Objects ) ) then -- Last object
		UpdateFrame:Hide();
		UpdateFrame:UnregisterEvent( "SPELLS_CHANGED" );
	end
end

HelpIDs = ( {
	DEATHKNIGHT = { 47541 }; -- Death Coil (40yd) - Starter
	DRUID = { 5185 }; -- Healing Touch (40yd) - Lvl 3
	-- HUNTER = {};
	MAGE = { 475 }; -- Remove Curse (40yd) - Lvl 30
	PALADIN = { 85673 }; -- Word of Glory (40yd) - Lvl 9
	PRIEST = { 2061 }; -- Flash Heal (40yd) - Lvl 3
	-- ROGUE = {};
	SHAMAN = { 331 }; -- Healing Wave (40yd) - Lvl 7
	WARLOCK = { 5697 }; -- Unending Breath (30yd) - Lvl 16
	-- WARRIOR = {};
} )[ oUF_Aftermathh.Class ];

HarmIDs = ( {
	DEATHKNIGHT = { 47541 }; -- Death Coil (30yd) - Starter
	DRUID = { 5176 }; -- Wrath (40yd) - Starter
	HUNTER = { 75 }; -- Auto Shot (5-40yd) - Starter
	MAGE = { 133 }; -- Fireball (40yd) - Starter
	PALADIN = {
		62124, -- Hand of Reckoning (30yd) - Lvl 14
		879, -- Exorcism (30yd) - Lvl 18
	};
	PRIEST = { 589 }; -- Shadow Word: Pain (40yd) - Lvl 4
	-- ROGUE = {};
	SHAMAN = { 403 }; -- Lightning Bolt (30yd) - Starter
	WARLOCK = { 686 }; -- Shadow Bolt (40yd) - Starter
	WARRIOR = { 355 }; -- Taunt (30yd) - Lvl 12
} )[ oUF_Aftermathh.Class ];

oUF:AddElement( "SpellRange", Update, Enable, Disable );