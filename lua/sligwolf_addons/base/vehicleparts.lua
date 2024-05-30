AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SLIGWOLF_ADDON then
	SligWolf_Addons.AutoLoadAddon(function() end)
	return
end

local CONSTANTS = SligWolf_Addons.Constants

local LIBVehicle = SligWolf_Addons.Vehicle
local LIBEntities = SligWolf_Addons.Entities
local LIBPosition = SligWolf_Addons.Position
local LIBCoupling = SligWolf_Addons.Coupling
local LIBPhysics = SligWolf_Addons.Physics
local LIBSpamprotection = SligWolf_Addons.Spamprotection
local LIBUtil = SligWolf_Addons.Util

local g_FailbackComponentsParams = {
	model = "",
	class = "",
	color = CONSTANTS.colorDefault,
	skin = 0,
	bodygroups = {},
	shadow = false,
	nodraw = false,
	customPhysics = false,
	solid = SOLID_VPHYSICS,
	collision = COLLISION_GROUP_NONE,
	blocked = true,
	blockAllTools = false,
	keyValues = {},
	inputFires = {},
	constraints = {},
	motion = true,
	colorFromParent = false,
	isBody = false,
	removeAllOnDelete = true,

	typesParams = {
		propParent = {
			collision = COLLISION_GROUP_IN_VEHICLE,
			boneMerge = false,
		},
		trigger = {
			customPhysics = true,
			minSize = Vector(-4, -4, -4),
			maxSize = Vector(4, 4, 4),
		},
		door = {
			autoClose = true,
			openTime = 3,
			disableUse = false,
			spawnOpen = false,
		},
		connector = {
			connectortype = "unknown",
			gender = "N",
			searchRadius = 10,
		},
		connectorButton = {
			collision = COLLISION_GROUP_WORLD,
			inVehicle = false,
		},
		button = {
			collision = COLLISION_GROUP_WORLD,
			inVehicle = false,
		},
		smoke = {
			spawnTime = 0.1,
			velocity = 7,
			startSize = 5,
			endSize = 1,
			startAlpha = 100,
			endAlpha = 10,
			lifeTime = 0,
			dieTime = 3,
		},
		light = {
			fov = 120,
			farZ = 2048,
			shadowRenderDist = 2048,
		},
		glow = {
			size = 30,
			enlarge = 10,
			count = 2,
			alphaReduce = 100,
		},
		animatedWheel = {
			size = 8,
			restrate = 16,
			boneMerge = false,
			collision = COLLISION_GROUP_WEAPON,
		},
		speedometer = {
			minSpeed = 0,
			maxSpeed = 1312,
			minPoseValue = 0,
			maxPoseValue = 1,
			poseName = "vehicle_guage",
		},
		display = {
			scale = 0.25,
			functionName = "",
		},
		bendi = {
			parentNameFront = "",
			parentNameRear = "",
		},
		pod = {
			collision = COLLISION_GROUP_WORLD,
			boneMerge = false,
			keyValues = {
				vehiclescript = "scripts/vehicles/prisoner_pod.txt",
				limitview = 0,
			},
		},
		seatGroup = {
			collision = COLLISION_GROUP_WORLD,
			seatModel = CONSTANTS.mdlDynamicSeat,
			seatKeyValues = {
				vehiclescript = "scripts/vehicles/prisoner_pod.txt",
				limitview = 0,
			},
		},
		hoverball = {
			speed = 5,
			airResistance = 5,
			strength = 5,
			numDown = KEY_SPACE,
			numUp = KEY_SPACE,
			numBackDown = KEY_LALT,
			numBackUp = KEY_LALT,
			solid = SOLID_NONE,
		},
	},
}

local g_FailbackConstraintsParams = {
	Weld = {
		bone1 = 0,
		bone2 = 0,
		forcelimit = 0,
		nocollide = true,
	},
	NoCollide = {
		bone1 = 0,
		bone2 = 0,
	},
	Axis = {
		bone1 = 0,
		bone2 = 0,
		lpos1 = CONSTANTS.vecZero,
		lpos2 = CONSTANTS.vecZero,
		forcelimit = 0,
		torquelimit = 0,
		friction = 0,
		nocollide = 1,
		localaxis = CONSTANTS.vecZero,
	},
	Ballsocket = {
		bone1 = 0,
		bone2 = 0,
		localpos = CONSTANTS.vecZero,
		forcelimit = 0,
		torquelimit = 0,
		nocollide = 1,
	},
	AdvBallsocket = {
		bone1 = 0,
		bone2 = 0,
		lpos1 = CONSTANTS.vecZero,
		lpos2 = CONSTANTS.vecZero,
		forcelimit = 0,
		torquelimit = 0,
		xmin = -45,
		ymin = -45,
		zmin = -45,
		xmax = 45,
		ymax = 45,
		zmax = 45,
		xfric = 0,
		yfric = 0,
		zfric = 0,
		onlyrotation = 0,
		nocollide  = 1,
	},
	Keepupright = {
		ang = Angle(),
		bone1 = 0,
		angularLimit = 0,
	},
}

