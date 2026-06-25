// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:recipe_ai/Controllers/cookbook_controller.dart';
// // import 'package:recipe_ai/Controllers/home_controller.dart';
// // import 'package:recipe_ai/Core/Theme/app_theme.dart';
// // import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
// // import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
// // import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';

// // import 'package:recipe_ai/View/Home/home_screen.dart';
// // import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
// // import 'package:recipe_ai/Widget/custom_snackbar.dart';
// // import 'package:recipe_ai/Widget/custom_text.dart';
// // import 'package:url_launcher/url_launcher.dart';

// // class RecipeDetailScreen extends StatefulWidget {
// //   final RecipeModel recipe;

// //   const RecipeDetailScreen({super.key, required this.recipe});

// //   @override
// //   State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
// // }

// // class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
// //   late int _initialServings;
// //   late int _servings;
// //   @override
// //   void initState() {
// //     super.initState();
// //     // Parse servings from recipe (e.g. "4 servings", "Serves 4", "4")
// //     int parsed = 2;
// //     if (widget.recipe.servings != null) {
// //       final match = RegExp(r'\d+').firstMatch(widget.recipe.servings!);
// //       if (match != null) parsed = int.tryParse(match.group(0)!) ?? 4;
// //     }
// //     _initialServings = parsed <= 0 ? 2 : parsed;
// //     _servings = _initialServings;
// //   }

// //   // ── Add all ingredients to the grocery store ─────────────────────────────
// //   void _addToGroceries() {
// //     final groceryController = Get.find<GroceryStore>();

// //     final multiplier = _servings / _initialServings;
// //     final scaledIngredients = widget.recipe.ingredients.map((ingredient) {
// //       return IngredientScaleHelper.scaleIngredient(ingredient, multiplier);
// //     }).toList();

// //     groceryController.addFromRecipe(widget.recipe.id, scaledIngredients);

// //     CustomSnackbar.show(
// //       title:
// //           '${widget.recipe.ingredients.length} ingredients added to groceries',

// //       actionText: 'View',
// //       onAction: () {
// //         HomeScreen.activeIndex = 2; // Groceries tab
// //         Get.offUntil(
// //           MaterialPageRoute(builder: (_) => const HomeScreen()),
// //           (route) => route.isFirst,
// //         );
// //       },
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final recipe = widget.recipe;

// //     return Scaffold(
// //       body: CustomScrollView(
// //         slivers: [
// //           // ── Hero app bar ────────────────────────────────────────────
// //           SliverAppBar(
// //             scrolledUnderElevation: 0,
// //             pinned: true,
// //             centerTitle: false,
// //             title: CustomText(
// //               recipe.title,
// //               maxLines: 1,
// //               fontSize: 22,
// //               fontWeight: FontWeight.w700,
// //               color: AppTheme.textPrimary(context),

// //               overflow: TextOverflow.ellipsis,
// //             ),
// //             actions: [
// //               IconButton(
// //                 icon: Icon(
// //                   Icons.edit_outlined,
// //                   color: AppTheme.textPrimary(context),
// //                 ),
// //                 onPressed: () {
// //                   Get.to(() => RecipeEditorScreen(recipe: recipe));
// //                 },
// //               ),

// //               PopupMenuButton<String>(
// //                 icon: Icon(
// //                   Icons.more_vert,
// //                   color: AppTheme.textPrimary(context),
// //                 ),
// //                 onSelected: (value) async {
// //                   switch (value) {
// //                     case 'edit':
// //                       Get.to(() => RecipeEditorScreen(recipe: recipe));
// //                       break;

// //                     case 'delete':
// //                       Get.dialog(
// //                         AlertDialog(
// //                           title: const Text('Delete Recipe'),
// //                           content: Text(
// //                             'Are you sure you want to delete "${recipe.title}"?',
// //                           ),
// //                           actions: [
// //                             TextButton(
// //                               onPressed: () => Get.back(),
// //                               child: const Text('Cancel'),
// //                             ),
// //                             ElevatedButton(
// //                               style: ElevatedButton.styleFrom(
// //                                 backgroundColor: Colors.red,
// //                                 foregroundColor: Colors.white,
// //                               ),
// //                               onPressed: () async {
// //                                 Get.back();
// //                                 Get.back();
// //                                 await Get.find<HomeController>().deleteRecipe(
// //                                   recipe,
// //                                 );

// //                                 Get.back(); // Recipe Detail Screen close
// //                               },
// //                               child: const Text('Delete'),
// //                             ),
// //                           ],
// //                         ),
// //                       );
// //                       break;
// //                   }
// //                 },
// //                 itemBuilder: (context) => [
// //                   const PopupMenuItem(
// //                     value: 'edit',
// //                     child: Row(
// //                       children: [
// //                         Icon(Icons.edit_outlined),
// //                         SizedBox(width: 12),
// //                         Text('Edit'),
// //                       ],
// //                     ),
// //                   ),
// //                   const PopupMenuItem(
// //                     value: 'delete',
// //                     child: Row(
// //                       children: [
// //                         Icon(Icons.delete_outline, color: Colors.red),
// //                         SizedBox(width: 12),
// //                         Text('Delete', style: TextStyle(color: Colors.red)),
// //                       ],
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ],
// //           ),

// //           SliverPadding(
// //             padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
// //             sliver: SliverList(
// //               delegate: SliverChildListDelegate([
// //                 RecipeImage(
// //                   imageUrl: recipe.imageUrl,
// //                   width: double.infinity,
// //                   height: 280,
// //                 ),
// //               ]),
// //             ),
// //           ),
// //           SliverPadding(
// //             padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
// //             sliver: SliverList(
// //               delegate: SliverChildListDelegate([
// //                 // ── Title ─────────────────────────────────────────────
// //                 CustomText(
// //                   recipe.title,
// //                   fontSize: 28,
// //                   fontWeight: FontWeight.w800,
// //                 ),
// //                 const SizedBox(height: 20),

// //                 // ── 4 Action buttons ──────────────────────────────────
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceAround,
// //                   children: [
// //                     _ActionButton(
// //                       icon: Icons.bookmark_add_outlined,
// //                       label: 'Cookbooks',
// //                       onTap: () {
// //                        final cookbookController= Get.find<CookbookController>();

// //                         cookbookController.addRecipeToCookbook(cookbookId, recipe.id, recipe.imageUrl)},
// //                     ),
// //                     _ActionButton(
// //                       icon: Icons.calendar_today_outlined,
// //                       label: 'Meal Plan',
// //                       onTap: () {},
// //                     ),
// //                     _ActionButton(
// //                       icon: Icons.add_shopping_cart_outlined,
// //                       label: 'Groceries',
// //                       onTap: _addToGroceries,
// //                     ),
// //                     _ActionButton(
// //                       icon: Icons.share_outlined,
// //                       label: 'Share',
// //                       onTap: () {},
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 22),
// //                 const Divider(),
// //                 const SizedBox(height: 14),

// //                 // ── RECIPE NOTES label ────────────────────────────────
// //                 CustomText(
// //                   'RECIPE NOTES',

// //                   fontSize: 12,
// //                   fontWeight: FontWeight.w700,
// //                   letterSpacing: 0.9,
// //                   color: Theme.of(context).colorScheme.primary,
// //                 ),
// //                 const SizedBox(height: 12),

// //                 // ── Meta pills (prep / cook / total / etc.) ───────────
// //                 Wrap(
// //                   spacing: 10,
// //                   runSpacing: 10,
// //                   children: [
// //                     if (recipe.prepTime != null)
// //                       _InfoPill(
// //                         icon: Icons.timer_outlined,
// //                         label: 'Prep ${recipe.prepTime}',
// //                       ),
// //                     if (recipe.cookTime != null)
// //                       _InfoPill(
// //                         icon: Icons.local_fire_department_outlined,
// //                         label: 'Cook ${recipe.cookTime}',
// //                       ),
// //                     if (recipe.totalTime != null)
// //                       _InfoPill(
// //                         icon: Icons.schedule,
// //                         label: 'Total ${recipe.totalTime}',
// //                       ),
// //                     _InfoPill(
// //                       icon: Icons.shopping_basket_outlined,
// //                       label: '${recipe.ingredients.length} ingredients',
// //                     ),
// //                     _InfoPill(
// //                       icon: Icons.format_list_numbered,
// //                       label: '${recipe.instructions.length} steps',
// //                     ),
// //                   ],
// //                 ),

