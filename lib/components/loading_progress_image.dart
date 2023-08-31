import 'package:flutter/material.dart';

class LoadingProgressImage extends StatelessWidget {
  const LoadingProgressImage({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.errorBuilder,
  });

  final ImageProvider<Object> image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Alignment alignment;
  final Widget Function(BuildContext ctx, Object error, StackTrace? trace)?
      errorBuilder;

  double get _loadingSize {
    double size = 100;

    if (height != null) {
      size = height! * 0.35;
      if (width != null && width! < height!) size = width! * 0.35;
    }

    return size;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image(
        image: image,
        fit: fit,
        height: height,
        width: width,
        alignment: alignment,
        errorBuilder: errorBuilder ??
            (ctx, e, trace) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Failed to load media!",
                  style: TextStyle(
                    fontSize: _loadingSize * 0.2,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
              );
            },
        loadingBuilder: (context, child, chuck) {
          double? progress;

          if (chuck == null) {
            return Center(child: child);
          }

          if (chuck.expectedTotalBytes != null &&
              chuck.expectedTotalBytes != null) {
            progress = chuck.cumulativeBytesLoaded / chuck.expectedTotalBytes!;
          }

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: _loadingSize,
                  width: _loadingSize,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: CircularProgressIndicator(
                      value: progress,
                      color: Colors.grey.withOpacity(0.5),
                      strokeWidth: 2,
                    ),
                  ),
                ),
                Text(
                  "${((progress ?? 0) * 100).toInt()}%",
                  style: TextStyle(
                    fontSize: _loadingSize * 0.2,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
