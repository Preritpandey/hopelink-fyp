import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReportPdfViewPage extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final Map<String, String> headers;

  const ReportPdfViewPage({
    super.key,
    required this.title,
    required this.pdfUrl,
    required this.headers,
  });

  @override
  State<ReportPdfViewPage> createState() => _ReportPdfViewPageState();
}

class _ReportPdfViewPageState extends State<ReportPdfViewPage> {
  late Future<Uint8List> _pdfBytes;

  @override
  void initState() {
    super.initState();
    _pdfBytes = _loadPdfBytes();
  }

  Future<Uint8List> _loadPdfBytes() async {
    final res = await http.get(
      Uri.parse(widget.pdfUrl),
      headers: widget.headers,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load PDF (${res.statusCode})');
    }

    return res.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06101F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1629),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Preview',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunitoSans(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            final errorText = snapshot.error?.toString() ?? 'Unknown error';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load report preview.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      errorText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _pdfBytes = _loadPdfBytes();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          try {
            return SfPdfViewer.memory(
              snapshot.data!,
              canShowScrollHead: true,
              canShowScrollStatus: true,
            );
          } catch (e) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'PDF viewer error: $e',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
