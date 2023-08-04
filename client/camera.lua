function CreateCamera(coords,options)
    local cam = SetFreecamActive(true,coords,options)
    StartFreecamThread()
    return cam
end

--[[ Credits to txAdmin, modified by me to be compatible with the script ]]--

local rad = math.rad
local sin = math.sin
local cos = math.cos
local min = math.min
local max = math.max
local type = type

function table.copy(x)
    local copy = {}
    for k, v in pairs(x) do
        if type(v) == 'table' then
            copy[k] = table.copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function protect(t)
    local fn = function (_, k)
        error('Key `' .. tostring(k) .. '` is not supported.')
    end
  
    return setmetatable(t, {
        __index = fn,
        __newindex = fn
    })
  end
  
  function CreateGamepadMetatable(keyboard, gamepad)
    return setmetatable({}, {
        __index = function (t, k)
            local src = IsGamepadControl() and gamepad or keyboard
            return src[k]
        end
    })
end

function Clamp(x, _min, _max)
    return min(max(x, _min), _max)
end
  
function ClampCameraRotation(rotX, rotY, rotZ)
    local x = Clamp(rotX, -90.0, 90.0)
    local y = rotY % 360
    local z = rotZ % 360
    return x, y, z
end
  
function IsGamepadControl()
    return not IsInputDisabled(2)
end

function GetSmartControlNormal(control)
    if type(control) == 'table' then
        local normal1 = GetDisabledControlNormal(0, control[1])
        local normal2 = GetDisabledControlNormal(0, control[2])
        return normal1 - normal2
    end
  
    return GetDisabledControlNormal(0, control)
end

function EulerToMatrix(rotX, rotY, rotZ)
    local radX = rad(rotX)
    local radY = rad(rotY)
    local radZ = rad(rotZ)
  
    local sinX = sin(radX)
    local sinY = sin(radY)
    local sinZ = sin(radZ)
    local cosX = cos(radX)
    local cosY = cos(radY)
    local cosZ = cos(radZ)
  
    local vecX = {}
    local vecY = {}
    local vecZ = {}
  
    vecX.x = cosY * cosZ
    vecX.y = cosY * sinZ
    vecX.z = -sinY
  
    vecY.x = cosZ * sinX * sinY - cosX * sinZ
    vecY.y = cosX * cosZ - sinX * sinY * sinZ
    vecY.z = cosY * sinX
  
    vecZ.x = -cosX * cosZ * sinY + sinX * sinZ
    vecZ.y = -cosZ * sinX + cosX * sinY * sinZ
    vecZ.z = cosX * cosY
  
    vecX = vector3(vecX.x, vecX.y, vecX.z)
    vecY = vector3(vecY.x, vecY.y, vecY.z)
    vecZ = vector3(vecZ.x, vecZ.y, vecZ.z)
  
    return vecX, vecY, vecZ
end  

local INPUT_LOOK_LR = 1
local INPUT_LOOK_UD = 2
local INPUT_CHARACTER_WHEEL = 19
local INPUT_SPRINT = 21
local INPUT_MOVE_UD = 31
local INPUT_MOVE_LR = 30
local INPUT_VEH_ACCELERATE = 71
local INPUT_VEH_BRAKE = 72
local INPUT_PARACHUTE_BRAKE_LEFT = 152
local INPUT_PARACHUTE_BRAKE_RIGHT = 153
local INPUT_FRONTEND_RRIGHT = 194
local INPUT_FRONTEND_RDOWN = 191

--------------------------------------------------------------------------------

local BASE_CONTROL_MAPPING = protect({
  -- Rotation
  LOOK_X = INPUT_LOOK_LR,
  LOOK_Y = INPUT_LOOK_UD,

  -- Position
  MOVE_X = INPUT_MOVE_LR,
  MOVE_Y = INPUT_MOVE_UD,
  MOVE_Z = { INPUT_PARACHUTE_BRAKE_LEFT, INPUT_PARACHUTE_BRAKE_RIGHT },

  -- Multiplier
  MOVE_FAST = INPUT_SPRINT,
  MOVE_SLOW = INPUT_CHARACTER_WHEEL,

  -- Control
  ACCEPT = INPUT_FRONTEND_RDOWN,
  BACKSPACE = INPUT_FRONTEND_RRIGHT
})

--------------------------------------------------------------------------------

local BASE_CONTROL_SETTINGS = protect({
  -- Rotation
  LOOK_SENSITIVITY_X = 5,
  LOOK_SENSITIVITY_Y = 5,

  -- Position
  BASE_MOVE_MULTIPLIER = 0.85,
  FAST_MOVE_MULTIPLIER = 6,
  SLOW_MOVE_MULTIPLIER = 6,
})

--------------------------------------------------------------------------------

local BASE_CAMERA_SETTINGS = protect({
  --Camera
  FOV = 50.0,

  -- On enable/disable
  ENABLE_EASING = true,
  EASING_DURATION = 250,

  -- Keep position/rotation
  KEEP_POSITION = false,
  KEEP_ROTATION = false
})

--------------------------------------------------------------------------------

