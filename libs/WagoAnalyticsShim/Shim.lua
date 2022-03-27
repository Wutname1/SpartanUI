local WagoAnalyticsShim = LibStub:NewLibrary("WagoAnalytics", 2)

function WagoAnalyticsShim:Register(wagoID)
	local WagoAnalytics = WagoAnalytics
	if WagoAnalytics then
		return WagoAnalytics:Register(wagoID)
	else
		return setmetatable({}, {
			__index = {
				IncrementCounter = function() end,
				DecrementCounter = function() end,
				SetCounter = function() end,
				Switch = function() end,
				Error = function() end,
				Breadcrumb = function() end
			}
		})
	end
end

function WagoAnalyticsShim:RegisterAddon(addonName)
	local wagoID = GetAddOnMetadata(addonName, "X-Wago-ID")
	if not wagoID then
		return false
	end
	return self:Register(wagoID)
end

WagoAnalyticsShim.RegisterAddOn = WagoAnalyticsShim.RegisterAddon
