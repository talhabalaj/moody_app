import 'dart:typed_data';

import 'package:Moody/components/default_shimmer.dart';
import 'package:Moody/components/user_list_item.dart';
import 'package:Moody/helpers/dialogs.dart';
import 'package:Moody/helpers/emoji_text.dart';
import 'package:Moody/helpers/navigation.dart';
import 'package:Moody/models/comment_model.dart';
import 'package:Moody/models/error_response_model.dart';
import 'package:Moody/models/post_model.dart';
import 'package:Moody/screens/people_list_screen.dart';
import 'package:Moody/screens/post_comments_screen.dart';
import 'package:Moody/screens/profile_screen.dart';
import 'package:Moody/services/auth_service.dart';
import 'package:Moody/services/feed_service.dart';
import 'package:Moody/services/post_service.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_moment/simple_moment.dart';
import 'package:toast/toast.dart';

class PostWidget extends StatefulWidget {
  final PostModel post;
  final bool hasBottomDetails;

  const PostWidget({Key key, this.post, this.hasBottomDetails = true})
      : super(key: key);

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  PostService postServce;
  AuthService authService;

  Future<void> toggleLike() async {
    widget.post.likes.indexOf(authService.user.sId) == -1
        ? await postServce.like(widget.post)
        : await postServce.unlike(widget.post);
  }

  @override
  void didChangeDependencies() {
    postServce = Provider.of<PostService>(context);
    authService = Provider.of<AuthService>(context);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNetworkPost = widget.post.stateType == PostStateType.NETWORK;
    final Function like = isNetworkPost
        ? () async {
            await toggleLike();
          }
        : null;
    final Function comment = isNetworkPost
        ? () {
            gotoPageWithAnimation(
                context: context,
                page: PostCommentsScreen(
                  postId: widget.post.sId,
                ),
                name: '/post/${widget.post.sId}/comments');
          }
        : null;

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!isNetworkPost) LinearProgressIndicator(),
        PostTopBar(
          post: widget.post,
        ),
        Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              top: BorderSide(
                color: Colors.grey[300],
              ),
              bottom: BorderSide(
                color: Colors.grey[300],
              ),
            ),
          ),
          child: isNetworkPost
              ? ExtendedImage.network(
                  widget.post.imageUrl,
                  cache: true,
                  height: MediaQuery.of(context).size.width,
                  mode: kIsWeb
                      ? ExtendedImageMode.none
                      : ExtendedImageMode.gesture,
                  initGestureConfigHandler: (state) => GestureConfig(
                    minScale: 1,
                    maxScale: 2,
                  ),
                  onDoubleTap: (state) => like,
                )
              : ExtendedImage.memory(
                  Uint8List.fromList(widget.post.image),
                  height: MediaQuery.of(context).size.width,
                  mode: kIsWeb
                      ? ExtendedImageMode.none
                      : ExtendedImageMode.gesture,
                ),
        ),
        IconTheme(
          data: IconThemeData(color: Colors.grey[800], size: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: BorderDirectional(
                bottom: BorderSide(
                  color: Colors.grey[300],
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  icon: widget.post.likes.indexOf(authService.user.sId) == -1
                      ? Icon(
                          EvaIcons.heartOutline,
                          size: 30,
                        )
                      : Icon(
                          EvaIcons.heart,
                          color: Colors.red,
                          size: 30,
                        ),
                  onPressed: like,
                ),
                IconButton(
                  icon: Icon(EvaIcons.messageSquareOutline),
                  iconSize: 30,
                  onPressed: widget.hasBottomDetails ? comment : null,
                ),
              ],
            ),
          ),
        ),
        PostBottomDetails(
          post: widget.post,
          hasBottomPart: widget.hasBottomDetails,
        ),
        if (widget.hasBottomDetails)
          SizedBox(
            height: 30,
          ),
      ],
    );
  }
}

class PostTopBar extends StatelessWidget {
  const PostTopBar({Key key, this.post}) : super(key: key);

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final loggedInUser = Provider.of<AuthService>(context, listen: false).user;

    return Container(
      decoration: BoxDecoration(
        border: BorderDirectional(
          top: BorderSide(
            color: Colors.grey[300],
          ),
        ),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              gotoPageWithAnimation(
                context: context,
                page: ProfileScreen(
                  user: post.user,
                ),
                name: '/user/${post.user}',
              );
            },
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 18,
                  backgroundImage: ExtendedNetworkImageProvider(
                    post.user.profilePicUrl,
                    cache: true,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  '${post.user.userName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (post.user.sId == loggedInUser.sId)
            PopupMenuButton<String>(
              icon: Icon(EvaIcons.moreVertical),
              onSelected: (value) async {
                if (value == 'delete') {
                  bool choice = await showConfirmationDialog(
                    context: context,
                    title: "Delete post",
                    desc: "Are you sure you want to delete this post?",
                  );
                  if (choice) {
                    try {
                      await Provider.of<FeedService>(context, listen: false)
                          .deletePost(post);
                      Toast.show("Post was deleted successfully.", context);
                    } on WebErrorResponse catch (e) {
                      Toast.show(e.message, context);
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  child: Text('Delete'),
                  value: 'delete',
                )
              ],
            )
        ],
      ),
    );
  }
}