_G.KEYBOARD_CONTROL_MAPPING = table.copy(BASE_CONTROL_MAPPING)
_G.GAMEPAD_CONTROL_MAPPING = table.copy(BASE_CONTROL_MAPPING)

-- Swap up/down movement (LB for down, RB for up)
_G.GAMEPAD_CONTROL_MAPPING.MOVE_Z[1] = INPUT_PARACHUTE_BRAKE_LEFT
_G.GAMEPAD_CONTROL_MAPPING.MOVE_Z[2] = INPUT_PARACHUTE_BRAKE_RIGHT

-- Use LT and RT for speed
_G.GAMEPAD_CONTROL_MAPPING.MOVE_FAST = INPUT_VEH_ACCELERATE
_G.GAMEPAD_CONTROL_MAPPING.MOVE_SLOW = INPUT_VEH_BRAKE

protect(_G.KEYBOARD_CONTROL_MAPPING)
protect(_G.GAMEPAD_CONTROL_MAPPING)

--------------------------------------------------------------------------------

_G.KEYBOARD_CONTROL_SETTINGS = table.copy(BASE_CONTROL_SETTINGS)
_G.GAMEPAD_CONTROL_SETTINGS = table.copy(BASE_CONTROL_SETTINGS)

-- Gamepad sensitivity can be reduced by BASE.
_G.GAMEPAD_CONTROL_SETTINGS.LOOK_SENSITIVITY_X = 2
_G.GAMEPAD_CONTROL_SETTINGS.LOOK_SENSITIVITY_Y = 2

protect(_G.KEYBOARD_CONTROL_SETTINGS)
protect(_G.GAMEPAD_CONTROL_SETTINGS)

--------------------------------------------------------------------------------

_G.CAMERA_SETTINGS = table.copy(BASE_CAMERA_SETTINGS)
protect(_G.CAMERA_SETTINGS)

--------------------------------------------------------------------------------

-- Create some convenient variables.
-- Allows us to access controls and config without a gamepad switch.
_G.CONTROL_MAPPING  = CreateGamepadMetatable(_G.KEYBOARD_CONTROL_MAPPING,  _G.GAMEPAD_CONTROL_MAPPING)
_G.CONTROL_SETTINGS = CreateGamepadMetatable(_G.KEYBOARD_CONTROL_SETTINGS, _G.GAMEPAD_CONTROL_SETTINGS)

local floor = math.floor
local SetCamRot = SetCamRot
local IsCamActive = IsCamActive
local SetCamCoord = SetCamCoord
local LoadInterior = LoadInterior
local SetFocusArea = SetFocusArea
local LockMinimapAngle = LockMinimapAngle
local GetInteriorAtCoords = GetInteriorAtCoords
local LockMinimapPosition = LockMinimapPosition

local _internal_camera = nil
local _internal_isFrozen = false

local _internal_pos = nil
local _internal_rot = nil
local _internal_fov = nil
local _internal_vecX = nil
local _internal_vecY = nil
local _internal_vecZ = nil
local _internal_acc = nil
local _internal_bac = nil
local _internal_onupdate = nil

local Wait = Citizen.Wait
local vector3 = vector3
local IsPauseMenuActive = IsPauseMenuActive
local GetSmartControlNormal = GetSmartControlNormal

local SETTINGS = _G.CONTROL_SETTINGS
local CONTROLS = _G.CONTROL_MAPPING

local function GetSpeedMultiplier()
    local fastNormal = GetSmartControlNormal(CONTROLS.MOVE_FAST)
    local slowNormal = GetSmartControlNormal(CONTROLS.MOVE_SLOW)
  
    local baseSpeed = SETTINGS.BASE_MOVE_MULTIPLIER
    local fastSpeed = 1 + ((SETTINGS.FAST_MOVE_MULTIPLIER - 1) * fastNormal)
    local slowSpeed = 1 + ((SETTINGS.SLOW_MOVE_MULTIPLIER - 1) * slowNormal)
  
    local frameMultiplier = GetFrameTime() * 60
    local speedMultiplier = baseSpeed * fastSpeed / slowSpeed
  
    return speedMultiplier * frameMultiplier
end
  
