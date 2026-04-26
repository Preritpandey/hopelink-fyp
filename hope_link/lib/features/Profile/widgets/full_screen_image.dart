import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const FullScreenImageView({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: heroTag == null
            ? InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              )
            : Hero(
                tag: heroTag!,
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
      ),
    );
  }
}
