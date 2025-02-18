import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_2/components/chat_bubble.dart';
import 'package:flutter_application_2/components/my_textfield.dart';
import 'package:flutter_application_2/services/auth/auth_service.dart';
import 'package:flutter_application_2/services/chat/chat_service.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;
  ChatPage({super.key, required this.receiverEmail, required this.receiverID});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  FocusNode myFocusNode = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    myFocusNode.addListener((){
      if(myFocusNode.hasFocus){
        Future.delayed(const Duration(milliseconds: 500), () => scrollDown());
      }

    });

    Future.delayed(
      const Duration(milliseconds: 500),
      () => scrollDown(),
    );
  }
  @override
  void dispose() {
    myFocusNode.dispose();
    _messageController.dispose();
    super.dispose();
  }

  final ScrollController _scrollController = ScrollController();
  void scrollDown(){
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent, 
      duration: const Duration(seconds: 1), 
      curve: Curves.fastOutSlowIn
    );
  }

  void sendMessage() async{
    if(_messageController.text.isNotEmpty){
      await _chatService.sendMessage(widget.receiverID, message: _messageController.text);
      _messageController.clear();
    }
    scrollDown();
  }
  Future<void> _pickMedia(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Pick Image'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  File mediaFile = File(pickedFile.path);
                  await _chatService.sendMediaMessage(widget.receiverID, mediaFile, 'image');
                  scrollDown();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Pick Video'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
                if (pickedFile != null) {
                  File mediaFile = File(pickedFile.path);
                  await _chatService.sendMediaMessage(widget.receiverID, mediaFile, 'video');
                  scrollDown();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.receiverEmail),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList()
          ),
          _buildUserInput(),

        ],
      ),
    );
  }

  Widget _buildMessageList(){
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, senderID), 
      builder: (context, snapshot) {
        if(snapshot.hasError){
          return const Text('Error');
        }
        if(snapshot.connectionState == ConnectionState.waiting){
          return const Text("Loading");
        }

        return ListView(
          controller: _scrollController,
          children: snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      }
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc){
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentuser = data['senderID'] == _authService.getCurrentUser()!.uid;

    var alignment = isCurrentuser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: isCurrentuser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data["message"],
            isCurrentuser: isCurrentuser,
            messageId: doc.id,
            userId: data['senderID'],
            mediaURL: data['mediaURL'], // Pass media URL
            mediaType: data['mediaType'],
          )
        ],
      ),
    );
  }

  Widget _buildUserInput(){
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () => _pickMedia(context), // Pick media when clicked
          ),
          Expanded(
            child: MyTextField(
              hintText: "Type a message", 
              obscureText: false, 
              controller: _messageController,
              focusNode: myFocusNode
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
              shape: BoxShape.circle
            ),
            margin: const EdgeInsets.only(right: 25),
            child: IconButton(
              onPressed: sendMessage, 
              icon: Icon(Icons.arrow_upward)
            )
          )
        ],
      ),
    );
  }
}