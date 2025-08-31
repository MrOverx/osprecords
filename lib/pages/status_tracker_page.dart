import 'package:flutter/material.dart';
import 'package:osprecords/services/release_service.dart';
import 'package:provider/provider.dart';
import 'package:osprecords/providers/user_provider.dart';
// Add audio player package
import 'package:audioplayers/audioplayers.dart';
// Use Constants.uri for API base URL
import 'package:osprecords/utils/constants.dart';

class StatusTrackerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status Tracker'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Container(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(maxWidth: 700),
          padding: EdgeInsets.all(24),
          child: _StatusReleaseCards(),
        ),
      ),
    );
  }
}

class _StatusReleaseCards extends StatefulWidget {
  @override
  State<_StatusReleaseCards> createState() => _StatusReleaseCardsState();
}

class _StatusReleaseCardsState extends State<_StatusReleaseCards> {
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final data = await ReleaseService().fetchReleases(context: context);
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  Future<void> _playAudio(String audioPath, int index) async {
    // If already playing, stop first
    if (_playingIndex == index) {
      await _audioPlayer.stop();
      setState(() {
        _playingIndex = null;
      });
      return;
    }
    setState(() {
      _playingIndex = index;
    });

    // Fix: Replace spaces with %20 in the filename portion only
    String url = audioPath.startsWith('http')
        ? audioPath.replaceAll(' ', '%20')
        : ('${Constants.uri}/' + audioPath.replaceAll('\\', '/')).replaceAll(
            ' ',
            '%20',
          );

    print('Trying to play audio: $url');

    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      setState(() {
        _playingIndex = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio playback failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final bool isLoggedIn = user.token.isNotEmpty;

    if (!isLoggedIn) {
      return Center(
        child: Text(
          'Log in to view your releases.',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No releases found.',
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    // Use Constants.uri for API base URL
    final String apiBaseUrl = '${Constants.uri}/';

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = _items[index];
          final String releaseTitle = (item['releaseTitle'] ?? 'Untitled')
              .toString();
          final String songTitle = (item['songTitle'] ?? '').toString();
          final String labelName = (item['recordLabel'] ?? '').toString();
          final bool released = (item['releasedPass'] ?? false) == true;
          final String? coverImagePath =
              item['coverImageFullPath'] ?? item['coverImagePath'];
          final String? audioFilePath =
              item['audioFileFullPath'] ?? item['audioFilePath'];
          final String? releasedDate = item['releasedDate'];
          String artistName = '';
          if (item['artists'] is List && (item['artists'] as List).isNotEmpty) {
            final artists = item['artists'] as List;
            artistName = artists
                .map((a) => a['name'] ?? '')
                .where((n) => n != null && n.toString().isNotEmpty)
                .join(', ');
          }

          // Build image URL using the new GET endpoint
          String buildImageUrl(String? path) {
            if (path == null || path.isEmpty) return '';
            // Example path: uploads/<userId>/<releaseId>/<filename>
            final segments = path.split('/');
            if (segments.length >= 4 && segments[0] == 'uploads') {
              final userId = segments[1];
              final releaseId = segments[2];
              final filename = segments.sublist(3).join('/');
              return '${Constants.uri}/api/uploads/cover/$userId/$releaseId/$filename';
            }
            // fallback to previous logic
            if (path.startsWith('http')) return path;
            return '${Constants.uri}/static/$path';
          }

          // Build audio URL using the new GET endpoint
          String buildAudioUrl(String? path) {
            if (path == null || path.isEmpty) return '';
            final segments = path.split('/');
            if (segments.length >= 4 && segments[0] == 'uploads') {
              final userId = segments[1];
              final releaseId = segments[2];
              final filename = segments.sublist(3).join('/');
              return '${Constants.uri}/api/uploads/audio/$userId/$releaseId/$filename';
            }
            if (path.startsWith('http')) return path;
            return '${Constants.uri}/static/$path';
          }

          final String imageUrl = buildImageUrl(coverImagePath);
          print('Image URL: $imageUrl'); // Debug print
          final String audioUrl = buildAudioUrl(audioFilePath);

          return Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: released ? Colors.green : Colors.grey[800]!,
                width: 2,
              ),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image preview (from API server)
                      if (imageUrl.isNotEmpty)
                        Container(
                          width: 64,
                          height: 64,
                          margin: EdgeInsets.only(right: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.black,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey[800],
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.white54,
                                    ),
                                  ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 64,
                          height: 64,
                          margin: EdgeInsets.only(right: 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[800],
                          ),
                          child: Icon(Icons.music_note, color: Colors.white54),
                        ),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              releaseTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (songTitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Song: $songTitle',
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ),
                            if (artistName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Artist: $artistName',
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ),
                            if (labelName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Label: $labelName',
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ),
                            if (releasedDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  'Released: ${releasedDate.toString().split('T').first}',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ),
                            SizedBox(height: 8),
                            Text(
                              released
                                  ? 'Track is uploaded to metadata'
                                  : 'Track not uploaded to metadata',
                              style: TextStyle(
                                color: released
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        margin: EdgeInsets.only(left: 8, top: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: released
                              // ignore: deprecated_member_use
                              ? Colors.green.withOpacity(0.15)
                              : Colors.grey[800],
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: released ? Colors.green : Colors.grey[700]!,
                          ),
                        ),
                        child: Text(
                          released ? 'Released' : 'Not Released',
                          style: TextStyle(
                            color: released
                                ? Colors.greenAccent
                                : Colors.grey[300],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Audio play button (from API server)
                  if (audioUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _playAudio(audioUrl, index),
                            icon: Icon(
                              _playingIndex == index
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            label: Text(
                              _playingIndex == index ? 'Pause' : 'Play',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            audioFilePath != null
                                ? audioFilePath.split('/').last
                                : '',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
