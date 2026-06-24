# 🌾 SmartAgri — Crop Disease Detection App

> **We Focus on Farmer Growth**

SmartAgri is a Flutter-based mobile application that uses **TensorFlow Lite** machine learning to detect crop diseases from leaf images in real-time. Simply take a photo or upload one from your gallery, and the app will identify the disease, describe its symptoms, and recommend treatments — all with **text-to-speech** support for accessibility.

Made in India 🇮🇳

---

## ✨ Features

- 📸 **Camera & Gallery Support** — Capture a leaf photo or pick from gallery
- 🤖 **On-Device ML Classification** — Uses a TFLite model for fast, offline disease detection
- 🎯 **High Accuracy Filtering** — Only shows results with ≥90% confidence; flags unclear images
- 📋 **Detailed Disease Reports** — Description, symptoms, and treatment for each detected disease
- 🔊 **Text-to-Speech** — Reads out the full diagnosis aloud for hands-free use
- 🚫 **Invalid Image Detection** — Alerts users when uploaded images aren't suitable for analysis
- 🎨 **Clean, Modern UI** — Intuitive splash screen and scanner interface

---

## 🦠 Supported Diseases

| Crop | Disease |
|------|---------|
| 🍎 Apple | Apple Scab |
| 🍎 Apple | Black Rot |
| 🍎 Apple | Cedar Apple Rust |
| 🍎 Apple | Healthy ✅ |
| 🌽 Corn (Maize) | Cercospora Leaf Spot / Gray Leaf Spot |
| 🥔 Potato | Early Blight |

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| [Flutter](https://flutter.dev/) | Cross-platform mobile framework |
| [TensorFlow Lite](https://www.tensorflow.org/lite) (`tflite_v2`) | On-device ML inference |
| [image_picker](https://pub.dev/packages/image_picker) | Camera & gallery image selection |
| [flutter_tts](https://pub.dev/packages/flutter_tts) | Text-to-speech for accessibility |

---

## 📂 Project Structure

```
smartagri/
├── assets/
│   ├── crop_disease_model.tflite   # TFLite ML model
│   ├── labels.txt                  # Disease class labels
│   └── images/
│       └── logo.png                # App logo
├── lib/
│   └── main.dart                   # App source code
├── android/                        # Android platform files
├── ios/                            # iOS platform files
├── web/                            # Web platform files
├── pubspec.yaml                    # Dependencies & config
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.0.0)
- Android Studio / VS Code with Flutter extension
- A physical device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/vishwajeetdeshmukhdeveloper/SmartAgri.git
   cd smartagri
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 📱 How It Works

1. **Splash Screen** — App launches with the SmartAgri branding
2. **Scanner Screen** — Use the camera or gallery to select a crop leaf image
3. **Analysis** — The TFLite model classifies the image on-device
4. **Result Screen** — View the disease name, confidence score, description, symptoms, and treatment
5. **Listen** — Tap the speaker button to hear the full report read aloud

---

## 🤝 Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">
  <b>SmartAgri</b> — Empowering farmers with AI-powered crop disease detection 🌱
</p>
