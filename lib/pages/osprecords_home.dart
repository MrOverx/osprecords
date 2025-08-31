import 'package:flutter/material.dart';
// import 'package:osprecords/models/user.dart';
import 'package:osprecords/pages/album_details_form.dart';
import 'package:osprecords/services/auth_services.dart';
import 'package:osprecords/pages/login_dialog.dart';
import 'package:osprecords/pages/signup_dialog.dart';
import 'package:osprecords/providers/user_provider.dart';
import 'package:provider/provider.dart';
// import 'package:osprecords/models/album_model.dart';
import 'package:osprecords/services/release_service.dart';
import 'package:osprecords/services/music_research_service.dart';
import 'dart:convert'; // Added for base64Decode
import 'dart:typed_data'; // Added for Uint8List
import 'package:osprecords/pages/status_tracker_page.dart'; // Add this import at the top
import 'package:osprecords/pages/dashboard.dart';

PreferredSizeWidget _buildAppBar(
  BuildContext context, {
  VoidCallback? onFeaturesTap,
}) {
  final user = Provider.of<UserProvider>(context).user;
  final bool isLoggedIn = user.token.isNotEmpty;
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth <= 700;

  void openDrawer() {
    ScaffoldMessenger.of(context).clearSnackBars();
    Scaffold.of(context).openDrawer();
  }

  // Helper for user avatar (with initial)
  Widget userAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.red[700],
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  return AppBar(
    backgroundColor: Colors.black,
    elevation: 0,
    automaticallyImplyLeading: false,
    title: Row(
      children: [
        if (isMobile)
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            ),
          ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.blue, Colors.black]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'osprecords.com',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        Spacer(),
        if (!isMobile)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DashboardPage(),
                    ),
                  );
                },
                child: Text('Dashboard', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: onFeaturesTap,
                child: Text('Features', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AlbumDetailsForm()),
                  );
                },
                child: Text(
                  'Distribution',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              // Add status symbol to navbar
              SizedBox(width: 8),
              if (isLoggedIn)
                Builder(
                  builder: (context) => IconButton(
                    icon: userAvatar(),
                    tooltip: user.name,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                )
              else ...[
                TextButton(
                  onPressed: () {
                    print('Log In button pressed');
                    showDialog(
                      context: context,
                      builder: (_) => const LoginDialog(),
                    );
                  },
                  child: Text('Log In', style: TextStyle(color: Colors.white)),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SignUpDialog(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    ),
  );
}

Widget _buildDrawer(BuildContext context, {VoidCallback? onFeaturesTap}) {
  final user = Provider.of<UserProvider>(context).user;

  void signOutUser() {
    AuthService().signOut(context);
  }

  final bool isLoggedIn = user.token.isNotEmpty;
  return Drawer(
    backgroundColor: Colors.grey[900],
    child: Column(
      children: [
        // Custom Profile Header
        Container(
          width: double.infinity,
          color: Colors.grey[900],
          padding: const EdgeInsets.only(top: 40, bottom: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar with initial
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.red[700],
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                user.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 4),
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.blue[200],
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'User ID: ${user.id}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
        // Menu Items
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(Icons.dashboard, color: Colors.teal),
                  title: Text(
                    'Dashboard',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DashboardPage(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.star, color: Colors.orange),
                  title: Text(
                    'Features',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (onFeaturesTap != null) onFeaturesTap();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.library_music, color: Colors.blue),
                  title: Text(
                    'Distribution',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AlbumDetailsForm(),
                      ),
                    );
                  },
                ),
                if (!isLoggedIn) ...[
                  ListTile(
                    leading: Icon(Icons.person_add, color: Colors.purple),
                    title: Text(
                      'Sign Up',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const SignUpDialog(),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.login, color: Colors.purple),
                    title: Text(
                      'Log In',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => const LoginDialog(),
                      );
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(
                      'Sign Out',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    onTap: signOutUser,
                  ),
                ],
                Divider(color: Colors.grey[300]),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.grey[600]),
                  title: Text(
                    'About',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // Add about functionality if needed
                  },
                ),
              ],
            ),
          ),
        ),
        // Footer
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border(top: BorderSide(color: Colors.grey[800]!)),
          ),
          child: Row(
            children: [
              Icon(Icons.phone, size: 16, color: Colors.grey[400]),
              SizedBox(width: 8),
              Text(
                'Support: support@osprecords.com',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class OSPHomePage extends StatefulWidget {
  const OSPHomePage({super.key});

  @override
  State<OSPHomePage> createState() => _OSPHomePageState();
}

class _OSPHomePageState extends State<OSPHomePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featureSectionKey = GlobalKey();
  int currentStep = 3; // Set to 3 to always show the button for testing

  void _scrollToFeatureSection() {
    // Wait for the next frame to ensure context is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _featureSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth <= 700;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(context, onFeaturesTap: _scrollToFeatureSection),
      drawer: _buildDrawer(context, onFeaturesTap: _scrollToFeatureSection),
      // No endDrawer, always use the same drawer for both hamburger and profile icon
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildPlatformsSection(),
            _buildFeatureCards(key: _featureSectionKey),
            _buildToolsSection(),
            _buildArtistSection(),
            // --- Add plans section here ---
            _buildPlansSection(),
            // --- Footer remains last ---
            _buildFooter(),
          ],
        ),
      ),
    );
  }
}

