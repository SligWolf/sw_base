AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons:ReloadAddonSystem()
	return
end

local LIBThemesystem = SligWolf_Addons.Themesystem
local LIBEntities = SligWolf_Addons.Entities
local LIBConvar = SligWolf_Addons.Convar
local LIBPlayer = SligWolf_Addons.Player
local LIBPrint = SligWolf_Addons.Print
local LIBUtil = SligWolf_Addons.Util

local g_root_path = "ROOT"

SLIGWOLF_ADDON.g_themeMaps = {}
SLIGWOLF_ADDON.g_themeConfigs = {}
SLIGWOLF_ADDON.g_themeConfigsForRandom = {}
SLIGWOLF_ADDON.g_themeConfigsOrdered = {}
SLIGWOLF_ADDON.g_themeConfigsDefaults = {}
SLIGWOLF_ADDON.g_themeConfigsRandomPickers = {}
SLIGWOLF_ADDON.g_themeConfigsPlayerColored = {}
SLIGWOLF_ADDON.g_themeConfigsInvalidateCache = {}

local g_themeParamKeys = LIBThemesystem.g_themeParamKeys

function SLIGWOLF_ADDON:ThemeGetConvarNameAndDefault(category)
	local defaultThemeConfig = self:ThemeGetDefaultConfig(category)
	if not defaultThemeConfig then
		return nil
	end

	local convarName = string.format("cl_sligwolf_%s_theme_%s", self.Addonname, category)
	local defaultThemeName = defaultThemeConfig.name

	return convarName, defaultThemeName
end

function SLIGWOLF_ADDON:ThemeAddConvar(category)
	if SERVER then
		return nil
	end

	if not category or category == "" then
		return nil
	end

	if self.ThemeConvars then
		local convar = self.ThemeConvars[category]
		if convar then
			return convar
		end
	end

	self.ThemeConvars = self.ThemeConvars or {}
	self.ThemeConvars[category] = nil

	local convarName, defaultThemeName = self:ThemeGetConvarNameAndDefault(category)
	if not convarName or not defaultThemeName then
		return nil
	end

	local help = string.format(
		"Set the color theme for the next spawned object for category \x04'%s'\x03 in addon \x04'%s'\x03.",
		category,
		self.Addonname
	)

	local convar = LIBConvar.AddClientConvar(convarName, {
		default = defaultThemeName,
		shouldsave = true,
		userinfo = true,
		help = help,
		unlisted = true,
	})

	self.ThemeConvars[category] = convar
	return convar
end

function SLIGWOLF_ADDON:ThemeGetSelectedName(ply, category)
	local convarName, defaultThemeName = self:ThemeGetConvarNameAndDefault(category)
	if not convarName or not defaultThemeName then
		return nil
	end

	if not IsValid(ply) and CLIENT then
		ply = LocalPlayer()
	end

	if not IsValid(ply) then
		return defaultThemeName
	end

	if not ply:IsPlayer() then
		return defaultThemeName
	end

	if ply:IsBot() then
		return defaultThemeName
	end

	local themeName = ply:GetInfo(convarName)

	themeName = self:ThemeNormalizeName(category, themeName)

	if not themeName then
		return defaultThemeName
	end

	return themeName
end

function SLIGWOLF_ADDON:ThemeNormalizeName(category, themeName)
	local defaultThemeConfig = self:ThemeGetDefaultConfig(category)
	if not defaultThemeConfig then
		return nil
	end

	themeName = string.lower(tostring(themeName or ""))

	local defaultThemeName = defaultThemeConfig.name

	if themeName == "" or themeName == LIBThemesystem.THEME_DEFAULT then
		return defaultThemeName
	end

	if themeName == LIBThemesystem.THEME_RANDOM then
		local themeConfig = self:ThemeGetRandomPickerConfig(category)
		if not themeConfig then
			return defaultThemeName
		end

		return themeConfig.name
	end

	if themeName == LIBThemesystem.THEME_PLAYER then
		local themeConfig = self:ThemeGetPlayerColoredConfig(category)
		if not themeConfig then
			return defaultThemeName
		end

		return themeConfig.name
	end

	local themeConfig = self:ThemeGetConfig(category, themeName, false)
	if not themeConfig then
		LIBPrint.Warn(
			"Theme '%s' was not found in addon '%s'. Failing back to default.",
			themeName,
			self.Addonname
		)

		return defaultThemeName
	end

	return themeConfig.name
end

