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

class CustomRadioField extends CustomField {
  @override
  String type = "radio";
  FormFieldState<String>? validation;

  final List<OptionItem> options = List.empty(growable: true);
  OptionItem? selectedOption;

  @override
  void init() {
    options.clear();
    selectedOption = null;

    print("===== INIT CustomRadioField =====");
    print("Raw parameters: ${parameters.toString()}");

    List<String> englishValues =
        (parameters['values'] as List?)?.map((e) => e.toString()).toList() ??
        [];
    final translatedValues =
        (parameters['translated_value'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final currentLanguageId = 1;

    print("Initial englishValues: $englishValues");
    print("Initial translatedValues: $translatedValues");
    print("FINAL englishValues TYPE → ${englishValues.runtimeType}");
    // --- Normalize any type (List, String, JSON) to List<String> ---
    List<String> normalize(dynamic value) {
      if (value == null) return [];

      if (value is List) {
        while (value.length == 1 && value.first is List) value = value.first;
        return value.map((e) => e.toString()).toList();
      }

      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) return [];
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
          return [decoded.toString()];
        } catch (_) {
          return [trimmed];
        }
      }

      return [value.toString()];
    }

    if (englishValues.isEmpty) {
      final translations = parameters['translations'] as List? ?? [];
      Map<String, dynamic>? targetTranslation;

      // Try current language first
      targetTranslation = translations
          .map((t) {
            return Map<String, dynamic>.from(t as Map);
          })
          .firstWhere(
            (t) => t['language_id'].toString() == currentLanguageId.toString(),
            orElse: () => {},
          );

      // Fallback: pick the first translation with data
      if (targetTranslation.isEmpty ||
          normalize(targetTranslation['value']).isEmpty) {
        targetTranslation = translations
            .map((t) {
              return Map<String, dynamic>.from(t as Map);
            })
            .firstWhere(
              (t) => normalize(t['value']).isNotEmpty,
              orElse: () => {},
            );
      }

      if (targetTranslation.isNotEmpty) {
        englishValues = normalize(targetTranslation['value']);
        print("Values extracted from translations: $englishValues");
      }
    }

    // Restore selected value safely
    final restored = normalize(parameters['value']);
    final selectedValue = restored.isNotEmpty ? restored.first : null;
    print(
      "Restored selected value: $restored -> selectedValue: $selectedValue",
    );

    // Build options list
    for (int i = 0; i < englishValues.length; i++) {
      final label = i < translatedValues.length
          ? translatedValues[i]
          : englishValues[i];
      final option = OptionItem(value: englishValues[i], label: label);
      options.add(option);

      if (selectedValue != null && englishValues[i] == selectedValue) {
        selectedOption = option;
      }
    }

    print('Radio options after parsing: $options');
    print('Selected option after parsing: $selectedOption');

    super.init();
  }

  @override
  Widget render() {
    if (options.isEmpty) {
      return Text("No options available", style: TextStyle(color: Colors.grey));
    }

    return CustomValidator<String>(
      initialValue: selectedOption?.value ?? options.first.value,
      builder: (FormFieldState<String> state) {
        if (validation == null) {
          validation = state;
          Future.delayed(Duration.zero, () => update(() {}));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER (Kept identical to Checkbox) ---
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
                CustomText(
                  parameters['translated_name'] ?? parameters['name'],
                  fontSize: context.font.large,
                  fontWeight: FontWeight.w500,
                  color: context.color.textColorDark,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // --- OPTIONS LIST (Updated for better UI) ---
            ...List.generate(options.length, (index) {
              final option = options[index];
              final isSelected = selectedOption == option;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: () {
                    selectedOption = option;
                    state.didChange(selectedOption?.value);
                    AbstractField.fieldsData[parameters['id'].toString()] = [
                      selectedOption?.value,
                    ];
                    if (update != null) {
                      update(() {});
                    }
                    ;
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      // Subtle background to avoid "all white" look
                      color: isSelected
                          ? context.color.territoryColor.withValues(alpha: 0.05)
                          : context.color.textDefaultColor.withValues(
                              alpha: 0.03,
                            ),
                      border: Border.all(
                        color: isSelected
                            ? context
                                  .color
                                  .territoryColor // Actual color on select
                            : context.color.borderColor.withValues(alpha: 0.6),
                        width: isSelected ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        // Radio Circle UI
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent, // Background stays clear
                            border: Border.all(
                              color: isSelected
                                  ? context.color.territoryColor
                                  : context.color.textDefaultColor.withValues(
                                      alpha: 0.2,
                                    ),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: context
                                          .color
                                          .territoryColor, // Inner dot
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: CustomText(
                            option.label,
                            color: isSelected
                                ? context.color.textDefaultColor
                                : context.color.textDefaultColor.withValues(
                                    alpha: 0.7,
                                  ),
                            fontSize: context.font.large,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            if (state.hasError)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 5, start: 8.0),
                child: CustomText(
                  state.errorText ?? "",
                  color: context.color.error,
                  fontSize: context.font.small,
                ),
              ),
          ],
        );
      },
      validator: (String? value) {
        if (parameters['required'] == 1 && selectedOption == null) {
          return "please_select_option".translate(context);
        }
        return null;
      },
    );
  }
}
