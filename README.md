# IoT Digital Twin with Roblox and The Things Network

Let's connect Roblox to The Things Network (the public LoRa network)... And create an IoT Digital Twin for real-world objects...

![IoT Digital Twin with Roblox and The Things Network](https://lupyuen.github.io/images/digital-twin.jpg)

What's a "Digital Twin"? It's a Virtual Object that mirrors a Real-World Object through Sensors and Actuators.

In Roblox we shall call the HTTP + JSON API...

https://developer.roblox.com/en-us/api-reference/class/HttpService

To access the Live Sensor Data at The Things Network...

https://www.thethingsindustries.com/docs/integrations/storage/retrieve/

This will be useful for educating kids about IoT, by creating digital mirrors of real-world objects.

# Fetch Sensor Data from The Things Network

The Things Network exposes an API (HTTP GET) to fetch the Uplink Messages transmitted by our IoT Device...

https://www.thethingsindustries.com/docs/integrations/storage/retrieve/

Here's the command to fetch the latest Uplink Message...

```bash
curl \
    -G "https://au1.cloud.thethings.network/api/v3/as/applications/luppy-application/packages/storage/uplink_message" \
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

`frm_payload` contains the Sensor Data that we need, encoded with Base64 and CBOR...

```json
"frm_payload": "omF0GQTUYWwZCSs="
```
