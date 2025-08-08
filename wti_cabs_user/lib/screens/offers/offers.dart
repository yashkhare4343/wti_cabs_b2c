import 'package:flutter/material.dart';

class Offers extends StatefulWidget {
  @override
  State<Offers> createState() => _OffersState();
}

class _OffersState extends State<Offers> {
  final List<CabOption> options = [
    CabOption(
      title: "Dzire, Etios",
      subtitle: "or similar",
      fuel: "CNG",
      seats: 4,
      ac: true,
      isNew: true,
      discount: "5% off",
      originalPrice: 4000,
      price: 3800,
      taxes: 1540,
    ),
    CabOption(
      title: "Maruti Suzuki Ertiga",
      subtitle: "exact model",
      fuel: "CNG",
      seats: 6,
      ac: true,
      isNew: true,
      discount: "3% off",
      originalPrice: 5999,
      price: 5799,
      taxes: 1903,
    ),
    CabOption(
      title: "Xylo, Ertiga",
      subtitle: "or similar",
      fuel: "CNG",
      seats: 6,
      ac: true,
      isNew: true,
      discount: "3% off",
      originalPrice: 6101,
      price: 5901,
      taxes: 2066,
    ),
    CabOption(
      title: "Innova Crysta",
      subtitle: "exact model",
      fuel: "Diesel",
      seats: 6,
      ac: true,
      isNew: true,
      discount: "2% off",
      originalPrice: 10000,
      price: 9800,
      taxes: 2523,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Agra, Uttar Pra... to Jaipur, Rajasthan, India",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text("Edit", style: TextStyle(color: Colors.blue)),
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(25),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              "05 Aug, 05:45 PM",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Color(0xFF1565C0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _featureIcon(Icons.verified_user, "Trusted Drivers"),
                  _featureIcon(Icons.cleaning_services, "Clean cabs"),
                  _featureIcon(Icons.access_time_rounded, "On-Time Pickup"),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
                "Rates for 239 Kms approx distance | 4.5 hr(s) approx time",
                style: TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                return CabCard(cab: options[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureIcon(IconData icon, String title) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class CabOption {
  final String title;
  final String subtitle;
  final String fuel;
  final int seats;
  final bool ac;
  final bool isNew;
  final String discount;
  final int originalPrice;
  final int price;
  final int taxes;

  CabOption({
    required this.title,
    required this.subtitle,
    required this.fuel,
    required this.seats,
    required this.ac,
    required this.isNew,
    required this.discount,
    required this.originalPrice,
    required this.price,
    required this.taxes,
  });
}

class CabCard extends StatelessWidget {
  final CabOption cab;
  const CabCard({Key? key, required this.cab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color fuelColor =
    cab.fuel == 'CNG' ? Colors.cyan : Colors.amber;
    return Card(
      color: Colors.white,
      elevation: 0.3,
      margin: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Image.asset('assets/images/card_image.png', width: 60, height: 60,),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: Text(cab.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),

                      SizedBox(width: 6),
                    ],
                  ),
                  Text(cab.subtitle, style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12, color: Colors.grey[600])),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text("${cab.seats} Seats",
                          style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12,color: Colors.grey[700])),
                      SizedBox(width: 8),
                      if (cab.ac)
                        Text("• AC", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12,color: Colors.grey[700])),
                    ],
                  )
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(cab.discount,
                        style: TextStyle(
                          fontSize: 12,
                            color: Colors.green, fontWeight: FontWeight.w500)),
                    SizedBox(width: 6),

                    Text(
                      "₹${cab.originalPrice}",
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                  ],
                ),
                SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [

                    Text(
                      "₹${cab.price}",
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text("+ ₹${cab.taxes} (Taxes & Charges)",
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 11)),
              ],
            )
          ],
        ),
      ),
    );
  }
}