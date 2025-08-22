---@diagnostic disable: duplicate-set-field
--[===[ File: Developer/PluginValidator.lua
LibsDataBar Plugin Validation Framework
Quality scoring and validation for plugin development
--]===]

-- Get the LibsDataBar library
local LibsDataBar = LibStub:GetLibrary('LibsDataBar-1.0')
if not LibsDataBar then return end

---@class PluginValidator
---@field validationRules table<string, function> Validation rules
---@field qualityChecks table<string, function> Quality checks
---@field scores table Plugin quality scores
local PluginValidator = {}
PluginValidator.__index = PluginValidator

-- Initialize Plugin Validator for LibsDataBar
LibsDataBar.validator = LibsDataBar.validator or setmetatable({
	validationRules = {},
	qualityChecks = {},
	scores = {},
}, PluginValidator)

---@class ValidationResult
---@field isValid boolean Whether plugin is valid
---@field score number Quality score (0-100)
---@field errors table<string> Validation errors
---@field warnings table<string> Validation warnings
---@field suggestions table<string> Improvement suggestions
---@field breakdown table<string, number> Score breakdown by category

-- Validation rules for plugins
local VALIDATION_RULES = {
	requiredFields = function(plugin)
		local required = { 'id', 'name', 'version', 'author' }
		local missing = {}

		for _, field in ipairs(required) do
			if not plugin[field] or plugin[field] == '' then table.insert(missing, field) end
		end

		return #missing == 0, missing
	end,

	requiredMethods = function(plugin)
		local required = { 'GetText' }
		local missing = {}

		for _, method in ipairs(required) do
			if not plugin[method] or type(plugin[method]) ~= 'function' then table.insert(missing, method) end
		end

		return #missing == 0, missing
	end,

	validId = function(plugin)
		if not plugin.id then return false, 'Missing ID' end

		-- Check ID format
		if not plugin.id:match('^[%w_]+$') then return false, 'ID contains invalid characters (use only letters, numbers, underscore)' end

		-- Check ID prefix
		if not plugin.id:match('^LibsDataBar_') and plugin.type ~= 'ldb' then return false, "Native plugin ID should start with 'LibsDataBar_'" end

		return true
	end,

	validVersion = function(plugin)
		if not plugin.version then return false, 'Missing version' end

		-- Check semantic versioning format
		if not plugin.version:match('^%d+%.%d+%.%d+') then return false, 'Version should follow semantic versioning (x.y.z)' end

		return true
	end,

	safeFunctions = function(plugin)
		local unsafe = {}

		-- Check GetText function for safety
		if plugin.GetText then
			local success, result = pcall(plugin.GetText, plugin)
			if not success then
				table.insert(unsafe, 'GetText function crashes: ' .. tostring(result))
			elseif type(result) ~= 'string' then
				table.insert(unsafe, 'GetText must return a string')
			end
		end

		return #unsafe == 0, unsafe
	end,
}

