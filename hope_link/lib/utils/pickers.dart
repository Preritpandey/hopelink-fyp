import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class Pickers {
  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final res = await picker.pickImage(source: ImageSource.gallery);
    return res != null ? File(res.path) : null;
  }

  static Future<File?> pickPDF() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    return res != null ? File(res.files.single.path!) : null;
  }
}
