import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/constants.dart';

class LoadingWidget extends StatelessWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const LoadingWidget({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.of(context).cardDark,
      highlightColor: AppColors.of(context).cardMedium,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.of(context).cardDark,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class LoadingListWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const LoadingListWidget({
    super.key,
    this.itemCount = 8,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => LoadingWidget(height: itemHeight),
    );
  }
}

class LoadingGridWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final int crossAxisCount;

  const LoadingGridWidget({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 100,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => LoadingWidget(height: itemHeight),
    );
  }
}

class LoadingCardWidget extends StatelessWidget {
  const LoadingCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.of(context).cardDark,
      highlightColor: AppColors.of(context).cardMedium,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 100, color: AppColors.of(context).cardMedium, margin: EdgeInsets.only(bottom: 8)),
            Container(height: 24, width: 60, color: AppColors.of(context).cardMedium),
            const SizedBox(height: 8),
            Container(height: 12, width: 140, color: AppColors.of(context).cardMedium),
          ],
        ),
      ),
    );
  }
}
