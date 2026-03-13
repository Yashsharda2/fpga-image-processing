# FPGA Image Processing Pipeline

> Work in progress — RAH Link live camera pipeline now functional

Real-time image processing pipeline on the **Vaaman FPGA board** (Efinix Trion T120 + Rockchip RK3399) using Verilog HDL. Camera frames are streamed from the IMX219 via the RK3399 SoC to the FPGA using the RAH Link protocol, processed pixel-by-pixel, and returned to the SoC for display.

---

## Board

| Component | Details |
|-----------|---------|
| Board | Vaaman by Vicharak |
| FPGA | Efinix Trion T120 |
| SoC | Rockchip RK3399 |
| Camera | IMX219 (Sony 8MP) |
| Protocol | RAH Link (custom SoC↔FPGA over MIPI) |
| Toolchain | Efinity 2025.2 |

---

## Current Status

### Working
- RAH Link fully set up and operational
- Live pixel streaming from RK3399 to FPGA and back
- RGB888 pixel pipeline on FPGA
- Three processing modules synthesizing and running:
  - Grayscale conversion
  - Brightness adjustment
  - Binary threshold
- Mode selection via GPIO pins — switch processing at runtime
- Processed pixels returned to SoC via RAH encoder

### In Progress
- IMX219 camera hardware bring-up (I2C detection issue)
- FPGA communication overlay on RK3399 side
- Display output 

### Planned
- Sobel edge detection
- Gaussian blur
- Canny edge detection
- Morphological dilation
- Green tint correction via color matrix (ISP workaround)
- Full 800×600 resolution pipeline

---

## Architecture

```
IMX219 → RK3399
           │
      rah_write(APP_ID=1, frame)
           │
        MIPI TX
           │
     data_aligner         ← aligns 64-bit MIPI words to 48-bit RAH packets
           │
      rah_decoder          ← decodes app_id, routes to correct FIFO
           │
   APP_WR_FIFO[1]
           │
        cam_rx.v           ← pops pixel from FIFO → wire [23:0] pixel
           │
    ┌──────┼──────┐
grayscale  brightness  threshold   ← all receive same pixel wire in parallel
    └──────┼──────┘
           │
      case(mode)           ← GPIO selects which output to use
           │
      rah_encoder          ← packs result back into MIPI frames
           │
        MIPI RX
           │
      rah_read(APP_ID=1)
           │
        display
```

---

## RAH Link Setup

RAH (Real-time Application Handler) is Vicharak's custom protocol for high-speed bidirectional data transfer between the RK3399 SoC and Trion T120 FPGA over the board's MIPI interface.

### Required Source Files

All of these must be added to the Efinity project. The `.vh` file must be `.vh` not `.v` — Efinity treats them differently.

| File | Purpose |
|------|---------|
| `rah_var_defs.vh` | App ID definitions and macros |
| `rah_decoder.v` | Decodes MIPI frames into per-app FIFOs |
| `rah_encoder.v` | Encodes app data into MIPI frames |
| `data_aligner.v` | Aligns 64-bit MIPI words to 48-bit packets |
| `rah_version_check.v` | App ID 0 — mandatory version handshake |
| `rrq.v` | Round-robin queue for multi-app arbitration |
| `video_gen.v` | Pattern generator used by encoder internally |
| `uart.v` | UART driver (required by RAH modules) |

### Required Efinity IPs

Add both via **IP Manager → FIFO** in Efinity. Do not instantiate manually — RAH modules use them internally.

- `synchronous_fifo`
- `async_fifo`

### App ID Definitions
 [rah_var_defs.vh](rtl/rah_var_defs.vh)



| Module | Output Port | Description |
|--------|-------------|-------------|
| `grayscale.v` | `gray` | ITU-R BT.601 luma coefficients (77, 150, 29) |
| `Brightness.v` | `bright` | Signed R/G/B offset, clamped 0–255 |
| `threshold.v` | `b_w` | Sum of channels vs 3×T → black or white |

### Mode Selection via GPIO

```
mode[1:0] = 2'b00  →  grayscale
mode[1:0] = 2'b01  →  brightness  (fixed offset: +20 per channel)
mode[1:0] = 2'b10  →  threshold   (fixed threshold: 128)
```

`rst`, `bright_R/G/B`, and `thresh_T` are currently hardcoded internally — no extra GPIO pins needed.

---

## Project Structure

```
image/
├── image.v                   # Top module — RAH wiring + mode select
├── cam_rx.v                  # RAH pixel receiver → wire [23:0] pixel
├── grayscale.v               # Grayscale processing
├── Brightness.v              # Brightness adjustment
├── threshold.v               # Binary threshold
├── rah_var_defs.vh           # App ID definitions (must be .vh)
├── rah_decoder.v             # RAH decoder (Vicharak IP, encrypted)
├── rah_encoder.v             # RAH encoder (Vicharak IP, encrypted)
├── rah_version_check.v       # Version check (Vicharak IP)
├── data_aligner.v            # MIPI data aligner (Vicharak IP)
├── rrq.v                     # Round-robin queue (Vicharak IP)
├── video_gen.v               # Video pattern generator (Vicharak IP)
├── uart.v                    # UART driver
└── ip/
    ├── synchronous_fifo/     # Efinix IP — added via IP Manager
    └── async_fifo/           # Efinix IP — added via IP Manager
```

---

## Data Format

| Property | Value |
|----------|-------|
| Color format | RGB888 |
| Bits per pixel | 24 (8 per channel) |
| Frame size | 400×266 |
| RAH packet width | 48 bits |
| Pixel packing | Lower 24 bits of 48-bit packet |

---

## CPU Side (RK3399)
[pipeline.py](rtl/pipeline.py)


### Startup Order (important)

```
1. Upload bitstream to FPGA via Efinity programmer
2. sudo systemctl start rah-service
3. python3 pipeline.py
```

## Tools & Dependencies

| Tool | Purpose |
|------|---------|
| Efinity 2025.2 | Synthesis, place & route, bitstream |
| Verilog HDL | RTL design |
| pyrah / librah | CPU-side RAH library |
| OpenCV 4.5.4 | Frame capture and display |
| v4l2 | Camera device access |

---

## References

- [Vicharak RAH Protocol](https://github.com/vicharak-in/rah-bit)
- [Vaaman Docs](https://docs.vicharak.in)
