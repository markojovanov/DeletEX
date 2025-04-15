# DeletEX – iOS App for Face-Based Photo Grouping & Deletion

DeletEX is a privacy-focused iOS application that allows users to scan their photo library, detect and group photos based on faces, and selectively delete images associated with a specific person — such as an ex-partner. All processing is done **entirely on-device**, ensuring speed, privacy, and full user control.

---

## 🔍 Features

- ✅ **On-device face detection** using Apple’s Vision framework  
- ✅ **Face recognition** powered by a TensorFlow Lite implementation of **FaceNet**  
- ✅ **Real-time processing** of large photo libraries  
- ✅ **Intuitive UI** with SwiftUI and MVVM architecture  
- ✅ **Selective review & batch deletion** of grouped images  
- ✅ **No cloud storage, no data leaks** – your photos stay yours  

---

## 🧠 Tech Stack

- **Swift + SwiftUI**
- **Vision Framework** (face detection)
- **TensorFlow Lite + FaceNet** (face recognition)
- **Photos Framework** (photo access & deletion)
- **MVVM Architecture**
- **CocoaPods** (for dependency management)

---

## 🚀 Getting Started

1. **Clone the repo:**
   ```bash
   git clone https://github.com/markojovanov/DeletEX.git
   ```

2. **Install dependencies:**
   ```bash
   cd DeletEX
   pod install
   open DeletEX.xcworkspace
   ```

3. **Build & Run in Xcode (iOS 16+)**

> Make sure to allow photo library access in your iOS Simulator or device.

---

## ⚙️ Configuration

- The FaceNet model (`facenet.tflite`) is already optimized for mobile via TensorFlow Lite.
- The app uses Euclidean distance for face matching, with a similarity threshold of **0.9**.
- All photo processing and face embedding happens **locally**, and is never uploaded anywhere.

---

## 🧪 Testing & Validation

- Internal testing across 1000+ photos  
- Achieved **90%+ recognition accuracy** in realistic scenarios  
- Supports various lighting conditions, expressions, and angles  
- Manual review step helps avoid accidental deletions

---

## 🔐 Privacy

DeletEX guarantees that:
- 📷 Your photos never leave your device
- ☁️ No third-party servers are used
- 🔒 Local-only processing ensures maximum privacy

---

## 🧑‍💻 Author

**Marko Jovanov**  
📍 Skopje, North Macedonia  
📧 marko.jovanov15@hotmail.com  

---

## 📝 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
