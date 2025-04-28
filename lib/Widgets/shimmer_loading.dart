import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    Key? key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        super(key: key);

  const ShimmerLoading.circular({
    Key? key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[400]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class BookCardShimmer extends StatelessWidget {
  const BookCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book cover
          ShimmerLoading.rectangular(height: 180),
          const SizedBox(height: 8),
          // Title
          ShimmerLoading.rectangular(height: 16),
          const SizedBox(height: 4),
          // Author
          ShimmerLoading.rectangular(height: 14, width: 100),
          const SizedBox(height: 4),
          // Price
          ShimmerLoading.rectangular(height: 14, width: 60),
        ],
      ),
    );
  }
}

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          ShimmerLoading.circular(width: 60, height: 60),
          const SizedBox(height: 8),
          ShimmerLoading.rectangular(height: 12, width: 60),
        ],
      ),
    );
  }
}

class BookListShimmer extends StatelessWidget {
  final int itemCount;

  const BookListShimmer({Key? key, this.itemCount = 3}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              ShimmerLoading.rectangular(width: 80, height: 120),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    ShimmerLoading.rectangular(height: 16),
                    const SizedBox(height: 8),
                    // Author
                    ShimmerLoading.rectangular(height: 14, width: 150),
                    const SizedBox(height: 8),
                    // Description
                    ShimmerLoading.rectangular(height: 12),
                    const SizedBox(height: 4),
                    ShimmerLoading.rectangular(height: 12),
                    const SizedBox(height: 4),
                    ShimmerLoading.rectangular(height: 12, width: 200),
                    const SizedBox(height: 8),
                    // Price
                    ShimmerLoading.rectangular(height: 14, width: 60),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