class PostBottomDetails extends StatefulWidget {
  PostBottomDetails({Key key, this.post, this.hasBottomPart = true})
      : super(key: key);
  final PostModel post;
  final bool hasBottomPart;

  @override
  _PostBottomDetailsState createState() => _PostBottomDetailsState();
}

class _PostBottomDetailsState extends State<PostBottomDetails> {
  Widget getLikesDescription(context) {
    final loggedInUser = Provider.of<AuthService>(context, listen: false).user;
    final knownLikers = loggedInUser.following
        .where((f) => widget.post.likes.indexOf(f.sId) != -1)
        .toList()
          ..shuffle();
    final textStyle = TextStyle(fontWeight: FontWeight.bold);
    Widget likeWidget =
        Text('${widget.post.likes.length} likes', style: textStyle);

    if (knownLikers.length > 0) {
      List<Widget> likeWidgetList = [
        Padding(
          padding: const EdgeInsets.only(right: 5, left: 1),
          child: CircleAvatar(
            radius: 10,
            backgroundImage:
                ExtendedNetworkImageProvider(knownLikers[0].profilePicUrl),
          ),
        ),
        Text(
          'Liked by ',
          style: textStyle,
        ),
        Text(knownLikers[0].userName, style: textStyle),
      ];
      if (widget.post.likes.length - 1 > 0)
        likeWidgetList.add(
          Text(
            ' and ${widget.post.likes.length - 1} others',
            style: textStyle,
          ),
        );

      likeWidget = Row(
        children: likeWidgetList,
      );
    }

    return GestureDetector(
      onTap: () {
        gotoPageWithAnimation(
            context: context,
            page: PeopleListScreen(
              list: widget.post.likes,
              listTitle: "Likers",
            ),
            name: '/post/${widget.post.sId}/likes');
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: likeWidget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          getLikesDescription(context),
          if (widget.post.caption != '' && widget.hasBottomPart)
            PostCaption(post: widget.post),
          if (widget.post.comments.length > 0 && widget.hasBottomPart)
            PostCompactComments(post: widget.post),
          if (widget.post.createdAt != null && widget.hasBottomPart)
            Text(
              Moment.fromDate(
                DateTime.now(),
              ).from(
                DateTime.parse(widget.post.createdAt),
              ),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            )
        ],
      ),
    );
  }
}

class PostCompactComments extends StatefulWidget {
  PostCompactComments({
    Key key,
    @required this.post,
  }) : super(key: key);

  final PostModel post;

  @override
  _PostCompactCommentsState createState() => _PostCompactCommentsState();
}

class _PostCompactCommentsState extends State<PostCompactComments> {
  TextSpan buildComment(CommentModel comment) {
    return TextSpan(
      style: TextStyle(
        color: comment.isProcessing ? Colors.black45 : Colors.black,
      ),
      children: [
        TextSpan(
          text: comment.user.userName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: " "),
        buildTextSpansWithEmojiSupport(comment.message),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxCommentRange =
        (widget.post.comments.length > 3 ? 3 : widget.post.comments.length);
    final lessComments = widget.post.comments.reversed
        .toList()
        .getRange(
          0,
          maxCommentRange,
        )
        .toList()
        .reversed
        .toList();

    return GestureDetector(
      onTap: () {
        gotoPageWithAnimation(
            context: context,
            page: PostCommentsScreen(postId: widget.post.sId),
            name: '/post/${widget.post.sId}/comments');
      },
      child: Text.rich(
        TextSpan(
          children: [
            if (widget.post.comments.length > 3)
              TextSpan(
                text: 'View all comments\n',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            for (int idx = 0; idx < lessComments.length; idx++)
              TextSpan(
                children: [
                  buildComment(lessComments[idx]),
                  if (idx != lessComments.length - 1) TextSpan(text: '\n')
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class PostCaption extends StatelessWidget {
  const PostCaption({
    Key key,
    @required this.post,
  }) : super(key: key);

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(children: [
            TextSpan(
              text: post.user.userName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: " "),
            buildTextSpansWithEmojiSupport(post.caption),
          ]),
        ],
      ),
    );
  }
}

class PostWidgetLoading extends StatelessWidget {
  const PostWidgetLoading({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UserListItem(user: null, chevron: false),
        DefaultShimmer(
          height: MediaQuery.of(context).size.width,
          width: MediaQuery.of(context).size.width,
        ),
        SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: DefaultShimmer(width: 75, height: 10),
        ),
      ],
    );
  }
}
