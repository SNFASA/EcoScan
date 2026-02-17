import 'package:flutter/material.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Top Eco Heroes")),
      body: ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: 10,
        itemBuilder: (context, index) {
          final isMe = index == 4; // Mocking current user at rank 5
          return Card(
            elevation: isMe ? 4 : 0,
            color: isMe ? Colors.green[50] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              leading: Text("#${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              title: Text(isMe ? "Shaamalan (You)" : "EcoUser_${index + 100}"),
              subtitle: Text("${2000 - (index * 150)} Points"),
              trailing: const Icon(Icons.keyboard_arrow_right),
            ),
          );
        },
      ),
    );
  }
}