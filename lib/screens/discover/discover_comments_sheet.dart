import 'package:flutter/material.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/bottom_sheet_handle.dart';

class DiscoverCommentsSheet extends StatelessWidget {
  const DiscoverCommentsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusSheet),
              ),
            ),
            child: _CommentsContent(scrollController: scrollController),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _CommentsContent extends StatelessWidget {
  final ScrollController scrollController;

  const _CommentsContent({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final comments = [
      const _CommentData(
        name: 'Alex Kim',
        initials: 'AK',
        timeAgo: '1h ago',
        text:
            'Made this last night and it was incredible! The red pepper flakes really make it.',
      ),
      const _CommentData(
        name: 'Maria Lopez',
        initials: 'ML',
        timeAgo: '3h ago',
        text: 'Can I substitute penne for rigatoni? Looks so good!',
      ),
      const _CommentData(
        name: 'Tom Wilson',
        initials: 'TW',
        timeAgo: '6h ago',
        text:
            'Added some Italian sausage and it was next level! My whole family loved it.',
      ),
      const _CommentData(
        name: 'Priya Sharma',
        initials: 'PS',
        timeAgo: '8h ago',
        text:
            'This is now a weekly staple in our house. Thank you for sharing!',
      ),
      const _CommentData(
        name: 'James Chen',
        initials: 'JC',
        timeAgo: '1d ago',
        text: 'Perfect weeknight dinner. Quick and so flavourful.',
      ),
    ];

    return Column(
      children: [
        const BottomSheetHandle(),
        const SizedBox(height: 8),
        // Title row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Comments',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusRound,
                  ),
                ),
                child: Text(
                  '28',
                  style: AppTextStyles.smallLabel.copyWith(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.divider, height: 1),
        // Comments list
        Expanded(
          child: ListView.separated(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            itemCount: comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final c = comments[index];
              return _buildComment(c);
            },
          ),
        ),
        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: AppDimensions.inputHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusRound,
                      ),
                      border: Border.all(color: AppColors.surfaceBorderLight),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add a comment...',
                      style: AppTextStyles.inputHint,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 42,
                  height: 42,

                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComment(_CommentData c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceBorder,
          ),
          child: Center(
            child: Text(
              c.initials,
              style: AppTextStyles.smallLabel.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    c.name,
                    style: AppTextStyles.chipLabel.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    c.timeAgo,
                    style: AppTextStyles.smallLabel.copyWith(
                      fontSize: 11.5,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                c.text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textBody,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Reply',
                  style: AppTextStyles.link.copyWith(
                    fontSize: 12,
                    color: AppColors.textMedium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentData {
  final String name;
  final String initials;
  final String timeAgo;
  final String text;

  const _CommentData({
    required this.name,
    required this.initials,
    required this.timeAgo,
    required this.text,
  });
}
