import 'package:flutter/material.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration
    final leaderboard = List.generate(
      20,
      (index) => {
        'rank': index + 1,
        'nom': 'Agriculteur ${index + 1}',
        'points': 10000 - (index * 500),
        'niveau': 10 - (index ~/ 3),
        'badges': 5 - (index ~/ 5),
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
        backgroundColor: Colors.amber.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Top 3 podium
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.amber.shade700, Colors.amber.shade50],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPodiumCard(leaderboard[1], 2, 100),
                _buildPodiumCard(leaderboard[0], 1, 120),
                _buildPodiumCard(leaderboard[2], 3, 80),
              ],
            ),
          ),

          // Rest of leaderboard
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leaderboard.length - 3,
              itemBuilder: (context, index) {
                final entry = leaderboard[index + 3];
                return _buildLeaderboardTile(entry);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> entry, int rank, double height) {
    Color medalColor;
    if (rank == 1) {
      medalColor = Colors.amber;
    } else if (rank == 2) medalColor = Colors.grey.shade400;
    else medalColor = Colors.brown.shade300;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: medalColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              rank == 1 ? Icons.emoji_events : Icons.emoji_events_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: medalColor.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: medalColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry['nom'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry['points']} pts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: medalColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(Map<String, dynamic> entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          child: Text(
            '${entry['rank']}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          entry['nom'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.stars, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text('Niveau ${entry['niveau']}'),
            const SizedBox(width: 16),
            const Icon(Icons.emoji_events, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text('${entry['badges']} badges'),
          ],
        ),
        trailing: Text(
          '${entry['points']} pts',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
