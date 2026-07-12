import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/offline_payment/screens/offline_payment_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/customer_packages/controllers/customer_package_controller.dart';

class PackageCheckoutScreen extends StatelessWidget {
  final CustomerPackageModel package;
  final double insuranceAmount;
  final String userToken;
  final int? invoiceId;

  const PackageCheckoutScreen({
    Key? key,
    required this.package,
    required this.insuranceAmount,
    required this.userToken,
    required this.invoiceId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double packagePrice = package.price ?? 0.0;
    double totalAmount = packagePrice + insuranceAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'مراجعة وتأكيد الاشتراك',
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                package.name ?? 'اسم الباقة',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF212529)),
                              ),
                              Text(
                                '\$$packagePrice',
                                // ✅ تعديل الوزن من black إلى w900 لحل الخطأ نهائياً
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            package.description ?? '',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'الملخص المالي الفعلي',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF495057)),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Column(
                        children: [
                          _buildAmountRow('قيمة اشتراك الباقة', '\$$packagePrice'),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(color: Color(0xFFF1F3F5), height: 1),
                          ),
                          _buildAmountRow('مبلغ التأمين المسترد', '\$$insuranceAmount', isSubText: true),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(color: Color(0xFFF1F3F5), height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'إجمالي المطلوب سداده',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF212529)),
                              ),
                              Text(
                                '\$$totalAmount',
                                // ✅ تعديل الوزن من black إلى w900 لحل الخطأ نهائياً
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                ]
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OfflinePaymentScreen(
                          payableAmount: totalAmount,
                          callback: (bool isSuccess) {
                            if (isSuccess) {
                              Navigator.pop(context); 
                            }
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'تأكيد والانتقال للدفع اليدوي',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String title, String value, {bool isSubText = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF495057))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.bold, 
            color: isSubText ? Colors.purple : const Color(0xFF212529)
          ),
        ),
      ],
    );
  }
}