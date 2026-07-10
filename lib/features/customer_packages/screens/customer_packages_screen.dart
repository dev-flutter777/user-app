import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/screens/offline_payment_screen.dart'; 
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

// =========================================================================
// 1. MODELS
// =========================================================================

class CustomerPackageModel {
  int? id;
  String? name;
  double? price;
  int? durationInDays;
  String? description;
  int? orderLimit;
  List<String>? advantages;

  CustomerPackageModel({
    this.id,
    this.name,
    this.price,
    this.durationInDays,
    this.description,
    this.orderLimit,
    this.advantages,
  });

  CustomerPackageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = double.tryParse(json['price'].toString());
    durationInDays = json['duration_in_days'];
    description = json['description'];
    orderLimit = json['order_limit'];
    if (json['advantages'] != null) {
      advantages = List<String>.from(json['advantages']);
    }
  }
}

class ActivationInvoiceModel {
  int? id;
  String? invoiceNo;
  double? totalAmount;
  String? paymentStatus;
  String? status; // 'pending', 'active', 'expired', 'canceled'
  PackageInfo? package;
  InsuranceInfo? insurance;

  ActivationInvoiceModel({
    this.id,
    this.invoiceNo,
    this.totalAmount,
    this.paymentStatus,
    this.status,
    this.package,
    this.insurance,
  });

  ActivationInvoiceModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    invoiceNo = json['invoice_no'];
    totalAmount = double.tryParse(json['total_amount'].toString());
    paymentStatus = json['payment_status'];
    status = json['status'];
    package = json['package'] != null ? PackageInfo.fromJson(json['package']) : null;
    insurance = json['insurance'] != null ? InsuranceInfo.fromJson(json['insurance']) : null;
  }
}

class PackageInfo {
  int? id;
  String? name;
  double? price;
  double? purchaseLimit;

  PackageInfo({this.id, this.name, this.price, this.purchaseLimit});

  PackageInfo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    price = double.tryParse(json['price'].toString());
    purchaseLimit = double.tryParse(json['purchase_limit'].toString());
  }
}

class InsuranceInfo {
  double? amount;

  InsuranceInfo({this.amount});

  InsuranceInfo.fromJson(Map<String, dynamic> json) {
    amount = double.tryParse(json['amount'].toString());
  }
}

// =========================================================================
// 2. CONTROLLER
// =========================================================================

class CustomerPackageController extends ChangeNotifier {
  final String baseUrl = AppConstants.baseUrl; 

  List<CustomerPackageModel> packageList = [];
  ActivationInvoiceModel? currentInvoice;
  bool isLoading = false;
  bool isCheckingStatus = true; 

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> initializeData(String token) async {
    isCheckingStatus = true;
    isLoading = true;
    notifyListeners();

    await getCurrentActivationInvoice(token);

    if (currentInvoice == null || currentInvoice!.status == 'canceled' || currentInvoice!.status == 'expired') {
      await getPackageList(token);
    }

    isCheckingStatus = false;
    isLoading = false;
    notifyListeners();
  }

  Future<void> getPackageList(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/customer/purchase-packages'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['packages'] != null) {
          packageList = [];
          for (var package in data['packages']) {
            packageList.add(CustomerPackageModel.fromJson(package));
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching packages: $e");
    }
  }

  Future<bool> initiatePurchase(int packageId, String token) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/customer/purchase-packages/purchase'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'package_id': packageId,
          'payment_method': 'offline_payment',
          'payment_platform': 'app',
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getCurrentActivationInvoice(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/customer/purchase-packages/current'),
        headers: _getHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['invoice'] != null) {
          currentInvoice = ActivationInvoiceModel.fromJson(data['invoice']);
        } else {
          currentInvoice = null;
        }
      }
    } catch (e) {
      debugPrint("Error fetching invoice: $e");
      currentInvoice = null;
    }
  }
}

// =========================================================================
// 3. SCREEN UI
// =========================================================================

class CustomerPackagesScreen extends StatefulWidget {
  final String userToken; 

  const CustomerPackagesScreen({Key? key, required this.userToken}) : super(key: key);

  @override
  State<CustomerPackagesScreen> createState() => _CustomerPackagesScreenState();
}

