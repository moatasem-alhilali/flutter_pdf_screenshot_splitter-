import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';

import 'package:ewallet/core/services/share_service.dart';

class PdfGeneratorService {
  final ScreenshotController screenshotController;
  final int imageDpi;
  final int jpegQuality;

  PdfGeneratorService({
    required this.screenshotController,
    this.imageDpi = 150,
    this.jpegQuality = 90,
  });

  Future<void> generateAndSave(
    BuildContext context, {
    String pdfName = "Statement_Account",
    String imageName = "Statement_Account",
  }) async {
    try {
      final Uint8List? imageBytes =
          await screenshotController.capture(pixelRatio: 1.5);
      if (imageBytes == null) throw Exception("Screenshot capture failed");

      Uint8List? processedImage = await _processImageInBackground(imageBytes);
      if (processedImage == null) throw Exception("Image processing failed");

      final img.Image? fullImage = img.decodeImage(processedImage);
      if (fullImage == null) throw Exception("Image decoding failed");

      final List<img.Image> imageParts = _splitImage(fullImage);

      final pdfFile = await _savePdf(imageParts, pdfName);
      final imageFile = await _saveImage(fullImage, imageName);

      if (context.mounted) {
        _showPreview(context, imageBytes, pdfFile.path, imageFile.path);
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  Future<Uint8List?> _processImageInBackground(Uint8List imageBytes) async {
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(_imageProcessingTask, receivePort.sendPort);
    final SendPort sendPort = await receivePort.first;

    final responsePort = ReceivePort();
    sendPort.send([imageBytes, responsePort.sendPort]);

    return await responsePort.first;
  }

  static void _imageProcessingTask(SendPort sendPort) {
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    port.listen((message) {
      final Uint8List imageBytes = message[0];
      final SendPort replyPort = message[1];

      img.Image? fullImage = img.decodeImage(imageBytes);
      if (fullImage == null) {
        replyPort.send(null);
        return;
      }

      fullImage = img.copyResize(fullImage,
          width: 1240,
          height: (fullImage.height * 1240 ~/ fullImage.width),
          interpolation: img.Interpolation.linear);

      replyPort.send(Uint8List.fromList(img.encodeJpg(fullImage, quality: 90)));
    });
  }

  List<img.Image> _splitImage(img.Image image) {
    const double a4Width = 595.28;
    const double a4Height = 841.89;
    final int a4PixelWidth = (a4Width * imageDpi ~/ 72);
    final int a4PixelHeight = (a4Height * imageDpi ~/ 72);

    List<img.Image> parts = [];
    for (int i = 0; i < image.height; i += a4PixelHeight) {
      int sliceHeight =
          (i + a4PixelHeight > image.height) ? image.height - i : a4PixelHeight;
      parts.add(img.copyCrop(image,
          x: 0, y: i, width: a4PixelWidth, height: sliceHeight));
    }
    return parts;
  }

  Future<File> _savePdf(List<img.Image> imageParts, String fileName) async {
    final pdf = pw.Document();
    for (var part in imageParts) {
      final Uint8List partBytes =
          Uint8List.fromList(img.encodeJpg(part, quality: jpegQuality));
      final pw.MemoryImage pdfImage = pw.MemoryImage(partBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => pw.Center(child: pw.Image(pdfImage)),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));
    }

    final directory = await getExternalStorageDirectory();
    if (directory == null) throw Exception("Unable to access storage");

    final pdfFilePath = "${directory.path}/$fileName.pdf";
    final file = File(pdfFilePath);
    await file.writeAsBytes(await pdf.save());
    print("✅ PDF saved at: $pdfFilePath");
    return file;
  }

  Future<File> _saveImage(img.Image image, String fileName) async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) throw Exception("Unable to access storage");

    final imageFilePath = "${directory.path}/$fileName.jpg";
    final file = File(imageFilePath);
    await file.writeAsBytes(
        Uint8List.fromList(img.encodeJpg(image, quality: jpegQuality)));

    print("✅ Image saved at: $imageFilePath");
    return file;
  }

  void _showPreview(BuildContext context, Uint8List imageBytes, String pdfPath,
      String imagePath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Image Preview",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Image.memory(imageBytes, width: double.infinity, height: 200),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _openFile(pdfPath),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Open PDF"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openFile(imagePath),
                    icon: const Icon(Icons.image),
                    label: const Text("Open Image"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ShareService.shareFileBytes(imageBytes),
                    icon: const Icon(Icons.share),
                    label: const Text("Share Image"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openFile(String filePath) {
    File file = File(filePath);
    if (file.existsSync()) {
      OpenFile.open(filePath);
    }
  }
}
