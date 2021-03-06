import 'package:Moody/models/comment_model.dart';
import 'package:Moody/models/conversation_model.dart';
import 'package:Moody/models/feed_model.dart';
import 'package:Moody/models/m_notification_model.dart';
import 'package:Moody/models/message_model.dart';
import 'package:Moody/models/post_model.dart';
import 'package:Moody/models/user_model.dart';
import 'package:flutter/widgets.dart';

bool isSubtype<T1, T2>() => <T1>[] is List<T2>;

class WebResponse<T> {
  String message;
  int status;
  T data;

  WebResponse.withData(
      {@required this.status, @required this.message, this.data});

  WebResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    if (json['data'] != null) {
      if (T == UserModel) {
        data = UserModel.fromJson(json['data']['user']) as T;
      } else if (T == FeedModel) {
        data = FeedModel.fromJson(json['data']['posts']) as T;
      } else if (T == PostModel) {
        data = PostModel.fromJson(json['data']['post']) as T;
      } else if (T == CommentModel) {
        data = CommentModel.fromJson(json['data']['comment']) as T;
      } else if (T == ConversationModel) {
        data = ConversationModel.fromJson(json['data']['conversation']) as T;
      } else if (T == MessageModel) {
        data = MessageModel.fromJson(json['data']['message']) as T;
      } else if (T == Map) {
        data = json['data'];
      } else if (isSubtype<T, List<UserModel>>()) {
        data = new List<UserModel>() as T;
        var list = data as List;
        if (json['data']['users'] != null) {
          json['data']['users'].forEach((v) => list.add(UserModel.fromJson(v)));
        }
      } else if (isSubtype<T, List<ConversationModel>>()) {
        data = new List<ConversationModel>() as T;
        var list = data as List;
        if (json['data']['conversations'] != null) {
          json['data']['conversations']
              .forEach((v) => list.add(ConversationModel.fromJson(v)));
        }
      } else if (isSubtype<T, List<MessageModel>>()) {
        data = new List<MessageModel>() as T;
        var list = data as List;
        if (json['data']['messages'] != null) {
          json['data']['messages']
              .forEach((v) => list.add(MessageModel.fromJson(v)));
        }
      } else if (isSubtype<T, List<PostModel>>()) {
        data = new List<PostModel>() as T;
        var list = data as List;
        if (json['data']['posts'] != null) {
          json['data']['posts'].forEach((v) => list.add(PostModel.fromJson(v)));
        }
      } else if (isSubtype<T, List<MNotification>>()) {
        data = new List<MNotification>() as T;
        var list = data as List;
        if (json['data']['notifications'] != null) {
          json['data']['notifications']
              .forEach((v) => list.add(MNotification.fromJson(v)));
        }
      } else {
        data = new Map<String, dynamic>() as T;
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    return data;
  }
}
