import 'package:flutter/material.dart';

void main() {
  runApp(const BuildHireApp());
}

/// Root App
class BuildHireApp extends StatelessWidget {
  const BuildHireApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFFFF7A00); // construction orange
    const Color dark = Color(0xFF1E2A38); // steel navy

    return MaterialApp(
      title: 'BuildHire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F5F7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: dark,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: dark,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  int _navIndex = 0;

  static const Color primary = Color(0xFFFF7A00);
  static const Color dark = Color(0xFF1E2A38);

  final List<_Trade> _trades = const [
    _Trade('Electrician', Icons.electrical_services),
    _Trade('Plumber', Icons.plumbing),
    _Trade('Mason', Icons.foundation),
    _Trade('Carpenter', Icons.carpenter),
    _Trade('Welder', Icons.local_fire_department),
    _Trade('Crane Op.', Icons.precision_manufacturing),
    _Trade('Painter', Icons.format_paint),
    _Trade('Laborer', Icons.engineering),
  ];

  final List<_JobPosting> _jobs = const [
    _JobPosting(
      title: 'Site Electrician',
      company: 'Vertex Builders',
      location: 'Bathinda, PB',
      pay: '₹850/day',
      tags: ['Full-time', 'Urgent', 'On-site'],
      posted: '2h ago',
    ),
    _JobPosting(
      title: 'Steel Fixer / Rebar Mason',
      company: 'Skyline Infra',
      location: 'Chandigarh',
      pay: '₹900/day',
      tags: ['Contract', 'Housing'],
      posted: '5h ago',
    ),
    _JobPosting(
      title: 'Heavy Equipment Operator',
      company: 'GroundWorks Co.',
      location: 'Ludhiana',
      pay: '₹1,200/day',
      tags: ['Full-time', 'Experienced'],
      posted: '1d ago',
    ),
    _JobPosting(
      title: 'Plumbing Foreman',
      company: 'AquaTech Contractors',
      location: 'Patiala',
      pay: '₹1,100/day',
      tags: ['Supervisor', 'Long-term'],
      posted: '1d ago',
    ),
    _JobPosting(
      title: 'General Site Laborer',
      company: 'Metro Build Group',
      location: 'Bathinda, PB',
      pay: '₹650/day',
      tags: ['Daily wage', 'Immediate joining'],
      posted: '3d ago',
    ),
  ];

  @override
  void dispose() {
    _roleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: const [
            Icon(Icons.foundation, color: primary),
            SizedBox(width: 8),
            Text(
              'BuildHire',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.apartment, color: Colors.white70, size: 18),
            label: const Text(
              'For Employers',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHero(context),
            _buildTradesRow(),
            _buildStatsBar(),
            _buildJobsHeader(),
            ..._jobs.map((j) => _JobCard(job: j)),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () {},
        icon: const Icon(Icons.badge_outlined),
        label: const Text('Post a Job'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Jobs'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Workers'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: const BoxDecoration(
        color: dark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find skilled workers.\nFind your next site job.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Thousands of construction jobs near you, updated daily.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _roleController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: primary),
                    border: InputBorder.none,
                    hintText: 'Trade, role, or keyword',
                  ),
                ),
                const Divider(height: 1),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    icon: Icon(Icons.location_on_outlined, color: primary),
                    border: InputBorder.none,
                    hintText: 'City or site location',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Search Jobs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradesRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Trade',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _trades.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = _trades[i];
                return Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t.icon, color: primary, size: 26),
                      const SizedBox(height: 6),
                      Text(
                        t.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: dark),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          stat('12,400+', 'Open Jobs'),
          stat('3,800+', 'Hiring Sites'),
          stat('64,000+', 'Registered Workers'),
        ],
      ),
    );
  }

  Widget _buildJobsHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Latest Job Postings',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            'See all',
            style: TextStyle(color: primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Trade {
  final String name;
  final IconData icon;
  const _Trade(this.name, this.icon);
}

class _JobPosting {
  final String title;
  final String company;
  final String location;
  final String pay;
  final List<String> tags;
  final String posted;

  const _JobPosting({
    required this.title,
    required this.company,
    required this.location,
    required this.pay,
    required this.tags,
    required this.posted,
  });
}

class _JobCard extends StatelessWidget {
  final _JobPosting job;
  const _JobCard({required this.job});

  static const Color primary = Color(0xFFFF7A00);
  static const Color dark = Color(0xFF1E2A38);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: dark.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.business, color: dark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      job.company,
                      style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Text(
                job.posted,
                style: const TextStyle(color: Colors.black38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 15, color: Colors.black45),
              const SizedBox(width: 4),
              Text(job.location, style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
              const SizedBox(width: 14),
              const Icon(Icons.payments_outlined, size: 15, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                job.pay,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: dark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: job.tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(fontSize: 10.5, color: primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}