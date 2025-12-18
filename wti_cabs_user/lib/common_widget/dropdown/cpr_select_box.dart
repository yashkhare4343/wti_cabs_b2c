import 'package:flutter/material.dart';

class CprSelectBox extends StatelessWidget {
  final String labelText;
  final String hintText;
  final List<String> items;
  final String? selectedValue;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;
  final EdgeInsetsGeometry? contentPadding;

  const CprSelectBox({
    super.key,
    required this.labelText,
    required this.hintText,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.validator,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: validator,
      initialValue: selectedValue,
      builder: (state) {
        final bool isEmpty =
            (selectedValue == null || (selectedValue?.isEmpty ?? true));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                if (items.isEmpty) return;

                final result = await showModalBottomSheet<String>(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  backgroundColor: Colors.white,
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            height: 4,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            labelText,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final value = items[index];
                                final bool isSelected =
                                    value == selectedValue;

                                return ListTile(
                                  title: Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.black87,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle,
                                          color: Colors.blue)
                                      : null,
                                  onTap: () {
                                    Navigator.pop(context, value);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );

                if (result != null) {
                  onChanged(result);
                  state.didChange(result);
                }
              },
              child: InputDecorator(
                isEmpty: isEmpty,
                decoration: InputDecoration(
                  labelText: labelText,
                  // hintText: hintText,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                  ),
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF333333),
                  ),
                  contentPadding: contentPadding ??
                      const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color(0x1A000000), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: Color(0x1A000000), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: state.errorText,
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                ),
                child: Text(
                  isEmpty ? hintText : (selectedValue ?? ''),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color:
                        isEmpty ? const Color(0xFF333333) : Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
