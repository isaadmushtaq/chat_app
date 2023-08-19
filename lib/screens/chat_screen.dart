import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

late User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final messageTextController = TextEditingController();

  late String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  //In the updated Firestore API, document has been replaced by docs and data by data().


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                  );
                }
                final messages = snapshot.data?.docs;
                List<MessageBubble> messageBubbles = [];
                for (var message in messages!) {
                  final messageText = message.get('text');
                  final messageSender = message.get('sender');
                  final time = message.get('timestamp');
                  final currentUser = loggedInUser.email;

                  final currentTime = Timestamp.fromMicrosecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);
                  final timeStamps = time == null ? currentTime : time as Timestamp;


                final messageBubble = MessageBubble(
                    sender: messageSender,
                    text: messageText,
                    isMe: currentUser == messageSender,
                    timestamp: timeStamps,
                  );

                  messageBubbles.add(messageBubble);
                }
                return Expanded(
                  child: ListView(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    children: messageBubbles,
                  ),
                );
              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      try {
                        messageTextController.clear();
                        _firestore.collection("messages").add({
                          "sender": loggedInUser.email,
                          "text": messageText,
                          "timestamp": FieldValue.serverTimestamp(),
                        });
                        //addUser();
                      } catch (e) {
                        print(e);
                      }

                    },
                    icon: const Icon(Icons.send),
                    //
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

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {Key? key, required this.sender, required this.text, required this.isMe,required this.timestamp,})
      : super(key: key);

  final String sender;
  final String text;
  final Timestamp timestamp;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Material(
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : const BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            DateFormat('hh:mm').format(timestamp.toDate()), // Display timestamp
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
