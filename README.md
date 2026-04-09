# FPGA Image Processing Pipeline

Real-time image processing pipeline on the **Vaaman FPGA board**  using Verilog HDL. Camera frames are streamed from the IMX219 via the RK3399 SoC to the FPGA using the RAH Link protocol, processed pixel-by-pixel, and returned to the SoC for display.

---

## Current Status

### Working
- Four processing modules synthesizing and running:
  - Grayscale conversion
  - Brightness adjustment
  - Binary threshold
  - Sobel edge

### Planned
- Gaussian blur
- Canny edge detection
- Morphological dilation
- Green tint correction via color matrix (ISP workaround)
- Full 800×600 resolution pipeline

---

## RAH Link Setup
RAH (Real-time Application Handler) is Vicharak's custom protocol for high-speed bidirectional data transfer between the RK3399 SoC and Trion T120 FPGA over the board's MIPI interface.

### Required Source Files

All of these must be added to the Efinity project. 

| File | Purpose |
|------|---------|
| `rah_var_defs.vh` | App ID definitions and macros |
| `rah_decoder.v` | Decodes MIPI frames into per-app FIFOs |
| `rah_encoder.v` | Encodes app data into MIPI frames |
| `data_aligner.v` | Aligns 64-bit MIPI words to 48-bit packets |
| `rah_version_check.v` | App ID 0 — mandatory version handshake |
| `rrq.v` | Round-robin queue for multi-app arbitration |
| `video_gen.v` | Pattern generator used by encoder internally |

### Required Efinity IPs

Add both via **IP Manager → FIFO** in Efinity. Do not instantiate manually — RAH modules use them internally.

- `synchronous_fifo`
- `async_fifo`

### App ID Definitions
 [rah_var_defs.vh](rtl/rah_var_defs.vh)

---