-- Quality scoring checks
local QUALITY_CHECKS = {
	documentation = function(plugin)
		local score = 0
		local max = 25

		-- Description quality
		if plugin.description and #plugin.description > 20 then
			score = score + 5
		elseif plugin.description and #plugin.description > 0 then
			score = score + 2
		end

		-- Author information
		if plugin.author and plugin.author ~= '' then score = score + 5 end

		-- Category specified
		if plugin.category and plugin.category ~= '' then score = score + 5 end

		-- Version information
		if plugin.version and plugin.version:match('^%d+%.%d+%.%d+') then score = score + 5 end

		-- Dependencies documented
		if plugin.dependencies and next(plugin.dependencies) then score = score + 5 end

		return math.min(score, max), max
	end,

	functionality = function(plugin)
		local score = 0
		local max = 30

		-- Required methods
		if plugin.GetText and type(plugin.GetText) == 'function' then score = score + 10 end

		-- Optional methods
		local optionalMethods = { 'GetIcon', 'UpdateTooltip', 'OnClick', 'GetConfigOptions' }
		for _, method in ipairs(optionalMethods) do
			if plugin[method] and type(plugin[method]) == 'function' then score = score + 5 end
		end

		return math.min(score, max), max
	end,

	lifecycle = function(plugin)
		local score = 0
		local max = 20

		-- Lifecycle methods
		local lifecycleMethods = { 'OnInitialize', 'OnEnable', 'OnDisable', 'GetDefaultConfig' }
		for _, method in ipairs(lifecycleMethods) do
			if plugin[method] and type(plugin[method]) == 'function' then score = score + 5 end
		end

		return math.min(score, max), max
	end,

	errorHandling = function(plugin)
		local score = 0
		local max = 15

		-- Safe function calls
		if plugin.GetText then
			local success = pcall(plugin.GetText, plugin)
			if success then score = score + 10 end
		end

		-- Configuration handling
		if plugin.GetDefaultConfig then
			local success, result = pcall(plugin.GetDefaultConfig, plugin)
			if success and type(result) == 'table' then score = score + 5 end
		end

		return math.min(score, max), max
	end,

	performance = function(plugin)
		local score = 10 -- Base score
		local max = 10

		-- Performance penalties
		if plugin._updateInterval and plugin._updateInterval < 0.5 then
			score = score - 5 -- Penalty for frequent updates
		end

		-- Check for global variable pollution
		-- This would require more complex analysis

		return math.max(score, 0), max
	end,
}

---Initialize the validator
function PluginValidator:Initialize()
	-- Register validation rules
	for ruleName, ruleFunc in pairs(VALIDATION_RULES) do
		self.validationRules[ruleName] = ruleFunc
	end

	-- Register quality checks
	for checkName, checkFunc in pairs(QUALITY_CHECKS) do
		self.qualityChecks[checkName] = checkFunc
	end

	LibsDataBar:DebugLog('info', 'PluginValidator initialized with ' .. self:GetRuleCount() .. ' rules and ' .. self:GetCheckCount() .. ' quality checks')
end

---Validate a plugin
---@param plugin table Plugin to validate
---@return ValidationResult result Validation result
function PluginValidator:ValidatePlugin(plugin)
	local result = {
		isValid = true,
		score = 0,
		errors = {},
		warnings = {},
		suggestions = {},
		breakdown = {},
	}

	-- Run validation rules
	for ruleName, rule in pairs(self.validationRules) do
		local isValid, details = rule(plugin)
		if not isValid then
			result.isValid = false
			if type(details) == 'table' then
				for _, detail in ipairs(details) do
					table.insert(result.errors, ruleName .. ': ' .. detail)
				end
			else
				table.insert(result.errors, ruleName .. ': ' .. tostring(details))
			end
		end
	end

	-- Run quality checks
	local totalScore = 0
	local maxScore = 0

	for checkName, check in pairs(self.qualityChecks) do
		local score, max = check(plugin)
		totalScore = totalScore + score
		maxScore = maxScore + max
		result.breakdown[checkName] = { score = score, max = max }
	end

	-- Calculate final score
	result.score = maxScore > 0 and math.floor((totalScore / maxScore) * 100) or 0

	-- Generate suggestions based on score breakdown
	self:GenerateSuggestions(result, plugin)

	-- Store score
	if plugin.id then self.scores[plugin.id] = result.score end

	return result
end