// //                 // ── Open website link ─────────────────────────────────
// //                 if (recipe.sourceUrl.isNotEmpty) ...[
// //                   const SizedBox(height: 12),
// //                   GestureDetector(
// //                     onTap: () async {
// //                       final uri = Uri.tryParse(recipe.sourceUrl);
// //                       if (uri != null) {
// //                         await launchUrl(
// //                           uri,
// //                           mode: LaunchMode.externalApplication,
// //                         );
// //                       }
// //                     },
// //                     child: Row(
// //                       children: [
// //                         CustomText(
// //                           'Open website ',
// //                           color: Colors.grey.shade500,
// //                           decoration: TextDecoration.underline,
// //                           decorationColor: Colors.grey.shade500,
// //                         ),
// //                         Icon(Icons.open_in_new),
// //                       ],
// //                     ),
// //                   ),
// //                 ],

// //                 // ── Star rating ───────────────────────────────────────
// //                 const SizedBox(height: 16),
// //                 Row(
// //                   children: [
// //                     const CustomText(
// //                       'Your rating',
// //                       fontWeight: FontWeight.w600,
// //                     ),

// //                     const SizedBox(width: 10),
// //                     ...List.generate(
// //                       5,
// //                       (_) => const Icon(
// //                         Icons.star_border,
// //                         size: 22,
// //                         color: Colors.grey,
// //                       ),
// //                     ),
// //                     const Spacer(),
// //                     TextButton(
// //                       onPressed: () {},
// //                       child: CustomText(
// //                         'Add',
// //                         color: Theme.of(context).colorScheme.primary,
// //                         fontWeight: FontWeight.w600,
// //                       ),
// //                     ),
// //                   ],
// //                 ),

// //                 // ── Notes box ────────────────────────────────────────
// //                 Container(
// //                   width: double.infinity,
// //                   padding: const EdgeInsets.all(14),
// //                   decoration: BoxDecoration(
// //                     color: Theme.of(context).colorScheme.surface,
// //                     borderRadius: BorderRadius.circular(12),
// //                     border: Border.all(color: Colors.grey.shade200),
// //                   ),
// //                   child: CustomText(
// //                     'No notes yet',
// //                     color: Colors.grey.shade400,
// //                   ),
// //                 ),

// //                 // ── Description ───────────────────────────────────────
// //                 if (recipe.description != null) ...[
// //                   const SizedBox(height: 18),
// //                   CustomText(
// //                     recipe.description!,
// //                     fontSize: 16,
// //                     height: 1.5,
// //                     color: Colors.grey.shade700,
// //                   ),
// //                 ],

// //                 // ── Category / cuisine / keyword chips ────────────────
// //                 if (recipe.category != null ||
// //                     recipe.cuisine != null ||
// //                     recipe.keywords.isNotEmpty) ...[
// //                   const SizedBox(height: 16),
// //                   Wrap(
// //                     spacing: 8,
// //                     runSpacing: 8,
// //                     children: [
// //                       if (recipe.category != null)
// //                         _TagChip(label: recipe.category!),
// //                       if (recipe.cuisine != null)
// //                         _TagChip(label: recipe.cuisine!),
// //                       ...recipe.keywords.take(6).map((k) => _TagChip(label: k)),
// //                     ],
// //                   ),
// //                 ],

// //                 const SizedBox(height: 26),
// //                 const Divider(),
// //                 const SizedBox(height: 16),

// //                 // ════════════════════════════════════════════════════
// //                 // INGREDIENTS section
// //                 // ════════════════════════════════════════════════════
// //                 CustomText(
// //                   'INGREDIENTS',
// //                   fontSize: 12,
// //                   fontWeight: FontWeight.w700,
// //                   letterSpacing: 0.9,
// //                   color: Theme.of(context).colorScheme.primary,
// //                 ),

// //                 const SizedBox(height: 16),

// //                 // ── Servings stepper ──────────────────────────────────
// //                 Row(
// //                   children: [
// //                     _StepperButton(
// //                       icon: Icons.remove,
// //                       enabled: _servings > 1,
// //                       onTap: () => setState(() => _servings--),
// //                     ),
// //                     const SizedBox(width: 16),
// //                     CustomText(
// //                       '$_servings',
// //                       fontSize: 18,
// //                       fontWeight: FontWeight.w700,
// //                     ),
// //                     const SizedBox(width: 16),
// //                     _StepperButton(
// //                       icon: Icons.add,
// //                       enabled: true,
// //                       onTap: () => setState(() => _servings++),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     const CustomText(
// //                       'servings',
// //                       fontSize: 15,
// //                       fontWeight: FontWeight.w700,
// //                     ),
// //                     const Spacer(),
// //                     // Convert button (premium – placeholder)
// //                     OutlinedButton.icon(
// //                       onPressed: () {},
// //                       icon: const Icon(Icons.auto_awesome, size: 15),
// //                       label: const CustomText('Convert'),
// //                       style: OutlinedButton.styleFrom(
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 12,
// //                           vertical: 8,
// //                         ),
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(20),
// //                         ),
// //                         side: BorderSide(color: Colors.grey.shade300),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 14),

// //                 // ── Ingredient list ───────────────────────────────────
// //                 ..._buildIngredients(context),
// //                 const SizedBox(height: 18),

