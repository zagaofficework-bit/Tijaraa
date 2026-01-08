import 'dart:convert';

import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/option_item.dart';
import 'package:Tijaraa/ui/screens/widgets/dynamic_field.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:Tijaraa/utils/validator.dart';
import 'package:flutter/material.dart';

class CustomCheckboxField extends CustomField {
  @override
  String type = "checkbox";

  final List<OptionItem> options = List.empty(growable: true);
  final Set<String> selectedOptions = Set.identity();

  @override
  void init() {
    options.clear();
    selectedOptions.clear();

    print("===== INIT CustomCheckboxField =====");
    print("Raw parameters: ${parameters.toString()}");

    List<String> englishValues =
        (parameters['values'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    final translatedValues =
        (parameters['translated_value'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final selectedValues =
        (parameters['value'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final currentLanguageId = 1;

    // --- Normalize helper ---
    List<String> normalize(dynamic value) {
      if (value == null) return [];
      if (value is String) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
        return [value];
      }
      if (value is List) return value.map((e) => e.toString()).toList();
      return [value.toString()];
    }

    // If values are empty, try translations
    if (englishValues.isEmpty) {
      final translations = (parameters['translations'] as List? ?? [])
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList();

      // 1️⃣ Try to find current language first
      Map<String, dynamic>? targetTranslation = translations.firstWhere(
        (t) => t['language_id'].toString() == currentLanguageId.toString(),
        orElse: () => {},
      );

      // 2️⃣ Fallback: first translation with non-empty value
      if (targetTranslation.isEmpty ||
          normalize(targetTranslation['value']).isEmpty) {
        targetTranslation = translations.firstWhere(
          (t) => normalize(t['value']).isNotEmpty,
          orElse: () => {},
        );
      }

      if (targetTranslation.isNotEmpty) {
        englishValues = normalize(targetTranslation['value']);
        print("Values extracted from translations: $englishValues");
      }
      print("FINAL englishValues TYPE → ${englishValues.runtimeType}");
    }

    // Build options list
    for (int i = 0; i < englishValues.length; i++) {
      final label = i < translatedValues.length
          ? translatedValues[i]
          : englishValues[i];
      final option = OptionItem(value: englishValues[i], label: label);
      options.add(option);

      if (selectedValues.contains(englishValues[i])) {
        selectedOptions.add(englishValues[i]);
      }
    }

    print("Checkbox options after parsing: $options");
    print("Selected options after parsing: $selectedOptions");

    super.init();
  }

  @override
  Widget render() {
    if (options.isEmpty) {
      return Text("No options available", style: TextStyle(color: Colors.grey));
    }

    bool isAllSelected =
        selectedOptions.length == options.length && options.isNotEmpty;

    return CustomValidator<List>(
      validator: (List? value) {
        if (parameters['required'] != 1) return null;
        if ((value?.isNotEmpty ?? false) || selectedOptions.isNotEmpty)
          return null;
        return "pleaseSelectValue".translate(context);
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                if (parameters['image'] != null) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.color.territoryColor.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: FittedBox(
                        fit: BoxFit.none,
                        child: UiUtils.imageType(
                          parameters['image'],
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          color: context.color.textDefaultColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: CustomText(
                    parameters['translated_name'] ?? parameters['name'],
                    fontSize: context.font.large,
                    fontWeight: FontWeight.w500,
                    color: context.color.textColorDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (isAllSelected) {
                      selectedOptions.clear();
                    } else {
                      selectedOptions.addAll(options.map((e) => e.value));
                    }
                    AbstractField.fieldsData[parameters['id'].toString()] =
                        selectedOptions.toList();
                    state.didChange(selectedOptions.toList());
                    if (update != null) {
                      update(() {});
                    }
                  },
                  child: CustomText(
                    isAllSelected ? "Deselect All" : "Select All",
                    color: context.color.territoryColor,
                    fontSize: context.font.small,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- OPTIONS LIST ---
            ...List.generate(options.length, (index) {
              final option = options[index];
              final isChecked = selectedOptions.contains(option.value);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: () {
                    if (isChecked) {
                      selectedOptions.remove(option.value);
                    } else {
                      selectedOptions.add(option.value);
                    }
                    AbstractField.fieldsData[parameters['id'].toString()] =
                        selectedOptions.toList();
                    state.didChange(selectedOptions.toList());
                    update(() {});
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      // IMPROVED: Added a very light grey background for unselected state
                      color: isChecked
                          ? context.color.territoryColor.withValues(alpha: 0.05)
                          : context.color.textDefaultColor.withValues(
                              alpha: 0.03,
                            ),
                      border: Border.all(
                        color: isChecked
                            ? context.color.territoryColor
                            : context.color.borderColor.withValues(alpha: 0.6),
                        width: isChecked ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Checkbox UI
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isChecked
                                ? context.color.territoryColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isChecked
                                  ? context.color.territoryColor
                                  : context.color.textDefaultColor.withValues(
                                      alpha: 0.2,
                                    ),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: isChecked
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: CustomText(
                            option.label,
                            color: isChecked
                                ? context.color.textDefaultColor
                                : context.color.textDefaultColor.withValues(
                                    alpha: 0.7,
                                  ),
                            fontSize: context.font.large,
                            fontWeight: isChecked
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
