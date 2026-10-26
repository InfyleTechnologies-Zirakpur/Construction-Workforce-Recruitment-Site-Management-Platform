import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/api_error_parser.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/dialogs/app_confirm_dialog.dart';
import '../../features/repositories/company_repository.dart';
import 'company_home_screen.dart';
import 'widgets/company_app_bar.dart';

class CompanyProfileFormScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;
  final bool isInitialSetup;
  final String? initialEmail;
  final String? initialName;

  const CompanyProfileFormScreen({
    super.key,
    this.profile,
    this.isInitialSetup = false,
    this.initialEmail,
    this.initialName,
  });
  @override
  State<CompanyProfileFormScreen> createState() => _CompanyProfileFormScreenState();
}

class _CompanyProfileFormScreenState extends State<CompanyProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CompanyRepository();

  late final TextEditingController _name;
  late final TextEditingController _contactEmail;
  late final TextEditingController _contactPhone;
  late final TextEditingController _alternatePhone;
  late final TextEditingController _registrationNumber;
  late final TextEditingController _gstNumber;
  late final TextEditingController _panNumber;
  late final TextEditingController _website;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  late final TextEditingController _yearEstablished;
  late final TextEditingController _specializations;
  late final TextEditingController _operationalAreas;
  late final TextEditingController _logoUrl;
  late final TextEditingController _description;

  String? _businessType;
  String? _teamSizeRange;
  bool _saving = false;
  String? _error;

  final List<String> _businessTypes = [
    'Private Limited',
    'Public Limited',
    'Proprietorship',
    'Partnership',
    'LLP',
    'Other',
  ];

  final List<String> _teamSizes = [
    '1-10',
    '10-50',
    '50-100',
    '100-250',
    '250-500',
    '500+',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile ?? {};

    _name = TextEditingController(text: p['name']?.toString() ?? widget.initialName ?? '');
    _contactEmail = TextEditingController(text: p['contactEmail']?.toString() ?? widget.initialEmail ?? '');
    _contactPhone = TextEditingController(text: p['contactPhone']?.toString() ?? '');
    _alternatePhone = TextEditingController(text: p['alternatePhone']?.toString() ?? '');
    _registrationNumber = TextEditingController(text: p['registrationNumber']?.toString() ?? '');
    _gstNumber = TextEditingController(text: p['gstNumber']?.toString() ?? '');
    _panNumber = TextEditingController(text: p['panNumber']?.toString() ?? '');
    _website = TextEditingController(text: p['website']?.toString() ?? '');
    _address = TextEditingController(text: p['address']?.toString() ?? '');
    _city = TextEditingController(text: p['city']?.toString() ?? '');
    _state = TextEditingController(text: p['state']?.toString() ?? '');
    _pincode = TextEditingController(text: p['pincode']?.toString() ?? '');
    _yearEstablished = TextEditingController(text: p['yearEstablished']?.toString() ?? '');

    List<String> specList = (p['specializations'] is List) ? List<String>.from(p['specializations']) : [];
    _specializations = TextEditingController(text: specList.join(', '));

    List<String> areaList = (p['operationalAreas'] is List) ? List<String>.from(p['operationalAreas']) : [];
    _operationalAreas = TextEditingController(text: areaList.join(', '));

    _logoUrl = TextEditingController(text: p['logoUrl']?.toString() ?? '');
    _description = TextEditingController(text: p['description']?.toString() ?? '');

    _businessType = p['businessType']?.toString();
    _teamSizeRange = p['teamSizeRange']?.toString();
  }

  String? get _selectedBusinessType {
    if (_businessType == null) return null;
    final normalized = _businessType!.trim().toLowerCase();
    for (final t in _businessTypes) {
      if (t.trim().toLowerCase() == normalized) return t;
    }
    return null;
  }

  String? get _selectedTeamSize {
    if (_teamSizeRange == null) return null;
    final normalized = _teamSizeRange!.trim().toLowerCase();
    for (final s in _teamSizes) {
      if (s.trim().toLowerCase() == normalized) return s;
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    _alternatePhone.dispose();
    _registrationNumber.dispose();
    _gstNumber.dispose();
    _panNumber.dispose();
    _website.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _yearEstablished.dispose();
    _specializations.dispose();
    _operationalAreas.dispose();
    _logoUrl.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'contactEmail': _contactEmail.text.trim(),
      'contactPhone': _contactPhone.text.trim(),
      if (_alternatePhone.text.trim().isNotEmpty) 'alternatePhone': _alternatePhone.text.trim(),
      if (_registrationNumber.text.trim().isNotEmpty) 'registrationNumber': _registrationNumber.text.trim(),
      if (_gstNumber.text.trim().isNotEmpty) 'gstNumber': _gstNumber.text.trim(),
      if (_panNumber.text.trim().isNotEmpty) 'panNumber': _panNumber.text.trim(),
      if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
      if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
      if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
      if (_state.text.trim().isNotEmpty) 'state': _state.text.trim(),
      if (_pincode.text.trim().isNotEmpty) 'pincode': _pincode.text.trim(),
      if (_businessType != null) 'businessType': _businessType,
      if (_yearEstablished.text.trim().isNotEmpty) 'yearEstablished': int.tryParse(_yearEstablished.text.trim()),
      if (_teamSizeRange != null) 'teamSizeRange': _teamSizeRange,
      if (_specializations.text.trim().isNotEmpty)
        'specializations': _specializations.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      if (_operationalAreas.text.trim().isNotEmpty)
        'operationalAreas': _operationalAreas.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      if (_logoUrl.text.trim().isNotEmpty) 'logoUrl': _logoUrl.text.trim(),
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
    };

    try {
      if (widget.profile != null && widget.profile!['id'] != null) {
        await _repo.updateCompanyProfile(widget.profile!['id'].toString(), body);
      } else {
        await _repo.createCompanyProfile(body);
      }

      const storageEncrypted = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      const storagePlain = FlutterSecureStorage();
      await storageEncrypted.write(key: 'profileCompleted', value: 'true');
      await storagePlain.write(key: 'profileCompleted', value: 'true');
      await storageEncrypted.write(key: 'isProfileComplete', value: 'true');
      await storagePlain.write(key: 'isProfileComplete', value: 'true');
      if (_name.text.trim().isNotEmpty) {
        await storageEncrypted.write(key: 'companyName', value: _name.text.trim());
        await storagePlain.write(key: 'companyName', value: _name.text.trim());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.profile != null ? 'Company profile updated!' : 'Company profile created!'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.isInitialSetup) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CompanyHomeScreen()),
            (_) => false,
          );
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiErrorParser.extractMessage(
            e,
            fallback: 'Failed to save company profile. Please check your inputs.',
          );
          _saving = false;
        });
      }
    }
  }

  Future<void> _handleBack() async {
    if (widget.isInitialSetup) {
      final confirm = await AppConfirmDialog.show(
        context,
        title: 'Exit Profile Setup?',
        message:
            'You can complete your company profile details later from your employer portal before posting job requirements.',
        confirmLabel: 'Go to Dashboard',
        cancelLabel: 'Stay Here',
        icon: Icons.dashboard_customize_rounded,
        isDestructive: false,
      );
      if (confirm && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CompanyHomeScreen()),
          (_) => false,
        );
      }
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.profile != null;

    return PopScope(
      canPop: !widget.isInitialSetup,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Theme(
        data: AppTheme.companyTheme(context),
        child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CompanyAppBar(
          showBackButton: true,
          showNotifications: false,
          showProfileAvatar: false,
          onBackPressed: _handleBack,
        ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Update Company Details' : 'Register Company Profile',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.dark,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEdit
                              ? 'Update your company details and verification credentials'
                              : 'Provide verified credentials for worker trust & site management',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                  ),
                ],

                // Basic Details
                _sectionHeader('Basic Details', Icons.business, textTheme),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Company Name *', hintText: 'e.g. BuildCraft Infrastructure Ltd'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Company name is required' : null,
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _contactEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Contact Email *', hintText: 'contact@company.com'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _contactPhone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Contact Phone *', hintText: '9876543210'),
                        validator: (v) => (v == null || v.trim().length < 10) ? 'Valid phone required' : null,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _alternatePhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Alternate Phone', hintText: 'Secondary landline or phone'),
                ),

                SizedBox(height: context.h(20)),
                // Legal & Tax
                _sectionHeader('Legal & Registration', Icons.badge_outlined, textTheme),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _registrationNumber,
                  decoration: const InputDecoration(labelText: 'CIN / Registration No.', hintText: 'U45200PB2021PTC053912'),
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gstNumber,
                        decoration: const InputDecoration(labelText: 'GST Number', hintText: '03AABCB1234F1Z5'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _panNumber,
                        decoration: const InputDecoration(labelText: 'PAN Number', hintText: 'AABCB1234F'),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: context.h(20)),
                // Location & Web
                _sectionHeader('Address & Location', Icons.location_on_outlined, textTheme),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Office Address', hintText: 'Street address / Industrial area'),
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _city,
                        decoration: const InputDecoration(labelText: 'City', hintText: 'Mohali'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _state,
                        decoration: const InputDecoration(labelText: 'State', hintText: 'Punjab'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _pincode,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Pincode', hintText: '160062'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _website,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(labelText: 'Website URL', hintText: 'https://company.com'),
                ),

                SizedBox(height: context.h(20)),
                // Structure & Scope
                _sectionHeader('Business Scope', Icons.work_outline, textTheme),
                SizedBox(height: context.h(12)),
                DropdownButtonFormField<String>(
                  value: _selectedBusinessType,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.companyPrimary,
                    size: 22,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  elevation: 3,
                  menuMaxHeight: 320,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Business Structure / Scope',
                    hintText: 'Select entity type',
                  ),
                  items: _businessTypes.map((t) {
                    final isSelected = t == _selectedBusinessType;
                    return DropdownMenuItem<String>(
                      value: t,
                      child: Row(
                        children: [
                          Icon(
                            Icons.business_outlined,
                            size: 18,
                            color: isSelected ? AppColors.companyPrimary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.companyPrimary : AppColors.dark,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: AppColors.companyPrimary,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _businessType = v),
                ),
                SizedBox(height: context.h(12)),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yearEstablished,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Established Year', hintText: '2018'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTeamSize,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.companyPrimary,
                          size: 22,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 3,
                        menuMaxHeight: 320,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Team Size',
                          hintText: 'Select size',
                        ),
                        items: _teamSizes.map((s) {
                          final isSelected = s == _selectedTeamSize;
                          return DropdownMenuItem<String>(
                            value: s,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.groups_outlined,
                                  size: 18,
                                  color: isSelected ? AppColors.companyPrimary : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.companyPrimary : AppColors.dark,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: AppColors.companyPrimary,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _teamSizeRange = v),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _specializations,
                  decoration: const InputDecoration(
                    labelText: 'Specializations (Comma separated)',
                    hintText: 'Industrial Warehouses, Factory Sheds, RCC Structures',
                  ),
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _operationalAreas,
                  decoration: const InputDecoration(
                    labelText: 'Operational Areas (Comma separated)',
                    hintText: 'Punjab, Himachal Pradesh, Jammu',
                  ),
                ),
                SizedBox(height: context.h(12)),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Company Description',
                    hintText: 'Overview of construction projects and capabilities...',
                  ),
                ),

                SizedBox(height: context.h(28)),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.companyPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            isEdit ? 'Save Changes' : 'Submit Registration',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
),
    ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.companyTagBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.companyPrimary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.dark,
          ),
        ),
      ],
    );
  }
}
