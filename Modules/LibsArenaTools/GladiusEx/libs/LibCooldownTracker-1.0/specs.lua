local lib, version = LibStub("LibCooldownTracker-1.0")

function lib:GetSpecializationInfoByID(specID)
	local specs = {
		-- rogue
		[259] = {
			name = "Assassination",
			icon = 132292,
		},
		[260] = {
			name = "Combat",
			icon = 132090,
		},
		[261] = {
			name = "Subtlety",
			icon = 132320,
		},
		-- priest
		[256] = {
			name = "Discipline",
			icon = 135987,
		},
		[257] = {
			name = "Holy",
			icon = 135920,
		},
		[258] = {
			name = "Shadow",
			icon = 136207,
		},
		-- druid
		[102] = {
			name = "Balance",
			icon = 136096,
		},
		[103] = {
			name = "Feral",
			icon = 132276,
		},
		[104] = {
			name = "Resto",
			icon = 136041,
		},
		-- warrior
		[71] = {
			name = "Arms",
			icon = 132292,
		},
		[72] = {
			name = "Fury",
			icon = 132347,
		},
		[73] = {
			name = "Protection",
			icon = 132341,
		},
		-- paladin
		[65] = {
			name = "Holy",
			icon = 135920,
		},
		[66] = {
			name = "Protection",
			icon = 135893,
		},
		[70] = {
			name = "Retribution",
			icon = 135873,
		},
		-- hunter
		[253] = {
			name = "Beast Mastery",
			icon = 132164,
		},
		[254] = {
			name = "Marksmanship",
			icon = 132222,
		},
		[255] = {
			name = "Survival",
			icon = 132215,
		},
		-- warlock
		[265] = {
			name = "Affliction",
			icon = 136145,
		},
		[266] = {
			name = "Demonology",
			icon = 136172,
		},
		[267] = {
			name = "Destruction",
			icon = 136186,
		},
		-- mage
		[62] = {
			name = "Arcane",
			icon = 135932,
		},
		[63] = {
			name = "Fire",
			icon = 135810,
		},
		[64] = {
			name = "Frost",
			icon = 135846,
		},
		-- shaman
		[262] = {
			name = "Elemental",
			icon = 136048,
		},
		[263] = {
			name = "Enhancement",
			icon = 136051,
		},
		[264] = {
			name = "Restoration",
			icon = 136052,
		},
		-- evoker
		[1467] = {
			name = "Devastation",
			icon = 4511811
		},
		[1468] = {
			name = "Preservation",
			icon = 4511812
		}
	}
	return specs[specID].name, specs[specID].icon
end