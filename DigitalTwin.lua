-- TODO: Change this to your Application ID for The Things Network
-- (Must have permission to Read Application Traffic)
local TTN_APPLICATION_ID = "YOUR_APPLICATION_ID"

-- TODO: Change this to your API Key for The Things Network
local TTN_API_KEY = "YOUR_API_KEY"

-- TODO: Change this to your region-specific URL for The Things Network
local TTN_URL = "https://au1.cloud.thethings.network/api/v3/as/applications/" .. TTN_APPLICATION_ID .. "/packages/storage/uplink_message?limit=1&order=-received_at"

-- Load the Base64 and CBOR ModuleScripts from ServerStorage
local ServerStorage = game:GetService("ServerStorage")
local base64 = require(ServerStorage.Base64)
local cbor   = require(ServerStorage.Cbor)

-- Get the HttpService for making HTTP Requests
local HttpService = game:GetService("HttpService")

-- Fetch Sensor Data from The Things Network (LoRa) as a Lua Table
local function getSensorData()
	-- HTTPS JSON Response from The Things Network
	local response = nil
	-- Lua Table parsed from JSON response
	local data = nil
	-- Message Payload from the Lua Table (encoded with Base64)
	local frmPayload = nil
	-- Message Payload after Base64 Decoding
	local payload = nil
	-- Lua Table of Sensor Data after CBOR Decoding
	local sensorData = nil
	
	-- Set the API Key in the HTTP Request Header	
	local headers = {
		["Authorization"] = "Bearer " .. TTN_API_KEY,
	}

	-- Wrap with pcall in case something goes wrong
	pcall(function ()
		-- Fetch the data from The Things Network, no caching
		response = HttpService:GetAsync(TTN_URL, false, headers)
		
		-- Decode the JSON response into a Lua Table
		data = HttpService:JSONDecode(response)
		
		-- Get the Message Payload. If missing, pcall will catch the error.
		frmPayload = data.result.uplink_message.frm_payload
		
		-- Base64 Decode the Message Payload
		payload = base64.decode(frmPayload)

		-- Decode the CBOR Map to get Sensor Data
		sensorData = cbor.decode(payload)
	end)	
	
	-- Show the error
	if response == nil then
		print("Error returned by The Things Network")
	elseif data == nil then
		print("Failed to parse JSON response from The Things Network")
	elseif frmPayload == nil then
		print("Missing message payload")
	elseif payload == nil then
		print("Base64 decoding failed")
	elseif sensorData == nil then
		print("CBOR decoding failed")
	end

	-- sensorData will be nil if our request failed or JSON failed to parse
	-- or Message Payload missing or Base64 / CBOR decoding failed
	return sensorData
end

-- Fetch the Sensor Data from The Things Network (LoRa)
local sensorData = getSensorData()

-- Show the Temperature
if sensorData then
	print("Temperature:")
	print(sensorData.t)
else
	print("Failed to get sensor data")
end

-- Test Base64 Decode the Message Payload
--payload = base64.decode('omF0GQTUYWwZCSs=')
--print("payload:")
--print(payload)

-- Test Decode CBOR Map
--sensorData = cbor.decode(payload)
--print("sensorData:")
--print(sensorData)

-- Dump the properties of the Particle Emitter
local function dumpParticleEmitter(emitter)
	print("Acceleration:")
	print(emitter.Acceleration)
	print("Color:")
	print(emitter.Color)
	print("Drag:")
	print(emitter.Drag)
	print("EmissionDirection:")
	print(emitter.EmissionDirection)
	print("Lifetime:")
	print(emitter.Lifetime)
	print("LightEmission:")
	print(emitter.LightEmission)
	print("LightInfluence:")
	print(emitter.LightInfluence)
	print("Orientation:")
	print(emitter.Orientation)
	print("Rate:")
	print(emitter.Rate)
	print("Rotation:")
	print(emitter.Rotation)
	print("RotSpeed:")
	print(emitter.RotSpeed)
	print("Size:")
	print(emitter.Size)
	print("Speed:")
	print(emitter.Speed)
	print("SpreadAngle:")
	print(emitter.SpreadAngle)
	print("Texture:")
	print(emitter.Texture)
	print("TimeScale:")
	print(emitter.TimeScale)
	print("Transparency:")
	print(emitter.Transparency)
	print("VelocityInheritance:")
	print(emitter.VelocityInheritance)
	print("ZOffset:")
	print(emitter.ZOffset)
