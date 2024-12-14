import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .snapshots(),
      builder: (ctx, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!chatSnapshot.hasData || chatSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages found.'),
          );
        }

        if (chatSnapshot.hasError) {
          return const Center(
            child: Text('An error occurred!'),
          );
        }

        final chatDocs = chatSnapshot.data!.docs;
        return ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 40,
              left: 13,
              right: 13,
            ),
            reverse: true,
            itemCount: chatDocs.length,
            itemBuilder: (ctx, index) {
              final chatmessage = chatDocs[index].data();
              final nextChatMessage = index + 1 < chatDocs.length
                  ? chatDocs[index + 1].data()
                  : null;
              final currentMessageUserId = chatmessage['userId'];
              final nextMessageUserId =
                  nextChatMessage != null ? nextChatMessage['userId'] : null;
              final nextUserIsSame = nextMessageUserId == currentMessageUserId;


              if (nextUserIsSame) {
                return MessageBubble.next(
                  message: chatmessage['text'],
                  isMe: authenticatedUser.uid == chatmessage['userId'],
                );
              } else {
                return MessageBubble.first(
                  userImage: chatmessage['userImage'],
                  username: chatmessage['username'],
                  message: chatmessage['text'],
                  isMe: authenticatedUser.uid == chatmessage['userId'],
                );
              }
            });
      },
    );
  }
}
