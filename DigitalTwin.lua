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
		
	-- End of pcall block
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

-- Create the Particle Emitter for Normal Temperature
-- Based on https://developer.roblox.com/en-us/api-reference/class/ParticleEmitter
local function createParticleEmitter()
	local emitter = Instance.new("ParticleEmitter")
	-- Number of particles = Rate * Lifetime
	emitter.Rate = 20 -- Particles per second
	emitter.Lifetime = NumberRange.new(5, 10) -- How long the particles should be alive (min, max)
	emitter.Enabled = true 

	-- Visual properties
	-- Texture for the particles: "star sparkle particle" by @Vupatu
	-- https://www.roblox.com/library/6490035152/star-sparkle-particle
	emitter.Texture = "rbxassetid://6490035152"

	-- For Color, build a ColorSequence using ColorSequenceKeypoint
	local colorKeypoints = {
		-- API: ColorSequenceKeypoint.new(time, color)
		ColorSequenceKeypoint.new( 0.0, Color3.new(0.3, 0.6, 0.0)),  -- At time=0: Green
		ColorSequenceKeypoint.new( 1.0, Color3.new(0.3, 0.6, 0.0))   -- At time=1: Green
	}
	emitter.Color = ColorSequence.new(colorKeypoints)

	-- For Transparency, build a NumberSequence using NumberSequenceKeypoint
	local numberKeypoints = {
		-- API: NumberSequenceKeypoint.new(time, size, envelop)
		NumberSequenceKeypoint.new( 0.0, 0.0);    -- At time=0, fully opaque
		NumberSequenceKeypoint.new( 1.0, 0.0);    -- At time=1, fully opaque
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
		NumberSequenceKeypoint.new(0.0, 0.2);  -- Size at time=0
		NumberSequenceKeypoint.new(1.0, 0.2);  -- Size at time=1
	}
	emitter.Size = NumberSequence.new(numberKeypoints2)
	emitter.ZOffset = 0.0 -- Render in front or behind the actual position
	emitter.Rotation = NumberRange.new(0.0, 0.0) -- Rotation
	emitter.RotSpeed = NumberRange.new(0.0) -- Do not rotate during simulation
	
	-- Add the emitter to our Part
	emitter.Parent = script.Parent
	return emitter
end

-- Minimum, Maximum and Mid values for Temperature (t) that will be interpolated
local T_MIN = 0
local T_MAX = 10000
local T_MID = (T_MIN + T_MAX) / 2

-- Linear Interpolate the value of y, given that
-- (1) x ranges from T_MIN to T_MAX
-- (2) When x=T_MIN, y=yMin
-- (3) When x=T_MID, y=yMid
-- (4) When x=T_MAX, y=yMax
local function lin(x, yMin, yMid, yMax)
	local y
	if x < T_MID then
		-- Interpolate between T_MIN and T_MID
		y = yMin + (yMid - yMin) * (x - T_MIN) / (T_MID - T_MIN)
	else
		-- Interpolate between T_MID and T_MAX
		y = yMid + (yMax - yMid) * (x - T_MID) / (T_MAX - T_MID)
	end	
	-- Force y to be between yMin and yMax
	if y < math.min(yMin, yMid, yMax) then
		y = math.min(yMin, yMid, yMax)
	end
	if y > math.max(yMin, yMid, yMax) then
		y = math.max(yMin, yMid, yMax)
	end
	return y
end

