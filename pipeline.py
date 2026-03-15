import cv2
import numpy as np
import pyrah

# ─── Config ───────────────────────────────────────────
DEVICE      = "/dev/video0"
WIDTH       = 400
HEIGHT      = 266
APP_ID      = 1          # CAM_RX app_id in rah_var_defs.vh
FRAME_BYTES = WIDTH * HEIGHT * 3   # RGB888 = 3 bytes per pixel
# ──────────────────────────────────────────────────────

def open_camera():
    cap = cv2.VideoCapture(DEVICE, cv2.CAP_V4L2)
    cap.set(cv2.CAP_PROP_FOURCC, cv2.VideoWriter_fourcc(*'RGB3'))
    cap.set(cv2.CAP_PROP_FRAME_WIDTH,  WIDTH)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, HEIGHT)
    if not cap.isOpened():
        raise RuntimeError(f"Cannot open {DEVICE}")
    return cap

def send_frame_to_fpga(frame_rgb):
    """Send entire frame to FPGA in one rah_write call"""
    raw = frame_rgb.tobytes()          # flat RGB888 bytes
    pyrah.rah_write(APP_ID, raw)

def read_frame_from_fpga():
    """Read processed frame back from FPGA in one rah_read call"""
    raw = pyrah.rah_read(APP_ID, FRAME_BYTES)
    frame = np.frombuffer(raw, dtype=np.uint8)
    frame = frame.reshape((HEIGHT, WIDTH, 3))
    return frame

def main():
    cap = open_camera()
    print(f"Camera opened: {WIDTH}x{HEIGHT}")
    print("Press ESC to quit")

    while True:
        ret, frame_bgr = cap.read()
        if not ret:
            print("Frame capture failed")
            break

        # OpenCV captures BGR, convert to RGB for FPGA
        frame_rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)

        # Send to FPGA
        send_frame_to_fpga(frame_rgb)

        # Read processed result back
        processed = read_frame_from_fpga()

        # Convert back to BGR for OpenCV display
        display = cv2.cvtColor(processed, cv2.COLOR_RGB2BGR)

        # Show both original and processed side by side
        combined = np.hstack([frame_bgr, display])
        cv2.imshow("Original | Processed", combined)

        if cv2.waitKey(1) == 27:   # ESC
            break

    cap.release()
    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
