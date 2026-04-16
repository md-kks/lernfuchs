import 'package:flutter/material.dart';
import '../../shared/constants/app_colors.dart';

class ShellPlaceholderScreen extends StatelessWidget {
  final String title;

  const ShellPlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          '$title kommt später.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
