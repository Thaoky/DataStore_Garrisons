local L = LibStub("AceLocale-3.0"):NewLocale("DataStore_Garrisons", "esES")

if not L then return end

L["REPORT_LEVEL_LABEL"] = "Reportar en %s%s"
L["REPORT_LEVEL_TOOLTIP"] = "Reportar cuando el nivel de recursos no recogidos sea superior a este valor"
L["REPORT_UNCOLLECTED_DISABLED"] = "No se informará nada."
L["REPORT_UNCOLLECTED_ENABLED"] = "Al iniciar sesión, los alters con más de 400 recursos sin recoger serán informados en el chat."
L["REPORT_UNCOLLECTED_LABEL"] = "Reportar recursos no recogidos"
L["REPORT_UNCOLLECTED_TITLE"] = "Reportar recursos no recogidos"
L["UNCOLLECTED_RESOURCES_ALERT"] = "%s tiene %s recursos sin recoger"