local function GetColor(superparent, colorOrColorName)
	if not IsValid(superparent) then
		error("Superparent is missing!")
		return nil
	end

	if not isstring(colorOrColorName) then
		if not IsColor(colorOrColorName) then
			ErrorNoHaltWithStack(
				string.format(
					"Invalid or missing color at entity '%s', replaced with a fallback color!",
					LIBVehicle.ToString(superparent)
				)
			)

			return CONSTANTS.colorError1
		end

		return colorOrColorName
	end

	local superparentTable = superparent:SligWolf_GetTable()

	local customProperties = superparentTable.customSpawnProperties or {}
	local colors = customProperties.colors or {}

	local color = colors[colorOrColorName]
	if not color or not IsColor(color)  then
		ErrorNoHaltWithStack(
			string.format(
				"Color named '%s' is invalid or missing at entity '%s', replaced with a fallback color!",
				colorOrColorName,
				LIBVehicle.ToString(superparent)
			)
		)

		return CONSTANTS.colorError2
	end

	return color
end

local function GetSkin(superparent, skinOrSkinName)
	if not IsValid(superparent) then
		error("Superparent is missing!")
		return nil
	end

	if not isstring(skinOrSkinName) then
		if not isnumber(skinOrSkinName) then
			ErrorNoHaltWithStack(
				string.format(
					"Invalid or missing skin at entity '%s', replaced with a fallback skin!",
					LIBVehicle.ToString(superparent)
				)
			)

			return CONSTANTS.skinError
		end

		return skinOrSkinName
	end

	local superparentTable = superparent:SligWolf_GetTable()

	local customProperties = superparentTable.customSpawnProperties or {}
	local skins = customProperties.skins or {}

	local skinValue = skins[skinOrSkinName]
	if not skinValue or not isnumber(skinValue)  then
		ErrorNoHaltWithStack(
			string.format(
				"Skin named '%s' is invalid or missing at entity '%s', replaced with a fallback skin!",
				skinOrSkinName,
				LIBVehicle.ToString(superparent)
			)
		)

		return CONSTANTS.skinError
	end

	return skinValue
end

local function SetPartKeyValues(ent, keyValues)
	if not keyValues then return end

	for k, v in pairs(keyValues) do
		ent:SetKeyValue(tostring(k), v)
	end
end

local function SetPartInputFire(ent, inputFires)
	if not inputFires then return end

	for _, v in ipairs(inputFires) do
		ent:Fire(v)
	end
end

local function SetUnsetConstraintValuesToDefaults(constraint, constraintInfo)
	local failbackConstraintParamsForConstraint = g_FailbackConstraintsParams[constraint] or {}

	for k, v in pairs(failbackConstraintParamsForConstraint) do
		if constraintInfo[k] ~= nil then
			continue
		end

		constraintInfo[k] = v
	end

	return constraintInfo
end

local function SetUnsetConstraintsValuesToDefaults(constraints)
	constraints = constraints or {}

	for constraint, constraintInfo in pairs(constraints) do
		constraintInfo = SetUnsetConstraintValuesToDefaults(constraint, constraintInfo)
		constraints[constraint] = constraintInfo
	end

	return constraints
end

local function CreateWeld(ent, parent, constraintInfos)
	local WD = constraint.Weld(
		ent,
		parent,
		constraintInfos.bone1,
		constraintInfos.bone2,
		constraintInfos.forcelimit,
		constraintInfos.nocollide,
		true
	)

	if not IsValid(WD) then
		return
	end

	WD.DoNotDuplicate = true
	parent.sligwolf_constraintWeld = WD

	return WD
end

local function CreateNoCollide(ent, parent, constraintInfos)
	local NC = constraint.NoCollide(
		ent,
		parent,
		constraintInfos.bone1,
		constraintInfos.bone2
	)

	if not IsValid(NC) then
		return
	end

	NC.DoNotDuplicate = true
	parent.sligwolf_constraintNoCollide = NC

	return NC
end

local function CreateAxis(ent, parent, constraintInfos)
	local AX = constraint.Axis(
		ent,
		parent,
		constraintInfos.bone1,
		constraintInfos.bone2,
		constraintInfos.lpos1,
		constraintInfos.lpos2,
		constraintInfos.forcelimit,
		constraintInfos.torquelimit,
		constraintInfos.friction,
		constraintInfos.nocollide,
		constraintInfos.localaxis
	)

	if not IsValid(AX) then
		return
	end

	AX.DoNotDuplicate = true
	parent.sligwolf_constraintAxis = AX

	return AX
