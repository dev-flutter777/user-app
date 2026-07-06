import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'offline_payment_screen.dart'; // <--- تم إضافة الـ import هنا لربط الشاشتين

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
  String? status;
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
  final String baseUrl = "https://yourdomain.com"; // اكتب هنا الدومين بتاع موقعك الأساسي

  List<CustomerPackageModel> packageList = [];
  ActivationInvoiceModel? currentInvoice;
  bool isLoading = false;

  Map<String, String> _getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> getPackageList(String token) async {
    isLoading = true;
    notifyListeners();
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
    isLoading = false;
    notifyListeners();
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
      isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
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
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching invoice: $e");
    }
  }

  Future<bool> submitOfflinePayment({
    required int invoiceId,
    required int methodId,
    required String walletInfo,
    required String token,
    String? note,
  }) async {
    isLoading = true;
    notifyListeners();

    String encodedInfo = base64Encode(utf8.encode(walletInfo));

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/customer/purchase-packages/pay-by-offline-payment'),
        headers: _getHeaders(token),
        body: jsonEncode({
          'activation_invoice_id': invoiceId,
          'method_id': methodId,
          'method_informations': encodedInfo,
          'payment_note': note ?? 'طلب تفعيل باقة وتأمين حساب أوفلاين',
        }),
      );
      
      isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } catch (e) {
      isLoading = false;
      notifyListeners();
      return false;
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
      _controller.getPackageList(widget.userToken);
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
              'تنشيط الحساب - باقات العملاء',
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
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator()) 
              : _controller.packageList.isEmpty
                  ? const Center(child: Text('لا توجد باقات متاحة حالياً في لوحة التحكم'))
                  : SingleChildScrollView(
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
                                    'تم استلام طلب المنتجات بنجاح وجاري مراجعته. يرجى اختيار وتفعيل باقة المشتري (Customer Package) لتنشيط حسابك بالكامل وإتمام العملية.',
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
                                                      
                                                      // <--- هنا تم وضع زرار الـ Navigator الفعلي والانتقال بنجاح لشاشة الدفع
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => OfflinePaymentScreen(
                                                            invoice: _controller.currentInvoice!,
                                                            token: widget.userToken,
                                                          ),
                                                        ),
                                                      );
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
                    ),
        );
      },
    );
  }
}