import 'package:flutter/material.dart';
import 'package:recipe_ai/widgets/app_wordmark.dart';
import 'package:recipe_ai/theme/app_colors.dart';
import 'package:recipe_ai/theme/app_text_styles.dart';
import 'package:recipe_ai/theme/app_dimensions.dart';
import 'package:recipe_ai/widgets/app_bottom_nav.dart';
import 'package:recipe_ai/widgets/app_search_bar.dart';

class DiscoverFeedScreen extends StatefulWidget {
  const DiscoverFeedScreen({super.key});

  @override
  State<DiscoverFeedScreen> createState() => _DiscoverFeedScreenState();
}

class _DiscoverFeedScreenState extends State<DiscoverFeedScreen> {
  int _selectedFilter = 0;

  final _filters = ['All', 'Quick & Easy', 'Vegan', 'Desserts', 'Breakfast'];

  final _posts = const [
    _PostData(
      author: 'Sarah Mitchell',
      avatar: 'SM',
      timeAgo: '2h ago',
      title: 'Spicy Tomato Rigatoni',
      image: 'rigatoni',
      cookTime: '35 min',
      likes: 142,
      comments: 28,
    ),
    _PostData(
      author: 'James Chen',
      avatar: 'JC',
      timeAgo: '5h ago',
      title: 'Crispy Honey Garlic Salmon',
      image: 'salmon',
      cookTime: '25 min',
      likes: 89,
      comments: 15,
    ),
    _PostData(
      author: 'Priya Sharma',
      avatar: 'PS',
      timeAgo: '8h ago',
      title: 'Rainbow Buddha Bowl',
      image: 'buddha',
      cookTime: '20 min',
      likes: 216,
      comments: 42,
    ),
    _PostData(
      author: 'Emily Davis',
      avatar: 'ED',
      timeAgo: '1d ago',
      title: 'Brown Butter Choc Cookies',
      image: 'cookies',
      cookTime: '45 min',
      likes: 324,
      comments: 67,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AppSearchBar(hintText: 'Search community recipes'),
                  ),
                  const SizedBox(height: 16),
                  _buildFilterChips(),
                  const SizedBox(height: 18),
                  ..._posts.map((post) => _buildPostCard(post)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 1, onTap: (i) {}),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 8),
          AppWordmark(fontSize: 18),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.goldBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(
                  '4/5',
                  style: AppTextStyles.tagLabel.copyWith(color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == _selectedFilter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                border: selected
                    ? null
                    : Border.all(color: AppColors.surfaceBorderLight),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primaryShadow.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _filters[index],
                style: AppTextStyles.chipLabel.copyWith(
                  color: selected ? Colors.white : AppColors.textBodyDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPostCard(_PostData post) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                _buildAvatar(post.avatar, 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: AppTextStyles.chipLabel.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: AppTextStyles.smallLabel.copyWith(
                          fontSize: 11.5,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'View recipe >',
                    style: AppTextStyles.link.copyWith(fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          // Photo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: Stack(
                children: [
                  Container(
                    height: 280,
                    width: double.infinity,
                    color: _getPostColor(post.image),
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 60,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  // Time badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 13,
                            color: AppColors.textMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            post.cookTime,
                            style: AppTextStyles.smallLabel.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Title overlay
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 30, 16, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                      child: Text(
                        post.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.favorite, size: 22, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  '${post.likes}',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(width: 18),
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: AppColors.textMedium,
                ),
                const SizedBox(width: 5),
                Text(
                  '${post.comments}',
                  style: AppTextStyles.chipLabel.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
                const SizedBox(width: 18),
                const Icon(
                  Icons.send_outlined,
                  size: 20,
                  color: AppColors.textMedium,
                ),
                const Spacer(),
                const Icon(
                  Icons.bookmark_border,
                  size: 22,
                  color: AppColors.textMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFF2623E), Color(0xFFFF8763)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTextStyles.smallLabel.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.32,
          ),
        ),
      ),
    );
  }

  Color _getPostColor(String image) {
    switch (image) {
      case 'rigatoni':
        return const Color(0xFFD44A2E);
      case 'salmon':
        return const Color(0xFFE8976B);
      case 'buddha':
        return const Color(0xFF5BA87A);
      case 'cookies':
        return const Color(0xFF8B6340);
      default:
        return AppColors.textMedium;
    }
  }
}

class _PostData {
  final String author;
  final String avatar;
  final String timeAgo;
  final String title;
  final String image;
  final String cookTime;
  final int likes;
  final int comments;

  const _PostData({
    required this.author,
    required this.avatar,
    required this.timeAgo,
    required this.title,
    required this.image,
    required this.cookTime,
    required this.likes,
    required this.comments,
  });
}
