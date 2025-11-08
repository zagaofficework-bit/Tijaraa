// lib/ui/screens/notification/notification_screen.dart
import 'package:Tijaraa/services/cloud_firestore.dart';
import 'package:Tijaraa/ui/screens/home/home_screen.dart';
import 'package:Tijaraa/ui/screens/widgets/errors/no_data_found.dart';
import 'package:Tijaraa/ui/theme/theme.dart';
import 'package:Tijaraa/utils/app_icon.dart';
import 'package:Tijaraa/utils/custom_text.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
import 'package:Tijaraa/utils/hive_utils.dart';
import 'package:Tijaraa/utils/ui_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  static Route route(RouteSettings settings) {
    return MaterialPageRoute(builder: (context) => const NotificationScreen());
  }

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final ScrollController _scrollController = ScrollController();
  final String? userId = HiveUtils.getUserId();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.color.backgroundColor, // Use a visible color
        elevation: 0,
        title: Text(
          "Notifications",
          style: TextStyle(
            color: context.color.backgroundColor, // Make sure title is visible
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.color.backgroundColor),
          onPressed: () {
            // Navigate back to home screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: CloudFirestoreService().getNotificationsStream(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: UiUtils.progress());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return NoDataFound(subMessage: "", onTap: () {});
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            controller: _scrollController,
            itemCount: notifications.length,
            padding: const EdgeInsets.only(top: 10),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data();
              final title = data['title'] ?? '';
              final body = data['body'] ?? '';
              final isRead = data['isRead'] ?? false;
              final imageUrl = data['imageUrl'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0.0,
                  horizontal: 10,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    border: Border.all(
                      color: context.color.borderColor,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: notificationItem(
                    context,
                    doc,
                    title,
                    body,
                    isRead,
                    imageUrl,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget notificationItem(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String title,
    String body,
    bool isRead,
    String imageUrl,
  ) {
    return InkWell(
      onTap: () async {
        if (!isRead) {
          await doc.reference.update({'isRead': true});
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                if (imageUrl.isNotEmpty) {
                  UiUtils.showFullScreenImage(
                    context,
                    provider: CachedNetworkImageProvider(imageUrl),
                  );
                }
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: imageUrl.isEmpty
                      ? CircleAvatar(
                          radius: 18,
                          backgroundColor: context.color.territoryColor,
                          child: SvgPicture.asset(
                            AppIcons.notification,
                            height: 20,
                            width: 20,
                            colorFilter: ColorFilter.mode(
                              context.color.buttonColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 18,
                          backgroundColor: context.color.territoryColor,
                          backgroundImage: NetworkImage(imageUrl),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    color: context.color.textColorDark,
                    fontSize: context.font.large,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 3),
                  CustomText(
                    body,
                    color: context.color.textColorDark.withOpacity(0.8),
                    fontSize: context.font.normal,
                  ),
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
