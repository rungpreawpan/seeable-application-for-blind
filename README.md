# Seeable Application

Seeable is a mobile application designed to assist visually impaired users in navigating indoor environments safely using Augmented Reality (AR) and real-time object detection. The system detects surrounding obstacles and provides audio guidance to help users move safely within buildings.

The application integrates computer vision, object detection, and navigation systems to improve accessibility and reduce navigation risks for visually impaired individuals.

---

## System Architecture

The Seeable system consists of three main components:

1. **Mobile Application (Flutter)**
   - Provides the user interface
   - Uses camera input for object detection
   - Delivers navigation guidance via audio feedback

2. **Navigation Server (Express.js)**
   - Manages indoor navigation routes
   - Processes marker detection and user positioning
   - Handles API communication between mobile app and database

3. **Object Detection Server (Flask + YOLO)**
   - Performs real-time obstacle detection
   - Processes images sent from the mobile application
   - Returns detected objects with bounding boxes and labels

---

## Repositories

The Seeable system is divided into multiple repositories:

### Mobile Application
Flutter application for visually impaired navigation.

```
https://github.com/rungpreawpan/seeable-application-for-blind
```

### Navigation Server (Express.js)
Handles navigation logic, marker detection, and API services.

```
https://github.com/rungpreawpan/seeable_server
```

### Object Detection Server (Flask)
Processes images using a YOLO-based model to detect obstacles.

```
https://github.com/rungpreawpan/seeable-script
```

---

## Key Features

- Indoor navigation using AR markers
- Real-time obstacle detection
- Audio feedback for visually impaired users
- Priority-based obstacle alert system
- Route guidance inside buildings
- Integration with object detection AI models

---

## Technologies Used

### Mobile Application
- Flutter
- Dart
- AR / Camera APIs
- Text-to-Speech (TTS)

### Backend
- Node.js
- Express.js
- REST API

### AI Detection Server
- Python
- Flask
- YOLO (Object Detection)
- OpenCV

---

## Installation

### 1. Clone Mobile Application

```bash
git clone https://github.com/rungpreawpan/seeable-application-for-blind
cd seeable-application-for-blind
flutter pub get
```

### 2. Clone Navigation Server

```bash
git clone https://github.com/rungpreawpan/seeable_server
cd seeable-server
npm install
npm run dev
```

### 3. Clone Object Detection Server

```bash
git clone https://github.com/rungpreawpan/seeable-script
cd seeable-script
python main.py
```

---

## How It Works

1. The mobile app captures images using the device camera.
2. Images are sent to the Flask detection server.
3. The server runs object detection and returns detected obstacles.
4. The app calculates obstacle priority using the object weighting framework.
5. Audio alerts guide the user to avoid obstacles safely.
6. Navigation routes are managed by the Express.js server.

---

## Research Context

This project is part of a research study focused on improving indoor navigation accessibility for visually impaired users using augmented reality and AI-based obstacle detection.

---

## License

This project is for research and educational purposes.