-- Update the Particle Emitter based on the Temperature t.
-- t ranges from T_MIN to T_MAX.
local function updateParticleEmitter(emitter, t)
	-- Interpolate Color: (Red, Green, Blue)
	-- COLD:   0.3, 1.0, 1.0
	-- NORMAL: 0.3, 0.6, 0.0
	-- HOT:    1.0, 0.3, 0.0
	local color = Color3.new(
		lin(t, 0.3, 0.3, 1.0),  -- Red
		lin(t, 1.0, 0.6, 0.3),  -- Green
		lin(t, 1.0, 0.0, 0.0)   -- Blue
	)
	local colorKeypoints = {
		-- API: ColorSequenceKeypoint.new(time, color)
		ColorSequenceKeypoint.new(0.0, color),  -- At time=0
		ColorSequenceKeypoint.new(1.0, color)   -- At time=1
	}
	emitter.Color = ColorSequence.new(colorKeypoints)

	-- Interpolate Drag:
	-- COLD:   5
	-- NORMAL: 10
	-- HOT:    0
	emitter.Drag = lin(t, 5.0, 10.0, 0.0)

	-- Interpolate LightEmission: 
	-- COLD:   1
	-- NORMAL: 0
	-- HOT:    0
	emitter.LightEmission = lin(t, 1.0, 0.0, 0.0)

	-- Interpolate LightInfluence: 
	-- COLD:   1
	-- NORMAL: 1
	-- HOT:    0
	emitter.LightInfluence = lin(t, 1.0, 1.0, 0.0)

	-- Interpolate Rotation: 
	-- COLD:   0.0 180.0 
	-- NORMAL: 0.0 0.0 
	-- HOT:    0.0 0.0 
	local rotation = lin(t, 180.0, 0.0, 0.0)
	emitter.Rotation = NumberRange.new(0.0, rotation) -- Rotation

	-- Interpolate RotSpeed: 
	-- COLD:   -170.0 
	-- NORMAL: 0.0 
	-- HOT:    0.0 
	local rotSpeed = lin(t, -170.0, 0.0, 0.0)
	emitter.RotSpeed = NumberRange.new(rotSpeed) -- Rotation speed

	-- Interpolate Size: 
	-- COLD:   1.0 
	-- NORMAL: 0.2 
	-- HOT:    0.4
	local size = lin(t, 1.0, 0.2, 0.4)
	local numberKeypoints2 = {
		NumberSequenceKeypoint.new(0.0, size);  -- Size at time=0
		NumberSequenceKeypoint.new(1.0, size);  -- Size at time=1
	}
	emitter.Size = NumberSequence.new(numberKeypoints2)

	-- Interpolate Speed: 
	-- COLD:   0.0 
	-- NORMAL: 5.0 
	-- HOT:    1.0
	local speed = lin(t, 0.0, 5.0, 1.0)
	emitter.Speed = NumberRange.new(speed, speed) -- Speed

	-- Interpolate SpreadAngle: 
	-- COLD:   10.0
	-- NORMAL: 50.0
	-- HOT:    50.0
	local spreadAngle = lin(t, 10.0, 50.0, 50.0)
	emitter.SpreadAngle = Vector2.new(spreadAngle, spreadAngle) -- Spread angle on X and Y
end

-- For Testing: Dump the properties of the Particle Emitter
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

-- Demo Mode if we don't have an IoT Device connected to The Things Network.
-- Gradually update our Particle Emitter for Temperature=10,000 to 0 and back to 10,000.
local function demoMode(emitter)
	-- Gradually update the emitter for Temperature=10,000 to 0
	for t = T_MAX, T_MIN, -600 do
		print(string.format("t: %d", t))
		updateParticleEmitter(emitter, t)
		wait(4)
	end
	
	-- Gradually update the emitter for Temperature=0 to 10,000
	for t = T_MIN, T_MAX, 600 do
		print(string.format("t: %d", t))
		updateParticleEmitter(emitter, t)
		wait(4)
	end
end

-- Main Function. Fetch and render the Sensor Data from The Things Network every 5 seconds.
-- If fetch failed, show Demo Mode.
local function main()	
	-- Create a Particle Emitter for Normal Temperature
	local emitter = createParticleEmitter()
	
	-- Loop forever fetching and rendering Sensor Data from The Things Network
	while true do
		-- Lua Table that will contain Sensor Data from The Things Network	
		local sensorData = nil

		-- Temperature from The Things Network. Ranges from 0 to 10,000.
		local t = nil

		-- If API Key for The Things Network is defined...
		if TTN_API_KEY ~= "YOUR_API_KEY" then
			-- Fetch the Sensor Data from The Things Network
			sensorData = getSensorData()	

			-- Get the Temperature if it exists
			if sensorData then
				t = sensorData.t
			end
		end

		-- If Temperature was successfully fetched from The Things Network...
		if t then
			-- Render the Temperature with our Particle Emitter
			print(string.format("t: %d", t))
			updateParticleEmitter(emitter, t)
		else
			-- Else render our Particle Emitter in Demo Mode
			print("Failed to get sensor data. Enter Demo Mode.")
			demoMode(emitter)
		end
		
		-- Sleep 5 seconds so we don't overwhelm The Things Network
		wait(5)		
	end
end

-- Start the Main Function
main()

-- For Testing: Base64 Decode for Message Payload
-- payload = base64.decode('omF0GQTUYWwZCSs=')
-- print("payload:")
-- print(payload)

-- For Testing: Decode CBOR Map
-- sensorData = cbor.decode(payload)
-- print("sensorData:")
-- print(sensorData)

-- For Testing: Dump the 3 Particle Emitters: Cold, Normal, Hot
-- print("COLD")
-- dumpParticleEmitter(script.Parent.Cold)
-- print("NORMAL")
-- dumpParticleEmitter(script.Parent.Normal)
-- print("HOT")
-- dumpParticleEmitter(script.Parent.Hot)