function SLIGWOLF_ADDON:ThemeGetNameFromKeyValue(category, keyValue)
	category = tostring(category or "")
	keyValue = string.lower(tostring(keyValue or ""))

	local defaultThemeConfig = self:ThemeGetDefaultConfig(category)
	if not defaultThemeConfig then
		return nil
	end

	local defaultThemeName = defaultThemeConfig.name

	if keyValue == "" or keyValue == LIBThemesystem.THEME_DEFAULT then
		return defaultThemeName
	end

	if keyValue == LIBThemesystem.THEME_RANDOM then
		local themeConfig = self:ThemeGetRandomPickerConfig(category)
		if not themeConfig then
			return defaultThemeName
		end

		return themeConfig.name
	end

	if keyValue == LIBThemesystem.THEME_PLAYER then
		if not IsValid(LIBPlayer.GetFailbackPlayer()) then
			return defaultThemeName
		end

		local themeConfig = self:ThemeGetPlayerColoredConfig(category)
		if not themeConfig then
			return defaultThemeName
		end

		return themeConfig.name
	end

	local separatorPos = string.find(keyValue, "_")
	if not separatorPos then
		LIBPrint.Warn("Malformed sligwolf_theme = '%s'. Failing back to default.", keyValue)
		return defaultThemeName
	end

	local foundAddonname = string.sub(keyValue, 1, separatorPos - 1)
	local themeName = string.sub(keyValue, separatorPos + 1)

	if foundAddonname ~= self.Addonname then
		LIBPrint.Warn(
			"Addon mismatch in sligwolf_theme = '%s', expected addon '%s', got '%s'. Failing back to default.",
			keyValue,
			self.Addonname,
			foundAddonname
		)

		return defaultThemeName
	end

	local themeConfig = self:ThemeGetConfig(category, themeName, true)
	if not themeConfig then
		LIBPrint.Warn(
			"Theme '%s' was not found in addon '%s', got sligwolf_theme = '%s'. Failing back to default.",
			themeName,
			self.Addonname,
			keyValue
		)

		return defaultThemeName
	end

	return themeConfig.name
end

function SLIGWOLF_ADDON:ThemeGetCategoryAndMapName(ent)
	local spawntable = LIBEntities.GetSpawntable(ent)
	local categoryName, mapName = self:ThemeGetCategoryAndMapNameFromSpawntable(spawntable)

	if not categoryName then
		return nil
	end

	if not mapName then
		return nil
	end

	return categoryName, mapName
end

function SLIGWOLF_ADDON:ThemeGetCategoryAndMapNameFromSpawntable(spawntable)
	if not spawntable then
		return nil
	end

	if not spawntable.Is_SLIGWOLF then
		return nil
	end

	if spawntable.SLIGWOLF_Addonname ~= self.Addonname then
		return nil
	end

	local categoryName = spawntable.SLIGWOLF_ThemeCategory
	if not categoryName then
		return nil
	end

	local mapName = spawntable.SLIGWOLF_ThemeMapName
	if not mapName then
		return nil
	end

	return categoryName, mapName
end

function SLIGWOLF_ADDON:ThemeAddMap(name, partsData)
	name = tostring(name or "")

	if name == "" then
		return
	end

	local map =  {}
	self.g_themeMaps[name] = map

	map.name = name

	local parts = {}
	map.parts = parts

	for partPath, partProperties in pairs(partsData) do
		partPath = tostring(partPath)

		if partPath == "" then
			partPath = g_root_path
		end

		parts[partPath] = {
			path = partPath,
			color = partProperties.color,
			skin = partProperties.skin,
			bodygroups = partProperties.bodygroups,
		}
	end
end

function SLIGWOLF_ADDON:ThemeGetMap(name)
	name = tostring(name or "")
	if name == "" then
		return nil
	end

	local map = self.g_themeMaps[name]
	if not map then
		return nil
	end

	return map
end

local function resolveThemeItemNames(themeParams)
	for i = 0, 8 do
		if i >= 8 then
			table.Empty(themeParams)
			error("infinite loop in resolveThemeItemNames detected")
			return
		end

		local nextRound = false

		for themeParamsName, themeParamsItemUnresolved in pairs(themeParams) do
			for _, themeParamKey in ipairs(g_themeParamKeys) do
				local themeParam = themeParamsItemUnresolved[themeParamKey]

				if themeParam and isstring(themeParam) and not LIBThemesystem.HasThemeMetaFunction(themeParamKey, themeParam) then
					local themeParamsItemResolved = themeParams[themeParam]
					if themeParamsItemResolved then
						themeParam = themeParamsItemResolved[themeParamKey]

						if themeParam then
							nextRound = true
						end
					else
						themeParam = nil
					end
				end

				themeParamsItemUnresolved[themeParamKey] = themeParam
			end
		end

		if not nextRound then
			return
		end
	end
