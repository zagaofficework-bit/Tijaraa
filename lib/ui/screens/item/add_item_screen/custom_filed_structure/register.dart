import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_checkbox_field.dart';
import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_dropdown_field.dart';
import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_file_field.dart';
import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_number_field.dart';
import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_radio_field.dart';
import 'package:Tijaraa/ui/screens/item/add_item_screen/custom_filed_structure/fields/custom_text_field.dart';

class KRegisteredFields {
  ///ADD NEW FIELD HERE
  final List<CustomField> _fields = [
    CustomFieldText(), //text field
    CustomFieldDropdown(), //dropdown field
    CustomNumberField(),
    CustomCheckboxField(),
    CustomRadioField(),
    CustomFileField(),
  ];

  CustomField? get(String type) {
    switch (type) {
      case 'textbox':
        return CustomFieldText();
      case 'dropdown':
        return CustomFieldDropdown();
      case 'number':
        return CustomNumberField();
      case 'checkbox':
        return CustomCheckboxField();
      case 'radio':
        return CustomRadioField();
      case 'fileinput':
        return CustomFileField();
      default:
        return null;
    }
  }
}
