# 📄 Flutter PDF Report Generator

## 🚀 Overview
This Flutter service generates high-quality PDF reports from UI screenshots while handling long scrollable content efficiently. It supports:
- Capturing UI as an image.
- Splitting long images into multiple PDF pages.
- Enhancing image resolution to maintain clarity.
- Processing images in a separate isolate to prevent UI freezing.

## ✨ Features
- **📷 Screenshot Capture**: Uses `ScreenshotController` to capture the UI.
- **🖼 Image Processing in Isolate**: Offloads image processing to a separate thread to keep the app responsive.
- **📑 Multi-Page PDF Generation**: Splits long screenshots into multiple A4-sized pages.
- **📂 Local File Storage**: Saves both the PDF and image to external storage.
- **📤 File Sharing**: Allows opening and sharing the generated files.

## 🛠 Technologies Used
- **Flutter**
- `screenshot` (Capture UI as image)
- `pdf` (Generate PDFs)
- `image` (Image processing)
- `path_provider` (Access storage paths)
- `open_file_plus` (Open files)
- `isolate` (Background image processing)

## 📦 Installation
1. Add dependencies to `pubspec.yaml`:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     screenshot: ^1.3.0
     pdf: ^3.10.4
     path_provider: ^2.0.15
     open_file_plus: ^3.4.1
     image: ^4.0.17
   ```

2. Run:
   ```sh
   flutter pub get
   ```

## 🔥 Usage
### 1️⃣ Initialize the `PdfGeneratorService`
```dart
final screenshotController = ScreenshotController();
final pdfService = PdfGeneratorService(screenshotController: screenshotController);
```

### 2️⃣ Capture Screenshot & Generate PDF
```dart
await pdfService.generateAndSave(context);
```

## 📸 How It Works
1. **Capture Screenshot**: The UI is captured using `ScreenshotController`.
2. **Process Image in Isolate**: The captured image is resized in a separate thread to prevent UI freezing.
3. **Split Image if Too Long**: If the image height exceeds A4 size, it's split into multiple pages.
4. **Generate & Save PDF**: The processed image parts are saved as a multi-page PDF.
5. **Preview, Open, or Share**: The user can view, open, or share the generated files.

## 🏗 Example UI Implementation
```dart
Screenshot(
  controller: screenshotController,
  child: MyCustomReportWidget(),
);
```

## 📝 License
This project is licensed under the MIT License.

## 📬 Contact
For any questions, feel free to open an issue or reach out. Happy coding! 🚀