class _CustomerPackagesScreenState extends State<CustomerPackagesScreen> {
  final CustomerPackageController _controller = CustomerPackageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.initializeData(widget.userToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: const Text(
              'حالة تنشيط الحساب',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: _controller.isCheckingStatus || _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _controller.currentInvoice != null && _controller.currentInvoice!.status == 'active'
                  ? _buildActivePackageSubscribed()
                  : _controller.currentInvoice != null && _controller.currentInvoice!.status == 'pending'
                      ? _buildPendingReviewStatus()
                      : _buildPackagesListUsage(),
        );
      },
    );
  }

  Widget _buildActivePackageSubscribed() {
    final invoice = _controller.currentInvoice;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 90),
            const SizedBox(height: 20),
            const Text(
              'حسابك نشط ومفعّل بالفعل!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'أنت مشترك حالياً في: ${invoice?.package?.name ?? "الباقة الأساسية"}',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 25),

// 📊 كروت عرض الحد المالي للباقة ومبلغ التأمين
Row(
  children: [
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الحد المالي للشراء', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('${invoice?.package?.purchaseLimit ?? 0} \$', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مبلغ التأمين المسترد', style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('${invoice?.insurance?.amount ?? 0} \$', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
          ],
        ),
      ),
    ),
  ],
),
const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                 _buildInvoiceRow('رقم الفاتورة:', '${invoice?.invoiceNo}'),
                 const Divider(),
                 _buildInvoiceRow('سعر الباقة الأساسي:', '${invoice?.package?.price ?? 0} \$'), // 👈 سطر جديد
                 const Divider(),
                _buildInvoiceRow('مبلغ التأمين المسترد:', '${invoice?.insurance?.amount ?? 0} \$'), // 👈 سطر جديد
                const Divider(),
                _buildInvoiceRow('إجمالي مدفوعاتك:', '${invoice?.totalAmount} \$'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('الذهاب للرئيسية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingReviewStatus() {
    final invoice = _controller.currentInvoice;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 85),
            const SizedBox(height: 24),
            const Text(
              'طلب التنشيط قيد المراجعة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'لقد قمت بطلب باقة (${invoice?.package?.name ?? ""}) وإرسال بيانات تحويل الأموال أوفلاين بنجاح. جاري مراجعة طلبك وتنشيط حسابك من قبل الإدارة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300, width: 1), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _controller.initializeData(widget.userToken), 
              icon: const Icon(Icons.refresh, color: Colors.black87),
              label: const Text('تحديث الحالة', style: TextStyle(color: Colors.black87)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesListUsage() {
    if (_controller.packageList.isEmpty) {
      return const Center(child: Text('لا توجد باقات متاحة حالياً في لوحة التحكم'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade800, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تم استلام طلب المنتجات بنجاح وجاري مراجعته. يرجى اختيار وتفعيل باقة المشتري لتنشيط حسابك بالكامل وإتمام العملية.',
                    style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'الباقات المتاحة لحسابك:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _controller.packageList.length,
            itemBuilder: (context, index) {
              final package = _controller.packageList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              package.name ?? '',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '${package.price ?? 0} \$',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.description ?? 'لا يوجد وصف متاح لهذه الباقة',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'صلاحية الباقة: ${package.durationInDays ?? 0} يوم  |  حد الطلبات: ${package.orderLimit ?? 0}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                          ),
                          
                          if (package.advantages != null && package.advantages!.isNotEmpty) ...[
                            const Divider(height: 24),
                            const Text(
                              'المميزات:',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...package.advantages!.map((adv) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Text(adv, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                                ],
                              ),
                            )).toList(),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                if (package.id != null) {
                                  bool success = await _controller.initiatePurchase(package.id!, widget.userToken);
                                  
                                  if (success) {
                                    await _controller.getCurrentActivationInvoice(widget.userToken);
                                    
                                    if (_controller.currentInvoice != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('تم تجهيز الفاتورة لباقة: ${package.name}')),
                                      );
                                      
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OfflinePaymentScreen(
                                            payableAmount: _controller.currentInvoice!.totalAmount ?? 0.0,
                                            callback: (bool isSuccess) {
                                              if(isSuccess) {
                                                _controller.initializeData(widget.userToken);
                                              }
                                            },
                                          ),
                                        ),
                                      ).then((_) {
                                        _controller.initializeData(widget.userToken);
                                      });
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('حدث خطأ أثناء حجز الباقة بالسيرفر')),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'اشترك الآن وفعل حسابك',
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}