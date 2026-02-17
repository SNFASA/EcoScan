import 'package:flutter/material.dart';

class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Top Eco Heroes"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView.separated(
          itemCount: 10,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final isMe = index == 4; // Mocking current user at rank 5
            return _scoreRow(index + 1, isMe);
          },
        ),
      ),
    );
  }

  Widget _scoreRow(int rank, bool isMe) {
    final username = isMe ? "Shaamalan (You)" : "EcoUser_${rank + 99}";
    final points = 2000 - ((rank - 1) * 150);

    return Card(
      elevation: isMe ? 4 : 0,
      color: isMe ? Colors.green[50] : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Text(
          "#$rank",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        title: Text(username),
        subtitle: Text("$points Points"),
        trailing: const Icon(Icons.keyboard_arrow_right),
      ),
    );
  }
}
