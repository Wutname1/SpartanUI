local MINOR = 2
local lib, minor = LibStub('LibEditMode')
if minor > MINOR then
	return
end

-- fork of ObjectPoolMixin to support passing through parent
local poolMixin = CreateFromMixins(ObjectPoolMixin)
function poolMixin:Acquire(parent)
	local numInactiveObjects = #self.inactiveObjects
	if numInactiveObjects > 0 then
		local obj = self.inactiveObjects[numInactiveObjects]
		self.activeObjects[obj] = true
		self.numActiveObjects = self.numActiveObjects + 1
		self.inactiveObjects[numInactiveObjects] = nil
		return obj, false
	end

	local newObj = self.creationFunc(self)
	if self.resetterFunc and not self.disallowResetIfNew then
		self.resetterFunc(self, newObj)
	end

	self.activeObjects[newObj] = true
	self.numActiveObjects = self.numActiveObjects + 1

	newObj:SetParent(parent)

	return newObj, true
end

local pools = {}
function lib.internal:CreatePool(kind, creationFunc, resetterFunc)
	-- wrapper for ObjectPoolMixin
	local pool = CreateFromMixins(poolMixin)
	pool:OnLoad(creationFunc, resetterFunc)

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