local function UpdateCamera()
    if not IsFreecamActive() or IsPauseMenuActive() then
        return
    end
    if IsControlJustPressed(0,CONTROLS.ACCEPT) then
        if _internal_acc then
            _internal_acc(_internal_camera)
        end
        SetFreecamActive(false)
    end

    if IsControlJustPressed(0, CONTROLS.BACKSPACE) then
        if _internal_bac then
            _internal_bac(_internal_camera)
        end
        SetFreecamActive(false)
    end

    local vecX, vecY = GetFreecamMatrix()
    local vecZ = vector3(0, 0, 1)

    local pos = GetFreecamPosition()
    local rot = GetFreecamRotation()
    local sPos = vector3(pos.x, pos.y, pos.z)
    local sRot = vector3(rot.x, rot.y, rot.z)

    -- Get speed multiplier for movement
    local speedMultiplier = GetSpeedMultiplier()

    -- Get rotation input
    local lookX = GetSmartControlNormal(CONTROLS.LOOK_X)
    local lookY = GetSmartControlNormal(CONTROLS.LOOK_Y)

    -- Get position input
    local moveX = GetSmartControlNormal(CONTROLS.MOVE_X)
    local moveY = GetSmartControlNormal(CONTROLS.MOVE_Y)
    local moveZ = GetSmartControlNormal(CONTROLS.MOVE_Z)

    -- Calculate new rotation.
    local rotX = rot.x + (-lookY * SETTINGS.LOOK_SENSITIVITY_X)
    local rotZ = rot.z + (-lookX * SETTINGS.LOOK_SENSITIVITY_Y)
    local rotY = rot.y

    -- Adjust position relative to camera rotation.
    pos = pos + (vecX *  moveX * speedMultiplier)
    pos = pos + (vecY * -moveY * speedMultiplier)
    pos = pos + (vecZ *  moveZ * speedMultiplier)

    -- Adjust new rotation
    rot = vector3(rotX, rotY, rotZ)

    -- Update camera
    SetFreecamPosition(pos.x, pos.y, pos.z)
    SetFreecamRotation(rot.x, rot.y, rot.z)
    if _internal_onupdate and #(rot-sRot)+#(pos-sPos)~=0 then
        _internal_onupdate(_internal_camera)
    end
    return pos, rotZ
end

function StartFreecamThread()
    Citizen.CreateThread(function ()
        local ped = PlayerPedId()
        local initialPos = GetEntityCoords(ped)
        SetFreecamPosition(initialPos[1], initialPos[2], initialPos[3])
        while IsFreecamActive() do
            SetEntityLocallyInvisible(ped,true)
            UpdateCamera()
            Wait(10)
        end
    end)
end

--------------------------------------------------------------------------------

function GetInitialCameraPosition()
    if _G.CAMERA_SETTINGS.KEEP_POSITION and _internal_pos then
        return _internal_pos
    end

    return GetGameplayCamCoord()
end

function GetInitialCameraRotation()
    if _G.CAMERA_SETTINGS.KEEP_ROTATION and _internal_rot then
        return _internal_rot
    end

    local rot = GetGameplayCamRot()
    return vector3(rot.x, 0.0, rot.z)
end

--------------------------------------------------------------------------------

function IsFreecamFrozen()
    return _internal_isFrozen
end

function SetFreecamFrozen(frozen)
    local frozen = frozen == true
    _internal_isFrozen = frozen
end

--------------------------------------------------------------------------------

function GetFreecamPosition()
    return _internal_pos
end

function SetFreecamPosition(x, y, z)
    local pos = vector3(x, y, z)
    local int = GetInteriorAtCoords(pos)

    LoadInterior(int)
    SetFocusArea(pos)
    LockMinimapPosition(x, y)
    SetCamCoord(_internal_camera, pos)

    _internal_pos = pos
end

--------------------------------------------------------------------------------

function GetFreecamRotation()
    return _internal_rot
end


function SetFreecamRotation(x, y, z)
    local rotX, rotY, rotZ = ClampCameraRotation(x, y, z)
    local vecX, vecY, vecZ = EulerToMatrix(rotX, rotY, rotZ)
    local rot = vector3(rotX, rotY, rotZ)

    LockMinimapAngle(floor(rotZ))
    SetCamRot(_internal_camera, rot)

    _internal_rot  = rot
    _internal_vecX = vecX
    _internal_vecY = vecY
    _internal_vecZ = vecZ
end

--------------------------------------------------------------------------------

function GetFreecamFov()
    return _internal_fov
end

function SetFreecamFov(fov)
    local fov = Clamp(fov, 0.0, 90.0)
    SetCamFov(_internal_camera, fov)
    _internal_fov = fov
end

--------------------------------------------------------------------------------

function GetFreecamMatrix()
    return _internal_vecX,
            _internal_vecY,
            _internal_vecZ,
            _internal_pos
end

function GetFreecamTarget(distance)
    local target = _internal_pos + (_internal_vecY * distance)
    return target
end

--------------------------------------------------------------------------------

function IsFreecamActive()
    return IsCamActive(_internal_camera) == 1
end

function SetFreecamActive(active, coords, options)
    if active == IsFreecamActive() then
        return
    end
    options = options or {}
    local enableEasing = _G.CAMERA_SETTINGS.ENABLE_EASING
    local easingDuration = _G.CAMERA_SETTINGS.EASING_DURATION

    if active then
        _internal_acc = nil
        _internal_bac = nil
        _internal_onupdate = nil
        local pos = coords or GetInitialCameraPosition()
        local rot = GetInitialCameraRotation()

        _internal_camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        _internal_acc = options.accept
        _internal_bac = options.destructor
        _internal_onupdate = options.onupdate

        SetFreecamFov(_G.CAMERA_SETTINGS.FOV)
        SetFreecamPosition(pos.x, pos.y, pos.z)
        SetFreecamRotation(rot.x, rot.y, rot.z)
    else
        DestroyCam(_internal_camera)
        ClearFocus()
        UnlockMinimapPosition()
        UnlockMinimapAngle()
    end

    RenderScriptCams(active, enableEasing, easingDuration, true, true)
    return _internal_camera or 0
end