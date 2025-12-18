import 'package:flutter/material.dart';
import 'package:hope_link/core/theme/app_colors.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            thickness: 1,
            color: AppColorToken.grey.color,
            indent: 20,
            endIndent: 10,
          ),
        ),
        const Text("Or sign up with", style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Divider(
            thickness: 1,
            color: AppColorToken.grey.color,
            indent: 10,
            endIndent: 20,
          ),
        ),
      ],
    );
  }
}
