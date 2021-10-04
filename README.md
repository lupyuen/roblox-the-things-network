# IoT Digital Twin with Roblox and The Things Network

Follow the updates on Twitter: https://twitter.com/MisterTechBlog/status/1443824711050301444

Let's connect Roblox to The Things Network (the public LoRa network)... And create an IoT Digital Twin for real-world objects...

![IoT Digital Twin with Roblox and The Things Network](https://lupyuen.github.io/images/digital-twin.jpg)

What's a "Digital Twin"? It's a Virtual Object that mirrors a Real-World Object through Sensors and Actuators.

In Roblox we shall call the HTTP + JSON API...

https://developer.roblox.com/en-us/api-reference/class/HttpService

To access the Live Sensor Data at The Things Network...

https://www.thethingsindustries.com/docs/integrations/storage/retrieve/

This will be useful for educating kids about IoT, by creating digital mirrors of real-world objects.

More about The Things Network...

-   ["The Things Network on PineDio Stack BL604 RISC-V Board"](https://lupyuen.github.io/articles/ttn)

# Fetch Sensor Data from The Things Network

The Things Network exposes an API (HTTP GET) to fetch the Uplink Messages transmitted by our IoT Device...

https://www.thethingsindustries.com/docs/integrations/storage/retrieve/

Here's the command to fetch the latest Uplink Message...

```bash
curl \
    -G "https://au1.cloud.thethings.network/api/v3/as/applications/$YOUR_APPLICATION_ID/packages/storage/uplink_message" \
    -H "Authorization: Bearer $YOUR_API_KEY" \
    -H "Accept: text/event-stream" \
    -d "limit=1" \
    -d "order=-received_at"
```

Which returns...

```json
{
    "result": {
        "end_device_ids": {
            "device_id": "eui-YOUR_DEVICE_EUI",
            "application_ids": {
                "application_id": "luppy-application"
            },
            "dev_eui": "YOUR_DEVICE_EUI",
            "dev_addr": "YOUR_DEVICE_ADDR"
        },
        "received_at": "2021-10-02T12:10:54.594006440Z",
        "uplink_message": {
            "f_port": 2,
            "f_cnt": 3,
            "frm_payload": "omF0GQTUYWwZCSs=",
            "rx_metadata": [
                {
                    "gateway_ids": {
                        "gateway_id": "luppy-wisgate-rak7248",
                        "eui": "YOUR_GATEWAY_EUI"
                    },
                    "time": "2021-10-02T13:04:34.552513Z",
                    "timestamp": 3576406949,
                    "rssi": -53,
                    "channel_rssi": -53,
                    "snr": 12.2,
                    "location": {
                        "latitude": 1.27125,
                        "longitude": 103.80795,
                        "altitude": 70,
                        "source": "SOURCE_REGISTRY"
                    },
                    "channel_index": 4
                }
            ],
            "settings": {
                "data_rate": {
                    "lora": {
                        "bandwidth": 125000,
                        "spreading_factor": 10
                    }
                },
                "data_rate_index": 2,
                "coding_rate": "4/5",
                "frequency": "922600000",
                "timestamp": 3576406949,
                "time": "2021-10-02T13:04:34.552513Z"
            },
            "received_at": "2021-10-02T12:10:54.385972437Z",
            "consumed_airtime": "0.370688s",
            "network_ids": {
                "net_id": "000013",
                "tenant_id": "ttn",
                "cluster_id": "ttn-au1"
            }
        }
    }
}
```

`result.uplink_message.frm_payload` contains the Sensor Data that we need, encoded with Base64 and CBOR...

```json
"frm_payload": "omF0GQTUYWwZCSs="
```

Our Sensor Data is encoded with [CBOR](https://en.wikipedia.org/wiki/CBOR) to keep the LoRa Packets small (max 12 bytes), due to the Fair Use Policy of The Things Network...

-   ["Fair Use of The Things Network"](https://lupyuen.github.io/articles/ttn#fair-use-of-the-things-network)

More about CBOR Encoding...

-   ["Encode Sensor Data with CBOR on BL602"](https://lupyuen.github.io/articles/cbor)

# Roblox Fetching Sensor Data From The Things Network

Roblox provides a Lua Scripting API that fetches External HTTP URLs (GET and POST)

https://developer.roblox.com/en-us/api-reference/class/HttpService

Here's how we call it to fetch the Sensor Data from The Things Network...

-   [`DigitalTwin.lua`](DigitalTwin.lua)

Enable HTTP Requests: Click Home -> Game Settings -> Security -> Allow HTTP Requests

Under `Workspace`, create a `Part`.

Under the `Part`, create a `Script`.

Copy and paste the script from [`DigitalTwin.lua`](DigitalTwin.lua)

Follow the steps in the next section to copy and paste the ModuleScripts for `Base64` and `Cbor`

To fetch the Sensor Data from The Things Network, we call `getSensorData` in [`DigitalTwin.lua`](DigitalTwin.lua)

When we run this Roblox Script...

```lua
-- Fetch the Sensor Data from The Things Network (LoRa)
local sensorData = getSensorData()

-- Show the Temperature
if sensorData then
	print("Temperature:")
	print(sensorData.t)
else
	print("Failed to get sensor data")
end
```

We should see the Temperature Sensor Data fetched from The Things Network...

```text
Temperature:
1236
```

# Decode Base64 and CBOR in Roblox

Under `ServerStorage`, create two __ModuleScripts__: `Base64` and `Cbor`.

Copy and paste the ModuleScripts from...

-   [`Base64`](Base64.lua)

-   [`Cbor`](Cbor.lua)

(Yep they need to be __ModuleScripts__. Normal Scripts won't work)

To test Base64 and CBOR Decoding...

```lua
-- Load the Base64 and CBOR ModuleScripts from ServerStorage
local ServerStorage = game:GetService("ServerStorage")
local base64 = require(ServerStorage.Base64)
local cbor = require(ServerStorage.Cbor)

-- Base64 Decode the Message Payload
payload = base64.decode('omF0GQTUYWwZCSs=')
print("payload:")
print(payload)

-- Decode the CBOR Map
sensorData = cbor.decode(payload)
print("sensorData:")
print(sensorData)
```

We should see...

```text
payload:
�at�al

sensorData:
{
    ["l"] = 2347,
    ["t"] = 1236
}
```

The ModuleScripts were copied from...

https://github.com/iskolbin/lbase64/blob/master/base64.lua

https://github.com/Zash/lua-cbor/blob/master/cbor.lua

This line in [base64.lua](https://github.com/iskolbin/lbase64/blob/master/base64.lua) was changed from...

```lua
local extract = _G.bit32 and _G.bit32.extract
```

To...

```lua
local extract = bit32 and bit32.extract
```

# Render Temperature With Roblox Particle Emitter

Let's use a Roblox Particle Emitter to show the Temperature (t) of our object...

https://youtu.be/38VcndHc2B0
    
We have defined 3 Particle Emitters: Cold (t=0), Normal (t=5000), Hot (t=10000).

To render the Temperature, we shall do Linear Interpolation of the 3 Particle Emitters...

```yaml
COLD Particle Emitter (t=0)
  Acceleration: 0, 0, 0
  Color: 0 0.333333 1 1 0 1 0.333333 1 1 0 
  Drag: 5
  EmissionDirection: Enum.NormalId.Top
  Lifetime: 5 10 
  LightEmission: 1
  LightInfluence: 1
  Orientation: Enum.ParticleOrientation.FacingCamera
  Rate: 20
  Rotation: 0 180 
  RotSpeed: -170 -170 
  Size: 0 1 0 1 1 0 
  Speed: 0 0 
  SpreadAngle: 10, 10
  Texture: rbxasset:textures/particles/sparkles_main.dds
  TimeScale: 1
  Transparency: 0 0 0 1 0 0 
  VelocityInheritance: 0
  ZOffset: 0

NORMAL Particle Emitter (t=5000)
  Acceleration: 0, 0, 0
  Color: 0 0.333333 0.666667 0 0 1 0.333333 0.666667 0 0 
  Drag: 10
  EmissionDirection: Enum.NormalId.Top
  Lifetime: 5 10 
  LightEmission: 0
  LightInfluence: 1
  Orientation: Enum.ParticleOrientation.FacingCamera
  Rate: 20
  Rotation: 0 0 
  RotSpeed: 0 0 
  Size: 0 0.2 0 1 0.2 0 
  Speed: 5 5 
  SpreadAngle: 50, 50
  Texture: rbxasset:textures/particles/sparkles_main.dds
  TimeScale: 1
  Transparency: 0 0 0 1 0 0 
  VelocityInheritance: 0
  ZOffset: 0

HOT Particle Emitter (t=10000)
  Acceleration: 0, 0, 0
  Color: 0 1 0.333333 0 0 1 1 0.333333 0 0 
  Drag: 0
  EmissionDirection: Enum.NormalId.Top
  Lifetime: 5 10 
  LightEmission: 0
  LightInfluence: 0
  Orientation: Enum.ParticleOrientation.FacingCamera
  Rate: 20
  Rotation: 0 0 
  RotSpeed: 0 0 
  Size: 0 0.4 0 1 0.4 0 
  Speed: 1 1 
  SpreadAngle: 50, 50
  Texture: rbxasset:textures/particles/sparkles_main.dds
  TimeScale: 1
  Transparency: 0 0 0 1 0 0 
  VelocityInheritance: 0
  ZOffset: 0
```

Values to be interpolated...

```yaml
Color:
  COLD:
    0 0.333333 1 1 0 
    1 0.333333 1 1 0 
  NORMAL:
    0 0.333333 0.666667 0 0 
    1 0.333333 0.666667 0 0 
  HOT:
    0 1 0.333333 0 0 
    1 1 0.333333 0 0 

Drag:
  COLD: 5
  NORMAL: 10
  HOT: 0

LightEmission: 
  COLD: 1
  NORMAL: 0
  HOT: 0

LightInfluence: 
  COLD: 1
  NORMAL: 1
  HOT: 0

Rotation: 
  COLD: 0 180 
  NORMAL: 0 0 
  HOT: 0 0 

RotSpeed: 
  COLD: -170 -170 
  NORMAL: 0 0 
  HOT: 0 0 

Size: 
  COLD: 0 1 0 1 1 0 
  NORMAL: 0 0.2 0 1 0.2 0 
  HOT: 0 0.4 0 1 0.4 0 
  
Speed: 
  COLD: 0 0 
  NORMAL: 5 5 
  HOT: 1 1 

SpreadAngle: 
  COLD: 10, 10
  NORMAL: 50, 50
  HOT: 50, 50
```

The properties of the Particle Emitters were dumped with the `dumpParticleEmitter` function in [`DigitalTwin.lua`](DigitalTwin.lua).

Note that `rbxasset` won't work for setting the Texture...

```lua
emitter.Texture = "rbxasset:textures/particles/sparkles_main.dds"
```

But `rbxassetid` works OK...

```lua
-- Texture for the particles: "star sparkle particle" by @Vupatu
-- https://www.roblox.com/library/6490035152/star-sparkle-particle
emitter.Texture = "rbxassetid://6490035152"
```

To create a Particle Emitter for Normal Temperature, we call `createParticleEmitter` in [`DigitalTwin.lua`](DigitalTwin.lua)

```lua
-- Create a Particle Emitter for Normal Temperature
local emitter = createParticleEmitter()
```

To interpolate the Particle Emitter for High / Mid / Low Temperatures, we call `updateParticleEmitter` in [`DigitalTwin.lua`](DigitalTwin.lua)

```lua
-- Gradually update the emitter for Temperature=10,000 to 0
updateParticleEmitter(emitter, T_MAX)
wait(5)
for t = T_MAX, T_MIN, -600 do
	print(string.format("t: %d", t))
	updateParticleEmitter(emitter, t)
	wait(4)
end
```

Here's how the Interpolating Particle Emitter looks...

https://www.youtube.com/watch?v=3CP7ELTAFLg
