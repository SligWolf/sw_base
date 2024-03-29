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

function SLIGWOLF_ADDON:GuessFallbackVehicleSpawnname(model)
	model = tostring(model or "")
	if model == "" then return nil end

	local registerdVehicleSpawnnamesByModel = self.RegisterdVehicleSpawnnamesByModel
	if not registerdVehicleSpawnnamesByModel then return nil end

	local vehicleSpawnname = registerdVehicleSpawnnamesByModel[model]
	if not vehicleSpawnname then return nil end

	return vehicleSpawnname
end

function SLIGWOLF_ADDON:HandleVehicleSpawn(vehicle)
	if not IsValid(vehicle) then return end
	if not vehicle:IsVehicle() then return end

	local model = vehicle:GetModel()
	local guessedVehicleSpawnname = self:GuessFallbackVehicleSpawnname(model)

	if not guessedVehicleSpawnname then
		-- Ensure the vehicle actually belongs to the current addon.
		return
	end

	local vehicleSpawnname = LIBVehicle.GetVehicleSpawnnameFromVehicle(vehicle)
	local vehicleTable = LIBVehicle.GetVehicleTableFromVehicle(vehicle)

	local wasGuessed = false

	if not vehicleSpawnname then
		vehicleSpawnname = guessedVehicleSpawnname
		wasGuessed = true
	end

	if not vehicleTable then
		vehicleTable = LIBVehicle.GetVehicleTableFromSpawnname(vehicleSpawnname)
	end

	if not vehicleTable then
		return
	end

	vehicleTable = table.Copy(vehicleTable)

	vehicle.sligwolf_entity = true
	vehicle.sligwolf_physEntity = true
	vehicle.sligwolf_vehicle = true

	vehicle.sligwolf_Addonname = self.Addonname

	local ply = vehicle.sligwolf_SpawnerPlayer
	vehicle.sligwolf_SpawnerPlayer = nil

	vehicle.VehicleName = vehicleSpawnname
	vehicle.VehicleTable = vehicleTable

	local customProperties = vehicleTable.SLIGWOLF_Custom
	vehicle.sligwolf_customProperties = customProperties

	if wasGuessed and vehicleTable.Members then
		table.Merge(vehicle, vehicleTable.Members)

		if SERVER then
			duplicator.StoreEntityModifier(vehicle, "VehicleMemDupe", vehicleTable.Members)
		end
	end

	local ok = self:CallAddonFunctionWithErrorNoHalt("SpawnVehicle", ply, vehicle, customProperties)

	if not ok then
		vehicle.sligwolf_customProperties = nil
	end
end

return true

