local MINOR = 8
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

local Acquire = CreateUnsecuredObjectPool().Acquire
local function acquire(self, parent)
	local obj, new = Acquire(self)
	obj:SetParent(parent)
	return obj, new
end

local pools = {}
function lib.internal:CreatePool(kind, creationFunc, resetterFunc)
	local pool = CreateUnsecuredObjectPool(creationFunc, resetterFunc)
	pool.Acquire = acquire
	pools[kind] = pool
end

function lib.internal:GetPool(kind)
	return pools[kind]
end

function lib.internal:ReleaseAllPools()
	for _, pool in next, pools do
		pool:ReleaseAll()
	end
end
