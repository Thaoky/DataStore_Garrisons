if not DataStore then return end

local addonName, addon = ...

function addon:SetupOptions()
	local f = DataStore.Frames.GarrisonsOptions
	
	DataStore:AddOptionCategory(f, addonName, "DataStore")

	-- localize options
	local L = AddonFactory:GetLocale(addonName)
	
	DataStoreGarrisonsOptions_SliderReportLevel.tooltipText = L["REPORT_LEVEL_TOOLTIP"]
	DataStoreGarrisonsOptions_SliderReportLevelLow:SetText("350")
	DataStoreGarrisonsOptions_SliderReportLevelHigh:SetText("975")
	
	-- restore saved options to gui
	local options = DataStore_Garrisons_Options
	local level = options.ReportLevel
	
	DataStoreGarrisonsOptions_SliderReportLevel:SetValue(level)
	DataStoreGarrisonsOptions_SliderReportLevelText:SetText(format(L["REPORT_LEVEL_LABEL"], "|cFF00FF00", level))
	f.ReportUncollected:SetChecked(options.ReportUncollected)
end
