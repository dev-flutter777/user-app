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