end

local function CreateBallSocket(ent, parent, constraintInfos)
	local BS = constraint.Ballsocket(
		parent,
		ent,
		constraintInfos.bone1,
		constraintInfos.bone2,
		constraintInfos.localpos,
		constraintInfos.forcelimit,
		constraintInfos.torquelimit,
		constraintInfos.nocollide
	)

	if not IsValid(BS) then
		return
	end

	BS.DoNotDuplicate = true
	parent.sligwolf_constraintBallSocket = BS

	return BS
end

local function CreateAdvBallsocket(ent, parent, constraintInfos)
	local ADVBS = constraint.AdvBallsocket(
		ent,
		parent,
		constraintInfos.bone1,
		constraintInfos.bone2,
		constraintInfos.lpos1,
		constraintInfos.lpos2,
		constraintInfos.forcelimit,
		constraintInfos.torquelimit,
		constraintInfos.xmin,
		constraintInfos.ymin,
		constraintInfos.zmin,
		constraintInfos.xmax,
		constraintInfos.ymax,
		constraintInfos.zmax,
		constraintInfos.xfric,
		constraintInfos.yfric,
		constraintInfos.zfric,
		constraintInfos.onlyrotation,
		constraintInfos.nocollide
	)

	if not IsValid(ADVBS) then
		return
	end

	ADVBS.DoNotDuplicate = true
	parent.sligwolf_constraintAdvBallsocket = ADVBS

	return ADVBS
end

local function CreateKeepupright(ent, parent, constraintInfos)
	local KU = constraint.Keepupright(
		ent,
		constraintInfos.ang,
		constraintInfos.bone1,
		constraintInfos.angularLimit
	)

	if not IsValid(KU) then
		return
	end

	KU.DoNotDuplicate = true
	parent.sligwolf_constraintKeepupright = KU

	return KU
end

local g_ConstraintCreateFunctions = {
	Weld = CreateWeld,
	NoCollide = CreateNoCollide,
	Axis = CreateAxis,
	Ballsocket = CreateBallSocket,
	AdvBallsocket = CreateAdvBallsocket,
	Keepupright = CreateKeepupright,
}

function SLIGWOLF_ADDON:CreateConstraint(ent, parent, constraintName, constraintInfos)
	if LIBEntities.IsMarkedForDeletion(ent) then
		return nil
	end

	if LIBEntities.IsMarkedForDeletion(parent) then
		return nil
	end

	local func = g_ConstraintCreateFunctions[constraintName]

	if not func then
		self:Error("%s is not a valid constraint type", constraintName)
		return nil
	end

	local constraintEnt = func(ent, parent, constraintInfos)

	if not IsValid(constraintEnt) then
		self:RemoveFaultyEntites(
			{ent, parent},
			"Couldn't create %s constraint between %s <===> %s. Removing entities.",
			constraintName,
			ent,
			parent
		)

		return nil
	end

	return constraintEnt
end


function SLIGWOLF_ADDON:CreateConstraints(ent, parent, componentConstraints)
	componentConstraints = componentConstraints or {}
	componentConstraints = SetUnsetConstraintsValuesToDefaults(componentConstraints)

	for constraintName, constraintInfos in pairs(componentConstraints) do
		local cEnt = self:CreateConstraint(ent, parent, constraintName, constraintInfos)

		if not IsValid(cEnt) then
			return false
		end
	end

	return true
end

local function ProceedVehicleSetUp(ent, tb)
	if LIBEntities.IsMarkedForDeletion(ent) then
		return false
	end

	if not istable(tb) then
		return false
	end

	return true
end

local function SetUnsetComponentsValuesToDefaults(component)
	local componentType = tostring(component.type or "")
	if componentType == "" then
		error("component.type is not set!")
		return nil
	end
	component.type = componentType

	local mergedFailbackComponentsParams = table.Copy(g_FailbackComponentsParams)

	local typeParams = mergedFailbackComponentsParams.typesParams[componentType] or {}
	mergedFailbackComponentsParams.typesParams = nil

	mergedFailbackComponentsParams = table.Merge(mergedFailbackComponentsParams, typeParams)

	for k, v in pairs(mergedFailbackComponentsParams) do
		if not istable(v) or IsColor(v) then
			if component[k] ~= nil then
				continue
			end

			component[k] = v
			continue
		end

		component[k] = table.Merge(v, component[k] or {})
	end

	local color = component.color
	if not color then
		color = mergedFailbackComponentsParams.color
	end

	local attachment = tostring(component.attachment or "")
	if attachment == "" then
		error("component.attachment is not set!")
		return nil
	end
	component.attachment = attachment

	local model = component.model
	if not LIBUtil.IsValidModel(model) then
		model = mergedFailbackComponentsParams.model
	end
	component.model = model

	local name = tostring(component.name or "")
	if name == "" then
		name = string.format("unnamed_%s_%09u", component.type, math.floor(math.random(0, 999999999)))
	end
	component.name = name

	local class = tostring(component.class or "")
	if class == "" then
		class = nil
	end
	component.class = class

	if component.customPhysics then
		component.solid = nil
		component.collision = nil
	end

	return component
