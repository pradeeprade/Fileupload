import 'package:open_filex/open_filex.dart';
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http_parser/http_parser.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: FileUploadPage(),
    debugShowCheckedModeBanner: false,
  );
}

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  List<PlatformFile> files = [];
  bool uploading = false;
  double progress = 0;

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result?.files.isNotEmpty ?? false) {
      setState(() {
        files.addAll(
          result!.files.where((f) => files.every((pf) => pf.path != f.path)),
        );
      });
    }
  }

  Future<void> uploadFiles() async {
    if (files.isEmpty) return;
    setState(() {
      uploading = true;
      progress = 0;
    });
    final dio = Dio();
    try {
      for (var f in files) {
        if (f.path == null) continue;
        final mime = lookupMimeType(f.name) ?? 'application/octet-stream';
        final data = FormData.fromMap({
          "file": await MultipartFile.fromFile(
            f.path!,
            filename: f.name,
            contentType: MediaType.parse(mime),
          ),
        });
        await dio.post(
          "https://mvp.edetectives.co.bw/external/api/v1/file-upload/threads-scam",
          data: data,
          options: Options(contentType: "multipart/form-data"),
          onSendProgress: (sent, total) =>
              setState(() => progress = sent / total),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ All files uploaded successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Upload failed: $e")));
    } finally {
      setState(() => uploading = false);
    }
  }

  void previewFile(PlatformFile file) {
    final mime = lookupMimeType(file.name) ?? '';
    if (file.path == null) return;

    if (mime.startsWith("image/"))
      _showDialog(Image.file(File(file.path!)));
    else if (mime.startsWith("video/"))
      _showDialog(_VideoPlayerWidget(filePath: file.path!));
    else if (mime == "application/pdf")
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(file.name)),
            body: SfPdfViewer.file(File(file.path!)),
          ),
        ),
      );
    else if (mime.contains("word"))
      OpenFilex.open(file.path!);
    else
      _showDialog(Text("Cannot preview this file type.\nFile: ${file.name}"));
  }

  void _showDialog(Widget content) => showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(padding: const EdgeInsets.all(8), child: content),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    ),
  );

  Widget _fileCard(PlatformFile file) => Card(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: ListTile(
      leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
      title: Text(file.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        "${lookupMimeType(file.name) ?? 'Unknown'} · ${file.size ~/ 1024} KB",
      ),
      trailing: IconButton(
        icon: const Icon(Icons.remove_red_eye, color: Colors.green),
        onPressed: () => previewFile(file),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("File Upload Example")),
    body: Column(
      children: [
        const SizedBox(height: 16),
        if (uploading)
          Column(
            children: [
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text("${(progress * 100).toStringAsFixed(0)}%"),
            ],
          ),
        Expanded(
          child: files.isEmpty
              ? const Center(child: Text("No files picked yet"))
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (_, i) => _fileCard(files[i]),
                ),
        ),
      ],
    ),
    floatingActionButton: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: "pick",
          onPressed: pickFiles,
          icon: const Icon(Icons.add),
          label: const Text("Pick Files"),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: "upload",
          onPressed: uploading ? null : uploadFiles,
          icon: const Icon(Icons.cloud_upload),
          label: const Text("Upload"),
        ),
      ],
    ),
  );
}

class _VideoPlayerWidget extends StatefulWidget {
  final String filePath;

  const _VideoPlayerWidget({required this.filePath});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then(
        (_) => setState(() {
          ready = true;
          _controller.play();
        }),
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ready
      ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio > 0
                  ? _controller.value.aspectRatio
                  : 16 / 9,
              child: VideoPlayer(_controller),
            ),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: () => setState(
                    () => _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play(),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ],
        )
      : const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
}
