import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controller/corporate/crp_branch_list_controller/crp_branch_list_controller.dart';

class CorporateBranchDropdown extends StatelessWidget {
  final String corpId;
  CorporateBranchDropdown({super.key, required this.corpId});

  final CrpBranchListController controller = Get.put(CrpBranchListController());

  @override
  Widget build(BuildContext context) {
    // Fetch branches when widget builds
    controller.fetchBranches(corpId);

    return Obx(() {
      final isLoading = controller.isLoading.value;
      final items = controller.branchNames;
      final selected = controller.selectedBranchName.value;

      return GestureDetector(
        onTap: isLoading
            ? null
            : () => _showBranchSelector(context, items, selected??''),
        child: AbsorbPointer(
          // Prevents text field interaction
          child: TextFormField(
            controller: TextEditingController(
              text: selected?.isEmpty??false ? '' : selected,
            ),
            readOnly: true,
            validator: (value) =>
            (value == null || value.isEmpty) ? "Please select a city" : null,
            decoration: InputDecoration(
              labelText: "Choose City",
              labelStyle: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              prefixIcon: const Icon(
                Icons.location_city_rounded,
                color: Colors.indigo,
              ),
              suffixIcon: isLoading
                  ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.indigo,
                  ),
                ),
              )
                  : const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.indigo,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
              ),
            ),
          ),
        ),
      );
    });
  }

  // 📍 BottomSheet UI
  void _showBranchSelector(
      BuildContext context, List<String> items, String selected) {
    if (items.isEmpty) {
      Get.snackbar("No Branches", "No branches found for this corporate ID",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              const Text(
                "Select Branch",
                style: TextStyle(
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
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final name = items[index];
                    final isSelected = name == selected;

                    return ListTile(
                      title: Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.indigo : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.indigo)
                          : null,
                      onTap: () {
                        controller.selectBranch(name);
                        Navigator.pop(context);
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
  }
}
