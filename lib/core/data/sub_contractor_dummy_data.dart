import '../../screens/feed/widgets/tender_feed_card.dart';
import '../../core/models/models.dart';

// =============================================================================
// SUB CONTRACTOR DUMMY DATA STORE & API INTEGRATION HUB
// =============================================================================
// All mock/dummy records for the Sub Contractor flow are centralized here.
// When your backend APIs are ready, you ONLY need to update or replace the
// methods in this file with your live Dio / HTTP calls.
//
// Planned Backend Endpoints:
// - GET  /sub-contractors/work-leads           -> Returns list of Work Leads
// - GET  /sub-contractors/work-leads/saved     -> Returns saved leads
// - POST /sub-contractors/work-leads/:id/apply -> Submit proposal
// - POST /sub-contractors/work-leads/:id/save  -> Toggle bookmark/save
// - GET  /sub-contractors/feed/tenders         -> Company tenders on feed
// =============================================================================

/// Model representing a Work Lead / Tender opportunity for Sub Contractors
class WorkLeadItem {
  final String id;
  final String title;
  final String clientName;
  final String? clientAvatar;
  final String status;
  final String description;
  final String location;
  final String budget;
  final String deadline;
  final String category;
  final String postedAgo;
  final String? savedAgo;
  final bool isApplied;
  final bool isSaved;
  final bool isRejected;
  final String? proposalQuote;
  final String? proposalTimeline;
  final String? proposalNotes;
  final String? rejectionReason;

  const WorkLeadItem({
    required this.id,
    required this.title,
    required this.clientName,
    this.clientAvatar,
    this.status = 'Open',
    required this.description,
    required this.location,
    required this.budget,
    required this.deadline,
    required this.category,
    required this.postedAgo,
    this.savedAgo,
    this.isApplied = false,
    this.isSaved = false,
    this.isRejected = false,
    this.proposalQuote,
    this.proposalTimeline,
    this.proposalNotes,
    this.rejectionReason,
  });

  WorkLeadItem copyWith({
    String? id,
    String? title,
    String? clientName,
    String? clientAvatar,
    String? status,
    String? description,
    String? location,
    String? budget,
    String? deadline,
    String? category,
    String? postedAgo,
    String? savedAgo,
    bool? isApplied,
    bool? isSaved,
    bool? isRejected,
    String? proposalQuote,
    String? proposalTimeline,
    String? proposalNotes,
    String? rejectionReason,
  }) {
    return WorkLeadItem(
      id: id ?? this.id,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      status: status ?? this.status,
      description: description ?? this.description,
      location: location ?? this.location,
      budget: budget ?? this.budget,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      postedAgo: postedAgo ?? this.postedAgo,
      savedAgo: savedAgo ?? this.savedAgo,
      isApplied: isApplied ?? this.isApplied,
      isSaved: isSaved ?? this.isSaved,
      isRejected: isRejected ?? this.isRejected,
      proposalQuote: proposalQuote ?? this.proposalQuote,
      proposalTimeline: proposalTimeline ?? this.proposalTimeline,
      proposalNotes: proposalNotes ?? this.proposalNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory WorkLeadItem.fromJson(Map<String, dynamic> json) {
    return WorkLeadItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      clientName: json['clientName'] ?? json['company']?['name'] ?? 'Client',
      clientAvatar: json['clientAvatar'] ?? json['company']?['logoUrl'],
      status: json['status'] ?? 'Open',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      budget: json['budget'] ?? 'Negotiable',
      deadline: json['deadline'] ?? '',
      category: json['category'] ?? 'General',
      postedAgo: json['postedAgo'] ?? 'Recently',
      savedAgo: json['savedAgo'],
      isApplied: json['isApplied'] == true,
      isSaved: json['isSaved'] == true,
      isRejected: json['isRejected'] == true,
      proposalQuote: json['proposalQuote'],
      proposalTimeline: json['proposalTimeline'],
      proposalNotes: json['proposalNotes'],
      rejectionReason: json['rejectionReason'],
    );
  }
}

class SubContractorDummyData {
  /// --------------------------------------------------------------------------
  /// 1. WORK LEADS DUMMY DATA (Used in WorkLeadsScreen)
  /// --------------------------------------------------------------------------
  /// Future API Replacement:
  /// final res = await ApiClient.instance.dio.get('/sub-contractors/work-leads');
  /// return (res.data['data'] as List).map((j) => WorkLeadItem.fromJson(j)).toList();
  /// --------------------------------------------------------------------------
  static List<WorkLeadItem> getInitialWorkLeads() {
    return [
      const WorkLeadItem(
        id: 'wl_1',
        title: 'HVAC Installation - Commercial Building',
        clientName: 'Metro Developers',
        status: 'Open',
        description: 'Complete HVAC system installation for 5-story commercial building',
        location: 'Saket, New Delhi',
        budget: '₹8,00,000 - ₹12,00,000',
        deadline: 'April 15, 2026',
        category: 'HVAC',
        postedAgo: 'Posted: 2 hours ago',
        isApplied: false,
        isSaved: false,
        isRejected: false,
      ),
      const WorkLeadItem(
        id: 'wl_saved_1',
        title: 'Residential Plumbing Project',
        clientName: 'Sunrise Apartments',
        status: 'Open',
        description: 'Plumbing installation for 20-unit apartment complex',
        location: 'Dwarka, New Delhi',
        budget: '₹4,00,000 - ₹5,50,000',
        deadline: 'April 25, 2026',
        category: 'Plumbing',
        postedAgo: 'Posted: 4 days ago',
        savedAgo: 'Saved: 3 days ago',
        isApplied: false,
        isSaved: true,
        isRejected: false,
      ),
      const WorkLeadItem(
        id: 'wl_2',
        title: 'Electrical Wiring - Residential Complex',
        clientName: 'Green Valley Homes',
        status: 'Open',
        description: 'Complete electrical wiring for 12-unit residential complex',
        location: 'Sector 56, Gurgaon',
        budget: '₹4,50,000 - ₹6,00,000',
        deadline: 'April 30, 2026',
        category: 'Electrical',
        postedAgo: 'Posted: 1 day ago',
        isApplied: false,
        isSaved: false,
        isRejected: false,
      ),
      const WorkLeadItem(
        id: 'wl_3',
        title: 'Plumbing System - New Restaurant',
        clientName: 'Food Ventures India',
        status: 'Open',
        description: 'Commercial kitchen plumbing and bathroom installations',
        location: 'Indiranagar, Bengaluru',
        budget: '₹3,00,000 - ₹4,50,000',
        deadline: 'April 8, 2026',
        category: 'Plumbing',
        postedAgo: 'Posted: 2 days ago',
        isApplied: true,
        isSaved: false,
        isRejected: false,
        proposalQuote: '₹3,80,000',
        proposalTimeline: '20 days',
      ),
      const WorkLeadItem(
        id: 'wl_4',
        title: 'Firefighting Piping & Sprinkler System',
        clientName: 'Apex Tower Corp',
        status: 'Open',
        description: 'High-pressure firefighting sprinkler piping and hydrants for commercial mall',
        location: 'Cyber City, Gurgaon',
        budget: '₹9,50,000 - ₹14,00,000',
        deadline: 'May 5, 2026',
        category: 'HVAC',
        postedAgo: 'Posted: 4 hours ago',
        isApplied: true,
        isSaved: false,
        isRejected: false,
        proposalQuote: '₹11,00,000',
        proposalTimeline: '45 days',
      ),
      const WorkLeadItem(
        id: 'wl_5',
        title: 'Civil Finishing & Flooring Work',
        clientName: 'Prestige Estates',
        status: 'Open',
        description: 'Granite and vitrified tile flooring for lobby and residential towers',
        location: 'Whitefield, Bengaluru',
        budget: '₹14,00,000 - ₹20,00,000',
        deadline: 'June 1, 2026',
        category: 'Civil Construction',
        postedAgo: 'Posted: 6 hours ago',
        isApplied: false,
        isSaved: false,
        isRejected: false,
      ),
      const WorkLeadItem(
        id: 'wl_6',
        title: 'Central AC Ducting - IT Park',
        clientName: 'DLF CyberCity Developers',
        status: 'Rejected',
        description: 'Complete supply and installation of galvanized iron ducting for IT tower',
        location: 'Sector 25A, Gurgaon',
        budget: '₹12,00,000 - ₹16,00,000',
        deadline: 'April 1, 2026',
        category: 'HVAC',
        postedAgo: 'Posted: 5 days ago',
        isApplied: true,
        isSaved: false,
        isRejected: true,
        proposalQuote: '₹14,50,000',
        proposalTimeline: '30 days',
        rejectionReason: 'Client selected alternate vendor due to timeline constraints',
      ),
    ];
  }