end

function SLIGWOLF_ADDON:CheckToProceedToCreateEnt(ent, tb)
	if not ProceedVehicleSetUp(ent, tb) then return nil end

	local att = tostring(tb.attachment or "")
	if att == "" then return nil end

	local parentAttId = ent:LookupAttachment(att) or 0
	if parentAttId == 0 then return nil end

	return parentAttId
end

function SLIGWOLF_ADDON:SetPartValues(ent, parent, component, attachment, superparent)
	if not IsValid(ent) then return end

	local model = component.model
	local color = GetColor(superparent, component.color)
	local skin = GetSkin(superparent, component.skin)
	local bodygroups = component.bodygroups
	local shadow = component.shadow
	local nodraw = component.nodraw
	local solid = component.solid
	local collision = component.collision
	local blocked = component.blocked
	local blockAllTools = component.blockAllTools
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local motion = component.motion
	local mass = component.mass
	local colorFromParent = component.colorFromParent
	local isBody = component.isBody
	local selfAttachment = component.selfAttachment

	if LIBUtil.IsValidModel(model) then
		ent:SetModel(model)
	end

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)

	if ent.sligwolf_baseEntity then
		-- spawn first when if it is a custom entity, so we can use model dependent positioning

	 	ent:Spawn()
	 	ent:Activate()
	end

	local model = ent:GetModel()

	if not LIBUtil.IsValidModel(model) then
		self:RemoveFaultyEntites(
			{parent, ent},
			"Invalid model ('%s') on entity %s. Removing entities.",
			model,
			ent
		)

		return
	end

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment) then
		self:RemoveFaultyEntites(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	if not ent.sligwolf_baseEntity then
		-- engine entities must not be spawned before model dependent positioning.

		ent:Spawn()
		ent:Activate()
	end

	ent:SetColor(color)
	ent:SetSkin(skin)

	ent.DoNotDuplicate = true

	for bodygroupName, bodygroup in pairs(bodygroups) do
		ent:SetBodygroup(bodygroup.index, bodygroup.mesh)
	end

	ent:DrawShadow(shadow)

	if solid then
		ent:SetSolid(solid)
	end

	if collision then
		ent:SetCollisionGroup(collision)
	end

	ent:SetNoDraw(nodraw)

	if colorFromParent and ent.sligwolf_baseEntity then
		ent:SetColorBaseEntity(parent)
	end

	if blocked then
		ent.sligwolf_blockedprop = true
		ent:SetNWBool("sligwolf_blockedprop", true)
	end

	if blockAllTools then
		ent.sligwolf_blockAllTools = true
		ent:SetNWBool("sligwolf_blockAllTools", true)
	end

	if isBody then
		ent.sligwolf_isBody = true
		ent:SetNWBool("sligwolf_isBody", true)
	end

	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) then
		return ent
	end

	phys:Wake()
	phys:EnableMotion(motion)

	if mass then
		phys:SetMass(mass)
	end
end

function SLIGWOLF_ADDON:SetUpVehicleParts(parent, components, dtr, ply, superparent)
	if not ProceedVehicleSetUp(parent, components) then return end
	if table.IsEmpty(components) then return end

	dtr = dtr or {}
	superparent = superparent or parent

	for i, component in ipairs(components) do
		self:SetUpVehiclePart(parent, component, dtr, ply, superparent)
	end
end

function SLIGWOLF_ADDON:SetUpVehiclePartsDelayed(parent, components, dtr, ply, superparent)
	if not ProceedVehicleSetUp(parent, components) then return end
	if table.IsEmpty(components) then return end

	dtr = dtr or {}
	superparent = superparent or parent

	local timername = "SetUpVehicleParts"

	LIBSpamprotection.DelayNextSpawn(ply)

	self:EntityTimerOnce(parent, timername, 0.125, function()
		-- Delay the spawning of the next level of sub entities by at least 0.125 seconds. 
		-- This will prevent positioning issues from happening.

		if not IsValid(superparent) then
			return
		end

		self:SetUpVehicleParts(parent, components, dtr, ply, superparent)
		return
	end)
end

