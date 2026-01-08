import 'dart:convert';

import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/option_item.dart';
import 'package:Tijaraa/ui/screens/widgets/dynamic_field.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/app_icon.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomFieldDropdown extends CustomField {
  @override
  String type = "dropdown";
  String? selected;

  final List<OptionItem> options = List.empty(growable: true);
  @override
  void init() {
    options.clear();
    selected = null;

    List<String> flatList = [];

    List<String> normalize(dynamic value) {
      if (value == null) return [];

      // 🔥 CASE 1: JSON string like '["Petrol","Diesel"]'
      if (value is String) {
        final trimmed = value.trim();

        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          try {
            final decoded = jsonDecode(trimmed);
            if (decoded is List) {
              return decoded.map((e) => e.toString()).toList();
            }
          } catch (_) {
            // fall through
          }
        }

        // Normal single string
        return trimmed.isNotEmpty ? [trimmed] : [];
      }

      // 🔥 CASE 2: Deeply nested lists
      while (value is List && value.length == 1) {
        value = value.first;
      }

      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }

      return [];
    }

    // 1️⃣ First priority: translated_value (backend-resolved)
    flatList = normalize(parameters['translated_value']);

    // 2️⃣ Second priority: translations[*].value
    if (flatList.isEmpty && parameters['translations'] is List) {
      for (final t in parameters['translations']) {
        final values = normalize(t['value']);
        if (values.isNotEmpty) {
          flatList = values;
          break;
        }
      }
    }

    // 🔍 DEBUG (keep this temporarily)
    debugPrint("DROPDOWN RAW DATA → $flatList");
    debugPrint("FLAT TYPE → ${flatList.runtimeType}");
    // 3️⃣ Build dropdown options (single-single)
    for (final v in flatList) {
      options.add(OptionItem(value: v, label: v));
    }

    // 4️⃣ Restore selected value (edit case)
    final restored = normalize(parameters['value']);
    if (restored.isNotEmpty && flatList.contains(restored.first)) {
      selected = restored.first;
    }

    super.init();
  }

  @override
  Widget render() {
    // print(
    //   "DEBUG: Rendering ${parameters['name']} dropdown. Current options count: ${options.length}",
    // );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (parameters['image'] != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.color.territoryColor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: FittedBox(
                    fit: BoxFit.none,
                    child: UiUtils.imageType(
                      parameters['image'],
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                      color: context.color.textDefaultColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
            ],
            CustomText(
              parameters['translated_name'] ?? parameters['name'],
              fontSize: context.font.large,
              fontWeight: FontWeight.w500,
              color: context.color.textColorDark,
            ),
          ],
        ),
        SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.color.secondaryColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    width: 1,
                    color: context.color.textLightColor.withValues(alpha: 0.18),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      value: selected,
                      hint: CustomText(
                        'select'.translate(context),
                        color: context.color.textDefaultColor.withValues(
                          alpha: 0.5,
                        ),
                        fontSize: context.font.large,
                      ),
                      isExpanded: true,
                      dropdownColor: context.color.secondaryColor,
                      icon: SvgPicture.asset(
                        AppIcons.downArrow,
                        colorFilter: ColorFilter.mode(
                          context.color.textDefaultColor,
                          BlendMode.srcIn,
                        ),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      isDense: true,
                      borderRadius: BorderRadius.circular(10),
                      style: TextStyle(
                        color: context.color.textDefaultColor,
                        fontSize: context.font.large,
                      ),
                      items: options.map((item) {
                        return DropdownMenuItem<String>(
                          value: item.value,
                          child: CustomText(item.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        selected = value;
                        update(() {});
                        AbstractField.fieldsData[parameters['id'].toString()] =
                            [selected];
                      },
                    ),
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
