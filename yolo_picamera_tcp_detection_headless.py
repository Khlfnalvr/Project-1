import torch
import numpy as np
from picamera2 import Picamera2
from pathlib import Path
from models.common import DetectMultiBackend
from utils.general import check_img_size, non_max_suppression, LOGGER
from utils.torch_utils import select_device, time_sync
import socket
import time  # For delay control
import random  # For random timeout generation
import signal
import sys

# Fungsi scale_coords manual
def scale_coords(img1_shape, coords, img0_shape, ratio_pad=None):
    if ratio_pad is None:
        gain = min(img1_shape[0] / img0_shape[0], img1_shape[1] / img0_shape[1])
        pad = (img1_shape[1] - img0_shape[1] * gain) / 2, (img1_shape[0] - img0_shape[0] * gain) / 2
    else:
        gain = ratio_pad[0][0]
        pad = ratio_pad[1]

    coords[:, [0, 2]] -= pad[0]
    coords[:, [1, 3]] -= pad[1]
    coords[:, :4] /= gain
    coords[:, :4] = coords[:, :4].clamp(min=0)
    return coords


# Global variables for cleanup
picam = None
client = None

def signal_handler(sig, frame):
    """Handle Ctrl+C gracefully"""
    print("\nStopping... Cleaning up resources.")
    if picam:
        picam.close()
    if client:
        client.close()
    sys.exit(0)

# Register signal handler
signal.signal(signal.SIGINT, signal_handler)


def main():
    global picam, client

    weights = 'best.pt'
    imgsz = (640, 640)
    conf_thres = 0.5
    iou_thres = 0.45
    device = 'cpu'

    # Setup model
    device = select_device(device)
    model = DetectMultiBackend(weights, device=device, data=None)
    stride, names, pt = model.stride, model.names, model.pt
    imgsz = check_img_size(imgsz, s=stride)
    model.warmup(imgsz=(1, 3, *imgsz))

    # Setup Picamera2
    picam = Picamera2()
    picam.configure(picam.create_preview_configuration(main={'format': 'RGB888', 'size': (imgsz[0], imgsz[1])}))
    picam.start()

    # Setup TCP connection
    ESP2_IP = "192.168.4.1"
    PORT = 5000
    try:
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.connect((ESP2_IP, PORT))
        print("Connected to ESP2 at", ESP2_IP)
    except Exception as e:
        print("Connection failed:", e)
        exit()

    print("Kamera HQ aktif (headless mode). Tekan Ctrl+C untuk keluar.")
    print("Running without GUI window - optimized for performance!")

    last_sent_time = time.time()  # Initialize with current time for 25s delay from start
    delay = 25  # Delay time in seconds between detection sends

    # Random timeout setup
    no_detection_timeout = random.randint(20, 100)  # Random timeout between 20-100 seconds
    last_detection_time = time.time()  # Track last time object was detected (or started)
    print(f"Random timeout set to {no_detection_timeout} seconds")
    print(f"Total timeout (delay + random) = {delay + no_detection_timeout} seconds")

    frame_count = 0
    start_time = time.time()

    while True:
        frame = picam.capture_array()
        img = torch.from_numpy(frame).to(device).float() / 255.0
        img = img.permute(2, 0, 1).unsqueeze(0)

        t1 = time_sync()
        pred = model(img)
        pred = non_max_suppression(pred, conf_thres, iou_thres)
        t2 = time_sync()

        detected = False  # Flag to check if an object is detected
        detection_details = []  # Store detection info for logging

        for det in pred:
            if len(det):
                detected = True  # Set to True if an object is detected
                det[:, :4] = scale_coords(img.shape[2:], det[:, :4], frame.shape).round()
                for *xyxy, conf, cls in reversed(det):
                    detection_details.append(f"{names[int(cls)]} ({conf:.2f})")

        # Log detection info (without drawing boxes)
        if detected:
            frame_count += 1
            if frame_count % 30 == 0:  # Log every 30 frames with detection
                print(f"Detected: {', '.join(detection_details)} | Inference: {(t2-t1)*1000:.1f}ms")

        # If object detected and enough time has passed (25 seconds delay)
        if detected and (time.time() - last_sent_time) >= delay:
            try:
                client.sendall(b"on")  # Send "on" message
                print(f"Sent 'on' via TCP (Object detected: {', '.join(detection_details)}).")
                last_sent_time = time.time()  # Update the last sent time
                last_detection_time = time.time()  # Reset no-detection timer
                # Generate new random timeout
                no_detection_timeout = random.randint(20, 100)
                print(f"New random timeout set to {no_detection_timeout} seconds")
                print(f"Total timeout (delay + random) = {delay + no_detection_timeout} seconds")
            except Exception as e:
                print(f"Failed to send message: {e}")

        # If object detected, update last detection time (even if not sending due to delay)
        if detected:
            last_detection_time = time.time()

        # If no object detected for longer than (delay + random timeout)
        # Simple logic: if timeout reached since last send, send "on"
        total_timeout = delay + no_detection_timeout
        if not detected and (time.time() - last_sent_time) >= total_timeout:
            try:
                client.sendall(b"on")  # Send "on" message due to timeout
                print(f"Sent 'on' via TCP (No detection timeout: {total_timeout}s reached).")
                last_sent_time = time.time()  # Update the last sent time
                last_detection_time = time.time()  # Reset no-detection timer
                # Generate new random timeout
                no_detection_timeout = random.randint(20, 100)
                print(f"New random timeout set to {no_detection_timeout} seconds")
                print(f"Total timeout (delay + random) = {delay + no_detection_timeout} seconds")
            except Exception as e:
                print(f"Failed to send message: {e}")

        # Small sleep to prevent excessive CPU usage
        time.sleep(0.01)

    # Cleanup (will be called by signal handler)
    picam.close()
    client.close()


if __name__ == "__main__":
    main()