---Generate improvement suggestions
---@param result ValidationResult Validation result
---@param plugin table Plugin being validated
function PluginValidator:GenerateSuggestions(result, plugin)
	-- Documentation suggestions
	if result.breakdown.documentation and result.breakdown.documentation.score < 15 then
		table.insert(result.suggestions, 'Add comprehensive description (20+ characters)')
		table.insert(result.suggestions, 'Specify plugin category for better organization')
		table.insert(result.suggestions, 'Document plugin dependencies')
	end

	-- Functionality suggestions
	if result.breakdown.functionality and result.breakdown.functionality.score < 20 then
		if not plugin.GetIcon then table.insert(result.suggestions, 'Add GetIcon() method for visual appeal') end
		if not plugin.UpdateTooltip then table.insert(result.suggestions, 'Add UpdateTooltip() method for better user experience') end
		if not plugin.OnClick then table.insert(result.suggestions, 'Add OnClick() method for interactivity') end
		if not plugin.GetConfigOptions then table.insert(result.suggestions, 'Add GetConfigOptions() method for user customization') end
	end

	-- Lifecycle suggestions
	if result.breakdown.lifecycle and result.breakdown.lifecycle.score < 15 then
		table.insert(result.suggestions, 'Add lifecycle methods (OnInitialize, OnEnable, OnDisable)')
		table.insert(result.suggestions, 'Implement GetDefaultConfig() for proper configuration')
	end

	-- Performance suggestions
	if result.breakdown.performance and result.breakdown.performance.score < 8 then
		table.insert(result.suggestions, 'Consider increasing update interval to reduce CPU usage')
		table.insert(result.suggestions, 'Cache expensive calculations to improve performance')
	end
end

---Get validation report for a plugin
---@param plugin table Plugin to analyze
---@return string report Formatted validation report
function PluginValidator:GetValidationReport(plugin)
	local result = self:ValidatePlugin(plugin)
	local report = {}

	-- Header
	table.insert(report, '=== LibsDataBar Plugin Validation Report ===')
	table.insert(report, 'Plugin: ' .. (plugin.name or 'Unknown'))
	table.insert(report, 'Quality Score: ' .. result.score .. '/100')
	table.insert(report, 'Status: ' .. (result.isValid and 'VALID' or 'INVALID'))
	table.insert(report, '')

	-- Errors
	if #result.errors > 0 then
		table.insert(report, 'ERRORS:')
		for _, error in ipairs(result.errors) do
			table.insert(report, '  ✗ ' .. error)
		end
		table.insert(report, '')
	end

	-- Score breakdown
	table.insert(report, 'SCORE BREAKDOWN:')
	for category, breakdown in pairs(result.breakdown) do
		local percentage = breakdown.max > 0 and math.floor((breakdown.score / breakdown.max) * 100) or 0
		table.insert(report, string.format('  %s: %d/%d (%d%%)', category:gsub('^%l', string.upper), breakdown.score, breakdown.max, percentage))
	end
	table.insert(report, '')

	-- Suggestions
	if #result.suggestions > 0 then
		table.insert(report, 'SUGGESTIONS FOR IMPROVEMENT:')
		for _, suggestion in ipairs(result.suggestions) do
			table.insert(report, '  → ' .. suggestion)
		end
		table.insert(report, '')
	end

	return table.concat(report, '\n')
end

---Get number of validation rules
---@return number count Number of rules
function PluginValidator:GetRuleCount()
	local count = 0
	for _ in pairs(self.validationRules) do
		count = count + 1
	end
	return count
end

---Get number of quality checks
---@return number count Number of checks
function PluginValidator:GetCheckCount()
	local count = 0
	for _ in pairs(self.qualityChecks) do
		count = count + 1
	end
	return count
end

---Get plugin quality score
---@param pluginId string Plugin ID
---@return number? score Quality score or nil if not validated
function PluginValidator:GetPluginScore(pluginId)
	return self.scores[pluginId]
end

---Add custom validation rule
---@param ruleName string Rule name
---@param ruleFunction function Validation function
function PluginValidator:AddValidationRule(ruleName, ruleFunction)
	self.validationRules[ruleName] = ruleFunction
	LibsDataBar:DebugLog('info', 'Added validation rule: ' .. ruleName)
end

---Add custom quality check
---@param checkName string Check name
---@param checkFunction function Quality check function
function PluginValidator:AddQualityCheck(checkName, checkFunction)
	self.qualityChecks[checkName] = checkFunction
	LibsDataBar:DebugLog('info', 'Added quality check: ' .. checkName)
end

-- Initialize the validator when this file loads
if LibsDataBar.validator then LibsDataBar.validator:Initialize() end

LibsDataBar:DebugLog('info', 'PluginValidator loaded successfully')
