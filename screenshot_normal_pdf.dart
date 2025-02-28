import 'dart:io';
import 'dart:typed_data';

import 'package:ewallet/core/services/share_service.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:image/image.dart' as img;

class ScreenshotPdfGenerator {
  Future<void> generatePdfAndImage(
    ScreenshotController screenshotController,
    BuildContext context,
  ) async {
    try {
      // Capture full widget as image
      final Uint8List? imageBytes = await screenshotController.capture(
          // pixelRatio: 1.0,
          );
      if (imageBytes == null) throw Exception("Screenshot capture failed");

      // Convert image to format for processing
      img.Image? fullImage = img.decodeImage(imageBytes);
      if (fullImage == null) throw Exception("Image decoding failed");

      // Define A4 dimensions (at 72 DPI)
      const double a4Width = 595.28; // A4 width in points
      const double a4Height = 841.89; // A4 height in points
      const int imageDpi = 72;
      const int a4PixelWidth = a4Width * imageDpi ~/ 72;
      const int a4PixelHeight = a4Height * imageDpi ~/ 72;

      // Scale image to A4 width
      fullImage = img.copyResize(fullImage, width: a4PixelWidth);

      // Split image if height exceeds A4
      List<img.Image> imageParts = [];
      for (int i = 0; i < fullImage.height; i += a4PixelHeight) {
        int sliceHeight = (i + a4PixelHeight > fullImage.height)
            ? fullImage.height - i
            : a4PixelHeight;
        imageParts.add(img.copyCrop(
          fullImage, // The source image
          x: 0, // Start from the leftmost position
          y: i, // Start slicing at the given height position
          width: a4PixelWidth, // Width of the cropped section
          height: sliceHeight, // Height of the cropped section
        ));
      }

      // Generate and save PDF
      final pdf = pw.Document();

      for (var part in imageParts) {
        final Uint8List partBytes = Uint8List.fromList(img.encodePng(part));
        final pw.MemoryImage pdfImage = pw.MemoryImage(partBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) => pw.Center(child: pw.Image(pdfImage)),
          ),
        );
      }

      // Get storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception("Unable to access storage");

      final pdfFilePath = "${directory.path}/Statement_Account.pdf";
      final pdfFile = File(pdfFilePath);
      await pdfFile.writeAsBytes(await pdf.save());

      print("✅ PDF saved at: $pdfFilePath");

      // Save Original Image
      final imageFilePath = "${directory.path}/Statement_Account.png";
      final imageFile = File(imageFilePath);
      await imageFile.writeAsBytes(imageBytes);

      print("✅ Image saved at: $imageFilePath");

      // Show bottom sheet preview
      if (context.mounted) {
        _showImagePreview(context, imageBytes, pdfFilePath, imageFilePath);
      }
    } catch (e) {
      print("❌ Error generating PDF/Image: $e");
    }
  }

  Future<void> generatePdfAndImageTow(
    ScreenshotController screenshotController,
    BuildContext context,
  ) async {
    try {
      // Capture widget as image
      final Uint8List? imageBytes = await screenshotController.capture();
      if (imageBytes == null) throw Exception("Screenshot capture failed");

      // Generate and save PDF
      final pdf = pw.Document();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(
                image, fit: pw.BoxFit.contain,
                // fit: BoxFit.cover,
              ),
            );
          },
        ),
      );

      // Get storage directory
      final directory = await getExternalStorageDirectory();
      if (directory == null) throw Exception("Unable to access storage");

      final pdfFilePath = "${directory.path}/Statement_Account.pdf";
      final pdfFile = File(pdfFilePath);
      await pdfFile.writeAsBytes(await pdf.save());

      print("✅ PDF saved at: $pdfFilePath");

      // Save Image
      final imageFilePath = "${directory.path}/Statement_Account.png";
      final imageFile = File(imageFilePath);
      await imageFile.writeAsBytes(imageBytes);

      print("✅ Image saved at: $imageFilePath");

      // Show bottom sheet with the captured image
      if (context.mounted) {
        _showImagePreview(context, imageBytes, pdfFilePath, imageFilePath);
      }
    } catch (e) {
      print("❌ Error generating PDF/Image: $e");
    }
  }

  void _showImagePreview(BuildContext context, Uint8List imageBytes,
      String pdfPath, String imagePath) {
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
              Image.memory(
                imageBytes,
                width: double.infinity,
                height: 200,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _openFile(pdfPath);
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Open PDF"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _openFile(imagePath);
                    },
                    icon: const Icon(Icons.image),
                    label: const Text("Open Image"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ShareService.shareFileBytes(imageBytes);

                      // _openFile(imagePath);
                    },
                    icon: const Icon(Icons.image),
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
