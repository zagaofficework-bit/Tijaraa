import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';

class GoldMembersDrawerScreen extends StatelessWidget {
  final List<Map<String, String>> featuredAds = const [
    {
      "image": "https://via.placeholder.com/300x200.png?text=Gold+Member+Ad+1",
      "title": "Luxury Car for Sale",
      "price": "₹25,00,000",
    },
    {
      "image": "https://via.placeholder.com/300x200.png?text=Gold+Member+Ad+2",
      "title": "Premium Villa in Mumbai",
      "price": "₹1.2 Cr",
    },
    {
      "image": "https://via.placeholder.com/300x200.png?text=Gold+Member+Ad+3",
      "title": "High-End Gaming Laptop",
      "price": "₹1,80,000",
    },
  ];

  const GoldMembersDrawerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.color.primaryColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟡 HEADER
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Colors.amber.shade400,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Gold Members Featured Ads",
                      style: TextStyle(
                        color: context.color.textDefaultColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1),

            // 🧱 BODY
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: featuredAds.length,
                itemBuilder: (context, index) {
                  final ad = featuredAds[index];
                  return Card(
                    color: context.color.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Opening ${ad['title']}...")),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🖼️ IMAGE with fallback
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              ad["image"]!,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180,
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 📝 TEXT
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ad["title"]!,
                                  style: TextStyle(
                                    color: context.color.textDefaultColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ad["price"]!,
                                  style: TextStyle(
                                    color: context.color.territoryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🌟 FOOTER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: context.color.secondaryColor,
              child: Center(
                child: Text(
                  "🌟 Join Gold Membership to get featured here!",
                  style: TextStyle(
                    color: context.color.textDefaultColor,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
