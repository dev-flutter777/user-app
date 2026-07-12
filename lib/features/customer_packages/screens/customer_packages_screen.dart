import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// الـ Imports الصحيحة للمشروع
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart'; 
import 'package:flutter_sixvalley_ecommerce/features/customer_packages/controllers/customer_package_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/screens/offline_payment_screen.dart'; 
import 'package:flutter_sixvalley_ecommerce/features/customer_packages/screens/package_checkout_screen.dart';

// تم إزالة الموديلات اليدوية المتعارضة والاعتماد على الكنترولر الفعلي

class CustomerPackagesScreen extends StatefulWidget {
  final String? userToken; 

  const CustomerPackagesScreen({Key? key, this.userToken}) : super(key: key);

  @override
  State<CustomerPackagesScreen> createState() => _CustomerPackagesScreenState();
}

class _CustomerPackagesScreenState extends State<CustomerPackagesScreen> {
  List<CustomerPackageModel> _packageList = [];
  ActivationInvoiceModel? _currentInvoice;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = widget.userToken != null && widget.userToken!.isNotEmpty;
    if (_isLoggedIn) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await _getCurrentInvoice();
    if (_currentInvoice == null || _currentInvoice!.status == 'canceled' || _currentInvoice!.status == 'expired') {
      await _getPackages();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentInvoice() async {
    final url = '${AppConstants.baseUrl}/api/v1/customer/activation-invoice/current';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ${widget.userToken}',
        'Accept': 'application/json',
        'lang': 'ar'
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['invoice'] != null) {
          _currentInvoice = ActivationInvoiceModel.fromJson(data['invoice']);
        } else {
          _currentInvoice = null;
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _getPackages() async {
    final url = '${AppConstants.baseUrl}/api/v1/customer/purchase-packages';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ${widget.userToken}',
        'Accept': 'application/json',
        'lang': 'ar'
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['packages'] != null) {
          _packageList = (data['packages'] as List)
              .map((p) => CustomerPackageModel.fromJson(p))
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _buyPackage(int packageId, CustomerPackageModel selectedPackage) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final url = '${AppConstants.baseUrl}/api/v1/customer/purchase-packages/purchase';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.userToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'lang': 'ar'
        },
        body: jsonEncode({
          'package_id': packageId,
          'payment_method': 'offline_payment',
          'payment_platform': 'app',
        }),
      );

      if (response.statusCode == 200) {
        await _getCurrentInvoice();
        if (_currentInvoice != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PackageCheckoutScreen(
                package: selectedPackage,
                insuranceAmount: _currentInvoice!.insurance?.amount ?? 150.0,
                userToken: widget.userToken!,
                invoiceId: _currentInvoice!.id, // تفعيل الـ invoiceId المطلوب تماماً
              ),
            ),
          ).then((_) => _loadData());
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('باقات تفعيل الحساب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_isLoggedIn
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text(
                  'يرجى تسجيل الدخول أولاً لتتمكن من استعراض واختيار باقات المشترين وتنشيط حسابك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Color(0xFF6C757D), height: 1.5),
                ),
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _currentInvoice != null && _currentInvoice!.status == 'active'
                  ? _buildActiveUI()
                  : (_currentInvoice != null && (_currentInvoice!.status == 'pending' || _currentInvoice!.status == 'pending_offline_review'))
                      ? _buildPendingUI()
                      : _buildPackagesUI(),
    );
  }

  Widget _buildActiveUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE9ECEF))),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF2B9348), size: 72),
                const SizedBox(height: 16),
                Text('حسابك نشط ومفعّل بالكامل (${_currentInvoice?.package?.name ?? ""})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 72),
            const SizedBox(height: 20),
            Text(_currentInvoice?.message ?? 'تم استلام طلب الاشتراك وجاري مراجعة التحويل البنكي يدوياً.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _loadData, child: const Text('تحديث الحالة')),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesUI() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _packageList.length,
            itemBuilder: (context, index) {
              final package = _packageList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE9ECEF))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(package.name ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('\$${package.price ?? 0}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(package.description ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF6C757D))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        onPressed: () => _buyPackage(package.id!, package),
                        child: const Text('اشترك الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}