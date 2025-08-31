import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:osprecords/providers/user_provider.dart';
import 'package:osprecords/services/release_service.dart';
import 'package:osprecords/pages/release_details_page.dart';
import 'package:osprecords/utils/constants.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ReleaseService _releaseService = ReleaseService();
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(true);
  final ValueNotifier<List<Map<String, dynamic>>> _releases =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  String _stageFilter = 'All Stages';
  final List<String> _stages = const ['All Stages', 'Pending', 'Released'];

  // Sidebar/nav state
  String _currentNav = 'Dashboard';
  bool _allSelected = true;

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchController.addListener(() => setState(() {}));
  }

  Future<void> _fetch() async {
    _loading.value = true;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isLoggedIn = userProvider.user.token.isNotEmpty;
    if (!isLoggedIn) {
      // If not logged in, clear releases and stop loading
      _releases.value = [];
      _loading.value = false;
      return;
    }
    final list = await _releaseService.fetchReleases(context: context);
    if (!mounted) return;
    _releases.value = list;
    _loading.value = false;
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final stage = _stageFilter;
    return _releases.value.where((e) {
      final title = (e['releaseTitle'] ?? e['title'] ?? '').toString();
      final songTitle = (e['songTitle'] ?? '').toString();
      final matchesQuery =
          query.isEmpty ||
          title.toLowerCase().contains(query) ||
          songTitle.toLowerCase().contains(query);
      if (!matchesQuery) return false;
      if (stage == 'All Stages') return true;

      // Filter by release status based on releasedPass
      final releasedPass = _parseBool(e['releasedPass']);
      final releaseStatus = releasedPass ? 'Released' : 'Pending';
      return releaseStatus.toLowerCase() == stage.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final isLoggedIn = userProvider.user.token.isNotEmpty;
    if (!isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Please log in to view your dashboard.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Optionally, navigate to login page or pop
                  Navigator.of(context).pop();
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = width >= 1200;
    final bool isTablet = width >= 768;
    final bool isMobile = width < 768;
    final bool isSmallMobile = width < 480;

    return Scaffold(
      // Responsive layout
      drawer: isMobile ? _buildDrawer() : null,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(children: const [Text('osprecords Dashboard')]),
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _fetch,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blueGrey.shade700,
              child: Text(
                userProvider.user.name.isNotEmpty
                    ? userProvider.user.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar - always visible: full on desktop/tablet, mini (icons only) on mobile
          if (!isMobile)
            Container(
              width: isDesktop ? 280 : 240,
              child: _Sidebar(
                currentKey: _currentNav,
                onNavigate: (key) => setState(() => _currentNav = key),
              ),
            )
          else
            // Mini sidebar for mobile (icons only)
            Container(
              width: 56,
              color: const Color(0xFF11161D),
              child: _MiniSidebar(
                currentKey: _currentNav,
                onNavigate: (key) => setState(() => _currentNav = key),
              ),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(
                isSmallMobile
                    ? 8.0
                    : isMobile
                    ? 12.0
                    : 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Release (${_releases.value.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                    ],
                  ),
                  SizedBox(
                    height: isSmallMobile
                        ? 8
                        : isMobile
                        ? 12
                        : 16,
                  ),
                  // Responsive filter row
                  if (!isMobile) ...[
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _allSelected,
                          onSelected: (v) => setState(() => _allSelected = v),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF143C78),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Buy plan'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search),
                              hintText: 'Search releases...',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _stageFilter,
                              items: _stages
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _stageFilter = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Mobile layout - stacked vertically
                    if (!isSmallMobile) ...[
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _allSelected,
                        onSelected: (v) => setState(() => _allSelected = v),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF143C78),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('Buy plan'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _stageFilter,
                              items: _stages
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _stageFilter = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallMobile ? 8 : 12),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: isSmallMobile
                            ? 'Search...'
                            : 'Search releases...',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallMobile ? 8 : 12,
                          vertical: isSmallMobile ? 8 : 12,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(
                    height: isSmallMobile
                        ? 4
                        : isMobile
                        ? 8
                        : 12,
                  ),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _loading,
                      builder: (context, loading, _) {
                        if (loading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final list = _filtered;
                        if (list.isEmpty) {
                          return const Center(
                            child: Text('No releases found.'),
                          );
                        }
                        final crossAxisCount = isDesktop
                            ? 4
                            : isTablet
                            ? 2
                            : 1;
                        return GridView.builder(
                          padding: EdgeInsets.only(
                            top: isSmallMobile
                                ? 2
                                : isMobile
                                ? 4
                                : 8,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: isSmallMobile
                                    ? 8
                                    : isMobile
                                    ? 12
                                    : 16,
                                mainAxisSpacing: isSmallMobile
                                    ? 8
                                    : isMobile
                                    ? 12
                                    : 16,
                                childAspectRatio: isSmallMobile
                                    ? 3 / 4.5
                                    : isMobile
                                    ? 3 / 4.2
                                    : 3 / 3.8,
                              ),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            return _ReleaseCard(
                              data: item,
                              onDelete: () => _confirmDelete(item),
                              onTap: () => _navigateToDetails(item),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: _Sidebar(
        currentKey: _currentNav,
        onNavigate: (key) {
          setState(() => _currentNav = key);
          Navigator.of(context).pop(); // Close drawer on mobile
        },
      ),
    );
  }

  void _onNav(String key) {
    if (key == 'refresh') _fetch();
  }

  // Helper method to safely convert values to boolean
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }

  void _navigateToDetails(Map<String, dynamic> item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReleaseDetailsPage(releaseData: item),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final id = (item['_id'] ?? item['id'] ?? '').toString();
    if (id.isEmpty) return;
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Release'),
            content: Text(
              'Are you sure you want to delete "${item['releaseTitle'] ?? item['title'] ?? 'this release'}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    await _releaseService.deleteRelease(context: context, releaseId: id);
    await _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _loading.dispose();
    _releases.dispose();
    super.dispose();
  }
}

class _ReleaseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _ReleaseCard({required this.data, required this.onDelete, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imagePath = (data['coverImagePath'] ?? data['image'] ?? '')
        .toString();

    // Use direct static path
    String image = imagePath.isNotEmpty
        ? '${Constants.staticUri}/$imagePath'
        : '';
    final title = (data['releaseTitle'] ?? data['title'] ?? 'Untitled')
        .toString();
    final song = (data['songTitle'] ?? '').toString();
    final type = (data['releaseType'] ?? 'album').toString();
    final label = (data['recordLabel'] ?? 'Unknown Label').toString();
    final plan = (data['plan'] ?? 'Paid').toString();
    final releasedPass = _parseBool(data['releasedPass']);
    final createdRaw = (data['createdAt'] ?? data['created'] ?? '').toString();
    DateTime? created;
    try {
      if (createdRaw.isNotEmpty) created = DateTime.parse(createdRaw);
    } catch (_) {}
    final createdStr = created == null
        ? 'Unknown'
        : DateFormat('MMM d, yyyy').format(created!);

    // Determine status based on releasedPass
    final status = releasedPass ? 'Released' : 'Pending';
    final statusColor = releasedPass ? Colors.green : Colors.orange;
    final statusIcon = releasedPass ? Icons.check_circle : Icons.pending;

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  // Show actual image if available, otherwise placeholder
                  image.isNotEmpty
                      ? Image.network(
                          image,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                        ),
                  // Status badge (top-left)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Blue star for paid plan (top-right) with tooltip
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Tooltip(
                      message: 'Paid',
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (song.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        song,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 8),
                  _metaRow(Icons.album, type),
                  _metaRow(Icons.business, label),
                  _metaRow(Icons.event, 'Created: $createdStr'),
                  _metaRow(statusIcon, 'Status: $status'),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // Helper method to safely convert values to boolean
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value != 0;
    return false;
  }
}

class _Sidebar extends StatelessWidget {
  final String currentKey;
  final void Function(String key) onNavigate;

  const _Sidebar({required this.currentKey, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, String key) {
      return ListTile(
        leading: Icon(icon, color: currentKey == key ? Colors.white : null),
        title: Text(
          label,
          style: TextStyle(
            color: currentKey == key ? Colors.white : null,
            fontWeight: currentKey == key ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        tileColor: currentKey == key ? Colors.blueGrey.shade800 : null,
        onTap: () => onNavigate(key),
      );
    }

    return Material(
      color: const Color(0xFF11161D),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            item(Icons.dashboard_outlined, 'Dashboard', 'dashboard'),
            item(Icons.library_music, 'Release', 'release'),
            item(Icons.person_outline, 'Artist', 'artist'),
            item(Icons.monetization_on, 'Revenue', 'revenue'),
            item(Icons.notifications, 'Notification', 'notification'),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh'),
              onTap: () => onNavigate('refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// Mini sidebar for mobile: icons only
class _MiniSidebar extends StatelessWidget {
  final String currentKey;
  final void Function(String key) onNavigate;
  const _MiniSidebar({required this.currentKey, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    Widget iconBtn(IconData icon, String key, {String? tooltip}) {
      return IconButton(
        icon: Icon(
          icon,
          color: currentKey == key ? Colors.white : Colors.grey.shade400,
        ),
        tooltip: tooltip,
        onPressed: () => onNavigate(key),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          iconBtn(Icons.dashboard_outlined, 'dashboard', tooltip: 'Dashboard'),
          iconBtn(Icons.library_music, 'release', tooltip: 'Release'),
          iconBtn(Icons.person_outline, 'artist', tooltip: 'Artist'),
          iconBtn(Icons.monetization_on, 'revenue', tooltip: 'Revenue'),
          iconBtn(Icons.notifications, 'notification', tooltip: 'Notification'),
          const Spacer(),
          iconBtn(Icons.refresh, 'refresh', tooltip: 'Refresh'),
        ],
      ),
    );
  }
}
