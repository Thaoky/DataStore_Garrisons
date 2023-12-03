local L = LibStub("AceLocale-3.0"):NewLocale("DataStore_Garrisons", "enUS", true, true)

if not L then return end

L["UNCOLLECTED_RESOURCES_ALERT"] = "%s has %s uncollected resources"	
L["REPORT_UNCOLLECTED_LABEL"] = "Report uncollected resources"	
L["REPORT_UNCOLLECTED_DISABLED"] = "Nothing will be reported."
L["REPORT_UNCOLLECTED_ENABLED"] = "At logon, alts with more than 400 uncollected resources will be reported to the chat frame."
L["REPORT_UNCOLLECTED_TITLE"] = "Report uncollected resources"	
L["REPORT_LEVEL_LABEL"] = "Report at %s%s"
L["REPORT_LEVEL_TOOLTIP"] = "Report when the level of uncollected resources is higher than this value"
