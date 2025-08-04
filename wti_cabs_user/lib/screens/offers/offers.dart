import 'package:flutter/material.dart';

class Offers extends StatefulWidget {
  @override
  _OffersState createState() => _OffersState();
}

class _OffersState extends State<Offers> {
  List<Map<String, String>> currencyList = [
    {"country": "India", "currency": "INR"},
    {"country": "United States", "currency": "USD"},
    {"country": "United Kingdom", "currency": "GBP"},
    {"country": "Japan", "currency": "JPY"},
    {"country": "Germany", "currency": "EUR"},
    {"country": "Australia", "currency": "AUD"},
    {"country": "Canada", "currency": "CAD"},
  ];

  List<Map<String, String>> filteredCurrencyList = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCurrencyList = List.from(currencyList);
    searchController.addListener(() {
      final query = searchController.text.toLowerCase();
      setState(() {
        filteredCurrencyList = currencyList.where((item) {
          final country = item['country']?.toLowerCase() ?? '';
          final currency = item['currency']?.toLowerCase() ?? '';
          return country.contains(query) || currency.contains(query);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _showCurrencyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search country or currency',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: filteredCurrencyList.length,
                  itemBuilder: (context, index) {
                    final item = filteredCurrencyList[index];
                    return ListTile(
                      leading: Icon(Icons.flag),
                      title: Text(item['country'] ?? ''),
                      subtitle: Text(item['currency'] ?? ''),
                      onTap: () {
                        Navigator.pop(context, item);
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((selectedItem) {
      if (selectedItem != null) {
        print("Selected: ${selectedItem['country']} - ${selectedItem['currency']}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Country Currency")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showCurrencyBottomSheet(context),
          child: Text("Choose Currency"),
        ),
      ),
    );
  }
}
