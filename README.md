# FPGA Image Processing Pipeline (IN PROGRESS)

Implemanting image processing pipeline on FPGA using Verilog HDL on Vaaman FPGA Board.

## Current Scope
- It supports Hex file based image input
- Pixel-level operations:
  - Grayscale Conversion
  - Brightness
  - Threshold

- HEX image loaded into on-chip BRAM as frame buffer

## Data Format

- RGB888 (24-bit per pixel)
- 8-bit per channel
- Frame size: 400x266
- Pixel range: 0–255

## Future Scope
- Live camera input (IMX219)
- Streaming pixel pipeline
- Output on display using RAH link
## Tools
- Verilog HDL
- EFINITY
