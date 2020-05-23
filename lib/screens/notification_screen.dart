import 'package:Moody/components/loader.dart';
import 'package:Moody/helpers/navigation.dart';
import 'package:Moody/models/m_notification_model.dart';
import 'package:Moody/screens/post_comments_screen.dart';
import 'package:Moody/screens/post_screen.dart';
import 'package:Moody/screens/profile_screen.dart';
import 'package:Moody/services/notification_service.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_moment/simple_moment.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Widget buildNotification(MNotification mNotification) {
    InlineSpan richText;
    Function browseNotification;

    switch (mNotification.type) {
      case UserNotificationType.POST_LIKED:
        richText = likeNotificationText(mNotification);
        browseNotification = () {
          //gotoPageWithAnimation(context: context, page: PostScreen(post: ,));
        };
        break;
      case UserNotificationType.POST_COMMENTED:
        richText = commentNotificationText(mNotification);
        browseNotification = () {
          gotoPageWithAnimation(
            context: context,
            page: PostCommentsScreen(
              postId: mNotification.post.sId,
            ),
          );
        };
        break;
      case UserNotificationType.USER_FOLLOWED:
        richText = followNotificationText(mNotification);
        browseNotification = () {
          gotoPageWithAnimation(
            context: context,
            page: ProfileScreen(
              user: mNotification.from,
            ),
          );
        };
        break;
      case UserNotificationType.UNKNOWN:
      default:
        richText = unknownNotificationText(mNotification);
        browseNotification = null;
        break;
    }

    return FlatButton(
      onPressed: () {
        Provider.of<NotificationService>(context, listen: false)
            .markNotificationAsRead(mNotification.sId);
        browseNotification();
      },
      padding: EdgeInsets.all(10),
      color: mNotification.read ? Colors.white : Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 18,
                  backgroundImage: ExtendedNetworkImageProvider(
                    mNotification.from.profilePicUrl,
                    cache: true,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        richText,
                        TextSpan(text: '\n'),
                        TextSpan(
                          text: Moment.fromDate(
                            DateTime.now(),
                          ).from(
                            DateTime.parse(mNotification.createdAt),
                          ),
                          style: TextStyle(
                            fontSize: 10,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (mNotification.post != null)
            Container(
              height: 30,
              child: ExtendedImage.network(
                mNotification.post.imageUrl,
                cache: true,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: Colors.grey[300],
          ),
        ),
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await notificationService.refreshNotifications();
              await notificationService.markNewUnreadNotificationRead();
            },
            child: notificationService.notifications.length == 0
                ? Text('No new notifications')
                : ListView.separated(
                    itemBuilder: (context, index) => buildNotification(
                      notificationService.notifications[index],
                    ),
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: notificationService.notifications.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                    ),
                  ),
          );
        },
      ),
    );
  }

  InlineSpan likeNotificationText(MNotification mNotification) {
    return TextSpan(
      children: [
        TextSpan(
          text: mNotification.from.userName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: ' liked your post.',
        )
      ],
    );
  }

  InlineSpan commentNotificationText(MNotification mNotification) {
    return TextSpan(
      children: [
        TextSpan(
          children: [
            TextSpan(
              text: mNotification.from.userName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: ' commented on your post.\n',
            ),
          ],
        ),
        TextSpan(
          text: '"${mNotification.comment.message}"',
        ),
      ],
    );
  }

  InlineSpan followNotificationText(MNotification mNotification) {
    return TextSpan(
      children: [
        TextSpan(
          text: mNotification.from.userName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: ' is now following you.',
        )
      ],
    );
  }

  InlineSpan unknownNotificationText(MNotification mNotification) {
    return TextSpan(
      children: [
        TextSpan(
          text: mNotification.from.userName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextSpan(
          text: ' has a unknown notification for u, try upating the app.',
        )
      ],
    );
  }
}