  /// --------------------------------------------------------------------------
  /// 2. FEED TENDERS DUMMY DATA (Used in FeedScreen for Sub Contractors)
  /// --------------------------------------------------------------------------
  /// Future API Replacement:
  /// final res = await ApiClient.instance.dio.get('/sub-contractors/feed/tenders');
  /// return (res.data['data'] as List).map((t) => TenderJobItem.fromJson(t)).toList();
  /// --------------------------------------------------------------------------
  static List<TenderJobItem> getInitialFeedTenders() {
    return [
      const TenderJobItem(
        id: 'tender_1',
        companyName: 'Metro Developers',
        timeAgo: '5 hours ago',
        title: 'HVAC Installation - Commercial Building',
        description: 'Complete HVAC system installation for 5-story commercial building',
        location: 'Sector 56, Gurgaon',
        budget: '₹8,00,000 - ₹12,00,000',
        deadline: 'May 15, 2026',
        category: 'HVAC',
        applicantsCount: 14,
      ),
      const TenderJobItem(
        id: 'tender_2',
        companyName: 'Green Valley Homes',
        timeAgo: '1 day ago',
        title: 'Electrical Wiring - Residential Complex',
        description: 'Electrical wiring for 12-unit residential complex',
        location: 'Sector 56, Gurgaon',
        budget: '₹4,50,000 - ₹6,00,000',
        deadline: 'April 30, 2026',
        category: 'Electrical',
        applicantsCount: 8,
      ),
      const TenderJobItem(
        id: 'tender_3',
        companyName: 'Food Ventures India',
        timeAgo: '2 days ago',
        title: 'Plumbing System - New Restaurant',
        description: 'Commercial kitchen plumbing and bathroom installations',
        location: 'Indiranagar, Bengaluru',
        budget: '₹3,00,000 - ₹4,50,000',
        deadline: 'April 8, 2026',
        category: 'Plumbing',
        applicantsCount: 5,
      ),
    ];
  }

  /// --------------------------------------------------------------------------
  /// 3. FEATURED COMMUNITY POST DUMMY DATA (Sharma Construction Card)
  /// --------------------------------------------------------------------------
  static FeedPost getSampleFeaturedPost() {
    return FeedPost(
      id: 'post_featured_sharma',
      authorName: 'Sharma Construction',
      authorRole: 'Sub Contractor',
      content:
          'Successfully completed electrical installation for 50+ residential units in Dwarka Phase 3! Looking for skilled electricians for our next project.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likesCount: 24,
      commentsCount: 8,
      sharesCount: 3,
    );
  }
}