end

function SLIGWOLF_ADDON:ThemeAddConfig(category, name, config)
	category = tostring(category or "")
	name = tostring(name or "")

	if category == "" then
		return
	end

	if name == "" then
		return
	end

	local themeCategory = self.g_themeConfigs[category] or {}
	self.g_themeConfigs[category] = themeCategory

	local themeConfig = {}
	themeCategory[name] = themeConfig

	themeConfig.name = name
	themeConfig.category = category
	themeConfig.order = config.order or LIBUtil.Order()
	themeConfig.isRandom = config.isRandom or false

	themeConfig.isDefault = false

	if config.isDefault then
		themeConfig.isDefault = true
	end

	if config.isRandom then
		themeConfig.isRandom = true
	end

	if config.isPlayerColored then
		themeConfig.isPlayerColored = true
	end

	local buttonParams = config.button or {}
	local themeParams = config.theme or {}

	themeConfig.button = {
		title = buttonParams.title,
		overlayMaterial = buttonParams.overlayMaterial,
		pieces = buttonParams.pieces,
	}

	local themeParamsInternal = {}
	themeConfig.theme = themeParamsInternal

	for themeParamsName, themeParamsItem in pairs(themeParams) do
		themeParamsInternal[themeParamsName] = {
			color = themeParamsItem.color,
			skin = themeParamsItem.skin,
			bodygroups = themeParamsItem.bodygroups,
		}
	end

	resolveThemeItemNames(themeParamsInternal)

	self.g_themeConfigsOrdered[category] = {}
	self.g_themeConfigsForRandom[category] = {}

	self.g_themeConfigsInvalidateCache[category] = true

	if config.isDefault then
		self:ThemeAddConvar(category)
	end
end