Widget _buildHeroSection() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth <= 700;
      return Container(
        padding: EdgeInsets.all(60),
        child: Column(
          children: [
            Text(
              'Release Your Music with OSP Records',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Upload to all platforms and access our industry tools. Free for 30 days.',
              style: TextStyle(fontSize: 18, color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            if (isMobile)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Start Free Trial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Learn More',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Start Free Trial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Learn More',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}

Widget _buildFeatureCards({Key? key}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth <= 700;

      return Container(
        key: key,
        padding: EdgeInsets.all(isMobile ? 20 : 40),
        child: Column(
          children: [
            Text(
              'Everything you need to succeed',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : 40),
            if (isMobile)
              // Vertical layout for mobile
              Column(
                children: [
                  _buildFeatureCard(
                    Icons.cloud_upload,
                    'Unlimited Uploads',
                    'Drop unlimited singles, EPs and albums on more global music stores than anywhere else.',
                    Colors.purple,
                  ),
                  SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.monetization_on,
                    '100% Royalties',
                    'All the royalties you earn go straight into your pocket. Keep complete control of your career.',
                    Colors.pink,
                  ),
                  SizedBox(height: 16),
                  _buildFeatureCard(
                    Icons.analytics,
                    'Industry Tools',
                    'Access industry-leading tools designed to raise your profile and turn your music into more money.',
                    Colors.indigo,
                  ),
                ],
              )
            else
              // Horizontal layout for desktop
              Row(
                children: [
                  Expanded(
                    child: _buildFeatureCard(
                      Icons.cloud_upload,
                      'Unlimited Uploads',
                      'Drop unlimited singles, EPs and albums on more global music stores than anywhere else.',
                      Colors.purple,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: _buildFeatureCard(
                      Icons.monetization_on,
                      '100% Royalties',
                      'All the royalties you earn go straight into your pocket. Keep complete control of your career.',
                      Colors.pink,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: _buildFeatureCard(
                      Icons.analytics,
                      'Industry Tools',
                      'Access industry-leading tools designed to raise your profile and turn your music into more money.',
                      Colors.indigo,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}

Widget _buildFeatureCard(
  IconData icon,
  String title,
  String description,
  Color color,
) {
  return Container(
    padding: EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: Colors.grey[800]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          description,
          style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.5),
        ),
      ],
    ),
  );
}

Widget _buildPlatformsSection() {
  return Container(
    padding: EdgeInsets.all(40),
    color: Colors.grey[900],
    child: Column(
      children: [
        Text(
          'Release to All Major Platforms',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
        Text(
          'Release to the biggest music streaming, download and social platforms',
          style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            _buildPlatformChip('Spotify'),
            _buildPlatformChip('Apple Music'),
            _buildPlatformChip('TikTok'),
            _buildPlatformChip('Amazon Music'),
            _buildPlatformChip('Deezer'),
            _buildPlatformChip('Instagram'),
            _buildPlatformChip('Tidal'),
            _buildPlatformChip('YouTube Music'),
            _buildPlatformChip('Facebook'),
            // _buildPlatformChip('iHeartRadio'),
            _buildPlatformChip('Pandora'),
            _buildPlatformChip('SoundCloud'),
            _buildPlatformChip('Napster'),
            _buildPlatformChip('Shazam'),
            // _buildPlatformChip('Tencent'),
            // _buildPlatformChip('Anghami'),
            _buildPlatformChip('Boomplay'),
            _buildPlatformChip('Audiomack'),
            // _buildPlatformChip('Yandex Music'),
            // _buildPlatformChip('VK Music'),
            _buildPlatformChip('Saavn'),
            _buildPlatformChip('JioSaavn'),
            // _buildPlatformChip('Claro Música'),
            // _buildPlatformChip('Anghami'),

            // _buildPlatformChip('Zvooq'),
            _buildPlatformChip('more...'),
          ],
        ),
      ],
    ),
  );
}

Widget _buildPlatformChip(String platform) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Colors.grey[700]!),
    ),
    child: Text(
      platform,
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    ),
  );
}

Widget _buildToolsSection() {
  return Container(
    padding: EdgeInsets.all(40),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Track Your Success',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Track your music\'s performance across major platforms and learn where in the world your fans are listening.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  height: 1.6,
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text('View Analytics'),
              ),
            ],
          ),
        ),
        SizedBox(width: 40),
        Expanded(
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Icon(Icons.bar_chart, size: 80, color: Colors.purple),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildArtistSection() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth <= 700;

      return Container(
        padding: EdgeInsets.all(isMobile ? 32 : 50),
        margin: EdgeInsets.all(isMobile ? 16 : 24),
        color: Colors.grey[900],
        child: Column(
          children: [
            Text(
              'Join Thousands of Independent Artists',
              style: TextStyle(
                fontSize: isMobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 16 : 20),
            Text(
              'Some of the biggest artists in the game started their careers at OSP Records.',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 32 : 40),
            if (isMobile)
              // Vertical layout for mobile
              Column(
                children: [
                  _buildArtistCard('Rising Star', 'Over 1M streams'),
                  SizedBox(height: 20),
                  _buildArtistCard('Chart Topper', 'Billboard #1 Hit'),
                  SizedBox(height: 20),
                  _buildArtistCard('Global Reach', '50+ Countries'),
                ],
              )
            else
              // Horizontal layout for desktop
              Row(
                children: [
                  Expanded(
                    child: _buildArtistCard('Rising Star', 'Over 1M streams'),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: _buildArtistCard('Chart Topper', 'Billboard #1 Hit'),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: _buildArtistCard('Global Reach', '50+ Countries'),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}

Widget _buildArtistCard(String title, String subtitle) {
  return Container(
    padding: EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.purple,
          child: Icon(Icons.person, size: 40, color: Colors.white),
        ),
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
      ],
    ),
  );
}

// Finished Metadata section removed as requested.

Widget _buildTrackStatusSection(BuildContext context) {
  final user = Provider.of<UserProvider>(context).user;
  final bool isLoggedIn = user.token.isNotEmpty;

  return Container(
    padding: EdgeInsets.all(24),
    margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[800]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Track Status',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox.shrink(),
          ],
        ),
        SizedBox(height: 12),
        if (!isLoggedIn)
          Text(
            'Log in to view your releases.',
            style: TextStyle(color: Colors.grey[400]),
          )
        else
          _TrackStatusList(),
      ],
    ),
  );
}

class _TrackStatusList extends StatefulWidget {
  @override
  State<_TrackStatusList> createState() => _TrackStatusListState();
}

class _TrackStatusListState extends State<_TrackStatusList> {
  bool _loading = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final data = await ReleaseService().fetchReleases(context: context);
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _refresh,
              icon: Icon(Icons.refresh),
              label: Text('Refresh Releases'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            if (_loading) ...[
              SizedBox(width: 12),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        SizedBox(height: 12),
        if (_items.isEmpty && !_loading)
          Text('No releases found.', style: TextStyle(color: Colors.grey[400]))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, __) => Divider(color: Colors.grey[800]),
            itemBuilder: (context, index) {
              final item = _items[index];
              final String title = (item['releaseTitle'] ?? 'Untitled')
                  .toString();
              final bool released = (item['releasedPass'] ?? false) == true;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  released
                      ? 'Track is uploaded to metadata'
                      : 'Track not uploaded to metadata',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: released
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
                      color: released ? Colors.greenAccent : Colors.grey[300],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/*
Widget _buildMusicResearchSection() {
  return _MusicResearchPanel();
}

class _MusicResearchPanel extends StatefulWidget {
  @override
  State<_MusicResearchPanel> createState() => _MusicResearchPanelState();
}

class _MusicResearchPanelState extends State<_MusicResearchPanel> {
  final TextEditingController _urlController = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });
    try {
      final data = await MusicResearchService().fetchMetadataByUrl(
        _urlController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _result = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Music Research (Metadata)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'Enter audio file URL (mp3/m4a/etc)',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.black,
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _fetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Fetch'),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_error != null)
            Text(_error!, style: TextStyle(color: Colors.redAccent))
          else if (_result != null)
            _MetadataView(data: _result!)
          else
            Text(
              'Enter a URL to fetch metadata.',
              style: TextStyle(color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }
}
*/
class _MetadataView extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MetadataView({required this.data});

  Widget _kv(String k, String? v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(k, style: TextStyle(color: Colors.grey[400])),
        ),
        Expanded(
          child: Text(v ?? '', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Widget? _coverArt(dynamic picture) {
    if (picture is List && picture.isNotEmpty && picture[0]['data'] != null) {
      final bytes = picture[0]['data'];
      // If backend sends base64 string, decode it
      if (bytes is String) {
        try {
          return Image.memory(base64Decode(bytes), height: 100);
        } catch (_) {
          return null;
        }
      }
      // If backend sends bytes directly
      if (bytes is List<int>) {
        return Image.memory(Uint8List.fromList(bytes), height: 100);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final format = Map<String, dynamic>.from(data['format'] ?? {});
    final trackInfo = Map<String, dynamic>.from(data['trackInfo'] ?? {});

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Format',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _kv('Container', format['container']?.toString()),
            _kv('Codec', format['codec']?.toString()),
            _kv('Bitrate', format['bitrate']?.toString()),
            _kv('Sample Rate', format['sampleRate']?.toString()),
            _kv('Channels', format['numberOfChannels']?.toString()),
            _kv('Lossless', format['lossless']?.toString()),
            _kv(
              'Tag Types',
              (format['tagTypes'] is List)
                  ? (format['tagTypes'] as List).join(', ')
                  : format['tagTypes']?.toString(),
            ),
            _kv('Tool', format['tool']?.toString()),
            _kv('Duration (s)', format['duration']?.toString()),

            SizedBox(height: 12),
            Text(
              'Track Info',
              style: TextStyle(
                color: Colors.purple,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _kv('Title', trackInfo['title']?.toString()),
            _kv('Artist', trackInfo['artist']?.toString()),
            _kv('Album', trackInfo['album']?.toString()),
            _kv('Album Artist', trackInfo['albumartist']?.toString()),
            _kv('Year', trackInfo['year']?.toString()),
            _kv(
              'Genre',
              (trackInfo['genre'] is List)
                  ? (trackInfo['genre'] as List).join(', ')
                  : trackInfo['genre']?.toString(),
            ),
            _kv(
              'Track No.',
              (trackInfo['track'] is Map)
                  ? trackInfo['track']['no']?.toString()
                  : trackInfo['track']?.toString(),
            ),
            _kv(
              'Disk No.',
              (trackInfo['disk'] is Map)
                  ? trackInfo['disk']['no']?.toString()
                  : trackInfo['disk']?.toString(),
            ),

            _kv('Lyrics', trackInfo['lyrics']?.toString()),
            _kv('ISRC', trackInfo['isrc']?.toString()),
            _kv('Copyright', trackInfo['copyright']?.toString()),
            _kv('Publisher', trackInfo['publisher']?.toString()),
            _kv('BPM', trackInfo['bpm']?.toString()),
            _kv('Duration (s)', trackInfo['duration']?.toString()),

            if (trackInfo['picture'] != null &&
                trackInfo['picture'] is List &&
                (trackInfo['picture'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Cover Art:',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            if (trackInfo['picture'] != null &&
                trackInfo['picture'] is List &&
                (trackInfo['picture'] as List).isNotEmpty)
              _coverArt(trackInfo['picture']) ?? SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

Widget _buildFooter() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth <= 700;

      return Container(
        padding: EdgeInsets.all(isMobile ? 24 : 40),
        margin: EdgeInsets.only(
          bottom: isMobile ? 20 : 0,
        ), // Extra bottom margin for mobile
        color: Colors.black,
        child: Column(
          children: [
            if (isMobile)
              // Vertical layout for mobile
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, Colors.blue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#OSPRecords',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Independent music distribution and artist services.',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Product',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Distribution',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text('Analytics', style: TextStyle(color: Colors.grey[400])),
                  Text(
                    'Label Services',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Support',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Help Center',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text('Contact Us', style: TextStyle(color: Colors.grey[400])),
                  Text('Community', style: TextStyle(color: Colors.grey[400])),
                ],
              )
            else
              // Horizontal layout for desktop
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black, Colors.blue],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#OSPRecords',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Independent music distribution and artist services.',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Distribution',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          'Analytics',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          'Label Services',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Support',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Help Center',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          'Contact Us',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Text(
                          'Community',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            SizedBox(height: isMobile ? 32 : 40),
            Divider(color: Colors.grey[800]),
            SizedBox(height: isMobile ? 16 : 20),
            // Protected bottom row with copyright and terms
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '© 2025 OSP Records Music. All rights reserved.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Privacy Policy',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      SizedBox(width: 20),
                      Text(
                        'Terms of Service',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2025 OSP Records Music. All rights reserved.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      Text(
                        'Privacy Policy',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(width: 20),
                      Text(
                        'Terms of Service',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            // Extra bottom padding to ensure footer is not cut off
            SizedBox(height: isMobile ? 16 : 24),
          ],
        ),
      );
    },
  );
}

class _Plan {
  final String title;
  final String price;
  final String per;
  final Color color;
  final List<String> features;
  final bool highlight;

  _Plan({
    required this.title,
    required this.price,
    required this.per,
    required this.color,
    required this.features,
    this.highlight = false,
  });
}

Widget _buildPlansSection() {
  final plans = [
    _Plan(
      title: "OSP Social",
      price: "Free",
      per: "/Per Song",
      color: Colors.grey[850]!,
      features: [
        "Distribute to Facebook, Instagram, Triller, TikTok, Snapchat & YouTube Platforms",
        "Free ISRC & UPC",
        "Earn 80% royalty from your music",
        "Content will be live within 48-72 hours",
        "Your song will be live for lifetime (no renewal required)",
        "Royalty Dashboard",
        "Unlimited Artist Profile",
      ],
    ),
    _Plan(
      title: "OSP Pro",
      price: "₹349",
      per: "/Per Song",
      color: Colors.grey[900]!,
      features: [
        "Distribute to Indian, International, YouTube & Lyrics platforms only",
        "Free ISRC & UPC",
        "Keep 90% streaming and 85% YouTube royalties",
        "Content will be live within 48-72 hours",
        "Your song will be live for lifetime (no renewal required)",
        "Royalty Dashboard",
        "Unlimited Artist Profile",
      ],
    ),
    _Plan(
      title: "OSP CRBT+",
      price: "₹499",
      per: "/Per Song",
      color: Colors.blue[800]!,
      features: [
        "Distribute to Indian, International, YouTube & Lyrics platforms only",
        "Caller Tune on Jio, Airtel, Vi & BSNL",
        "Custom C-Line & P-Line",
        "Free ISRC & UPC",
        "Keep 90% streaming and 85% YouTube royalties",
        "Content will be live within 24-48 hours",
        "Your song will be live for lifetime (no renewal required)",
        "Editorial Playlist Support",
        "Royalty Dashboard",
        "Unlimited Artist Profile",
      ],
      highlight: true,
    ),
  ];

  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = constraints.maxWidth;
      final isMobile = screenWidth < 900;

      return Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 32 : 48,
          horizontal: isMobile ? 8 : 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Plans We Offer",
              style: TextStyle(
                fontSize: isMobile ? 28 : 38,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              "At OSP Records, we provide simple and flexible music distribution plans for artists at any stage. With our service, you maintain 100% ownership of your music and earn up to 90% of all royalties. Our plans include an easy-to-use dashboard, lifetime support, and scheduled releases to suit your needs.",
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: isMobile ? 13 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "We help you monetize your music across platforms like YouTube, Facebook, Instagram, Snapchat, and more. Your tracks will be available on popular streaming services, including Spotify, Apple Music, Gaana, JioSaavn, and many others.",
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: isMobile ? 12 : 15,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Text(
              "Smart, curated plans for every release",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: isMobile ? 17 : 22,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 18 : 32),
            isMobile
                ? Column(
                    children: plans
                        .map(
                          (plan) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: _PlanCard(plan: plan, isMobile: true),
                          ),
                        )
                        .toList(),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: plans
                        .map(
                          (plan) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: _PlanCard(plan: plan, isMobile: false),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      );
    },
  );
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final bool isMobile;
  const _PlanCard({required this.plan, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: plan.highlight ? Colors.blue[800] : plan.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: plan.highlight ? Colors.blueAccent : Colors.grey[800]!,
          width: plan.highlight ? 2.5 : 1,
        ),
        boxShadow: plan.highlight
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.18),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ]
            : [],
      ),
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 24 : 32,
        horizontal: isMobile ? 18 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.title,
            style: TextStyle(
              color: plan.highlight ? Colors.white : Colors.blue[100],
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 18 : 22,
            ),
          ),
          SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plan.price,
                style: TextStyle(
                  color: plan.highlight ? Colors.white : Colors.blue[100],
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 28 : 34,
                ),
              ),
              SizedBox(width: 6),
              Text(
                plan.per,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: isMobile ? 13 : 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...plan.features.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check,
                    color: plan.highlight ? Colors.white : Colors.purple,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 12.5 : 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // You can handle plan selection here
                showDialog(
                  context: context,
                  builder: (_) => const SignUpDialog(),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: plan.highlight ? Colors.white : Colors.purple,
                foregroundColor: plan.highlight
                    ? Colors.blue[800]
                    : Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                textStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
              child: Text(plan.highlight ? "Get CRBT+" : "Upload Now"),
            ),
          ),
        ],
      ),
    );
  }
}
