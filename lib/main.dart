import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
// import 'package:flutter/material.dart';
// import 'package:testing/screen/attendness_screen.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(debugShowCheckedModeBanner: false,
//       title: 'Attendance App',
//       home: AttendanceScreen(),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FileUploadPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  String? pickedFileName;
  String? pickedMime;
  bool isUploading = false;

  Future<void> pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles();

    if (result == null || result.files.isEmpty) {
      setState(() {
        pickedFileName = null;
        pickedMime = null;
      });
      return;
    }

    final picked = result.files.first;
    final mimeType = lookupMimeType(picked.name) ?? 'application/octet-stream';

    setState(() {
      pickedFileName = picked.name;
      pickedMime = mimeType;
    });

    try {
      setState(() => isUploading = true);

      MultipartFile multipartFile;

      if (picked.path != null) {
        // ✅ Read file as bytes instead of using readStream
        final fileBytes = await File(picked.path!).readAsBytes();

        multipartFile = MultipartFile.fromBytes(
          fileBytes,
          filename: picked.name,
          contentType: DioMediaType.parse(mimeType),
        );
      } else {
        throw Exception("Cannot access file path.");
      }

      final formData = FormData.fromMap({
        "file": multipartFile,
      });

      final dio = Dio();
      final response = await dio.post(
        "https://mvp.edetectives.co.bw/external/api/v1/file-upload/threads-scam", // replace with your real API
        data: formData,
        options: Options(contentType: "multipart/form-data"),
      );

      debugPrint("✅ Upload success: ${response.data}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File uploaded successfully")),
      );
    } catch (e) {
      debugPrint("❌ Upload failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("File Upload Example")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pickedFileName != null)
              Column(
                children: [
                  Text("Picked file: $pickedFileName"),
                  Text("MIME type: $pickedMime"),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isUploading ? null : pickAndUpload,
              child: isUploading
                  ? const CircularProgressIndicator()
                  : const Text("Pick & Upload File"),
            ),
          ],
        ),
      ),
    );
  }
}