end

-- Dump the 3 Particle Emitters: Cold, Normal, Hot
--print("COLD")
--dumpParticleEmitter(script.Parent.Cold)
--print("NORMAL")
--dumpParticleEmitter(script.Parent.Normal)
--print("HOT")
--dumpParticleEmitter(script.Parent.Hot)

-- Create the Particle Emitter for Normal Temperature
-- Based on https://developer.roblox.com/en-us/api-reference/class/ParticleEmitter
local function createParticleEmitter()
	local emitter = Instance.new("ParticleEmitter")
	-- Number of particles = Rate * Lifetime
	emitter.Rate = 20 -- Particles per second
	emitter.Lifetime = NumberRange.new(5, 10) -- How long the particles should be alive (min, max)
	emitter.Enabled = true 

	-- Texture for the particles: "star sparkle particle" by @Vupatu
	-- https://www.roblox.com/library/6490035152/star-sparkle-particle
	emitter.Texture = "rbxassetid://6490035152"

	-- For Color, build a ColorSequence using ColorSequenceKeypoint
	local colorKeypoints = {
		-- API: ColorSequenceKeypoint.new(time, color)
		ColorSequenceKeypoint.new( 0.0, Color3.new(0.3, 0.6, 0.0)),  -- At t=0: Green
		ColorSequenceKeypoint.new( 1.0, Color3.new(0.3, 0.6, 0.0))   -- At t=1: Green
	}
	emitter.Color = ColorSequence.new(colorKeypoints)

	-- For Transparency, build a NumberSequence using NumberSequenceKeypoint
	local numberKeypoints = {
		-- API: NumberSequenceKeypoint.new(time, size, envelop)
		NumberSequenceKeypoint.new( 0.0, 0.0);    -- At t=0, fully opaque
		NumberSequenceKeypoint.new( 1.0, 0.0);    -- At t=1, fully opaque
	}
	emitter.Transparency = NumberSequence.new(numberKeypoints)

	-- Light Emission and Influence
	emitter.LightEmission = 0 -- If 1: When particles overlap, multiply their color to be brighter
	emitter.LightInfluence = 1 -- If 0: Don't be affected by world lighting

	-- Speed properties
	emitter.EmissionDirection = Enum.NormalId.Top -- Emit towards top
	emitter.Speed = NumberRange.new(5.0, 5.0) -- Speed
	emitter.Drag = 10.0 -- Apply drag to particle motion
	emitter.VelocitySpread = NumberRange.new(0.0, 0.0)
	emitter.VelocityInheritance = 0 -- Don't inherit parent velocity
	emitter.Acceleration = Vector3.new(0.0, 0.0, 0.0)
	emitter.LockedToPart = false -- Don't lock the particles to the parent 
	emitter.SpreadAngle = Vector2.new(50.0, 50.0) -- Spread angle on X and Y

	-- Simulation properties
	local numberKeypoints2 = {
		NumberSequenceKeypoint.new(0.0, 0.2);  -- Size at t=0
		NumberSequenceKeypoint.new(1.0, 0.2); -- Size at t=1
	}
	emitter.Size = NumberSequence.new(numberKeypoints2)
	emitter.ZOffset = 0.0 -- Render in front or behind the actual position
	emitter.Rotation = NumberRange.new(0.0, 0.0) -- Rotation
	emitter.RotSpeed = NumberRange.new(0.0) -- Do not rotate during simulation
	
	-- Add the emitter to our Part
	emitter.Parent = script.Parent
	return emitter
end

-- Create a Particle Emitter for Normal Temperature
local emitter = createParticleEmitter()
