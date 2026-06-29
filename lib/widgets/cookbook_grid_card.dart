import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_dimensions.dart';

class CookbookGridCard extends StatelessWidget {
  final String title;
  final int recipeCount;
  final List<String> imageUrls;
  final VoidCallback? onTap;

  const CookbookGridCard({
    super.key,
    required this.title,
    required this.recipeCount,
    this.imageUrls = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  AppDimensions.radiusLg - 1,
                ),
                child: _buildGrid(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$recipeCount ${recipeCount == 1 ? 'recipe' : 'recipes'}',
            style: AppTextStyles.smallLabel,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _gridCell(0)),
              const SizedBox(width: 1.5),
              Expanded(child: _gridCell(1)),
            ],
          ),
        ),
        const SizedBox(height: 1.5),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _gridCell(2)),
              const SizedBox(width: 1.5),
              Expanded(child: _gridCell(3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gridCell(int index) {
    if (index < imageUrls.length && imageUrls[index].isNotEmpty) {
      return Image.network(
        imageUrls[index],
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.iconLight,
          size: 24,
        ),
      ),
    );
  }
}
