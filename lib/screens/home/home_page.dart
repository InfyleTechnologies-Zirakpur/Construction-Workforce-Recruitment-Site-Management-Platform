import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../core/widgets/search/hero_search_bar.dart';
import '../search/search_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  // Drives every SmartSkeleton on this page. Flip to false once your real
  // trades/stats/jobs data has actually loaded.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // TODO: replace with your real data fetch (API/repository call).
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

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

  void _showTradeJobs(BuildContext context, _Trade trade) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _TradeJobsBottomSheet(trade: trade);
      },
    );
  }

  void _showJobDetails(BuildContext context, _JobPosting job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobDetailsSheet(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.foundation, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'BuildHire',
              style: textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications,
              color: Colors.white70,
              size: 22,
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
            _buildTradesRow(context),
            _buildStatsBar(context),
            _buildJobsHeader(context),
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SmartSkeleton.list(
                      itemCount: 4,
                      hasLeading: true,
                      leadingSize: 44,
                      titleWords: 3,
                      subtitleWords: 2,
                      hasMeta: true,
                      hasTags: true,
                      tagCount: 3,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Column(
                      children: _jobs.map((j) => _JobCard(job: j)).toList(),
                    ),
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border_outlined),
            label: 'My Jobs',
            selectedIcon: Icon(Icons.bookmark),
          ),
          NavigationDestination(
            icon: Icon(Icons.messenger_outline),
            selectedIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: HeroSearchBar(
        readOnly: true,
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
        },
      ),
    );
  }

  Widget _buildTradesRow(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Browse by Trade', style: textTheme.titleMedium),
          const SizedBox(height: 12),
          _isLoading
              ? const SmartSkeleton.grid(
                  itemCount: 8,
                  itemWidth: 84,
                  itemHeight: 90,
                  hasLabel: true,
                  gridTileShape: BoxShape.circle,
                )
              : SizedBox(
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
                            Icon(t.icon, color: AppColors.primary, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              t.name,
                              textAlign: TextAlign.center,
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
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

  Widget _buildStatsBar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget stat(String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 18,
                color: AppColors.dark,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: textTheme.bodySmall?.copyWith(fontSize: 11)),
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
      child: _isLoading
          ? const SmartSkeleton.row(
              itemCount: 3,
              showRowLabel: true,
              showCardChrome: false,
            )
          : Row(
              children: [
                stat('12,400+', 'Open Jobs'),
                stat('3,800+', 'Hiring Sites'),
                stat('64,000+', 'Registered Workers'),
              ],
            ),
    );
  }

  Widget _buildJobsHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Latest Job Postings', style: textTheme.titleMedium),
          Text(
            'See all',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _JobDetailsSheet(job: job),
        );
      },
      child: Container(
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
                    color: AppColors.dark.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business, color: AppColors.dark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        job.company,
                        style: textTheme.bodySmall?.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Text(job.posted, style: textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: textTheme.bodySmall?.copyWith(fontSize: 12.5),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.payments_outlined,
                  size: 15,
                  color: Colors.black45,
                ),
                const SizedBox(width: 4),
                Text(
                  job.pay,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 10.5,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TradeJobsBottomSheet extends StatefulWidget {
  final _Trade trade;

  const _TradeJobsBottomSheet({required this.trade});

  @override
  State<_TradeJobsBottomSheet> createState() => _TradeJobsBottomSheetState();
}

class _TradeJobsBottomSheetState extends State<_TradeJobsBottomSheet> {
  bool isLoading = true;

  List<_JobPosting> jobs = [];

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    // Replace with your API call.
    await Future.delayed(const Duration(seconds: 2));

    jobs = [
      _JobPosting(
        title: "${widget.trade.name} Required",
        company: "BuildHire Pvt Ltd",
        location: "Bathinda",
        pay: "₹900/day",
        tags: const ["Urgent", "Full-time"],
        posted: "Today",
      ),
      _JobPosting(
        title: "Senior ${widget.trade.name}",
        company: "Skyline Infra",
        location: "Chandigarh",
        pay: "₹1,200/day",
        tags: const ["Experienced"],
        posted: "1 day ago",
      ),
      _JobPosting(
        title: "${widget.trade.name} Helper",
        company: "Metro Builders",
        location: "Mohali",
        pay: "₹700/day",
        tags: const ["Immediate"],
        posted: "2 days ago",
      ),
    ];

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * .75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(widget.trade.icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${widget.trade.name} Jobs",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SmartSkeleton.list(
                      itemCount: 5,
                      hasLeading: true,
                      leadingSize: 44,
                      titleWords: 3,
                      subtitleWords: 2,
                      hasMeta: true,
                      hasTags: true,
                      tagCount: 3,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: jobs.length,
                    itemBuilder: (_, i) {
                      return _JobCard(job: jobs[i]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _JobDetailsSheet extends StatefulWidget {
  final _JobPosting job;

  const _JobDetailsSheet({required this.job});

  @override
  State<_JobDetailsSheet> createState() => _JobDetailsSheetState();
}

class _JobDetailsSheetState extends State<_JobDetailsSheet> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: MediaQuery.of(context).size.height * .8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: SmartSkeleton.list(
                itemCount: 1,
                hasLeading: true,
                leadingSize: 50,
                titleWords: 3,
                subtitleWords: 2,
                hasMeta: true,
                hasTags: true,
                tagCount: 3,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.job.title, style: textTheme.headlineSmall),

                  const SizedBox(height: 8),

                  Text(widget.job.company),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined),
                      const SizedBox(width: 8),
                      Text(widget.job.location),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.payments_outlined),
                      const SizedBox(width: 8),
                      Text(widget.job.pay),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Text("Job Description", style: textTheme.titleMedium),

                  const SizedBox(height: 10),

                  const Text(
                    "We are looking for skilled workers for our construction site. "
                    "Candidates should have experience in their trade and be able "
                    "to work independently while following all safety regulations.",
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    children: widget.job.tags
                        .map((e) => Chip(label: Text(e)))
                        .toList(),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text("Apply Now"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
