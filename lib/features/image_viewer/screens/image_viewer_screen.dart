import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/widgets/local_image_view.dart';

class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({
    super.key,
    required this.imageFileNames,
    this.initialIndex = 0,
  });

  final List<String> imageFileNames;
  final int initialIndex;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageFileNames.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int total = widget.imageFileNames.length;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (int index) => setState(() => _currentIndex = index),
                itemBuilder: (BuildContext context, int index) {
                  return InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: Center(
                      child: LocalImageView(
                        fileName: widget.imageFileNames[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                        tooltip: 'Close',
                      ),
                      const Spacer(),
                      if (total > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            '${_currentIndex + 1} / $total',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
