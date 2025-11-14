import torch
import cv2
import numpy as np
from picamera2 import Picamera2
from pathlib import Path
from models.common import DetectMultiBackend
from utils.general import check_img_size, non_max_suppression, LOGGER
from utils.plots import Annotator, colors
from utils.torch_utils import select_device, time_sync
import socket
import time  # For delay control
import random  # For random timeout generation

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


def main():
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

    print("Kamera HQ aktif. Tekan Q untuk keluar.")

    last_sent_time = 0  # Initialize to 0 so first detection can send immediately
    delay = 25  # Delay time in seconds between detection sends

    # Random timeout setup
    no_detection_timeout = random.randint(20, 100)  # Random timeout between 20-100 seconds
    last_detection_time = time.time()  # Track last time object was detected (or started)
    print(f"Random timeout set to {no_detection_timeout} seconds")
    print(f"Total timeout (delay + random) = {delay + no_detection_timeout} seconds")

    while True:
        frame = picam.capture_array()
        img0 = frame.copy()
        img = torch.from_numpy(frame).to(device).float() / 255.0
        img = img.permute(2, 0, 1).unsqueeze(0)

        t1 = time_sync()
        pred = model(img)
        pred = non_max_suppression(pred, conf_thres, iou_thres)
        t2 = time_sync()

        detected = False  # Flag to check if an object is detected

        for det in pred:
            annotator = Annotator(img0, line_width=2, example=str(names))
            if len(det):
                detected = True  # Set to True if an object is detected
                det[:, :4] = scale_coords(img.shape[2:], det[:, :4], img0.shape).round()
                for *xyxy, conf, cls in reversed(det):
                    label = f'{names[int(cls)]} {conf:.2f}'
                    annotator.box_label(xyxy, label, color=colors(int(cls), True))

            img_disp = annotator.result()
            cv2.imshow("YOLOv5 RPICAM Preview", img_disp)

        # If object detected and enough time has passed (25 seconds delay)
        if detected and (time.time() - last_sent_time) >= delay:
            try:
                client.sendall(b"on\n")  # Send "on" message with newline for ESP32
                print("Sent 'on' via TCP (Object detected).")
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

        # Timeout logic: send if no detection for random timeout duration
        # AND respecting minimum delay from last send
        if not detected and \
           (time.time() - last_sent_time) >= delay and \
           (time.time() - last_detection_time) >= no_detection_timeout:
            try:
                client.sendall(b"on\n")  # Send "on" message due to timeout with newline for ESP32
                print(f"Sent 'on' via TCP (No detection for {no_detection_timeout}s, delay {delay}s respected).")
                last_sent_time = time.time()  # Update the last sent time
                last_detection_time = time.time()  # Reset no-detection timer
                # Generate new random timeout
                no_detection_timeout = random.randint(20, 100)
                print(f"New random timeout set to {no_detection_timeout} seconds")
                print(f"Total timeout (delay + random) = {delay + no_detection_timeout} seconds")
            except Exception as e:
                print(f"Failed to send message: {e}")

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    picam.close()
    cv2.destroyAllWindows()
    client.close()  # Close the TCP connection when done


if __name__ == "__main__":
    main()