// //                 // ── Add to groceries button ───────────────────────────
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton.icon(
// //                     onPressed: _addToGroceries,
// //                     icon: const Icon(Icons.add_shopping_cart_outlined),
// //                     label: const CustomText('Add to groceries'),
// //                     style: OutlinedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 14),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       side: BorderSide(
// //                         color: Theme.of(context).colorScheme.primary,
// //                       ),
// //                     ),
// //                   ),
// //                 ),

// //                 const SizedBox(height: 26),
// //                 const Divider(),
// //                 const SizedBox(height: 16),

// //                 // ════════════════════════════════════════════════════
// //                 // INSTRUCTIONS section
// //                 // ════════════════════════════════════════════════════
// //                 CustomText(
// //                   'INSTRUCTIONS',
// //                   fontSize: 12,
// //                   fontWeight: FontWeight.w700,
// //                   letterSpacing: 0.9,
// //                   color: Theme.of(context).colorScheme.primary,
// //                 ),

// //                 const SizedBox(height: 12),

// //                 // Cook step-by-step button
// //                 SizedBox(
// //                   width: double.infinity,
// //                   child: OutlinedButton.icon(
// //                     onPressed: () {},
// //                     icon: const Icon(Icons.play_circle_outline),
// //                     label: const CustomText('Cook step-by-step'),
// //                     style: OutlinedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 14),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(12),
// //                       ),
// //                       side: BorderSide(color: Colors.grey.shade300),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 16),

// //                 ..._buildInstructions(context),
// //               ]),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // ── Ingredient list builder ───────────────────────────────────────────────
// //   List<Widget> _buildIngredients(BuildContext context) {
// //     // Sections check + items check both
// //     final hasAnyItems = widget.recipe.ingredientSections.any(
// //       (s) => s.items.isNotEmpty,
// //     );

// //     if (widget.recipe.ingredientSections.isEmpty || !hasAnyItems) {
// //       // flat ingredients fallback
// //       if (widget.recipe.ingredients.isNotEmpty) {
// //         return widget.recipe.ingredients
// //             .map((ing) => _DetailBullet(text: ing) as Widget)
// //             .toList();
// //       }
// //       return [CustomText('No ingredients found.')];
// //     }
// //     final multiplier = _servings / _initialServings;
// //     final widgets = <Widget>[];
// //     for (final section in widget.recipe.ingredientSections) {
// //       if (section.name != null && section.name!.isNotEmpty) {
// //         widgets.add(
// //           Padding(
// //             padding: const EdgeInsets.only(top: 14, bottom: 6),
// //             child: CustomText(
// //               section.name!,
// //               fontSize: 16,
// //               fontWeight: FontWeight.w700,
// //               color: Theme.of(context).colorScheme.primary,
// //             ),
// //           ),
// //         );
// //       }
// //       for (final ingredient in section.items) {
// //         final scaledIngredient = IngredientScaleHelper.scaleIngredient(
// //           ingredient,
// //           multiplier,
// //         );
// //         widgets.add(_DetailBullet(text: scaledIngredient));
// //       }
// //     }
// //     return widgets;
// //   }

// //   // ── Instruction list builder ──────────────────────────────────────────────
// //   List<Widget> _buildInstructions(BuildContext context) {
// //     final hasSectionSteps = widget.recipe.instructionSections.any(
// //       (s) => s.steps.isNotEmpty,
// //     );

// //     if (!hasSectionSteps) {
// //       if (widget.recipe.instructions.isNotEmpty) {
// //         return widget.recipe.instructions
// //             .asMap()
// //             .entries
// //             .map((e) => _InstructionStep(number: e.key + 1, text: e.value))
// //             .toList();
// //       }
// //       return [
// //         CustomText(
// //           'No instructions found.',
// //           fontSize: 15,
// //           fontWeight: FontWeight.w700,
// //           color: Colors.grey.shade600,
// //         ),
// //       ];
// //     }

// //     final widgets = <Widget>[];
// //     var stepNum = 1;
// //     for (final section in widget.recipe.instructionSections) {
// //       if (section.steps.isEmpty) continue;

// //       if (section.name != null && section.name!.isNotEmpty) {
// //         widgets.add(
// //           Padding(
// //             padding: const EdgeInsets.only(top: 14, bottom: 10),
// //             child: CustomText(
// //               section.name!,
// //               fontSize: 16,
// //               fontWeight: FontWeight.w700,
// //               color: Theme.of(context).colorScheme.primary,
// //             ),
// //           ),
// //         );
// //       }
// //       for (final step in section.steps) {
// //         widgets.add(_InstructionStep(number: stepNum, text: step));
// //         stepNum++;
// //       }
// //     }
// //     return widgets;
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Action button (Cookbooks / Meal Plan / Groceries / Share)
// // // ─────────────────────────────────────────────────────────────────────────────

// // class _ActionButton extends StatelessWidget {
// //   final IconData icon;
// //   final String label;
// //   final VoidCallback onTap;

// //   const _ActionButton({
// //     required this.icon,
// //     required this.label,
// //     required this.onTap,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return GestureDetector(
// //       onTap: onTap,
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Container(
// //             width: 58,
// //             height: 58,
// //             decoration: BoxDecoration(
// //               shape: BoxShape.circle,
// //               border: Border.all(
// //                 color: Theme.of(
// //                   context,
// //                 ).colorScheme.primary.withValues(alpha: 0.35),
// //                 width: 1.5,
// //               ),
// //             ),
// //             child: Icon(
// //               icon,
// //               color: Theme.of(context).colorScheme.primary,
// //               size: 25,
// //             ),
// //           ),
// //           const SizedBox(height: 6),
// //           CustomText(label, fontSize: 12, fontWeight: FontWeight.w500),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Servings stepper button  (− / +)
// // // ─────────────────────────────────────────────────────────────────────────────

// // class _StepperButton extends StatelessWidget {
// //   final IconData icon;
// //   final bool enabled;
// //   final VoidCallback onTap;

// //   const _StepperButton({
// //     required this.icon,
// //     required this.enabled,
// //     required this.onTap,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     final color = enabled
// //         ? Theme.of(context).colorScheme.primary
// //         : Colors.grey.shade300;

// //     return GestureDetector(
// //       onTap: enabled ? onTap : null,
// //       child: Container(
// //         width: 38,
// //         height: 38,
// //         decoration: BoxDecoration(
// //           borderRadius: BorderRadius.circular(20),
// //           border: Border.all(color: color, width: 1.5),
// //         ),
// //         child: Icon(icon, size: 18, color: color),
// //       ),
// //     );
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Meta info pill
// // // ─────────────────────────────────────────────────────────────────────────────

// // class _InfoPill extends StatelessWidget {
// //   final IconData icon;
// //   final String label;

// //   const _InfoPill({required this.icon, required this.label});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
// //       decoration: BoxDecoration(
// //         color: AppTheme.primary.withValues(alpha: 0.1),
// //         borderRadius: BorderRadius.circular(20),
// //       ),
// //       child: Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Icon(icon, size: 16, color: AppTheme.primary),
// //           const SizedBox(width: 6),
// //           Expanded(
// //             child: CustomText(label, fontSize: 13, fontWeight: FontWeight.w600),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Category / keyword tag chip
// // // ─────────────────────────────────────────────────────────────────────────────

// // class _TagChip extends StatelessWidget {
// //   final String label;

// //   const _TagChip({required this.label});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Chip(
// //       label: CustomText(label, color: AppTheme.primary),
// //       backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
// //       side: BorderSide.none,
// //       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
// //     );
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Ingredient bullet row
// // // ─────────────────────────────────────────────────────────────────────────────

// // class _DetailBullet extends StatelessWidget {
// //   final String text;

// //   const _DetailBullet({required this.text});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 10),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           const Padding(
// //             padding: EdgeInsets.only(top: 4, right: 10),
// //             child: Icon(Icons.circle, size: 7),
// //           ),
// //           Expanded(child: CustomText(text, fontSize: 15)),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Numbered instruction step
// // // ─────────────────────────────────────────────────────────────────────────────

// // class _InstructionStep extends StatelessWidget {
// //   final int number;
// //   final String text;

// //   const _InstructionStep({required this.number, required this.text});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 16),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Container(
// //             width: 30,
// //             height: 30,
// //             alignment: Alignment.center,
// //             decoration: BoxDecoration(
// //               color: Theme.of(context).colorScheme.primary,
// //               shape: BoxShape.circle,
// //             ),
// //             child: CustomText(
// //               '$number',
// //               color: Colors.white,
// //               fontWeight: FontWeight.w700,
// //             ),
// //           ),
// //           const SizedBox(width: 12),
// //           Expanded(child: CustomText(text, fontSize: 15)),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // void showDeleteRecipeDialog(RecipeModel recipe, HomeController controller) {
// //   Get.dialog(
// //     AlertDialog(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
// //       title: const Text("Delete Recipe"),
// //       content: Text("Are you sure you want to delete '${recipe.title}'?"),
// //       actions: [
// //         TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
// //         ElevatedButton(
// //           style: ElevatedButton.styleFrom(
// //             backgroundColor: Colors.red,
// //             foregroundColor: Colors.white,
// //           ),
// //           onPressed: () async {
// //             Get.back();
// //             await controller.deleteRecipe(recipe);
// //           },
// //           child: const Text("Delete"),
// //         ),
// //       ],
// //     ),
// //   );
// // }

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:recipe_ai/Controllers/cookbook_controller.dart';
// import 'package:recipe_ai/Controllers/home_controller.dart';
// import 'package:recipe_ai/Core/Theme/app_theme.dart';
// import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
// import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
// import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';

// import 'package:recipe_ai/View/Home/home_screen.dart';
// import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
// import 'package:recipe_ai/Widget/custom_snackbar.dart';
// import 'package:recipe_ai/Widget/custom_text.dart';
// import 'package:url_launcher/url_launcher.dart';

// class RecipeDetailScreen extends StatefulWidget {
//   final RecipeModel recipe;

//   const RecipeDetailScreen({super.key, required this.recipe});

//   @override
//   State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
// }

// class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
//   late int _initialServings;
//   late int _servings;

//   @override
//   void initState() {
//     super.initState();
//     int parsed = 2;
//     if (widget.recipe.servings != null) {
//       final match = RegExp(r'\d+').firstMatch(widget.recipe.servings!);
//       if (match != null) parsed = int.tryParse(match.group(0)!) ?? 4;
//     }
//     _initialServings = parsed <= 0 ? 2 : parsed;
//     _servings = _initialServings;
//   }

//   // ── Add to groceries ───────────────────────────────────────────────────────
//   void _addToGroceries() {
//     final groceryController = Get.find<GroceryStore>();
//     final multiplier = _servings / _initialServings;
//     final scaledIngredients = widget.recipe.ingredients.map((ingredient) {
//       return IngredientScaleHelper.scaleIngredient(ingredient, multiplier);
//     }).toList();

//     groceryController.addFromRecipe(widget.recipe.id, scaledIngredients);

//     CustomSnackbar.show(
//       title:
//           '${widget.recipe.ingredients.length} ingredients added to groceries',
//       actionText: 'View',
//       onAction: () {
//         HomeScreen.activeIndex = 2;
//         Get.offUntil(
//           MaterialPageRoute(builder: (_) => const HomeScreen()),
//           (route) => route.isFirst,
//         );
//       },
//     );
//   }

//   // ── Cookbook bottom sheet ──────────────────────────────────────────────────
//   void _showCookbookPicker() {
//     final cookbookController = Get.find<CookbookController>();
//     final recipe = widget.recipe;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => _CookbookPickerSheet(
//         cookbookController: cookbookController,
//         recipeId: recipe.id,
//         recipeImageUrl: recipe.imageUrl,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final recipe = widget.recipe;

//     return Scaffold(
//       body: CustomScrollView(
//         slivers: [
//           // ── Hero app bar ──────────────────────────────────────────────────
//           SliverAppBar(
//             scrolledUnderElevation: 0,
//             pinned: true,
//             centerTitle: false,
//             title: CustomText(
//               recipe.title,
//               maxLines: 1,
//               fontSize: 22,
//               fontWeight: FontWeight.w700,
//               color: AppTheme.textPrimary(context),
//               overflow: TextOverflow.ellipsis,
//             ),
//             actions: [
//               IconButton(
//                 icon: Icon(
//                   Icons.edit_outlined,
//                   color: AppTheme.textPrimary(context),
//                 ),
//                 onPressed: () =>
//                     Get.to(() => RecipeEditorScreen(recipe: recipe)),
//               ),
//               PopupMenuButton<String>(
//                 icon: Icon(
//                   Icons.more_vert,
//                   color: AppTheme.textPrimary(context),
//                 ),
//                 onSelected: (value) async {
//                   switch (value) {
//                     case 'edit':
//                       Get.to(() => RecipeEditorScreen(recipe: recipe));
//                       break;
//                     case 'delete':
//                       Get.dialog(
//                         AlertDialog(
//                           title: const Text('Delete Recipe'),
//                           content: Text(
//                             'Are you sure you want to delete "${recipe.title}"?',
//                           ),
//                           actions: [
//                             TextButton(
//                               onPressed: () => Get.back(),
//                               child: const Text('Cancel'),
//                             ),
//                             ElevatedButton(
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.red,
//                                 foregroundColor: Colors.white,
//                               ),
//                               onPressed: () async {
//                                 Get.back();
//                                 Get.back();
//                                 await Get.find<HomeController>().deleteRecipe(
//                                   recipe,
//                                 );
//                                 Get.back();
//                               },
//                               child: const Text('Delete'),
//                             ),
//                           ],
//                         ),
//                       );
//                       break;
//                   }
//                 },
//                 itemBuilder: (context) => [
//                   const PopupMenuItem(
//                     value: 'edit',
//                     child: Row(
//                       children: [
//                         Icon(Icons.edit_outlined),
//                         SizedBox(width: 12),
//                         Text('Edit'),
//                       ],
//                     ),
//                   ),
//                   const PopupMenuItem(
//                     value: 'delete',
//                     child: Row(
//                       children: [
//                         Icon(Icons.delete_outline, color: Colors.red),
//                         SizedBox(width: 12),
//                         Text('Delete', style: TextStyle(color: Colors.red)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),

//           SliverPadding(
//             padding: EdgeInsets.zero,
//             sliver: SliverList(
//               delegate: SliverChildListDelegate([
//                 RecipeImage(
//                   imageUrl: recipe.imageUrl,
//                   width: double.infinity,
//                   height: 280,
//                 ),
//               ]),
//             ),
//           ),

//           SliverPadding(
//             padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
//             sliver: SliverList(
//               delegate: SliverChildListDelegate([
//                 // ── Title ───────────────────────────────────────────────────
//                 CustomText(
//                   recipe.title,
//                   fontSize: 28,
//                   fontWeight: FontWeight.w800,
//                 ),
//                 const SizedBox(height: 20),

//                 // ── 4 Action buttons ─────────────────────────────────────────
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _ActionButton(
//                       icon: Icons.bookmark_add_outlined,
//                       label: 'Cookbooks',
//                       onTap: _showCookbookPicker,
//                     ),
//                     _ActionButton(
//                       icon: Icons.calendar_today_outlined,
//                       label: 'Meal Plan',
//                       onTap: () {},
//                     ),
//                     _ActionButton(
//                       icon: Icons.add_shopping_cart_outlined,
//                       label: 'Groceries',
//                       onTap: _addToGroceries,
//                     ),
//                     _ActionButton(
//                       icon: Icons.share_outlined,
//                       label: 'Share',
//                       onTap: () {},
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 22),
//                 const Divider(),
//                 const SizedBox(height: 14),

//                 // ── RECIPE NOTES label ───────────────────────────────────────
//                 CustomText(
//                   'RECIPE NOTES',
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.9,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//                 const SizedBox(height: 12),

//                 // ── Meta pills ───────────────────────────────────────────────
//                 Wrap(
//                   spacing: 10,
//                   runSpacing: 10,
//                   children: [
//                     if (recipe.prepTime != null)
//                       _InfoPill(
//                         icon: Icons.timer_outlined,
//                         label: 'Prep ${recipe.prepTime}',
//                       ),
//                     if (recipe.cookTime != null)
//                       _InfoPill(
//                         icon: Icons.local_fire_department_outlined,
//                         label: 'Cook ${recipe.cookTime}',
//                       ),
//                     if (recipe.totalTime != null)
//                       _InfoPill(
//                         icon: Icons.schedule,
//                         label: 'Total ${recipe.totalTime}',
//                       ),
//                     _InfoPill(
//                       icon: Icons.shopping_basket_outlined,
//                       label: '${recipe.ingredients.length} ingredients',
//                     ),
//                     _InfoPill(
//                       icon: Icons.format_list_numbered,
//                       label: '${recipe.instructions.length} steps',
//                     ),
//                   ],
//                 ),

//                 // ── Source link ──────────────────────────────────────────────
//                 if (recipe.sourceUrl.isNotEmpty) ...[
//                   const SizedBox(height: 12),
//                   GestureDetector(
//                     onTap: () async {
//                       final uri = Uri.tryParse(recipe.sourceUrl);
//                       if (uri != null) {
//                         await launchUrl(
//                           uri,
//                           mode: LaunchMode.externalApplication,
//                         );
//                       }
//                     },
//                     child: Row(
//                       children: [
//                         CustomText(
//                           'Open website ',
//                           color: Colors.grey.shade500,
//                           decoration: TextDecoration.underline,
//                           decorationColor: Colors.grey.shade500,
//                         ),
//                         const Icon(Icons.open_in_new),
//                       ],
//                     ),
//                   ),
//                 ],

//                 // ── Star rating ──────────────────────────────────────────────
//                 const SizedBox(height: 16),
//                 Row(
//                   children: [
//                     const CustomText(
//                       'Your rating',
//                       fontWeight: FontWeight.w600,
//                     ),
//                     const SizedBox(width: 10),
//                     ...List.generate(
//                       5,
//                       (_) => const Icon(
//                         Icons.star_border,
//                         size: 22,
//                         color: Colors.grey,
//                       ),
//                     ),
//                     const Spacer(),
//                     TextButton(
//                       onPressed: () {},
//                       child: CustomText(
//                         'Add',
//                         color: Theme.of(context).colorScheme.primary,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),

//                 // ── Notes box ────────────────────────────────────────────────
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     color: Theme.of(context).colorScheme.surface,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: CustomText(
//                     'No notes yet',
//                     color: Colors.grey.shade400,
//                   ),
//                 ),

//                 // ── Description ──────────────────────────────────────────────
//                 if (recipe.description != null) ...[
//                   const SizedBox(height: 18),
//                   CustomText(
//                     recipe.description!,
//                     fontSize: 16,
//                     height: 1.5,
//                     color: Colors.grey.shade700,
//                   ),
//                 ],

//                 // ── Tags ─────────────────────────────────────────────────────
//                 if (recipe.category != null ||
//                     recipe.cuisine != null ||
//                     recipe.keywords.isNotEmpty) ...[
//                   const SizedBox(height: 16),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       if (recipe.category != null)
//                         _TagChip(label: recipe.category!),
//                       if (recipe.cuisine != null)
//                         _TagChip(label: recipe.cuisine!),
//                       ...recipe.keywords.take(6).map((k) => _TagChip(label: k)),
//                     ],
//                   ),
//                 ],

//                 const SizedBox(height: 26),
//                 const Divider(),
//                 const SizedBox(height: 16),

//                 // ════════════════════════════════════════════════════════════
//                 // INGREDIENTS
//                 // ════════════════════════════════════════════════════════════
//                 CustomText(
//                   'INGREDIENTS',
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.9,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//                 const SizedBox(height: 16),

//                 Row(
//                   children: [
//                     _StepperButton(
//                       icon: Icons.remove,
//                       enabled: _servings > 1,
//                       onTap: () => setState(() => _servings--),
//                     ),
//                     const SizedBox(width: 16),
//                     CustomText(
//                       '$_servings',
//                       fontSize: 18,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     const SizedBox(width: 16),
//                     _StepperButton(
//                       icon: Icons.add,
//                       enabled: true,
//                       onTap: () => setState(() => _servings++),
//                     ),
//                     const SizedBox(width: 10),
//                     const CustomText(
//                       'servings',
//                       fontSize: 15,
//                       fontWeight: FontWeight.w700,
//                     ),
//                     const Spacer(),
//                     OutlinedButton.icon(
//                       onPressed: () {},
//                       icon: const Icon(Icons.auto_awesome, size: 15),
//                       label: const CustomText('Convert'),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 8,
//                         ),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         side: BorderSide(color: Colors.grey.shade300),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 14),

//                 ..._buildIngredients(context),
//                 const SizedBox(height: 18),

//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: _addToGroceries,
//                     icon: const Icon(Icons.add_shopping_cart_outlined),
//                     label: const CustomText('Add to groceries'),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       side: BorderSide(
//                         color: Theme.of(context).colorScheme.primary,
//                       ),
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 26),
//                 const Divider(),
//                 const SizedBox(height: 16),

//                 // ════════════════════════════════════════════════════════════
//                 // INSTRUCTIONS
//                 // ════════════════════════════════════════════════════════════
//                 CustomText(
//                   'INSTRUCTIONS',
//                   fontSize: 12,
//                   fontWeight: FontWeight.w700,
//                   letterSpacing: 0.9,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//                 const SizedBox(height: 12),

//                 SizedBox(
//                   width: double.infinity,
//                   child: OutlinedButton.icon(
//                     onPressed: () {},
//                     icon: const Icon(Icons.play_circle_outline),
//                     label: const CustomText('Cook step-by-step'),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       side: BorderSide(color: Colors.grey.shade300),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),

//                 ..._buildInstructions(context),
//               ]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   List<Widget> _buildIngredients(BuildContext context) {
//     final hasAnyItems = widget.recipe.ingredientSections.any(
//       (s) => s.items.isNotEmpty,
//     );

//     if (widget.recipe.ingredientSections.isEmpty || !hasAnyItems) {
//       if (widget.recipe.ingredients.isNotEmpty) {
//         return widget.recipe.ingredients
//             .map((ing) => _DetailBullet(text: ing) as Widget)
//             .toList();
//       }
//       return [const CustomText('No ingredients found.')];
//     }

//     final multiplier = _servings / _initialServings;
//     final widgets = <Widget>[];
//     for (final section in widget.recipe.ingredientSections) {
//       if (section.name != null && section.name!.isNotEmpty) {
//         widgets.add(
//           Padding(
//             padding: const EdgeInsets.only(top: 14, bottom: 6),
//             child: CustomText(
//               section.name!,
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//           ),
//         );
//       }
//       for (final ingredient in section.items) {
//         final scaled = IngredientScaleHelper.scaleIngredient(
//           ingredient,
//           multiplier,
//         );
//         widgets.add(_DetailBullet(text: scaled));
//       }
//     }
//     return widgets;
//   }

//   List<Widget> _buildInstructions(BuildContext context) {
//     final hasSectionSteps = widget.recipe.instructionSections.any(
//       (s) => s.steps.isNotEmpty,
//     );

//     if (!hasSectionSteps) {
//       if (widget.recipe.instructions.isNotEmpty) {
//         return widget.recipe.instructions
//             .asMap()
//             .entries
//             .map((e) => _InstructionStep(number: e.key + 1, text: e.value))
//             .toList();
//       }
//       return [
//         CustomText(
//           'No instructions found.',
//           fontSize: 15,
//           fontWeight: FontWeight.w700,
//           color: Colors.grey.shade600,
//         ),
//       ];
//     }

//     final widgets = <Widget>[];
//     var stepNum = 1;
//     for (final section in widget.recipe.instructionSections) {
//       if (section.steps.isEmpty) continue;
//       if (section.name != null && section.name!.isNotEmpty) {
//         widgets.add(
//           Padding(
//             padding: const EdgeInsets.only(top: 14, bottom: 10),
//             child: CustomText(
//               section.name!,
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//           ),
//         );
//       }
//       for (final step in section.steps) {
//         widgets.add(_InstructionStep(number: stepNum, text: step));
//         stepNum++;
//       }
//     }
//     return widgets;
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Cookbook picker bottom sheet
// // ─────────────────────────────────────────────────────────────────────────────

// class _CookbookPickerSheet extends StatelessWidget {
//   final CookbookController cookbookController;
//   final String recipeId;
//   final String? recipeImageUrl;

//   const _CookbookPickerSheet({
//     required this.cookbookController,
//     required this.recipeId,
//     required this.recipeImageUrl,
//   });

//   void _createAndAdd(BuildContext context) {
//     final textController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const CustomText('New Cookbook', fontWeight: FontWeight.w700),
//         content: TextField(
//           controller: textController,
//           autofocus: true,
//           textCapitalization: TextCapitalization.sentences,
//           decoration: InputDecoration(
//             hintText: 'e.g. Weekend Dinners',
//             filled: true,
//             fillColor: const Color(0xFFF5F5F5),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide.none,
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 14,
//               vertical: 12,
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(),
//             child: const CustomText('Cancel'),
//           ),
//           TextButton(
//             onPressed: () async {
//               final name = textController.text.trim();
//               if (name.isEmpty) return;
//               Navigator.of(ctx).pop();
//               Navigator.of(context).pop(); // close bottom sheet too

//               // Create cookbook then add recipe to it
//               await cookbookController.createCookbook(name);

//               // Wait a tick for Firestore stream to update
//               await Future.delayed(const Duration(milliseconds: 800));

//               // Find the newly created cookbook by name (latest one)
//               final newCookbook = cookbookController.cookbooks.firstWhereOrNull(
//                 (c) => c.name == name,
//               );
//               if (newCookbook != null) {
//                 cookbookController.addRecipeToCookbook(
//                   newCookbook.id,
//                   recipeId,
//                   recipeImageUrl,
//                 );
//               }
//             },
//             child: CustomText(
//               'Create',
//               fontWeight: FontWeight.w600,
//               color: Get.theme.colorScheme.primary,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Container(
//       decoration: BoxDecoration(
//         color: theme.colorScheme.background,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Handle bar
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           const SizedBox(height: 18),

//           const CustomText(
//             'Save to Cookbook',
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//           ),
//           const SizedBox(height: 16),

//           // Create new cookbook row
//           GestureDetector(
//             onTap: () => _createAndAdd(context),
//             child: Row(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: theme.colorScheme.primary.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(Icons.add, color: theme.colorScheme.primary),
//                 ),
//                 const SizedBox(width: 14),
//                 CustomText(
//                   'Create new cookbook',
//                   fontWeight: FontWeight.w600,
//                   color: theme.colorScheme.primary,
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 14),
//           const Divider(),
//           const SizedBox(height: 8),

//           // Existing cookbooks
//           Obx(() {
//             final cookbooks = cookbookController.cookbooks;

//             if (cookbooks.isEmpty) {
//               return Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 child: Center(
//                   child: CustomText(
//                     'No cookbooks yet. Create one above.',
//                     color: Colors.grey,
//                     fontSize: 14,
//                   ),
//                 ),
//               );
//             }

//             return ListView.separated(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: cookbooks.length,
//               separatorBuilder: (_, __) => const Divider(height: 1),
//               itemBuilder: (_, index) {
//                 final cookbook = cookbooks[index];
//                 final alreadyAdded = cookbook.recipeIds.contains(recipeId);

//                 return ListTile(
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 0,
//                     vertical: 4,
//                   ),
//                   leading: ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: SizedBox(
//                       width: 48,
//                       height: 48,
//                       child: RecipeImage(imageUrl: cookbook.imageUrl),
//                     ),
//                   ),
//                   title: CustomText(
//                     cookbook.name,
//                     fontWeight: FontWeight.w600,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   subtitle: CustomText(
//                     '${cookbook.recipeIds.length} recipes',
//                     color: Colors.grey,
//                     fontSize: 12,
//                   ),
//                   trailing: alreadyAdded
//                       ? Icon(
//                           Icons.check_circle,
//                           color: theme.colorScheme.primary,
//                         )
//                       : Icon(
//                           Icons.add_circle_outline,
//                           color: Colors.grey.shade400,
//                         ),
//                   onTap: alreadyAdded
//                       ? null
//                       : () {
//                           cookbookController.addRecipeToCookbook(
//                             cookbook.id,
//                             recipeId,
//                             recipeImageUrl,
//                           );
//                           Navigator.of(context).pop();
//                         },
//                 );
//               },
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Shared widgets
// // ─────────────────────────────────────────────────────────────────────────────

// class _ActionButton extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   const _ActionButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 58,
//             height: 58,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(
//                 color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
//                 width: 1.5,
//               ),
//             ),
//             child: Icon(
//               icon,
//               color: Theme.of(context).colorScheme.primary,
//               size: 25,
//             ),
//           ),
//           const SizedBox(height: 6),
//           CustomText(label, fontSize: 12, fontWeight: FontWeight.w500),
//         ],
//       ),
//     );
//   }
// }

// class _StepperButton extends StatelessWidget {
//   final IconData icon;
//   final bool enabled;
//   final VoidCallback onTap;

//   const _StepperButton({
//     required this.icon,
//     required this.enabled,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color = enabled
//         ? Theme.of(context).colorScheme.primary
//         : Colors.grey.shade300;

//     return GestureDetector(
//       onTap: enabled ? onTap : null,
//       child: Container(
//         width: 38,
//         height: 38,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: color, width: 1.5),
//         ),
//         child: Icon(icon, size: 18, color: color),
//       ),
//     );
//   }
// }

// class _InfoPill extends StatelessWidget {
//   final IconData icon;
//   final String label;

//   const _InfoPill({required this.icon, required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: AppTheme.primary.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 16, color: AppTheme.primary),
//           const SizedBox(width: 6),
//           CustomText(label, fontSize: 13, fontWeight: FontWeight.w600),
//         ],
//       ),
//     );
//   }
// }

// class _TagChip extends StatelessWidget {
//   final String label;

//   const _TagChip({required this.label});

//   @override
//   Widget build(BuildContext context) {
//     return Chip(
//       label: CustomText(label, color: AppTheme.primary),
//       backgroundColor: AppTheme.primary.withOpacity(0.1),
//       side: BorderSide.none,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }
// }

// class _DetailBullet extends StatelessWidget {
//   final String text;

//   const _DetailBullet({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(top: 4, right: 10),
//             child: Icon(Icons.circle, size: 7),
//           ),
//           Expanded(child: CustomText(text, fontSize: 15)),
//         ],
//       ),
//     );
//   }
// }

// class _InstructionStep extends StatelessWidget {
//   final int number;
//   final String text;

//   const _InstructionStep({required this.number, required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 30,
//             height: 30,
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.primary,
//               shape: BoxShape.circle,
//             ),
//             child: CustomText(
//               '$number',
//               color: Colors.white,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(child: CustomText(text, fontSize: 15)),
//         ],
//       ),
//     );
//   }
// }

// void showDeleteRecipeDialog(RecipeModel recipe, HomeController controller) {
//   Get.dialog(
//     AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       title: const Text("Delete Recipe"),
//       content: Text("Are you sure you want to delete '${recipe.title}'?"),
//       actions: [
//         TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
//         ElevatedButton(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.red,
//             foregroundColor: Colors.white,
//           ),
//           onPressed: () async {
//             Get.back();
//             await controller.deleteRecipe(recipe);
//           },
//           child: const Text("Delete"),
//         ),
//       ],
//     ),
//   );
// }



import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_ai/Controllers/cookbook_controller.dart';
import 'package:recipe_ai/Controllers/home_controller.dart';
import 'package:recipe_ai/Core/Theme/app_theme.dart';
import 'package:recipe_ai/Controllers/grocery_store_controller.dart';
import 'package:recipe_ai/View/Home/cookbooks_screen.dart';
import 'package:recipe_ai/Helper/ingredient_scale_helper.dart';
import 'package:recipe_ai/View/Home/home_screen.dart';
import 'package:recipe_ai/View/Home/recipe_editor_screen.dart';
import 'package:recipe_ai/Widget/custom_snackbar.dart';
import 'package:recipe_ai/Widget/custom_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:recipe_ai/Controllers/meal_plan_controller.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _initialServings;
  late int _servings;

  @override
  void initState() {
    super.initState();
    int parsed = 2;
    if (widget.recipe.servings != null) {
      final match = RegExp(r'\d+').firstMatch(widget.recipe.servings!);
      if (match != null) parsed = int.tryParse(match.group(0)!) ?? 4;
    }
    _initialServings = parsed <= 0 ? 2 : parsed;
    _servings = _initialServings;
  }

  // ── Share recipe ───────────────────────────────────────────────────────────
  void _shareRecipe() {
    final recipe = widget.recipe;
    final buffer = StringBuffer();

    buffer.writeln('🍽️ ${recipe.title}');
    buffer.writeln();

    if (recipe.description != null && recipe.description!.isNotEmpty) {
      buffer.writeln(recipe.description);
      buffer.writeln();
    }

    final meta = <String>[];
    if (recipe.prepTime != null) meta.add('Prep: ${recipe.prepTime}');
    if (recipe.cookTime != null) meta.add('Cook: ${recipe.cookTime}');
    if (recipe.totalTime != null) meta.add('Total: ${recipe.totalTime}');
    if (recipe.servings != null) meta.add('Serves: ${recipe.servings}');
    if (meta.isNotEmpty) {
      buffer.writeln(meta.join('  •  '));
      buffer.writeln();
    }

    buffer.writeln('📋 INGREDIENTS');
    if (widget.recipe.ingredientSections.any((s) => s.items.isNotEmpty)) {
      for (final section in widget.recipe.ingredientSections) {
        if (section.name != null && section.name!.isNotEmpty) {
          buffer.writeln('\n${section.name}');
        }
        for (final item in section.items) {
          buffer.writeln('• $item');
        }
      }
    } else {
      for (final ing in recipe.ingredients) {
        buffer.writeln('• $ing');
      }
    }
    buffer.writeln();

    buffer.writeln('👩‍🍳 INSTRUCTIONS');
    if (widget.recipe.instructionSections.any((s) => s.steps.isNotEmpty)) {
      var stepNum = 1;
      for (final section in widget.recipe.instructionSections) {
        if (section.steps.isEmpty) continue;
        if (section.name != null && section.name!.isNotEmpty) {
          buffer.writeln('\n${section.name}');
        }
        for (final step in section.steps) {
          buffer.writeln('$stepNum. $step');
          stepNum++;
        }
      }
    } else {
      for (var i = 0; i < recipe.instructions.length; i++) {
        buffer.writeln('${i + 1}. ${recipe.instructions[i]}');
      }
    }

    if (recipe.sourceUrl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('🔗 Source: ${recipe.sourceUrl}');
    }

    Share.share(buffer.toString(), subject: recipe.title);
  }

  // ── Add to groceries ───────────────────────────────────────────────────────
  void _addToGroceries() {
    final groceryController = Get.find<GroceryStore>();
    final multiplier = _servings / _initialServings;
    final scaledIngredients = widget.recipe.ingredients.map((ingredient) {
      return IngredientScaleHelper.scaleIngredient(ingredient, multiplier);
    }).toList();

    groceryController.addFromRecipe(widget.recipe.id, scaledIngredients);

    CustomSnackbar.show(
      title: '${widget.recipe.ingredients.length} ingredients added to groceries',
      actionText: 'View',
      onAction: () {
        HomeScreen.activeIndex = 2;
        Get.offUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => route.isFirst,
        );
      },
    );
  }

  // ── Cookbook bottom sheet ──────────────────────────────────────────────────
  void _showCookbookPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CookbookPickerSheet(
        cookbookController: Get.find<CookbookController>(),
        recipeId: widget.recipe.id,
        recipeImageUrl: widget.recipe.imageUrl,
      ),
    );
  }

  // ── Meal Plan bottom sheet ─────────────────────────────────────────────────
  void _showMealPlanPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MealPlanPickerSheet(
        mealPlanController: Get.find<MealPlanController>(),
        recipe: widget.recipe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            scrolledUnderElevation: 0,
            pinned: true,
            centerTitle: false,
            title: CustomText(
              recipe.title,
              maxLines: 1,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary(context),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_outlined, color: AppTheme.textPrimary(context)),
                onPressed: () => Get.to(() => RecipeEditorScreen(recipe: recipe)),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: AppTheme.textPrimary(context)),
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      Get.to(() => RecipeEditorScreen(recipe: recipe));
                      break;
                    case 'delete':
                      Get.dialog(AlertDialog(
                        title: const Text('Delete Recipe'),
                        content: Text('Are you sure you want to delete "${recipe.title}"?'),
                        actions: [
                          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () async {
                              Get.back();
                              Get.back();
                              await Get.find<HomeController>().deleteRecipe(recipe);
                              Get.back();
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ));
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined), SizedBox(width: 12), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red), SizedBox(width: 12), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),

          SliverPadding(
            padding: EdgeInsets.zero,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                RecipeImage(imageUrl: recipe.imageUrl, width: double.infinity, height: 280),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                CustomText(recipe.title, fontSize: 28, fontWeight: FontWeight.w800),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ActionButton(icon: Icons.bookmark_add_outlined, label: 'Cookbooks', onTap: _showCookbookPicker),
                    _ActionButton(icon: Icons.calendar_today_outlined, label: 'Meal Plan', onTap: _showMealPlanPicker),
                    _ActionButton(icon: Icons.add_shopping_cart_outlined, label: 'Groceries', onTap: _addToGroceries),
                    _ActionButton(icon: Icons.share_outlined, label: 'Share', onTap: _shareRecipe),
                  ],
                ),
                const SizedBox(height: 22),
                const Divider(),
                const SizedBox(height: 14),

                CustomText('RECIPE NOTES', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (recipe.prepTime != null) _InfoPill(icon: Icons.timer_outlined, label: 'Prep ${recipe.prepTime}'),
                    if (recipe.cookTime != null) _InfoPill(icon: Icons.local_fire_department_outlined, label: 'Cook ${recipe.cookTime}'),
                    if (recipe.totalTime != null) _InfoPill(icon: Icons.schedule, label: 'Total ${recipe.totalTime}'),
                    _InfoPill(icon: Icons.shopping_basket_outlined, label: '${recipe.ingredients.length} ingredients'),
                    _InfoPill(icon: Icons.format_list_numbered, label: '${recipe.instructions.length} steps'),
                  ],
                ),

                if (recipe.sourceUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(recipe.sourceUrl);
                      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Row(
                      children: [
                        CustomText('Open website ', color: Colors.grey.shade500, decoration: TextDecoration.underline, decorationColor: Colors.grey.shade500),
                        const Icon(Icons.open_in_new),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    const CustomText('Your rating', fontWeight: FontWeight.w600),
                    const SizedBox(width: 10),
                    ...List.generate(5, (_) => const Icon(Icons.star_border, size: 22, color: Colors.grey)),
                    const Spacer(),
                    TextButton(onPressed: () {}, child: CustomText('Add', color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: CustomText('No notes yet', color: Colors.grey.shade400),
                ),

                if (recipe.description != null) ...[
                  const SizedBox(height: 18),
                  CustomText(recipe.description!, fontSize: 16, height: 1.5, color: Colors.grey.shade700),
                ],

                if (recipe.category != null || recipe.cuisine != null || recipe.keywords.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (recipe.category != null) _TagChip(label: recipe.category!),
                      if (recipe.cuisine != null) _TagChip(label: recipe.cuisine!),
                      ...recipe.keywords.take(6).map((k) => _TagChip(label: k)),
                    ],
                  ),
                ],

                const SizedBox(height: 26),
                const Divider(),
                const SizedBox(height: 16),

                CustomText('INGREDIENTS', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),

                Row(
                  children: [
                    _StepperButton(icon: Icons.remove, enabled: _servings > 1, onTap: () => setState(() => _servings--)),
                    const SizedBox(width: 16),
                    CustomText('$_servings', fontSize: 18, fontWeight: FontWeight.w700),
                    const SizedBox(width: 16),
                    _StepperButton(icon: Icons.add, enabled: true, onTap: () => setState(() => _servings++)),
                    const SizedBox(width: 10),
                    const CustomText('servings', fontSize: 15, fontWeight: FontWeight.w700),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.auto_awesome, size: 15),
                      label: const CustomText('Convert'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                ..._buildIngredients(context),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addToGroceries,
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    label: const CustomText('Add to groceries'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 26),
                const Divider(),
                const SizedBox(height: 16),

                CustomText('INSTRUCTIONS', fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.9, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_circle_outline),
                    label: const CustomText('Cook step-by-step'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                ..._buildInstructions(context),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIngredients(BuildContext context) {
    final hasAnyItems = widget.recipe.ingredientSections.any((s) => s.items.isNotEmpty);
    if (widget.recipe.ingredientSections.isEmpty || !hasAnyItems) {
      if (widget.recipe.ingredients.isNotEmpty) {
        return widget.recipe.ingredients.map((ing) => _DetailBullet(text: ing) as Widget).toList();
      }
      return [const CustomText('No ingredients found.')];
    }
    final multiplier = _servings / _initialServings;
    final widgets = <Widget>[];
    for (final section in widget.recipe.ingredientSections) {
      if (section.name != null && section.name!.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: CustomText(section.name!, fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
        ));
      }
      for (final ingredient in section.items) {
        widgets.add(_DetailBullet(text: IngredientScaleHelper.scaleIngredient(ingredient, multiplier)));
      }
    }
    return widgets;
  }

  List<Widget> _buildInstructions(BuildContext context) {
    final hasSectionSteps = widget.recipe.instructionSections.any((s) => s.steps.isNotEmpty);
    if (!hasSectionSteps) {
      if (widget.recipe.instructions.isNotEmpty) {
        return widget.recipe.instructions.asMap().entries.map((e) => _InstructionStep(number: e.key + 1, text: e.value)).toList();
      }
      return [CustomText('No instructions found.', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade600)];
    }
    final widgets = <Widget>[];
    var stepNum = 1;
    for (final section in widget.recipe.instructionSections) {
      if (section.steps.isEmpty) continue;
      if (section.name != null && section.name!.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 10),
          child: CustomText(section.name!, fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
        ));
      }
      for (final step in section.steps) {
        widgets.add(_InstructionStep(number: stepNum, text: step));
        stepNum++;
      }
    }
    return widgets;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meal Plan Picker Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _MealPlanPickerSheet extends StatefulWidget {
  final MealPlanController mealPlanController;
  final RecipeModel recipe;

  const _MealPlanPickerSheet({required this.mealPlanController, required this.recipe});

  @override
  State<_MealPlanPickerSheet> createState() => _MealPlanPickerSheetState();
}

class _MealPlanPickerSheetState extends State<_MealPlanPickerSheet> {
  DateTime _selectedDay = DateTime.now();
  String _selectedMealType = 'Dinner';
  bool _isAdding = false;

  static const List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  static const Map<String, Color> _mealColors = {
    'Breakfast': Color(0xFFF59E0B),
    'Lunch': Color(0xFF10B981),
    'Dinner': Color(0xFF6366F1),
    'Snack': Color(0xFFEF4444),
  };

  static const Map<String, IconData> _mealIcons = {
    'Breakfast': Icons.wb_sunny_outlined,
    'Lunch': Icons.lunch_dining_outlined,
    'Dinner': Icons.dinner_dining_outlined,
    'Snack': Icons.cookie_outlined,
  };

  List<DateTime> get _days => List.generate(14, (i) => DateTime.now().add(Duration(days: i)));

  String _dayLabel(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) return 'Today';
    return weekdays[date.weekday - 1];
  }

  bool _isSameDay(DateTime a, DateTime b) => a.day == b.day && a.month == b.month && a.year == b.year;

  Future<void> _confirm() async {
    setState(() => _isAdding = true);
    try {
      await widget.mealPlanController.addMealPlanItem(
        date: _selectedDay,
        mealType: _selectedMealType,
        recipeId: widget.recipe.id,
        recipeTitle: widget.recipe.title,
        recipeImageUrl: widget.recipe.imageUrl,
      );
      if (mounted) Navigator.of(context).pop();
      final color = _mealColors[_selectedMealType] ?? AppTheme.primary;
      Get.snackbar(
        'Added to $_selectedMealType',
        '${widget.recipe.title} added to meal plan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: color,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 16,
        icon: Icon(_mealIcons[_selectedMealType] ?? Icons.restaurant, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } catch (_) {
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = _mealColors[_selectedMealType] ?? AppTheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomText('Add to Meal Plan', fontSize: 18, fontWeight: FontWeight.w700),
                      const SizedBox(height: 2),
                      CustomText(widget.recipe.title, fontSize: 13, color: Colors.grey.shade500, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Day label
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: CustomText('SELECT DAY', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey.shade500),
          ),

          // Day scroll
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (_, i) {
                final day = _days[i];
                final isSelected = _isSameDay(day, _selectedDay);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 56,
                    decoration: BoxDecoration(
                      color: isSelected ? selectedColor : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? selectedColor : Colors.grey.shade200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomText(_dayLabel(day), fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white.withOpacity(0.85) : Colors.grey.shade500),
                        const SizedBox(height: 4),
                        CustomText('${day.day}', fontSize: 18, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : null),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Meal type label
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: CustomText('MEAL TYPE', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey.shade500),
          ),

          // Meal type chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _mealTypes.map((type) {
                final isSelected = _selectedMealType == type;
                final color = _mealColors[type]!;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedMealType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.12) : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
                      ),
                      child: Column(
                        children: [
                          Icon(_mealIcons[type]!, size: 20, color: isSelected ? color : Colors.grey.shade400),
                          const SizedBox(height: 4),
                          CustomText(type, fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? color : Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Add button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAdding ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isAdding
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_mealIcons[_selectedMealType] ?? Icons.restaurant, size: 18),
                          const SizedBox(width: 8),
                          CustomText('Add to $_selectedMealType', color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cookbook Picker Sheet
// ─────────────────────────────────────────────────────────────────────────────

class CookbookPickerSheet extends StatelessWidget {
  final CookbookController cookbookController;
  final String recipeId;
  final String? recipeImageUrl;

  const CookbookPickerSheet({required this.cookbookController, required this.recipeId, required this.recipeImageUrl});

  void _createAndAdd(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const CustomText('New Cookbook', fontWeight: FontWeight.w700),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'e.g. Weekend Dinners',
            filled: true,
            fillColor: const Color(0xFFF5F5F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const CustomText('Cancel')),
          TextButton(
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              await cookbookController.createCookbook(name);
              await Future.delayed(const Duration(milliseconds: 800));
              final newCookbook = cookbookController.cookbooks.firstWhereOrNull((c) => c.name == name);
              if (newCookbook != null) {
                cookbookController.addRecipeToCookbook(newCookbook.id, recipeId, recipeImageUrl);
              }
            },
            child: CustomText('Create', fontWeight: FontWeight.w600, color: Get.theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          const CustomText('Save to Cookbook', fontSize: 18, fontWeight: FontWeight.w700),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _createAndAdd(context),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.add, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                CustomText('Create new cookbook', fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),
          Obx(() {
            final cookbooks = cookbookController.cookbooks;
            if (cookbooks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CustomText('No cookbooks yet. Create one above.', color: Colors.grey, fontSize: 14)),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cookbooks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final cookbook = cookbooks[index];
                final alreadyAdded = cookbook.recipeIds.contains(recipeId);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 48, height: 48, child: RecipeImage(imageUrl: cookbook.imageUrl)),
                  ),
                  title: CustomText(cookbook.name, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: CustomText('${cookbook.recipeIds.length} recipes', color: Colors.grey, fontSize: 12),
                  trailing: alreadyAdded
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : Icon(Icons.add_circle_outline, color: Colors.grey.shade400),
                  onTap: alreadyAdded ? null : () {
                    cookbookController.addRecipeToCookbook(cookbook.id, recipeId, recipeImageUrl);
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.35), width: 1.5),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 25),
          ),
          const SizedBox(height: 6),
          CustomText(label, fontSize: 12, fontWeight: FontWeight.w500),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? Theme.of(context).colorScheme.primary : Colors.grey.shade300;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: color, width: 1.5)),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 6),
          CustomText(label, fontSize: 13, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: CustomText(label, color: AppTheme.primary),
      backgroundColor: AppTheme.primary.withOpacity(0.1),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _DetailBullet extends StatelessWidget {
  final String text;

  const _DetailBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.only(top: 4, right: 10), child: Icon(Icons.circle, size: 7)),
          Expanded(child: CustomText(text, fontSize: 15)),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            child: CustomText('$number', color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 12),
          Expanded(child: CustomText(text, fontSize: 15)),
        ],
      ),
    );
  }
}

void showDeleteRecipeDialog(RecipeModel recipe, HomeController controller) {
  Get.dialog(AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    title: const Text("Delete Recipe"),
    content: Text("Are you sure you want to delete '${recipe.title}'?"),
    actions: [
      TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
        onPressed: () async {
          Get.back();
          await controller.deleteRecipe(recipe);
        },
        child: const Text("Delete"),
      ),
    ],
  ));
}