function SLIGWOLF_ADDON:SetUpVehiclePart(parent, component, dtr, ply, superparent)
	if not ProceedVehicleSetUp(parent, component) then return end
	dtr = dtr or {}

	component = SetUnsetComponentsValuesToDefaults(component)

	local funcs = {
		prop = self.SetUpVehicleProp,
		slider = self.SetUpVehicleSlider,
		bogie = self.SetUpVehicleBogie,
		propParent = self.SetUpVehiclePropParented,
		seatGroup = self.SetUpVehicleSeatGroup,
		animatable = self.SetUpVehicleAnimatable,
		speedometer = self.SetUpVehicleSpeedometer,
		trigger = self.SetUpVehicleTrigger,
		door = self.SetUpVehicleDoor,
		connector = self.SetUpVehicleConnector,
		connectorButton = self.SetUpVehicleConnectorButton,
		button = self.SetUpVehicleButton,
		animatedWheel = self.SetUpVehicleAnimatedWheel,
		light = self.SetUpVehicleLight,
		glow = self.SetUpVehicleGlow,
		smoke = self.SetUpVehicleSmoke,
		pod = self.SetUpVehiclePod,
		display = self.SetUpVehicleDisplay,
		bendi = self.SetUpVehicleBendi,
		jeep = self.SetUpVehicleJeep,
		airboat = self.SetUpVehicleAirboat,
		hoverball = self.SetUpVehicleHoverball,
	}

	local componentType = component.type
	local func = funcs[componentType]

	if not func then
		self:Error("%s is not a valid part type", componentType)
		return
	end

	local ent = func(self, parent, component, ply, superparent)
	if not IsValid(ent) then return end

	local removeAllOnDelete = component.removeAllOnDelete

	if removeAllOnDelete then
		LIBEntities.RemoveSystemEntitesOnDelete(ent)
	end

	ent.sligwolf_denyToolReload = dtr

	local hasSpawnedConstraints = self:CreateConstraints(ent, parent, component.constraints)
	if not hasSpawnedConstraints then
		return
	end

	LIBSpamprotection.DelayNextSpawn(ply)
	self:SetUpVehiclePartsDelayed(ent, component.children, dtr, ply, superparent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleProp(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class

	local ent = self:MakeEntEnsured(class or "sligwolf_phys", ply, parent, "Prop_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleSlider(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class

	local ent = self:MakeEntEnsured(class or "sligwolf_slider", ply, parent, "Slider_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleBogie(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class

	local ent = self:MakeEntEnsured(class or "sligwolf_bogie", ply, parent, "Bogie_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehiclePropParented(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local boneMerge = component.boneMerge

	local ent = self:MakeEntEnsured(class or "sligwolf_phys", ply, parent, "ParentedProp_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.SetupChildEntity(ent, parent, component.collision, attachment)

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleSeatGroup(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local seatModel = component.seatModel
	local seatKeyValues = component.seatKeyValues

	local ent = self:MakeEntEnsured(class or "sligwolf_seat_group", ply, parent, "SeatGroup_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.SetupChildEntity(ent, parent, component.collision, attachment)

	ent:SetSeatModel(seatModel)
	ent:SetSeatKeyValues(seatKeyValues)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleAnimatable(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local boneMerge = component.boneMerge

	local ent = self:MakeEntEnsured(class or "sligwolf_animatable", ply, parent, "Animatable_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.SetupChildEntity(ent, parent, component.collision, attachment)

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleSpeedometer(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local minSpeed = component.minSpeed
	local maxSpeed = component.maxSpeed
	local minPoseValue = component.minPoseValue
	local maxPoseValue = component.maxPoseValue
	local poseName = component.poseName

	local ent = self:MakeEntEnsured(class or "sligwolf_speedometer", ply, parent, "Speedometer_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	ent:SetMinSpeed(minSpeed)
	ent:SetMaxSpeed(maxSpeed)
	ent:SetMinPoseValue(minPoseValue)
	ent:SetMaxPoseValue(maxPoseValue)
	ent:SetPoseName(poseName)
	ent:SetMessureEntity(parent)

	ent:AttachToEnt(parent, attachment)

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleTrigger(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local minSize = component.minSize
	local maxSize = component.maxSize
	local filterFunc = component.filterFunc

	if filterFunc and not isfunction(filterFunc) then
		error("component.filterFunc is not a function!")
		return
	end

	local ent = self:MakeEntEnsured(class or "sligwolf_trigger", ply, parent, "Trigger_" .. name)
	if not IsValid(ent) then return end

	ent:SetTriggerAABB(minSize, maxSize)

	if filterFunc then
		ent.PassesTriggerFilters = filterFunc
	end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.SetupChildEntity(ent, parent, component.collision, attachment)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleDoor(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local disableUse = component.disableUse
	local soundOpen = component.soundOpen
	local soundClose = component.soundClose
	local autoClose = component.autoClose
	local openTime = component.openTime
	local spawnOpen = component.spawnOpen
	local funcOnOpen = component.onOpen
	local funcOnClose = component.onClose

	if funcOnOpen and not isfunction(funcOnOpen) then
		error("component.funcOnOpen is not a function!")
		return
	end

	if funcOnClose and not isfunction(funcOnClose) then
		error("component.funcOnClose is not a function!")
		return
	end

	local ent = self:MakeEntEnsured(class or "sligwolf_door", ply, parent, "Door_" .. name)
	if not IsValid(ent) then
		return
	end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	if isstring(soundOpen) then
		ent:Set_OpenSound(soundOpen)
	end

	if isstring(soundClose) then
		ent:Set_CloseSound(soundClose)
	end

	ent:Set_OpenTime(openTime)
	ent:Set_AutoClose(autoClose)
	ent:Set_SpawnOpen(spawnOpen)
	ent:Set_DisableUse(disableUse)
	ent:TurnOn(true)

	if funcOnOpen then
		ent.OnOpen = funcOnOpen
	end

	if funcOnClose then
		ent.OnClose = funcOnClose
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleConnector(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local connectortype = component.connectortype
	local gender = component.gender
	local searchRadius = component.searchRadius

	local ent = self:MakeEntEnsured(class or "sligwolf_connector", ply, parent, "Connector_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)

	ent.sligwolf_connectorDirection = name
	LIBEntities.RemoveEntitiesOnDelete(parent, ent)

	ent.OnDisconnect = function(ConA, ConB)
		local vehicleA = LIBEntities.GetSuperParent(ConA)
		local vehicleB = LIBEntities.GetSuperParent(ConB)
		if not IsValid(vehicleA) then return end
		if not IsValid(vehicleB) then return end

		local DirA = ConA.sligwolf_connectorDirection
		local DirB = ConB.sligwolf_connectorDirection

		if isfunction(self.OnDisconnectTrailer) then
			self:OnDisconnectTrailer(vehicleA, vehicleB, DirA)
			self:OnDisconnectTrailer(vehicleB, vehicleA, DirB)
		end

		vehicleA.SLIGWOLF_Connected = vehicleA.SLIGWOLF_Connected or {}
		vehicleB.SLIGWOLF_Connected = vehicleB.SLIGWOLF_Connected or {}

		vehicleA.SLIGWOLF_Connected[DirA] = nil
		vehicleB.SLIGWOLF_Connected[DirB] = nil
	end

	ent.OnConnect = function(ConA, ConB)
		local vehicleA = LIBEntities.GetSuperParent(ConA)
		local vehicleB = LIBEntities.GetSuperParent(ConB)
		if not IsValid(vehicleA) then return end
		if not IsValid(vehicleB) then return end

		local DirA = ConA.sligwolf_connectorDirection
		local DirB = ConB.sligwolf_connectorDirection

		vehicleA.SLIGWOLF_Connected = vehicleA.SLIGWOLF_Connected or {}
		vehicleB.SLIGWOLF_Connected = vehicleB.SLIGWOLF_Connected or {}

		vehicleA.SLIGWOLF_Connected[DirA] = vehicleB
		vehicleB.SLIGWOLF_Connected[DirB] = vehicleA

		if isfunction(self.OnConnectTrailer) then
			self:OnConnectTrailer(vehicleA, vehicleB, DirA)
			self:OnConnectTrailer(vehicleB, vehicleA, DirB)
		end
	end

	ent.OnConnectionCheck = function(ConA, ConB)
		local vehicleA = LIBEntities.GetSuperParent(ConA)
		local vehicleB = LIBEntities.GetSuperParent(ConB)
		if not IsValid(vehicleA) then return end
		if not IsValid(vehicleB) then return end

		local DirA = ConA.sligwolf_connectorDirection
		local DirB = ConB.sligwolf_connectorDirection

		vehicleA.SLIGWOLF_Connected = vehicleA.SLIGWOLF_Connected or {}
		vehicleB.SLIGWOLF_Connected = vehicleB.SLIGWOLF_Connected or {}

		if not IsValid(vehicleA.SLIGWOLF_Connected[DirA]) then return false end
		if not IsValid(vehicleB.SLIGWOLF_Connected[DirB]) then return false end

		if vehicleA.SLIGWOLF_Connected[DirA] ~= vehicleB then return false end
		if vehicleB.SLIGWOLF_Connected[DirB] ~= vehicleA then return false end

		return true
	end

	ent:SetType(connectortype)
	ent:SetGender(gender)
	ent.searchRadius = searchRadius

	self:EntityTimerOnce(ent, "Auto_Connect_Trailers", 0.1, function(f_ent)
		LIBCoupling.AutoConnectVehicles(f_ent)
	end)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleConnectorButton(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local inVehicle = component.inVehicle

	local ent = self:MakeEntEnsured(class or "sligwolf_button", ply, parent, "ConnectorButton_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.SetupChildEntity(ent, parent, component.collision, attachment)

	ent.sligwolf_connectorDirection = name

	ent.sligwolf_noPickup = true
	ent:SetNWBool("sligwolf_noPickup", true)

	ent.sligwolf_inVehicle = inVehicle
	ent.SLIGWOLF_Buttonfunc = function(...)
		return LIBCoupling.CouplingMechanism(...)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleButton(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local inVehicle = component.inVehicle
	local func = component.func

	if not isfunction(func) then
		error("component.func is not a function!")
		return
	end

	local ent = self:MakeEntEnsured(class or "sligwolf_button", ply, parent, "Button_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.SetupChildEntity(ent, parent, component.collision, attachment)

	ent.sligwolf_noPickup = true
	ent:SetNWBool("sligwolf_noPickup", true)

	ent.sligwolf_inVehicle = inVehicle
	ent.SLIGWOLF_Buttonfunc = function(...)
		return func(...)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleSmoke(parent, component, ply, superparent)
	if not ProceedVehicleSetUp(parent, component) then return end

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local color = GetColor(superparent, component.color)
	local spawnTime = component.spawnTime
	local velocity = component.velocity
	local startSize = component.startSize
	local endSize = component.endSize
	local lifeTime = component.lifeTime
	local dieTime = component.dieTime
	local startAlpha = component.startAlpha
	local endAlpha = component.endAlpha
	local selfAttachment = component.selfAttachment

	local ent = self:MakeEntEnsured(class or "sligwolf_particle", ply, parent, "Smoke_" .. name)
	if not IsValid(ent) then return end

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)

	ent:Spawn()
	ent:Activate()

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment) then
		self:RemoveFaultyEntites(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	ent:AttachToEnt(parent, attachment)
	ent:Set_SpawnTime(spawnTime)
	ent:Set_Velocity(velocity)
	ent:SetColor(color)
	ent:Set_StartSize(startSize)
	ent:Set_EndSize(endSize)
	ent:Set_LifeTime(lifeTime)
	ent:Set_DieTime(dieTime)
	ent:Set_StartAlpha(startAlpha)
	ent:Set_EndAlpha(endAlpha)

	ent.sligwolf_blockedprop = true
	ent:SetNWBool("sligwolf_blockedprop", true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleLight(parent, component, ply, superparent)
	if not ProceedVehicleSetUp(parent, component) then return end

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local fov = component.fov
	local farZ = component.farZ
	local color = GetColor(superparent, component.color)
	local shadowRenderDist = component.shadowRenderDist
	local selfAttachment = component.selfAttachment

	local ent = self:MakeEntEnsured(class or "sligwolf_light_cone", ply, parent, "Light_" .. name)
	if not IsValid(ent) then return end

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)

	ent:Spawn()
	ent:Activate()

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment) then
		self:RemoveFaultyEntites(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	ent:AttachToEnt(parent, attachment)
	ent:Set_FOV(fov)
	ent:Set_FarZ(farZ)
	ent:SetColor(color)
	ent:Set_ShadowRenderDist(shadowRenderDist)

	ent.sligwolf_blockedprop = true
	ent:SetNWBool("sligwolf_blockedprop", true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleGlow(parent, component, ply, superparent)
	if not ProceedVehicleSetUp(parent, component) then return end

	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local keyValues = component.keyValues
	local inputFires = component.inputFires
	local color = GetColor(superparent, component.color)
	local size = component.size
	local enlarge = component.enlarge
	local count = component.count
	local alphaReduce = component.alphaReduce
	local selfAttachment = component.selfAttachment

	local ent = self:MakeEntEnsured(class or "sligwolf_glow", ply, parent, "Glow_" .. name)
	if not IsValid(ent) then return end

	SetPartKeyValues(ent, keyValues)
	SetPartInputFire(ent, inputFires)

	ent:Spawn()
	ent:Activate()

	if not LIBPosition.MountToAttachment(parent, ent, attachment, selfAttachment) then
		self:RemoveFaultyEntites(
			{parent, ent},
			"Couldn't attach entities %s <===> %s. Attachments %s <===> %s. Removing entities.",
			ent,
			parent,
			tostring(selfAttachment or "<origin>"),
			tostring(attachment or "<origin>")
		)

		return
	end

	ent:SetColor(color)
	ent:AttachToEnt(parent, attachment)
	ent:Set_Size(size)
	ent:Set_Enlarge(enlarge)
	ent:Set_Count(count)
	ent:Set_Alpha_Reduce(alphaReduce)
	ent:TurnOn(false)

	ent.sligwolf_blockedprop = true
	ent:SetNWBool("sligwolf_blockedprop", true)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehiclePod(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local boneMerge = component.boneMerge

	local ent = self:MakeEntEnsured("prop_vehicle_prisoner_pod", ply, parent, "Seat_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	LIBEntities.SetupChildEntity(ent, parent, component.collision, attachment)

	ent.sligwolf_vehicle = true
	ent.sligwolf_vehiclePod = true

	LIBPhysics.InitializeAsPhysEntity(ent)

	ent.sligwolf_ExitVectors = component.exitVectors

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end


	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleAnimatedWheel(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local size = component.size
	local restrate = component.restrate
	local boneMerge = component.boneMerge

	local ent = self:MakeEntEnsured(class or "sligwolf_wheel", ply, parent, "Wheel_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	ent:SetSize(size)
	ent:SetRestRate(restrate)
	ent:SetMessureEntity(parent)
	ent:AttachToEnt(parent, attachment)

	if boneMerge then
		ent:AddEffects(EF_BONEMERGE)
	end

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleDisplay(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local class = component.class
	local scale = component.scale
	local functionName = component.functionName

	local ent = self:MakeEntEnsured(class or "sligwolf_display", ply, parent, "Display_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)
	ent:SetDisplayOriginName("displaypos01")
	ent:AttachToEnt(parent, attachment)
	ent:TurnOn(true)
	ent:Set_Scale(scale)
	ent:SetDisplayFunctionName(functionName)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleBendi(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local parentNameFront = component.parentNameFront
	local parentNameRear = component.parentNameRear
	local parentFront = parent
	local parentRear = parent

	if parentNameFront ~= "" then
		parentFront = LIBEntities.GetChildFromPath(parent, parentNameFront)
	end

	if parentNameRear ~= "" then
		parentRear = LIBEntities.GetChildFromPath(parent, parentNameRear)
	end

	local ent = self:MakeEntEnsured("prop_ragdoll", ply, parent, "Bendi_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)

	LIBEntities.RemoveEntitiesOnDelete(parentFront, {parentRear, ent})
	LIBEntities.RemoveEntitiesOnDelete(parentRear, {parentFront, ent})

	local WD1 = self:CreateConstraint(ent, parentFront, "Weld", {
		bone1 = 1,
		bone2 = 0,
		forcelimit = 0,
		nocollide = true,
	})

	if not IsValid(WD1) then
		LIBEntities.RemoveEntites({ent, parentFront, parentRear})
		return
	end

	parent.sligwolf_constraintWeld1 = WD1

	local WD2 = self:CreateConstraint(ent, parentRear, "Weld", {
		bone1 = 0,
		bone2 = 0,
		forcelimit = 0,
		nocollide = true,
	})

	if not IsValid(WD2) then
		LIBEntities.RemoveEntites({ent, parentFront, parentRear})
		return
	end

	parent.sligwolf_constraintWeld2 = WD2

	LIBPhysics.InitializeAsPhysEntity(ent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicle(ent, parent, component, attachment, superparent)
	self:SetPartValues(ent, parent, component, attachment, superparent)

	ent.sligwolf_vehicle = true

	LIBPhysics.InitializeAsPhysEntity(ent)

	ent.sligwolf_ExitVectors = component.exitVectors
end

function SLIGWOLF_ADDON:SetUpVehicleJeep(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name

	local ent = self:MakeEntEnsured("prop_vehicle_jeep", ply, parent, "Jeep_" .. name)
	if not IsValid(ent) then return end

	self:SetUpVehicle(ent, parent, component, attachment, superparent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleAirboat(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name

	local ent = self:MakeEntEnsured("prop_vehicle_airboat", ply, parent, "Airboat_" .. name)
	if not IsValid(ent) then return end

	self:SetUpVehicle(ent, parent, component, attachment, superparent)

	return ent
end

function SLIGWOLF_ADDON:SetUpVehicleHoverball(parent, component, ply, superparent)
	local attachment = self:CheckToProceedToCreateEnt(parent, component)
	if not attachment then return end

	local name = component.name
	local speed = component.speed
	local airResistance = component.airResistance
	local strength = component.strength
	local numDown = component.numDown
	local numUp = component.numUp
	local numBackDown = component.numBackDown
	local numBackUp = component.numBackUp

	local ent = self:MakeEntEnsured("gmod_hoverball", ply, parent, "Hoverball_" .. name)
	if not IsValid(ent) then return end

	self:SetPartValues(ent, parent, component, attachment, superparent)

	LIBPhysics.InitializeAsPhysEntity(ent)

	ent:SetSpeed(speed)
	ent:SetAirResistance(airResistance)
	ent:SetStrength(strength)
	ent.NumDown = numpad.OnDown(ply, numDown, "Hoverball_Up", ent, true)
	ent.NumUp = numpad.OnUp(ply, numUp, "Hoverball_Up", ent, false)
	ent.NumBackDown = numpad.OnDown(ply, numBackDown, "Hoverball_Down", ent, true)
	ent.NumBackUp = numpad.OnUp(ply, numBackUp, "Hoverball_Down", ent, false)

	return ent
end

return true

