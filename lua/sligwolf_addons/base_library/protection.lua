AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Protection = SligWolf_Addons.Protection or {}
table.Empty(SligWolf_Addons.Protection)

local LIB = SligWolf_Addons.Protection

local CONSTANTS = SligWolf_Addons.Constants

local LIBHook = SligWolf_Addons.Hook

function LIB.CheckAllowUse(ent, ply)
	if not IsValid(ent) then return false end
	if not IsValid(ply) then return false end

	local allowuse = true

	if ent.CPPICanUse then
		allowuse = ent:CPPICanUse(ply) or false
	end

	return allowuse
end

local function CantCantPropDrive(ply, ent)
	if not IsValid(ent) then return end

	if ent.sligwolf_entity then
		return false
	end

	if ent:GetNWBool("sligwolf_entity", false) then
		return false
	end
end

LIBHook.Add("CanDrive", "Library_Protection_CantCantPropDrive", CantCantPropDrive, 10000)

local function CantCanPropertyCollision(ply, property, ent)
	if not IsValid(ent) then return end

	if property ~= "collision" then
		return
	end

	if ent.sligwolf_blockAllTools then
		return false
	end

	if ent:GetNWBool("sligwolf_blockAllTools", false) then
		return false
	end
end

LIBHook.Add("CanProperty", "Library_Protection_CantCanPropertyCollision", CantCanPropertyCollision, 10000)

local function CantCanPropertyRemover(ply, property, ent)
	if not IsValid(ent) then return end

	if property ~= "remover" then
		return
	end

	if ent.sligwolf_blockAllTools then
		return false
	end

	if ent:GetNWBool("sligwolf_blockAllTools", false) then
		return false
	end
end

LIBHook.Add("CanProperty", "Library_Protection_CantCanPropertyRemover", CantCanPropertyRemover, 10010)


local function CantTouch(ply, ent)
	if not IsValid(ent) then return end

	if ent.sligwolf_blockedprop then
		return false
	end

	if ent:GetNWBool("sligwolf_blockedprop", false) then
		return false
	end
end

LIBHook.Add("PhysgunPickup", "Library_Protection_CantTouch", CantTouch, 10000)

local function CantPickUp(ply, ent)
	if not IsValid(ent) then return end

	if ent.sligwolf_noPickup then
		return false
	end

	if ent:GetNWBool("sligwolf_noPickup", false) then
		return false
	end
end

LIBHook.Add("AllowPlayerPickup", "Library_Protection_CantPickUp", CantPickUp, 10000)

if SERVER then
	local function CantUnfreeze(ply, ent, phys)
		if not IsValid(ent) then return end

		if ent.sligwolf_blockedprop then
			return false
		end

		if ent.sligwolf_noUnfreeze then
			return false
		end
	end

	LIBHook.Add("CanPlayerUnfreeze", "Library_Protection_CantUnfreeze", CantUnfreeze, 10000)

	local function CantFreeze(weapon, phys, ent, ply)
		if not IsValid(ent) then return end

		if ent.sligwolf_blockedprop then
			return false
		end

		if ent.sligwolf_noFreeze then
			return false
		end
	end

	LIBHook.Add("OnPhysgunFreeze", "Library_Protection_CantFreeze", CantFreeze, 10000)
end

local function CanTool(ply, trace, mode, tool, button)
	if mode == CONSTANTS.toolRubatsEasyInspector then return end

	local ent = trace.Entity
	if not IsValid(ent) then return end

	if ent.sligwolf_blockAllTools then
		return false
	end

	if ent:GetNWBool("sligwolf_blockAllTools", false) then
		return false
	end

	local tb = ent.sligwolf_blockTool

	if istable(tb) then
		if tb[mode] then
			return false
		end
	end
end

LIBHook.Add("CanTool", "Library_Protection_CanTool", CanTool, 10000)

local function CanToolReload(ply, trace, mode, tool, button)
	if mode == CONSTANTS.toolRubatsEasyInspector then return end

	-- reload case
	if button ~= 3 then return end

	local ent = trace.Entity
	if not IsValid(ent) then return end

	local tb = ent.sligwolf_denyToolReload

	if not istable(tb) then return end
	if not tb[mode] then return end

	return false
end

LIBHook.Add("CanTool", "Library_Protection_CanToolReload", CanToolReload, 10010)

return true

