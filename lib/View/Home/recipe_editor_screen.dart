  // import 'dart:io';

  // import 'package:flutter/material.dart';
  // import 'package:get/get.dart';
  // import 'package:recipe_ai/Controllers/home_controller.dart';
  // import 'package:recipe_ai/Controllers/recipe_editor_controller.dart';
  // import 'package:recipe_ai/Core/Theme/app_theme.dart';
  // import 'package:recipe_ai/Widget/custom_text.dart';

  // class RecipeEditorScreen extends StatelessWidget {
  //   final RecipeModel? recipe;

  //   const RecipeEditorScreen({super.key, this.recipe});

  //   @override
  //   Widget build(BuildContext context) {
  //     final controller = Get.put(
  //       RecipeEditorController(recipe: recipe),
  //       tag: recipe?.id ?? "new_recipe",
  //     );
  //     // final controller = Get.find<RecipeEditorController>(
  //     //   tag: recipe?.id ?? "new_recipe",
  //     // );

  //     return Scaffold(
  //       backgroundColor: AppTheme.background(context),

  //       appBar: AppBar(
  //         elevation: 0,
  //         scrolledUnderElevation: 0,
  //         backgroundColor: Colors.transparent,

  //         title: CustomText(
  //           controller.isEdit ? "Edit Recipe" : "Create Recipe",
  //           fontSize: 20,
  //           fontWeight: FontWeight.w700,
  //         ),

  //         actions: [
  //           Obx(
  //             () => Padding(
  //               padding: const EdgeInsets.only(right: 12),
  //               child: FilledButton(
  //                 onPressed: controller.isSaving.value
  //                     ? null
  //                     : controller.saveRecipe,
  //                 child: controller.isSaving.value
  //                     ? const SizedBox(
  //                         height: 18,
  //                         width: 18,
  //                         child: CircularProgressIndicator(strokeWidth: 2),
  //                       )
  //                     : const Text("Save"),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),

  //       body: SingleChildScrollView(
  //         padding: const EdgeInsets.all(16),

  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,

  //           children: [
  //             _buildImageSection(context, controller),

  //             const SizedBox(height: 24),

  //             _buildTitleSection(controller),

  //             const SizedBox(height: 20),

  //             _buildDescriptionSection(controller),

  //             const SizedBox(height: 20),

  //             _buildInfoSection(controller),

  //             const SizedBox(height: 24),

  //             _buildTagsSection(context, controller),

  //             const SizedBox(height: 24),

  //             _buildIngredientSection(context, controller),

  //             const SizedBox(height: 24),

  //             _buildInstructionSection(context, controller),

  //             const SizedBox(height: 50),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  //   Widget _buildImageSection(
  //     BuildContext context,
  //     RecipeEditorController controller,
  //   ) {
  //     return Obx(() {
  //       Widget imageWidget;

  //       if (controller.imageFile.value != null) {
  //         imageWidget = Image.file(
  //           controller.imageFile.value!,
  //           fit: BoxFit.cover,
  //         );
  //       } else if (controller.imagePath.value.isNotEmpty) {
  //         final path = controller.imagePath.value;

  //         if (path.startsWith('http')) {
  //           imageWidget = Image.network(path, fit: BoxFit.cover);
  //         } else {
  //           imageWidget = Image.file(File(path), fit: BoxFit.cover);
  //         }
  //       } else {
  //         imageWidget = Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(Icons.add_a_photo_outlined, size: 50, color: AppTheme.primary),
  //             const SizedBox(height: 10),
  //             const CustomText("Select Recipe Image"),
  //           ],
  //         );
  //       }

  //       return GestureDetector(
  //         onTap: controller.pickImage,
  //         child: Container(
  //           height: 220,
  //           width: double.infinity,
  //           clipBehavior: Clip.antiAlias,
  //           decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
  //           child: Stack(
  //             fit: StackFit.expand,
  //             children: [
  //               // Original Image
  //               imageWidget,

  //               // Dark Overlay
  //               Container(color: Colors.black.withValues(alpha: 0.3)),

  //               // Delete Button
  //               Positioned(
  //                 top: 12,
  //                 right: 12,
  //                 child: GestureDetector(
  //                   onTap: controller.removeImage,
  //                   child: Container(
  //                     height: 40,
  //                     width: 40,
  //                     decoration: BoxDecoration(
  //                       color: Colors.black.withValues(alpha: 0.4),
  //                       shape: BoxShape.circle,
  //                     ),
  //                     child: const Icon(
  //                       Icons.delete,
  //                       color: Colors.red,
  //                       size: 22,
  //                     ),
  //                   ),
  //                 ),
  //               ),

  //               // Center Edit Icon
  //               Center(
  //                 child: Container(
  //                   height: 80,
  //                   width: 80,
  //                   decoration: BoxDecoration(
  //                     color: Colors.black.withValues(alpha: 0.4),
  //                     shape: BoxShape.circle,
  //                   ),
  //                   child: const Icon(Icons.edit, color: Colors.white, size: 36),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     });
  //   }

  //   Widget _buildTitleSection(RecipeEditorController controller) {
  //     return TextField(
  //       controller: controller.titleController,

  //       decoration: const InputDecoration(
  //         labelText: "Recipe Title",
  //         border: OutlineInputBorder(),
  //       ),
  //     );
  //   }

  //   Widget _buildDescriptionSection(RecipeEditorController controller) {
  //     return TextField(
  //       controller: controller.descriptionController,

  //       minLines: 4,
  //       maxLines: 6,

  //       decoration: const InputDecoration(
  //         labelText: "Description",
  //         border: OutlineInputBorder(),
  //       ),
  //     );
  //   }

  //   Widget _buildInfoSection(RecipeEditorController controller) {
  //     return Column(
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(
  //               child: TextField(
  //                 controller: controller.servingsController,

  //                 decoration: const InputDecoration(
  //                   labelText: "Servings",
  //                   border: OutlineInputBorder(),
  //                 ),
  //               ),
  //             ),

  //             const SizedBox(width: 12),

  //             Expanded(
  //               child: TextField(
  //                 controller: controller.prepTimeController,

  //                 decoration: const InputDecoration(
  //                   labelText: "Prep Time",
  //                   border: OutlineInputBorder(),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 12),

  //         Row(
  //           children: [
  //             Expanded(
  //               child: TextField(
  //                 controller: controller.cookTimeController,

  //                 decoration: const InputDecoration(
  //                   labelText: "Cook Time",
  //                   border: OutlineInputBorder(),
  //                 ),
  //               ),
  //             ),

  //             const SizedBox(width: 12),

  //             Expanded(
  //               child: TextField(
  //                 controller: controller.totalTimeController,

  //                 decoration: const InputDecoration(
  //                   labelText: "Total Time",
  //                   border: OutlineInputBorder(),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     );
  //   }

  //   Widget _buildTagsSection(
  //     BuildContext context,
  //     RecipeEditorController controller,
  //   ) {
  //     return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             const CustomText("Tags", fontSize: 18, fontWeight: FontWeight.w700),
  //             const Spacer(),
  //             TextButton.icon(
  //               onPressed: () => showAddTagDialog(context, controller),
  //               icon: const Icon(Icons.add),
  //               label: const Text("Add"),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 10),

  //         Obx(() {
  //           if (controller.tags.isEmpty) {
  //             return Container(
  //               width: double.infinity,
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 color: AppTheme.primary.withValues(alpha: .05),
  //                 borderRadius: BorderRadius.circular(16),
  //                 border: Border.all(
  //                   color: AppTheme.primary.withValues(alpha: .15),
  //                 ),
  //               ),
  //               child: Column(
  //                 children: [
  //                   Icon(Icons.sell_outlined, size: 36, color: AppTheme.primary),

  //                   const SizedBox(height: 10),

  //                   const CustomText(
  //                     "No tags added yet",
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.w700,
  //                   ),

  //                   const SizedBox(height: 4),

  //                   CustomText(
  //                     "Add tags like Breakfast, Healthy, Quick Meal or Dessert to organize your recipe.",
  //                     textAlign: TextAlign.center,
  //                     color: AppTheme.textSecondary(context),
  //                     fontSize: 13,
  //                   ),

  //                   const SizedBox(height: 12),

  //                   OutlinedButton.icon(
  //                     onPressed: () => showAddTagDialog(context, controller),
  //                     icon: const Icon(Icons.add),
  //                     label: const Text("Add First Tag"),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }

  //           return Wrap(
  //             spacing: 8,
  //             runSpacing: 8,
  //             children: controller.tags.map((tag) {
  //               return Chip(
  //                 label: Text(tag),
  //                 deleteIcon: const Icon(Icons.close, size: 18),
  //                 onDeleted: () => controller.removeTag(tag),
  //                 backgroundColor: AppTheme.primary.withValues(alpha: .08),
  //                 side: BorderSide(
  //                   color: AppTheme.primary.withValues(alpha: .15),
  //                 ),
  //               );
  //             }).toList(),
  //           );
  //         }),
  //       ],
  //     );
  //   }

  //   Widget _buildIngredientSection(
  //     BuildContext context,
  //     RecipeEditorController controller,
  //   ) {
  //     return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             const CustomText(
  //               "Ingredients",
  //               fontSize: 18,
  //               fontWeight: FontWeight.w700,
  //             ),
  //             const Spacer(),
  //             TextButton.icon(
  //               onPressed: () => showAddIngredientDialog(context, controller),
  //               icon: const Icon(Icons.add),
  //               label: const Text("Add"),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 10),

  //         Obx(() {
  //           if (controller.ingredients.isEmpty) {
  //             return Container(
  //               width: double.infinity,
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 color: AppTheme.primary.withValues(alpha: .05),
  //                 borderRadius: BorderRadius.circular(16),
  //                 border: Border.all(
  //                   color: AppTheme.primary.withValues(alpha: .15),
  //                 ),
  //               ),
  //               child: Column(
  //                 children: [
  //                   Icon(
  //                     Icons.restaurant_menu_outlined,
  //                     size: 36,
  //                     color: AppTheme.primary,
  //                   ),

  //                   const SizedBox(height: 10),

  //                   const CustomText(
  //                     "No ingredients added yet",
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.w700,
  //                   ),

  //                   const SizedBox(height: 4),

  //                   CustomText(
  //                     "Add all ingredients needed for this recipe. Example: 2 Eggs, 1 Cup Milk, 250g Flour.",
  //                     textAlign: TextAlign.center,
  //                     color: AppTheme.textSecondary(context),
  //                     fontSize: 13,
  //                   ),

  //                   const SizedBox(height: 12),

  //                   OutlinedButton.icon(
  //                     onPressed: () =>
  //                         showAddIngredientDialog(context, controller),
  //                     icon: const Icon(Icons.add),
  //                     label: const Text("Add First Ingredient"),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }

  //           // return ListView.separated(
  //           //   shrinkWrap: true,
  //           //   physics: const NeverScrollableScrollPhysics(),
  //           //   itemCount: controller.ingredients.length,
  //           //   separatorBuilder: (_, __) => const Divider(height: 1),
  //           //   itemBuilder: (_, index) {
  //           //     return ListTile(
  //           //       contentPadding: EdgeInsets.zero,

  //           //       onTap: () {
  //           //         showEditIngredientDialog(context, controller, index);
  //           //       },

  //           //       leading: Container(
  //           //         width: 34,
  //           //         height: 34,
  //           //         alignment: Alignment.center,
  //           //         decoration: BoxDecoration(
  //           //           color: AppTheme.primary.withValues(alpha: .1),
  //           //           shape: BoxShape.circle,
  //           //         ),
  //           //         child: const Icon(
  //           //           Icons.edit_outlined,
  //           //           size: 16,
  //           //           color: AppTheme.primary,
  //           //         ),
  //           //       ),

  //           //       title: CustomText(
  //           //         controller.ingredients[index],
  //           //         fontWeight: FontWeight.w600,
  //           //       ),

  //           //       trailing: IconButton(
  //           //         onPressed: () {
  //           //           controller.removeIngredient(index);
  //           //         },
  //           //         icon: const Icon(Icons.delete_outline),
  //           //       ),
  //           //     );
  //           //   },
  //           // );
  //           return ReorderableListView.builder(
  //             shrinkWrap: true,
  //             primary: false,
  //             physics: const NeverScrollableScrollPhysics(),
  //             buildDefaultDragHandles: false, // We'll use custom drag handle
  //             itemCount: controller.ingredients.length,
  //             onReorder: controller.reorderIngredients,

  //             itemBuilder: (context, index) {
  //               final ingredient = controller.ingredients[index];

  //               return AnimatedContainer(
  //                 key: ValueKey('${ingredient}_$index'),
  //                 duration: const Duration(milliseconds: 300),
  //                 margin: const EdgeInsets.only(bottom: 12),
  //                 decoration: BoxDecoration(
  //                   color: Theme.of(context).cardColor,
  //                   borderRadius: BorderRadius.circular(20),
  //                   border: Border.all(
  //                     color: AppTheme.primary.withValues(alpha: 0.1),
  //                   ),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.black.withValues(alpha: 0.06),
  //                       blurRadius: 12,
  //                       offset: const Offset(0, 4),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Material(
  //                   color: Colors.transparent,
  //                   borderRadius: BorderRadius.circular(20),
  //                   child: InkWell(
  //                     borderRadius: BorderRadius.circular(20),
  //                     onTap: () =>
  //                         showEditIngredientDialog(context, controller, index),
  //                     child: Padding(
  //                       padding: const EdgeInsets.symmetric(
  //                         horizontal: 16,
  //                         vertical: 12,
  //                       ),
  //                       child: Row(
  //                         children: [
  //                           // Leading Icon
  //                           Container(
  //                             width: 46,
  //                             height: 46,
  //                             decoration: BoxDecoration(
  //                               color: AppTheme.primary.withValues(alpha: 0.12),
  //                               shape: BoxShape.circle,
  //                             ),
  //                             child: const Icon(
  //                               Icons.restaurant_menu_rounded,
  //                               size: 22,
  //                               color: AppTheme.primary,
  //                             ),
  //                           ),

  //                           const SizedBox(width: 16),

  //                           // Ingredient Name
  //                           Expanded(
  //                             child: Text(
  //                               ingredient,
  //                               style: const TextStyle(
  //                                 fontSize: 16,
  //                                 fontWeight: FontWeight.w600,
  //                                 letterSpacing: -0.2,
  //                               ),
  //                               maxLines: 2,
  //                               overflow: TextOverflow.ellipsis,
  //                             ),
  //                           ),

  //                           const SizedBox(width: 12),

  //                           // Actions
  //                           Row(
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               // Drag Handle
  //                               ReorderableDragStartListener(
  //                                 index: index,
  //                                 child: Container(
  //                                   padding: const EdgeInsets.all(10),
  //                                   decoration: BoxDecoration(
  //                                     color: AppTheme.primary.withValues(
  //                                       alpha: 0.08,
  //                                     ),
  //                                     borderRadius: BorderRadius.circular(12),
  //                                   ),
  //                                   child: const Icon(
  //                                     Icons.drag_indicator_rounded,
  //                                     color: AppTheme.primary,
  //                                     size: 22,
  //                                   ),
  //                                 ),
  //                               ),

  //                               const SizedBox(width: 8),

  //                               // Delete Button
  //                               Material(
  //                                 color: Colors.transparent,
  //                                 child: GestureDetector(
  //                                   // borderRadius: BorderRadius.circular(12),
  //                                   onTap: () =>
  //                                       controller.removeIngredient(index),
  //                                   child: Padding(
  //                                     padding: const EdgeInsets.all(10),
  //                                     child: Icon(
  //                                       Icons.delete_outline_rounded,
  //                                       color: Colors.red.shade400,
  //                                       size: 24,
  //                                     ),
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               );
  //             },
  //           );
  //         }),
  //       ],
  //     );
  //   }

  //   Widget _buildInstructionSection(
  //     BuildContext context,
  //     RecipeEditorController controller,
  //   ) {
  //     return Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             const CustomText(
  //               "Instructions",
  //               fontSize: 18,
  //               fontWeight: FontWeight.w700,
  //             ),
  //             const Spacer(),
  //             TextButton.icon(
  //               onPressed: () => showAddInstructionDialog(context, controller),
  //               icon: const Icon(Icons.add),
  //               label: const Text("Add"),
  //             ),
  //           ],
  //         ),

  //         const SizedBox(height: 10),

  //         Obx(() {
  //           if (controller.instructions.isEmpty) {
  //             return Container(
  //               width: double.infinity,
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 color: AppTheme.primary.withValues(alpha: .05),
  //                 borderRadius: BorderRadius.circular(16),
  //                 border: Border.all(
  //                   color: AppTheme.primary.withValues(alpha: .15),
  //                 ),
  //               ),
  //               child: Column(
  //                 children: [
  //                   Icon(
  //                     Icons.format_list_numbered_rounded,
  //                     size: 36,
  //                     color: AppTheme.primary,
  //                   ),

  //                   const SizedBox(height: 10),

  //                   const CustomText(
  //                     "No instructions added yet",
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.w700,
  //                   ),

  //                   const SizedBox(height: 4),

  //                   CustomText(
  //                     "Add step-by-step cooking directions so others can easily follow this recipe.",
  //                     textAlign: TextAlign.center,
  //                     color: AppTheme.textSecondary(context),
  //                     fontSize: 13,
  //                   ),

  //                   const SizedBox(height: 12),

  //                   OutlinedButton.icon(
  //                     onPressed: () =>
  //                         showAddInstructionDialog(context, controller),
  //                     icon: const Icon(Icons.add),
  //                     label: const Text("Add First Step"),
  //                   ),
  //                 ],
  //               ),
  //             );
  //           }

  //           return ListView.builder(
  //             shrinkWrap: true,
  //             physics: const NeverScrollableScrollPhysics(),
  //             itemCount: controller.instructions.length,
  //             itemBuilder: (_, index) {
  //               return Card(
  //                 margin: const EdgeInsets.only(bottom: 10),
  //                 elevation: 0,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(14),
  //                   side: BorderSide(
  //                     color: AppTheme.primary.withValues(alpha: .10),
  //                   ),
  //                 ),
  //                 child: ListTile(
  //                   contentPadding: const EdgeInsets.symmetric(
  //                     horizontal: 12,
  //                     vertical: 6,
  //                   ),

  //                   onTap: () {
  //                     showEditInstructionDialog(context, controller, index);
  //                   },

  //                   leading: Container(
  //                     width: 36,
  //                     height: 36,
  //                     alignment: Alignment.center,
  //                     decoration: const BoxDecoration(
  //                       color: AppTheme.primary,
  //                       shape: BoxShape.circle,
  //                     ),
  //                     child: CustomText(
  //                       "${index + 1}",
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.w700,
  //                     ),
  //                   ),

  //                   title: CustomText(
  //                     controller.instructions[index],
  //                     fontWeight: FontWeight.w600,
  //                   ),

  //                   trailing: IconButton(
  //                     onPressed: () {
  //                       controller.removeInstruction(index);
  //                     },
  //                     icon: const Icon(Icons.delete_outline),
  //                   ),
  //                 ),
  //               );
  //             },
  //           );
  //         }),
  //       ],
  //     );
  //   }
  // }

  // void showAddTagDialog(BuildContext context, RecipeEditorController controller) {
  //   final txt = TextEditingController();

  //   showEditorDialog(
  //     title: "Add Tag",
  //     controller: txt,
  //     hint: "e.g. Vegan, Breakfast",
  //     onSave: () {
  //       if (txt.text.trim().isEmpty) return;

  //       controller.addTag(txt.text.trim());

  //       Get.back();
  //     },
  //   );
  // }

  // void showAddIngredientDialog(
  //   BuildContext context,
  //   RecipeEditorController controller,
  // ) {
  //   final txt = TextEditingController();

  //   showEditorDialog(
  //     title: "Add Ingredient",
  //     controller: txt,
  //     hint: "e.g. 2 cups flour",
  //     onSave: () {
  //       if (txt.text.trim().isEmpty) return;

  //       controller.addIngredient(txt.text.trim());
  //       Get.back();
  //     },
  //   );
  // }

  // void showEditIngredientDialog(
  //   BuildContext context,
  //   RecipeEditorController controller,
  //   int index,
  // ) {
  //   final txt = TextEditingController(text: controller.ingredients[index]);

  //   showEditorDialog(
  //     title: "Edit Ingredient",
  //     controller: txt,
  //     hint: "Ingredient",
  //     onSave: () {
  //       controller.updateIngredient(index, txt.text.trim());

  //       Get.back();
  //     },
  //   );
  // }

  // void showAddInstructionDialog(
  //   BuildContext context,
  //   RecipeEditorController controller,
  // ) {
  //   final txt = TextEditingController();

  //   showEditorDialog(
  //     title: "Add Instruction",
  //     controller: txt,
  //     minLines: 4,
  //     maxLines: 6,
  //     hint: "Describe this cooking step...",
  //     onSave: () {
  //       if (txt.text.trim().isEmpty) return;

  //       controller.addInstruction(txt.text.trim());

  //       Get.back();
  //     },
  //   );
  // }

  // void showEditInstructionDialog(
  //   BuildContext context,
  //   RecipeEditorController controller,
  //   int index,
  // ) {
  //   final txt = TextEditingController(text: controller.instructions[index]);

  //   showEditorDialog(
  //     title: "Edit Instruction",
  //     controller: txt,
  //     minLines: 4,
  //     maxLines: 6,
  //     hint: "Update cooking step...",
  //     onSave: () {
  //       controller.updateInstruction(index, txt.text.trim());

  //       Get.back();
  //     },
  //   );
  // }

  // void showEditorDialog({
  //   required String title,
  //   required TextEditingController controller,
  //   required VoidCallback onSave,
  //   int minLines = 1,
  //   int maxLines = 3,
  //   String hint = "",
  // }) {
  //   Get.dialog(
  //     Dialog(
  //       backgroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  //       child: Padding(
  //         padding: const EdgeInsets.all(20),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             /// Header
  //             Row(
  //               children: [
  //                 Container(
  //                   width: 42,
  //                   height: 42,
  //                   decoration: BoxDecoration(
  //                     color: AppTheme.primary.withValues(alpha: .1),
  //                     borderRadius: BorderRadius.circular(12),
  //                   ),
  //                   child: const Icon(
  //                     Icons.edit_outlined,
  //                     color: AppTheme.primary,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: CustomText(
  //                     title,
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.w700,
  //                   ),
  //                 ),
  //               ],
  //             ),

  //             const SizedBox(height: 20),

  //             /// Text Field
  //             TextField(
  //               controller: controller,
  //               minLines: minLines,
  //               maxLines: maxLines,
  //               textCapitalization: TextCapitalization.sentences,
  //               decoration: InputDecoration(
  //                 hintText: hint,
  //                 filled: true,
  //                 fillColor: Colors.grey.shade50,

  //                 contentPadding: const EdgeInsets.all(16),

  //                 border: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(16),
  //                   borderSide: BorderSide(color: Colors.grey.shade300),
  //                 ),

  //                 enabledBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(16),
  //                   borderSide: BorderSide(color: Colors.grey.shade300),
  //                 ),

  //                 focusedBorder: OutlineInputBorder(
  //                   borderRadius: BorderRadius.circular(16),
  //                   borderSide: const BorderSide(
  //                     color: AppTheme.primary,
  //                     width: 1.5,
  //                   ),
  //                 ),
  //               ),
  //             ),

  //             const SizedBox(height: 24),

  //             /// Buttons
  //             Row(
  //               children: [
  //                 Expanded(
  //                   child: OutlinedButton(
  //                     onPressed: () => Get.back(),
  //                     style: OutlinedButton.styleFrom(
  //                       minimumSize: const Size.fromHeight(52),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(14),
  //                       ),
  //                     ),
  //                     child: const Text("Cancel"),
  //                   ),
  //                 ),

  //                 const SizedBox(width: 12),

  //                 Expanded(
  //                   child: ElevatedButton.icon(
  //                     onPressed: onSave,
  //                     icon: const Icon(Icons.check, size: 18),
  //                     label: const Text("Save"),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: AppTheme.primary,
  //                       foregroundColor: Colors.white,
  //                       minimumSize: const Size.fromHeight(52),
  //                       elevation: 0,
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(14),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //     barrierDismissible: true,
  //   );
  // }

  import 'dart:io';

  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:recipe_ai/Controllers/home_controller.dart';
  import 'package:recipe_ai/Controllers/recipe_editor_controller.dart';
  import 'package:recipe_ai/Core/Theme/app_theme.dart';
  import 'package:recipe_ai/Widget/custom_text.dart';

  class RecipeEditorScreen extends StatelessWidget {
    final RecipeModel? recipe;

    const RecipeEditorScreen({super.key, this.recipe});

    @override
    Widget build(BuildContext context) {
      final controller = Get.put(
        RecipeEditorController(recipe: recipe),
        tag: recipe?.id ?? "new_recipe",
      );
      // final controller = Get.find<RecipeEditorController>(
      //   tag: recipe?.id ?? "new_recipe",
      // );

      return Scaffold(
        backgroundColor: AppTheme.background(context),

        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,

          title: CustomText(
            controller.isEdit ? "Edit Recipe" : "Create Recipe",
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),

          actions: [
            Obx(
              () => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton(
                  onPressed: controller.isSaving.value
                      ? null
                      : controller.saveRecipe,
                  child: controller.isSaving.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save"),
                ),
              ),
            ),
          ],
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _buildImageSection(context, controller),

              const SizedBox(height: 24),

              _buildTitleSection(controller),

              const SizedBox(height: 20),

              _buildDescriptionSection(controller),

              const SizedBox(height: 20),

              _buildInfoSection(controller),

              const SizedBox(height: 24),

              _buildTagsSection(context, controller),

              const SizedBox(height: 24),

              _buildIngredientSection(context, controller),

              const SizedBox(height: 24),

              _buildInstructionSection(context, controller),

              const SizedBox(height: 50),
            ],
          ),
        ),
      );
    }

    Widget _buildImageSection(
      BuildContext context,
      RecipeEditorController controller,
    ) {
      return Obx(() {
        Widget imageWidget;

        if (controller.imageFile.value != null) {
          imageWidget = Image.file(
            controller.imageFile.value!,
            fit: BoxFit.cover,
          );
        } else if (controller.imagePath.value.isNotEmpty) {
          final path = controller.imagePath.value;

          if (path.startsWith('http')) {
            imageWidget = Image.network(path, fit: BoxFit.cover);
          } else {
            imageWidget = Image.file(File(path), fit: BoxFit.cover);
          }
        } else {
          imageWidget = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 50, color: AppTheme.primary),
              const SizedBox(height: 10),
              const CustomText("Select Recipe Image"),
            ],
          );
        }

        return GestureDetector(
          onTap: controller.pickImage,
          child: Container(
            height: 220,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Original Image
                imageWidget,

                // Dark Overlay
                Container(color: Colors.black.withValues(alpha: 0.3)),

                // Delete Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: controller.removeImage,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                // Center Edit Icon
                Center(
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 36),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    Widget _buildTitleSection(RecipeEditorController controller) {
      return TextField(
        controller: controller.titleController,

        decoration: const InputDecoration(
          labelText: "Recipe Title",
          border: OutlineInputBorder(),
        ),
      );
    }

    Widget _buildDescriptionSection(RecipeEditorController controller) {
      return TextField(
        controller: controller.descriptionController,

        minLines: 4,
        maxLines: 6,

        decoration: const InputDecoration(
          labelText: "Description",
          border: OutlineInputBorder(),
        ),
      );
    }

    Widget _buildInfoSection(RecipeEditorController controller) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.servingsController,

                  decoration: const InputDecoration(
                    labelText: "Servings",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  controller: controller.prepTimeController,

                  decoration: const InputDecoration(
                    labelText: "Prep Time",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.cookTimeController,

                  decoration: const InputDecoration(
                    labelText: "Cook Time",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: TextField(
                  controller: controller.totalTimeController,

                  decoration: const InputDecoration(
                    labelText: "Total Time",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget _buildTagsSection(
      BuildContext context,
      RecipeEditorController controller,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomText("Tags", fontSize: 18, fontWeight: FontWeight.w700),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showAddTagDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Obx(() {
            if (controller.tags.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: .15),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.sell_outlined, size: 36, color: AppTheme.primary),

                    const SizedBox(height: 10),

                    const CustomText(
                      "No tags added yet",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),

                    const SizedBox(height: 4),

                    CustomText(
                      "Add tags like Breakfast, Healthy, Quick Meal or Dessert to organize your recipe.",
                      textAlign: TextAlign.center,
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () => showAddTagDialog(context, controller),
                      icon: const Icon(Icons.add),
                      label: const Text("Add First Tag"),
                    ),
                  ],
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => controller.removeTag(tag),
                  backgroundColor: AppTheme.primary.withValues(alpha: .08),
                  side: BorderSide(
                    color: AppTheme.primary.withValues(alpha: .15),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      );
    }

    // ---------------------------------------------------------------------
    // Shared reorderable card used by both Ingredients and Instructions so
    // the drag/drop feel (shadow, scale, handle) is identical everywhere.
    // ---------------------------------------------------------------------
    Widget _buildReorderableCard({
      required BuildContext context,
      required Key key,
      required int index,
      required Widget leading,
      required Widget content,
      required VoidCallback onTap,
      required VoidCallback onDelete,
    }) {
      return Container(
        key: key,
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: 16),
                  Expanded(child: content),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      ReorderableDragStartListener(
                        index: index,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.drag_indicator_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Delete Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onDelete,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red.shade400,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _buildIngredientSection(
      BuildContext context,
      RecipeEditorController controller,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomText(
                "Ingredients",
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showAddIngredientDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Obx(() {
            if (controller.ingredients.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: .15),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu_outlined,
                      size: 36,
                      color: AppTheme.primary,
                    ),

                    const SizedBox(height: 10),

                    const CustomText(
                      "No ingredients added yet",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),

                    const SizedBox(height: 4),

                    CustomText(
                      "Add all ingredients needed for this recipe. Example: 2 Eggs, 1 Cup Milk, 250g Flour.",
                      textAlign: TextAlign.center,
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () =>
                          showAddIngredientDialog(context, controller),
                      icon: const Icon(Icons.add),
                      label: const Text("Add First Ingredient"),
                    ),
                  ],
                ),
              );
            }

            return ReorderableListView.builder(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false, // custom drag handle only
              itemCount: controller.ingredients.length,
              onReorder: controller.reorderIngredients,

              // Smooths out the lift/drop animation instead of the default
              // abrupt jump-and-snap behaviour.
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final t = Curves.easeOut.transform(animation.value);
                    final scale = 1.0 + (0.03 * t);
                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        color: Colors.transparent,
                        elevation: 6 * t,
                        borderRadius: BorderRadius.circular(20),
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },

              itemBuilder: (context, index) {
                final ingredient = controller.ingredients[index];

                return _buildReorderableCard(
                  context: context,
                  key: ValueKey('ingredient_$index\_$ingredient'),
                  index: index,
                  onTap: () =>
                      showEditIngredientDialog(context, controller, index),
                  onDelete: () => controller.removeIngredient(index),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 22,
                      color: AppTheme.primary,
                    ),
                  ),
                  content: Text(
                    ingredient,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            );
          }),
        ],
      );
    }

    Widget _buildInstructionSection(
      BuildContext context,
      RecipeEditorController controller,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomText(
                "Instructions",
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showAddInstructionDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Obx(() {
            if (controller.instructions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: .05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: .15),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.format_list_numbered_rounded,
                      size: 36,
                      color: AppTheme.primary,
                    ),

                    const SizedBox(height: 10),

                    const CustomText(
                      "No instructions added yet",
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),

                    const SizedBox(height: 4),

                    CustomText(
                      "Add step-by-step cooking directions so others can easily follow this recipe.",
                      textAlign: TextAlign.center,
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                    ),

                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () =>
                          showAddInstructionDialog(context, controller),
                      icon: const Icon(Icons.add),
                      label: const Text("Add First Step"),
                    ),
                  ],
                ),
              );
            }

            // Reorderable now (previously a plain, non-reorderable
            // ListView.builder) so steps can be dragged just like
            // ingredients, with the step number always reflecting the
            // current position after a reorder.
            return ReorderableListView.builder(
              shrinkWrap: true,
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: controller.instructions.length,
              onReorder: controller.reorderInstructions,

              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final t = Curves.easeOut.transform(animation.value);
                    final scale = 1.0 + (0.03 * t);
                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        color: Colors.transparent,
                        elevation: 6 * t,
                        borderRadius: BorderRadius.circular(20),
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },

              itemBuilder: (context, index) {
                final instruction = controller.instructions[index];

                return _buildReorderableCard(
                  context: context,
                  key: ValueKey('instruction_$index\_$instruction'),
                  index: index,
                  onTap: () =>
                      showEditInstructionDialog(context, controller, index),
                  onDelete: () => controller.removeInstruction(index),
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: CustomText(
                      "${index + 1}",
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            );
          }),
        ],
      );
    }
  }

  void showAddTagDialog(BuildContext context, RecipeEditorController controller) {
    final txt = TextEditingController();

    showEditorDialog(
      title: "Add Tag",
      controller: txt,
      hint: "e.g. Vegan, Breakfast",
      onSave: () {
        if (txt.text.trim().isEmpty) return;

        controller.addTag(txt.text.trim());

        Get.back();
      },
    );
  }

  void showAddIngredientDialog(
    BuildContext context,
    RecipeEditorController controller,
  ) {
    final txt = TextEditingController();

    showEditorDialog(
      title: "Add Ingredient",
      controller: txt,
      hint: "e.g. 2 cups flour",
      onSave: () {
        if (txt.text.trim().isEmpty) return;

        controller.addIngredient(txt.text.trim());
        Get.back();
      },
    );
  }

  void showEditIngredientDialog(
    BuildContext context,
    RecipeEditorController controller,
    int index,
  ) {
    final txt = TextEditingController(text: controller.ingredients[index]);

    showEditorDialog(
      title: "Edit Ingredient",
      controller: txt,
      hint: "Ingredient",
      onSave: () {
        controller.updateIngredient(index, txt.text.trim());

        Get.back();
      },
    );
  }

  void showAddInstructionDialog(
    BuildContext context,
    RecipeEditorController controller,
  ) {
    final txt = TextEditingController();

    showEditorDialog(
      title: "Add Instruction",
      controller: txt,
      minLines: 4,
      maxLines: 6,
      hint: "Describe this cooking step...",
      onSave: () {
        if (txt.text.trim().isEmpty) return;

        controller.addInstruction(txt.text.trim());

        Get.back();
      },
    );
  }

  void showEditInstructionDialog(
    BuildContext context,
    RecipeEditorController controller,
    int index,
  ) {
    final txt = TextEditingController(text: controller.instructions[index]);

    showEditorDialog(
      title: "Edit Instruction",
      controller: txt,
      minLines: 4,
      maxLines: 6,
      hint: "Update cooking step...",
      onSave: () {
        controller.updateInstruction(index, txt.text.trim());

        Get.back();
      },
    );
  }

  void showEditorDialog({
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
    int minLines = 1,
    int maxLines = 3,
    String hint = "",
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomText(
                      title,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// Text Field
              TextField(
                controller: controller,
                minLines: minLines,
                maxLines: maxLines,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: Colors.grey.shade50,

                  contentPadding: const EdgeInsets.all(16),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              /// Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Save"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
