import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../features/repositories/company_repository.dart';
import 'company_home_screen.dart';

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
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.profile != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Company Profile' : 'Register Company'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.w(20)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Update Company Details' : 'Register Company Profile',
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark),
                ),
                SizedBox(height: context.h(4)),
                Text(
                  'Provide verified credentials for worker trust & site management.',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
                SizedBox(height: context.h(20)),

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
                  initialValue: _businessTypes.contains(_businessType) ? _businessType : null,
                  decoration: const InputDecoration(labelText: 'Business Structure'),
                  items: _businessTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
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
                        initialValue: _teamSizes.contains(_teamSizeRange) ? _teamSizeRange : null,
                        decoration: const InputDecoration(labelText: 'Team Size'),
                        items: _teamSizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: context.h(16)),
                    ),
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isEdit ? 'Save Changes' : 'Submit Registration', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                SizedBox(height: context.h(16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.dark)),
      ],
    );
  }
}
