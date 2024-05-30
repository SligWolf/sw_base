AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local SligWolf_Addons = SligWolf_Addons

local LIBVehicle = SligWolf_Addons.Vehicle
local LIBPhysics = SligWolf_Addons.Physics

function SLIGWOLF_ADDON:MakeVehicle(spawnname, plyOwner, parent, name)
	local ent = LIBVehicle.MakeVehicle(spawnname, plyOwner, parent, name, self.Addonname)
	if not ent then
		return nil
	end

	return ent
end

function SLIGWOLF_ADDON:MakeVehicleEnsured(spawnname, plyOwner, parent, name)
	local ent = self:MakeVehicle(spawnname, plyOwner, parent, name)
	if not IsValid(ent) then
		self:RemoveFaultyEntites(
			{parent},
			"Couldn't create '%s' vehicle entity named '%s' for %s. Removing entities.",
			tostring(spawnname),
			tostring(name or "<unnamed>"),
			parent
		)

		return
	end

	return ent
end

function SLIGWOLF_ADDON:GuessFallbackVehicleSpawnname(model)
	model = tostring(model or "")
	if model == "" then return nil end

	local registerdVehicleSpawnnamesByModel = self.RegisterdVehicleSpawnnamesByModel
	if not registerdVehicleSpawnnamesByModel then return nil end

	local vehicleSpawnname = registerdVehicleSpawnnamesByModel[model]
	if not vehicleSpawnname then return nil end

	return vehicleSpawnname
end

function SLIGWOLF_ADDON:ValidateVehicleTable(vehicle, vehicleTable)
	if not IsValid(vehicle) then return false end
	if not vehicle:IsVehicle() then return false end

	if not vehicleTable then return false end
	if not vehicleTable.Is_SLIGWOLF then return false end

	if vehicleTable.SLIGWOLF_Addonname ~= self.Addonname then
		-- Make sure this vehicle belongs to our addon
		return false
	end

	local tableName = vehicleTable.Name

	local vehicleClass = vehicle:GetClass() or ""
	local tableClass = vehicleTable.Class or ""

	if vehicleClass ~= tableClass then
		self:ErrorNoHalt(
			"Class missmatch in vehicle: %s (%s)\n  Expected: '%s'\n  Got: '%s'.\n  Ignoring vehicle for spawn setup.\n",
			tableName,
			vehicle,
			tableClass,
			vehicleClass
		)

		return false
	end

	if SERVER then
		local vehicleKeyValues = vehicle:GetKeyValues() or {}
		local tableKeyValues = vehicleTable.KeyValues or {}

		local vehicleScript = vehicleKeyValues.vehiclescript or ""
		local tableScript = tableKeyValues.vehiclescript or ""

		if vehicleScript ~= tableScript then
			self:ErrorNoHalt(
				"Vehicle script missmatch in vehicle: %s (%s)\n  Expected: '%s'\n  Got: '%s'.\n  Ignoring vehicle for spawn setup.\n",
				tableName,
				vehicle,
				tableScript,
				vehicleScript
			)

			return false
		end
	end

	local vehicleModel = vehicle:GetModel() or ""
	local tableModel = vehicleTable.Model or ""

	if vehicleModel ~= tableModel then
		self:ErrorNoHalt(
			"Model missmatch in vehicle: %s (%s)\n  Expected: '%s'\n  Got: '%s'.\n  Ignoring vehicle for spawn setup.\n",
			tableName,
			vehicle,
			tableModel,
			vehicleModel
		)

		return false
	end

	return true
end

function SLIGWOLF_ADDON:HandleVehicleSpawn(vehicle)
	if not IsValid(vehicle) then return end
	if not vehicle:IsVehicle() then return end

	local vehicleSpawnname = LIBVehicle.GetVehicleSpawnnameFromVehicle(vehicle)
	if not vehicleSpawnname then
		vehicleSpawnname = self:GuessFallbackVehicleSpawnname(vehicle:GetModel())
	end

	if not vehicleSpawnname then
		return
	end

	local vehicleTable = LIBVehicle.GetVehicleTableFromSpawnname(vehicleSpawnname)
	if not vehicleTable then
		return
	end

	if not self:ValidateVehicleTable(vehicle, vehicleTable) then
		-- Ensure the vehicle has the right properties and matches to the vehicle table
		return
	end

	-- Copy the vehicle table to make sure nothing can accidentally change the original
	vehicleTable = table.Copy(vehicleTable)

	local isSpawnedByEngine = LIBVehicle.IsSpawnedByEngine(vehicle)

	local keyValues = vehicleTable.KeyValues or {}
	local class = vehicleTable.Class
	local members = vehicleTable.Members

	local entTable = vehicle:SligWolf_GetTable()

	vehicle.sligwolf_entity = true
	vehicle.sligwolf_vehicle = true
	vehicle.sligwolf_headVehicle = true

	vehicle.sligwolf_Addonname = self.Addonname

	LIBPhysics.InitializeAsPhysEntity(vehicle)

	local ply = entTable.sligwolf_SpawnerPlayer
	entTable.sligwolf_SpawnerPlayer = nil

	if isSpawnedByEngine then
		-- We must not change the vehicle script after spawn
		keyValues.vehiclescript = nil

		LIBVehicle.SetupVehicleKeyValues(vehicle, keyValues)
	end

	vehicle.VehicleName = vehicleSpawnname
	vehicle.VehicleTable = vehicleTable

	local customSpawnProperties = vehicleTable.SLIGWOLF_Custom
	entTable.customSpawnProperties = customSpawnProperties

	if isSpawnedByEngine then
		if vehicle.SetVehicleClass and SERVER then
			vehicle:SetVehicleClass(vehicleSpawnname)
		end

		vehicle.ClassOverride = class

		if members then
			table.Merge(vehicle, members)

			if SERVER then
				duplicator.StoreEntityModifier(vehicle, "VehicleMemDupe", members)
			end
		end
	end

	self:CallAddonFunctionWithErrorNoHalt("SpawnVehicle", ply, vehicle, customSpawnProperties)
end

return true

