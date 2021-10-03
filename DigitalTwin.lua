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
