# ProjectHUD — Phase 2 Hardware & BLE Packet Specification

> [!IMPORTANT]
> **Why BLE Data Link instead of Video Stream?**
> A Bluetooth video stream (e.g. A2DP/RTSP/SPP video) requires heavy compression, consumes 1.5–3 Watts, introduces 150–400ms frame latency, and drains both the phone and a tiny clip-on battery within 45 minutes.
> 
> In contrast, ProjectHUD uses a **12-byte BLE telemetry packet sent at 2–5 Hz**. The clip-on hardware (ESP32-S3 / nRF52840 connected to a micro-OLED / prism projector) renders the vector symbols locally.
> - **Bandwidth:** 60 bytes/sec vs 1.2 MB/sec video (20,000x cheaper).
> - **Battery life:** 14+ hours on a 250mAh coin-cell/pouch battery.
> - **Latency:** < 15ms from phone GPS to visor projection.
> - **Road Safety Placement:** The projection sits strictly in the **lower corner of the visor / windshield** — the rider's forward sightline remains 100% unobstructed.

---

## 1. BLE GATT Service & Characteristics

| Parameter | Value | Description |
|-----------|-------|-------------|
| **Service UUID** | `00001234-0000-1000-8000-00805F9B34FB` | ProjectHUD Telemetry Service |
| **Telemetry Char UUID** | `00001235-0000-1000-8000-00805F9B34FB` | Write Without Response / Notify (12 bytes) |
| **Control/Heartbeat UUID** | `00001236-0000-1000-8000-00805F9B34FB` | Read / Write (Connection keepalive, brightness) |

---

## 2. 12-Byte Packet Structure

```
+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+
| Byte 0 | Byte 1 | Byte 2 | Byte 3 | Byte 4 | Byte 5 | Byte 6 | Byte 7 | Byte 8 | Byte 9 | Byte 10| Byte 11|
+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+
| Header | Header |  Turn  |   Distance (m)  |  Speed (km/h*10) | Hazard | Hazard Dist(m) |  Risk  | Flags  | Checksum|
|  0x48  |  0x44  | Action |   MSB  |   LSB  |   MSB  |   LSB  |  Type  |   MSB  |   LSB  |  Level | Bitmask|  (XOR)  |
+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+--------+
```

### Detailed Field Definitions

| Byte Offset | Field | Type | Encoding / Values | Description |
|-------------|-------|------|-------------------|-------------|
| `0` | Header 1 | `uint8` | `0x48` ('H') | Magic sync byte |
| `1` | Header 2 | `uint8` | `0x44` ('D') | Magic sync byte |
| `2` | Turn Action | `uint8` | `0x00`: Straight<br>`0x01`: Slight Left<br>`0x02`: Left<br>`0x03`: Sharp Left<br>`0x04`: Slight Right<br>`0x05`: Right<br>`0x06`: Sharp Right<br>`0x07`: U-Turn<br>`0x08`: Roundabout<br>`0x09`: Arrive | Active maneuver arrow to draw |
| `3 - 4` | Distance to Turn | `uint16` (Big Endian) | `0` to `65535` metres | E.g. `0x01F4` = 500 metres |
| `5 - 6` | Speed | `uint16` (Big Endian) | Speed in km/h × 10 | E.g. `0x0186` = 390 = 39.0 km/h |
| `7` | Hazard Type | `uint8` | `0x00`: Pothole<br>`0x01`: Accident<br>`0x02`: Waterlogging<br>`0x03`: Road Work<br>`0x04`: Police Check<br>`0x05`: Speed Breaker<br>`0xFF`: No active hazard | Road hazard symbol inside triangle |
| `8 - 9` | Hazard Distance | `uint16` (Big Endian) | `0` to `65535` metres | E.g. `0x012C` = 300 metres |
| `10` | Risk Level | `uint8` | `0x00`: Normal<br>`0x01`: Low Risk<br>`0x02`: Medium Risk<br>`0x03`: High Risk (Phase 3)<br>`0x04`: Critical Risk | Triggers warning border on projector |
| `11` | Checksum | `uint8` | XOR of bytes 0 through 10 | Packet error validation |

---

## 3. Placement & Human Factors (NHTSA Compliance)

1. **Visor Projection Field:** Sits in the **lower-right or lower-left 15° periphery** of the visor.
2. **Centre Clear Zone:** The central 60° forward field of view is **100% empty transparent optical path**.
3. **Monochrome Amber:** Single 590nm optical wavelength prevents night-vision bleaching and pupil dilation stress.
4. **No Text Paragraphs:** Only 3 glyphs (Arrow, Speed numeral, Hazard symbol) visible at any microsecond.
