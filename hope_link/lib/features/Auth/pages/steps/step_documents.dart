import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hope_link/features/Auth/widgets/form_section.dart';

class StepDocuments extends StatefulWidget {
  @override
  State<StepDocuments> createState() => _StepDocumentsState();
}

class _StepDocumentsState extends State<StepDocuments> {
  PlatformFile? taxCertificate;
  PlatformFile? constitution;
  PlatformFile? proofAddress;
  PlatformFile? voidCheque;

  Future pickFile(Function(PlatformFile) setter) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );
    if (result != null) {
      setter(result.files.first);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey("docs"),
      children: [
        FormSection(
          title: "Required Documents",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fileTile(
                "Tax Certificate",
                taxCertificate,
                () => pickFile((f) => taxCertificate = f),
              ),
              const SizedBox(height: 12),

              _fileTile(
                "Constitution File",
                constitution,
                () => pickFile((f) => constitution = f),
              ),
              const SizedBox(height: 12),

              _fileTile(
                "Proof of Address",
                proofAddress,
                () => pickFile((f) => proofAddress = f),
              ),
              const SizedBox(height: 12),

              _fileTile(
                "Void Cheque",
                voidCheque,
                () => pickFile((f) => voidCheque = f),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fileTile(String title, PlatformFile? file, VoidCallback pick) {
    return Row(
      children: [
        Expanded(
          child: Text(
            file == null ? "$title (Not Uploaded)" : "$title: ${file.name}",
            style: const TextStyle(fontSize: 15),
          ),
        ),
        ElevatedButton(onPressed: pick, child: const Text("Upload")),
      ],
    );
  }
}
