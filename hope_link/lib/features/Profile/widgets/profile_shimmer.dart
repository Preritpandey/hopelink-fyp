import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            const CircleAvatar(radius: 50),
            const SizedBox(height: 20),
            Container(height: 20, width: 200, color: Colors.white),
            const SizedBox(height: 10),
            Container(height: 16, width: 150, color: Colors.white),
            const SizedBox(height: 20),
            Container(height: 50, width: double.infinity, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
