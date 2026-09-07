import 'package:google_maps_flutter/google_maps_flutter.dart';

class EgyptLocationHelper {
  /// Canonical values shared with the administration's Egypt shipping zones.
  static const List<String> governorates = [
    'القاهرة', 'الجيزة', 'الإسكندرية', 'الدقهلية', 'البحر الأحمر', 'البحيرة',
    'الفيوم', 'الغربية', 'الإسماعيلية', 'المنوفية', 'المنيا', 'القليوبية',
    'الوادي الجديد', 'السويس', 'أسوان', 'أسيوط', 'بني سويف', 'بورسعيد',
    'دمياط', 'الشرقية', 'جنوب سيناء', 'كفر الشيخ', 'مطروح', 'الأقصر',
    'قنا', 'شمال سيناء', 'سوهاج',
  ];

  static const LatLng center = LatLng(26.8206, 30.8025);
  static final LatLngBounds bounds = LatLngBounds(
    southwest: const LatLng(21.70, 24.70),
    northeast: const LatLng(31.80, 37.10),
  );

  static bool contains(LatLng point) =>
      point.latitude >= bounds.southwest.latitude &&
      point.latitude <= bounds.northeast.latitude &&
      point.longitude >= bounds.southwest.longitude &&
      point.longitude <= bounds.northeast.longitude;

  static LatLng normalize(LatLng point) => contains(point) ? point : center;
}
