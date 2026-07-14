import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// الـ Imports الصحيحة للمشروع الخاص بك
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart'; 
import 'package:flutter_sixvalley_ecommerce/features/customer_packages/controllers/customer_package_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/screens/offline_payment_screen.dart'; 
import 'package:flutter_sixvalley_ecommerce/features/customer_packages/model/customer_package_model.dart'; 

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

  // تعريف ألوان التصميم
  final Color _primaryColor = const Color(0xFF0D53FC); 
  final Color _backgroundColor = const Color(0xFF0B0D17);
  final Color _cardColor = const Color(0xFF141729);
  final Color _strokeColor = const Color(0xFF242946);
  final Color _textColor = Colors.white;
  final Color _textMutedColor = const Color(0xFF8E95B2);

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
      debugPrint("Error fetching current invoice: $e");
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
      debugPrint("Error fetching packages: $e");
    }
  }

  // خطوة شراء الباقة المباشرة وفتح واجهة خيارات الدفع فوراً
  Future<void> _initiatePackagePurchase(CustomerPackageModel selectedPackage) async {
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
          'package_id': selectedPackage.id,
          'payment_method': 'offline_payment',
          'payment_platform': 'app',
        }),
      );

      if (response.statusCode == 200) {
        await _getCurrentInvoice();
        setState(() => _isLoading = false);
        if (_currentInvoice != null && mounted) {
          // حساب المبلغ الإجمالي: سعر الباقة + التأمين
          double packagePrice = selectedPackage.price ?? 0.0;
          double insuranceAmount = _currentInvoice!.insurance?.amount ?? 150.0;
          double totalPayableAmount = packagePrice + insuranceAmount;

          // توجيه المستخدم مباشرة واختيار الدفع دون المرور بصفحة الـ Checkout المعقدة
          _showDirectPaymentBottomSheet(totalPayableAmount);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error preparing purchase: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // نافذة اختيار الدفع المباشر من الأسفل (Bottom Sheet)
  void _showDirectPaymentBottomSheet(double payableAmount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تأكيد الدفع والاشتراك',
                  style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'المبلغ الإجمالي المطلوب سداده (شامل التأمين):',
                  style: TextStyle(color: _textMutedColor, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$$payableAmount',
                  style: TextStyle(color: _primaryColor, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                
                // الخيار الأول المباشر: الدفع اليدوي والتحويل البنكي
                InkWell(
                  onTap: () {
                    Navigator.pop(context); // إغلاق الـ Bottom Sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OfflinePaymentScreen(
                          payableAmount: payableAmount,
                          callback: (bool isSuccess) {
                            if (isSuccess) {
                              _loadData();
                            }
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1E36),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _strokeColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, color: _primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('التحويل اليدوي / البنكي', style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('إرسال إيصال الدفع يدوياً للمراجعة', style: TextStyle(color: _textMutedColor, fontSize: 11)),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, color: _textMutedColor, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'باقات تفعيل الحساب',
          style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: !_isLoggedIn
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'يرجى تسجيل الدخول أولاً لتتمكن من استعراض واختيار باقات المشترين وتنشيط حسابك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: _textMutedColor, height: 1.5),
                ),
              ),
            )
          : _isLoading
              ? Center(child: CircularProgressIndicator(color: _primaryColor))
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
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _strokeColor, width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF00B574), size: 80),
                const SizedBox(height: 20),
                Text(
                  'حسابك نشط ومفعّل بالكامل',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentInvoice?.package?.name ?? "الباقة الافتراضية",
                  style: TextStyle(fontSize: 15, color: _primaryColor, fontWeight: FontWeight.bold),
                ),
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
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFF7A00).withOpacity(0.3), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded, color: Color(0xFFFF7A00), size: 80),
              const SizedBox(height: 20),
              Text(
                'طلبك قيد المراجعة اليدوية',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor),
              ),
              const SizedBox(height: 12),
              Text(
                _currentInvoice?.message ?? 'تم استلام طلب الاشتراك وجاري مراجعة التحويل البنكي يدوياً والتحقق من المرفقات والبيانات المرسلة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _textMutedColor, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text('تحديث الحالة الآن', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackagesUI() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _packageList.length,
      itemBuilder: (context, index) {
        final package = _packageList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _strokeColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    package.name ?? '',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textColor),
                  ),
                  Text(
                    '\$${package.price ?? 0}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                package.description ?? '',
                style: TextStyle(fontSize: 13, color: _textMutedColor, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _initiatePackagePurchase(package),
                  child: const Text(
                    'اشترك الآن',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}