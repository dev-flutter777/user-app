import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'customer_packages_screen.dart'; // عشان يقدر يقرأ موديل الفاتورة والـ Controller

class OfflinePaymentScreen extends StatefulWidget {
  final ActivationInvoiceModel invoice; // الفاتورة الحقيقية اللي جاية من السيرفر مدمج بها التأمين
  final String token; // توكن العميل

  const OfflinePaymentScreen({Key? key, required this.invoice, required this.token}) : super(key: key);

  @override
  State<OfflinePaymentScreen> createState() => _OfflinePaymentScreenState();
}

class _OfflinePaymentScreenState extends State<OfflinePaymentScreen> {
  final CustomerPackageController _controller = CustomerPackageController();
  
  // حقول الإدخال لبيانات التحويل الأوفلاين
  final TextEditingController _walletInfoController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    // حساب الأرقام بدقة من السيرفر
    double packagePrice = widget.invoice.package?.price ?? 0.0;
    double insuranceAmount = widget.invoice.insurance?.amount ?? 0.0;
    double totalAmount = widget.invoice.totalAmount ?? (packagePrice + insuranceAmount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'تفاصيل الفاتورة والدفع',
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
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. كارت تفاصيل الحسبة المالية الحقيقية (الباقة + التأمين)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رقم الفاتورة: #${widget.invoice.invoiceNo ?? widget.invoice.id}',
                              style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 24),
                            
                            // سعر الباقة المختارة
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('سعر باقة (${widget.invoice.package?.name ?? "المختارة"}):', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                Text('$packagePrice \$', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // قيمة التأمين الإجباري المحسوب من الأدمن
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Text('رسوم تأمين الحساب ', style: TextStyle(fontSize: 14, color: Colors.black87)),
                                    Text('(مستردة)', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text('$insuranceAmount \$', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                            const Divider(height: 32, thickness: 1.2),
                            
                            // الإجمالي الكلي المطلوب سداده أوفلاين
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('الإجمالي المطلوب سداده:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                Text('$totalAmount \$', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. حقول إدخال بيانات التحويل (المحفظة والـ Transaction ID)
                      const Text('بيانات التحويل الأوفلاين:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _walletInfoController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'اكتب هنا: اسم المحفظة المحول منها، رقم الهاتف، والـ Transaction ID الخاص بالعملية...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى كتابة تفاصيل التحويل ليتسنى للأدمن مراجعتها';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'ملاحظات إضافية للأدمن (اختياري)',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          fillColor: Colors.white,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 3. زرار إرسال التأكيد النهائي وتغيير الحالة في الأدمن بانل
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // إرسال البيانات مشفرة base64 مباشرة للسيرفر
                              bool paymentSuccess = await _controller.submitOfflinePayment(
                                invoiceId: widget.invoice.id!,
                                methodId: 1, // رقم طريقة الدفع المعرفة في الأدمن (مثال: محفظة كاش = 1)
                                walletInfo: _walletInfoController.text,
                                note: _noteController.text,
                                token: widget.token,
                              );

                              if (paymentSuccess) {
                                // عرض ديايلوج النجاح والعودة للتطبيق
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green),
                                        SizedBox(width: 8),
                                        Text('تم إرسال طلبك'),
                                      ],
                                    ),
                                    content: const Text('تم استلام بيانات الدفع بنجاح. جاري مراجعة طلب تفعيل الباقة والتأمين من قبل الإدارة لتنشيط حسابك.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context); // قفل الديايلوج
                                          Navigator.pop(context); // العودة من شاشة الدفع
                                          Navigator.pop(context); // العودة من شاشة الباقات إلى التطبيق الأساسي
                                        },
                                        child: const Text('حسناً'),
                                      )
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('حدث خطأ أثناء إرسال بيانات الدفع أوفلاين')),
                                );
                              }
                            }
                          },
                          child: const Text('تأكيد الدفع وإرسال الطلب', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_controller.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}