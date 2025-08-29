import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:wti_cabs_user/core/route_management/app_routes.dart';

import '../../core/controller/currency_controller/currency_controller.dart';

class SelectCurrencyScreen extends StatelessWidget {
  SelectCurrencyScreen({Key? key}) : super(key: key);

  final CurrencyController controller = Get.put(CurrencyController());
  final RxString searchQuery = "".obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Currency",style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black),),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // ---------- Selected Currency Display ----------
          Obx(() {
            final selected = controller.selectedCurrency.value;
            return selected.code.isNotEmpty
                ? Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: Text(
                      selected.symbol,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        selected.code,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.blueAccent)
                ],
              ),
            )
                : const SizedBox.shrink();
          }),

          // ---------- Search Field ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search currency",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                searchQuery.value = value.trim().toLowerCase();
              },
            ),
          ),

          const SizedBox(height: 8),

          // ---------- Currency List ----------
          Expanded(
            child: Obx(() {
              final filtered = controller.availableCurrencies.where((c) {
                if (searchQuery.value.isEmpty) return true;
                return c.name.toLowerCase().contains(searchQuery.value) ||
                    c.code.toLowerCase().contains(searchQuery.value);
              }).toList();

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final currency = filtered[index];
                  final isSelected =
                      currency.code == controller.selectedCurrency.value.code;

                  return GestureDetector(
                    onTap: () async {
                      await controller.changeCurrency(currency);
                      GoRouter.of(context).go(AppRoutes.bottomNav);
                    },
                    child: Container(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:  Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child: Text(
                              currency.symbol,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currency.name,
                                  overflow: TextOverflow.clip,
                                  maxLines: 2,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                                Text(
                                  currency.code,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 24)
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
