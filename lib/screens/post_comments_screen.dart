import 'package:Moody/components/bottom_form_text_field.dart';
import 'package:Moody/components/default_shimmer.dart';
import 'package:Moody/components/post_widget.dart';
import 'package:Moody/helpers/emoji_text.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:Moody/helpers/random.dart';
import 'package:Moody/models/comment_model.dart';
import 'package:Moody/models/error_response_model.dart';
import 'package:Moody/models/post_model.dart';
import 'package:Moody/services/auth_service.dart';
import 'package:Moody/services/post_service.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:simple_moment/simple_moment.dart';
import 'package:toast/toast.dart';

class PostCommentsScreen extends StatefulWidget {
  PostCommentsScreen(
      {Key key, this.postId, this.hasPost = false, this.focusedCommentId})
      : super(key: key);

  final String postId;
  final bool hasPost;
  final String focusedCommentId;

  @override
  _PostCommentsScreenState createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  PostService postService;
  AuthService authService;
  ScrollController scrollController;
  AutoScrollController autoScrollController = AutoScrollController();
  bool loading = true;
  PostModel post;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    scrollController = ScrollController();
    postService = Provider.of<PostService>(context, listen: false);
    authService = Provider.of<AuthService>(context, listen: false);
    postService.getPost(widget.postId).then((value) {
      if (this.mounted)
        this.setState(() {
          post = value;
          loading = false;
        });
      if (widget.focusedCommentId != null)
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
          int index = post.comments
              .indexWhere((element) => element.sId == widget.focusedCommentId);
          await autoScrollController.scrollToIndex(index + 1,
              preferPosition: AutoScrollPosition.begin);
          autoScrollController.highlight(index);
        });
    });
  }

  @override
  void dispose() {
    autoScrollController.dispose();
    super.dispose();
  }

  Future<void> deleteComment(String commentId) async {
    final comment =
        post.comments.firstWhere((element) => element.sId == commentId);
    this.setState(() {
      comment.isProcessing = true;
    });
    try {
      await postService.deleteComment(post, commentId);
      Toast.show('Comment was deleted', context);
      this.setState(() {
        post.comments.removeWhere((element) => element.sId == commentId);
      });
    } on WebErrorResponse catch (e) {
      Toast.show(e.message, context);
      this.setState(() {
        comment.isProcessing = false;
      });
    }
  }

  Future<void> commentOnPost(String comment) async {
    if (comment != '') {
      String newCommentTempId = RandomString.createCryptoRandomString();
      this.setState(() {
        post.comments.add(
          CommentModel(
            message: comment,
            user: authService.user,
            isProcessing: true,
            sId: newCommentTempId,
          ),
        );
      });

      try {
        final req = await postService.comment(post, comment);
        this.setState(() {
          int index = post.comments
              .indexWhere((comment) => comment.sId == newCommentTempId);
          post.comments[index] = req.data;
        });
      } on WebErrorResponse catch (e) {
        Toast.show(e.message, context);
      }
    } else {
      Toast.show('Empty message not allowed!', context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text(widget.focusedCommentId != null ? 'Comments' : 'Post'),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              postService.getPost(widget.postId).then((value) {
                if (this.mounted)
                  this.setState(() {
                    post = value;
                  });
              });
            },
            child: SingleChildScrollView(
              controller: autoScrollController,
              child: Column(
                children: loading
                    ? [
                        if (widget.hasPost) PostWidgetLoading(),
                        for (int i = 0; i < 9; i++)
                          Opacity(
                            opacity: (9 - i) / 9 > 0 ? (9 - i) / 9 : 0,
                            child: PostFullComment(comment: null),
                          ),
                      ]
                    : <Widget>[
                        if (widget.hasPost)
                          PostWidget(post: post, hasBottomDetails: false),
                        if (post.caption != '')
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: <Widget>[
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundImage:
                                              ExtendedNetworkImageProvider(
                                                  post.user.profilePicUrl),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              post.user.userName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text.rich(
                                              buildTextSpansWithEmojiSupport(
                                                post.caption,
                                              ),
                                              softWrap: true,
                                            ),
                                            Text(
                                              Moment.now().from(
                                                DateTime.parse(post.createdAt),
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Divider()
                            ],
                          ),
                        if (post.comments.length == 0)
                          Container(
                            padding: EdgeInsets.all(20),
                            alignment: Alignment.center,
                            child: Text('No comments on this post.'),
                          ),
                        for (int i = 0; i < post.comments.length; i++)
                          Column(
                            children: [
                              AutoScrollTag(
                                key: ValueKey(i),
                                controller: autoScrollController,
                                index: i,
                                highlightColor: Colors.grey[300],
                                child: PostFullComment(
                                  comment: post.comments[i],
                                  onPostDeleteAction: (post.user.sId ==
                                              authService.user.sId ||
                                          (post.comments[i].user != null
                                                  ? post.comments[i].user.sId
                                                  : post.comments[i].userId) ==
                                              authService.user.sId)
                                      ? () async {
                                          await deleteComment(
                                              post.comments[i].sId);
                                        }
                                      : null,
                                ),
                              ),
                              Divider(
                                height: 1,
                                thickness: .5,
                              ),
                            ],
                          ),
                        AutoScrollTag(
                          key: ValueKey(post.comments.length),
                          controller: autoScrollController,
                          index: post.comments.length,
                          child: SizedBox(
                            height: 100,
                          ),
                        ),
                      ],
              ),
              physics: AlwaysScrollableScrollPhysics(),
            ),
          ),
          bottomSheet: BottomSingleTextFieldForm(
            onSend: (message) {
              commentOnPost(message);
            },
          )),
    );
  }
}

class PostFullComment extends StatefulWidget {
  const PostFullComment({
    Key key,
    @required this.comment,
    this.onPostDeleteAction,
  }) : super(key: key);

  final CommentModel comment;
  final Function onPostDeleteAction;

  @override
  _PostFullCommentState createState() => _PostFullCommentState();
}

class _PostFullCommentState extends State<PostFullComment> {
  @override
  Widget build(BuildContext context) {
    return Slidable(
      actionPane: SlidableDrawerActionPane(),
      secondaryActions: <Widget>[
        if (widget.onPostDeleteAction != null)
          IconSlideAction(
            icon: EvaIcons.trash2Outline,
            foregroundColor: Colors.red,
            color: Colors.transparent,
            onTap: widget.onPostDeleteAction,
          )
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: widget.comment == null
                        ? null
                        : ExtendedNetworkImageProvider(
                            widget.comment.user.profilePicUrl),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.comment == null
                          ? [
                              DefaultShimmer(
                                height: 13,
                                width: 70,
                              ),
                              DefaultShimmer(
                                height: 15,
                                width: 100,
                              ),
                            ]
                          : <Widget>[
                              Text(
                                widget.comment.user.userName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: widget.comment.isProcessing
                                      ? Colors.black45
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text.rich(
                                buildTextSpansWithEmojiSupport(
                                  widget.comment.message,
                                  style: TextStyle(
                                    color: widget.comment.isProcessing
                                        ? Colors.black45
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              if (!widget.comment.isProcessing)
                                Text(
                                  Moment.now().from(
                                    DateTime.parse(widget.comment.createdAt),
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
