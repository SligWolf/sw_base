AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.VR = SligWolf_Addons.VR or {}
table.Empty(SligWolf_Addons.VR)

local LIB = SligWolf_Addons.VR
local LIBHook = nil

local g_vrmod = nil
local g_version = nil
local g_versionErrorPrintedChecked = false

function LIB.Exist()
	local vrmod = g_vrmod or _G.vrmod
	if not istable(vrmod) then return false end

	local isPlayerInVRFunc = vrmod.IsPlayerInVR
	if not isfunction(isPlayerInVRFunc) then return false end

	if not LIB.CheckVersion() then return false end

	return true
end

function LIB.IsPlayerInVR(ply)
	if not IsValid(ply) then return false end
	if not ply.sligwolf_VRState then return false end

	return true
end

function LIB.GetLib()
	return g_vrmod
end

function LIB.GetLibVersion()
	if g_version ~= nil then
		if not g_version then
			return nil
		end

		return g_version
	end

	local vrmod = g_vrmod or _G.vrmod
	if not vrmod then
		return nil
	end

	local success = ProtectedCall(function()
		g_version = vrmod.GetVersion()
	end)

	if not success then
		g_version = false
		return nil
	end

	return g_version
end

function LIB.IsValidVersion()
	local version = LIB.GetLibVersion()
	if not version then
		return false
	end

	if version < 133 then
		return false
	end

	return true
end

function LIB.CheckVersion()
	if LIB.IsValidVersion() then
		return true
	end

	if g_versionErrorPrintedChecked then
		return false
	end

	if not LIBPrint then
		return false
	end

	g_versionErrorPrintedChecked = true
	LIBPrint.ErrorNoHalt("VRMod is outdated! (vrmod.GetVersion() < 133)")

	return false
end

local g_nextVRPoll = nil

local function VRPoll()
	local now = RealTime()

	if g_nextVRPoll and g_nextVRPoll > now then
		return
	end

	for k, ply in ipairs(player.GetHumans()) do
		if not IsValid(ply) then continue end

		local LastVRState = ply.sligwolf_VRState or false
		local VRState = g_vrmod.IsPlayerInVR(ply)

		if VRState ~= LastVRState then
			ply.sligwolf_VRState = VRState

			-- Ensure the vr state change is detected on EVERY client without additional networking
			if VRState then
				SligWolf_Addons.CallFunctionOnAllAddons("OnVRStart", ply)
			else
				SligWolf_Addons.CallFunctionOnAllAddons("OnVRExit", ply)
			end

			SligWolf_Addons.CallFunctionOnAllAddons("OnVRStateChange", ply, VRState)
		end
	end

	g_nextVRPoll = now + 0.2 + math.random() * 0.3
end

local function VRModStatusChange(ply)
	if not LIB.Exist() then
		return
	end

	g_nextVRPoll = nil
	VRPoll()
end

local function VRModStatusPoll()
	if not LIB.Exist() then
		return
	end

	VRPoll()
end

function LIB.Load()
	LIBHook = SligWolf_Addons.Hook
end

function LIB.AllAddonsLoaded()
	g_vrmod = nil

	if not LIB.Exist() then
		-- ensure the VRMod has been loaded
		return
	end

	g_vrmod = _G.vrmod

	LIBHook.Add("VRMod_Start", "Library_VR_VRModStatusChange", VRModStatusChange, 10000)
	LIBHook.Add("VRMod_Exit", "Library_VR_VRModStatusChange", VRModStatusChange, 10000)

	LIBHook.Add("Think", "Library_VR_Poll", VRModStatusPoll, 10000)
end

return true