function SLIGWOLF_ADDON:ThemeGetConfig(category, name, resolveRandom)
	category = tostring(category or "")
	name = tostring(name or "")

	if category == "" then
		return nil
	end

	if name == "" then
		return nil
	end

	local themeCategory = self.g_themeConfigs[category]
	if not themeCategory then
		return nil
	end

	local themeConfig = themeCategory[name]
	if not themeConfig then
		return nil
	end

	if not resolveRandom or not themeConfig.isRandom then
		return themeConfig
	end

	local nonRandomThemeConfigs = self.g_themeConfigsForRandom[category] or {}

	if table.IsEmpty(nonRandomThemeConfigs) then
		for _, nonRandomThemeConfig in pairs(themeCategory) do
			if nonRandomThemeConfig.isRandom then
				continue
			end

			if nonRandomThemeConfig.isPlayerColored then
				continue
			end

			table.insert(nonRandomThemeConfigs, nonRandomThemeConfig)
		end
	end

	local randomKey = math.random(#nonRandomThemeConfigs)
	local randomThemeConfig = nonRandomThemeConfigs[randomKey]

	if not randomThemeConfig then
		return nil
	end

	return randomThemeConfig
end

function SLIGWOLF_ADDON:ThemeGetConfigs(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	local themeConfigsOrdered = self.g_themeConfigsOrdered[category] or {}
	self.g_themeConfigsOrdered[category] = themeConfigsOrdered

	if not table.IsEmpty(themeConfigsOrdered) then
		return themeConfigsOrdered
	end

	local themeConfigs = self.g_themeConfigs[category]
	if not themeConfigs then
		return nil
	end

	for i, themeConfig in SortedPairsByMemberValue(themeConfigs, "order") do
		table.insert(themeConfigsOrdered, themeConfig)
	end

	return themeConfigsOrdered
end

function SLIGWOLF_ADDON:ThemeBuildConfigsCache(category)
	category = tostring(category or "")

	if category == "" then
		return
	end

	if not self.g_themeConfigsInvalidateCache[category] then
		return
	end

	local themeConfigs = self:ThemeGetConfigs(category)
	if not themeConfigs then
		return
	end

	self.g_themeConfigsDefaults[category] = nil
	self.g_themeConfigsRandomPickers[category] = nil
	self.g_themeConfigsPlayerColored[category] = nil

	for i, themeConfig in ipairs(themeConfigs) do
		if themeConfig.isDefault and not self.g_themeConfigsDefaults[category] then
			self.g_themeConfigsDefaults[category] = themeConfig
		end

		if themeConfig.isRandom and not self.g_themeConfigsRandomPickers[category] then
			self.g_themeConfigsRandomPickers[category] = themeConfig
		end

		if themeConfig.isPlayerColored and not self.g_themeConfigsPlayerColored[category] then
			self.g_themeConfigsPlayerColored[category] = themeConfig
		end
	end

	self.g_themeConfigsInvalidateCache[category] = nil
end

function SLIGWOLF_ADDON:ThemeHasSupport(category)
	category = tostring(category or "")

	if category == "" then
		return false
	end

	local themeConfigs = self.g_themeConfigs[category]
	if not themeConfigs then
		return false
	end

	return true
end

function SLIGWOLF_ADDON:ThemeGetDefaultConfig(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	if not self:ThemeHasSupport(category) then
		return nil
	end

	self:ThemeBuildConfigsCache(category)

	local defaultThemeConfig = self.g_themeConfigsDefaults[category]
	if defaultThemeConfig then
		return defaultThemeConfig
	end

	LIBPrint.ErrorNoHaltWithStack("No default theme found for category '%s' for addon '%s'.", category, self.Addonname)
	return nil
end

function SLIGWOLF_ADDON:ThemeGetRandomPickerConfig(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	self:ThemeBuildConfigsCache(category)

	local randomPickerThemeConfig = self.g_themeConfigsRandomPickers[category]
	if randomPickerThemeConfig then
		return randomPickerThemeConfig
	end

	return nil
end

function SLIGWOLF_ADDON:ThemeGetPlayerColoredConfig(category)
	category = tostring(category or "")

	if category == "" then
		return nil
	end

	self:ThemeBuildConfigsCache(category)

	local playerColoredThemeConfig = self.g_themeConfigsPlayerColored[category]
	if playerColoredThemeConfig then
		return playerColoredThemeConfig
	end

	return nil
end

function SLIGWOLF_ADDON:ThemeApplyData(superparent, themeData)
	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local categoryName, mapName = self:ThemeGetCategoryAndMapName(superparent)
	if not categoryName then
		return
	end

	local map = self:ThemeGetMap(mapName)
	if not map then
		return
	end

	local parts = map.parts
	local entTable = superparent:SligWolf_GetTable()

	local appliedTheme = {}
	entTable.appliedTheme = appliedTheme

	for _, partProperties in pairs(parts) do
		local path = partProperties.path
		local themeEntry = themeData[path]

		if not themeEntry then
			continue
		end

		local itemColor = partProperties.color and themeEntry.color
		local itemSkin = partProperties.skin and themeEntry.skin
		local itemBodygroups = partProperties.bodygroups and themeEntry.bodygroups

		if not itemColor or not istable(itemColor) then
			itemColor = nil
		end

		if not itemSkin or not isnumber(itemSkin) then
			itemSkin = nil
		end

		if not itemBodygroups or not istable(itemBodygroups) then
			itemBodygroups = nil
		end

		local appliedThemeEntry = {}

		if itemColor then
			appliedThemeEntry.color = Color(
				itemColor.r,
				itemColor.g,
				itemColor.b,
				itemColor.a
			)

			appliedTheme[path] = appliedThemeEntry

			entTable.themeHasApplied = true
			entTable.themeHasAppliedColor = true
		end

		if itemSkin then
			appliedThemeEntry.skin = itemSkin
			appliedTheme[path] = appliedThemeEntry

			entTable.themeHasApplied = true
			entTable.themeHasAppliedSkin = true
		end

		if itemBodygroups then
			appliedThemeEntry.bodygroups = itemBodygroups
			appliedTheme[path] = appliedThemeEntry

			entTable.themeHasApplied = true
			entTable.themeHasAppliedBodygroups = true
		end

		local ent = nil

		if path == g_root_path then
		 	ent = superparent
		else
		 	ent = LIBEntities.GetChildFromPath(superparent, path)
		end

		if not IsValid(ent) then
			continue
		end

		if itemColor then
			ent:SetColor(itemColor)
		end

		if itemSkin then
			ent:SetSkin(itemSkin)
		end

		LIBEntities.SetBodygroupMeshIds(ent, itemBodygroups)
	end
end

function SLIGWOLF_ADDON:ThemeApplyByName(superparent, themeConfigName)
	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local categoryName = self:ThemeGetCategoryAndMapName(superparent)
	if not categoryName then
		return
	end

	local themeConfig = self:ThemeGetConfig(categoryName, themeConfigName, true)
	if not themeConfig then
		return
	end

	self:ThemeApplyFromConfig(superparent, themeConfig)
end

function SLIGWOLF_ADDON:ThemeApplyFromConfig(superparent, themeConfig)
	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local categoryName, mapName = self:ThemeGetCategoryAndMapName(superparent)
	if not categoryName then
		return
	end

	local map = self:ThemeGetMap(mapName)
	if not map then
		return
	end

	if not themeConfig then
		return
	end

	local parts = map.parts
	local themeParams = themeConfig.theme

	local themeData = {}

	for _, partProperties in pairs(parts) do
		local path = partProperties.path

		local appliedThemeEntry = {}

		-- Resolve names to color/skin/bodygroups from theme
		for _, themeParamKey in ipairs(g_themeParamKeys) do
			local partProperty = partProperties[themeParamKey]
			if partProperty and isstring(partProperty) and not LIBThemesystem.HasThemeMetaFunction(themeParamKey, partProperty) then
				local themeParam = themeParams[partProperty]

				if themeParam then
					partProperty = themeParam[themeParamKey]
				end
			end

			if partProperty then
				if LIBThemesystem.HasThemeMetaFunction(themeParamKey, partProperty) then
					partProperty = LIBThemesystem.CallThemeMetaFunction(themeParamKey, partProperty, superparent)
				end

				if partProperty then
					appliedThemeEntry[themeParamKey] = partProperty
					themeData[path] = appliedThemeEntry
				end
			end
		end
	end

	self:ThemeApplyData(superparent, themeData)
end

function SLIGWOLF_ADDON:ThemeGetAppliedDataOfPath(superparent, path)
	if not path then
		return nil
	end

	if path == "" then
		path = g_root_path
	end

	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local _, mapName = self:ThemeGetCategoryAndMapName(superparent)
	if not mapName then
		return
	end

	local map = self:ThemeGetMap(mapName)
	if not map then
		return
	end

	local parts = map.parts
	if not parts[path] then
		return
	end

	local entTable = superparent:SligWolf_GetTable()
	local appliedTheme = entTable.appliedTheme

	if not appliedTheme then
		return
	end

	local appliedThemeData = appliedTheme[path]
	if not appliedThemeData then
		return
	end

	return appliedThemeData
end

function SLIGWOLF_ADDON:ThemeReapplyDataForPath(superparent, path)
	if not path then
		return nil
	end

	if path == "" then
		path = g_root_path
	end

	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local themeData = self:ThemeGetAppliedDataOfPath(superparent, path)
	if not themeData then
		return
	end

	local itemColor = themeData.color
	local itemSkin = themeData.skin
	local itemBodygroups = themeData.bodygroups

	local ent = nil

	if path == g_root_path then
		ent = superparent
	else
		ent = LIBEntities.GetChildFromPath(superparent, path)
	end

	if itemColor then
		ent:SetColor(itemColor)
	end

	if itemSkin then
		ent:SetSkin(itemSkin)
	end

	LIBEntities.SetBodygroupMeshIds(ent, itemBodygroups)
end

function SLIGWOLF_ADDON:ThemeGetData(superparent)
	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return
	end

	local categoryName, mapName = self:ThemeGetCategoryAndMapName(superparent)
	if not categoryName then
		return
	end

	local map = self:ThemeGetMap(mapName)
	if not map then
		return
	end

	local parts = map.parts
	local themeData = {}

	for _, partProperties in pairs(parts) do
		local path = partProperties.path

		local ent = nil

		if path == g_root_path then
		 	ent = superparent
		else
		 	ent = LIBEntities.GetChildFromPath(superparent, path)
		end

		if not IsValid(ent) then
			continue
		end

		local themeEntry = {}

		if partProperties.color then
			themeEntry.color = ent:GetColor()
			themeData[path] = themeEntry
		end

		if partProperties.skin then
			themeEntry.skin = ent:GetSkin()
			themeData[path] = themeEntry
		end

		if partProperties.bodygroups then
			themeEntry.bodygroups = LIBEntities.GetBodygroupMeshIds(ent)
			themeData[path] = themeEntry
		end
	end

	return themeData
end

function SLIGWOLF_ADDON:ThemeHasApplied(superparent)
	superparent = LIBEntities.GetSuperParent(superparent)
	if not IsValid(superparent) then
		return false
	end

	local entTable = superparent:SligWolf_GetTable()
	local appliedTheme = entTable.appliedTheme

	if not appliedTheme then
		return false
	end

	if table.IsEmpty(appliedTheme) then
		return false
	end

	return true
end

return true

