class ShippingMethodModel {
  int? id;
  String? creatorType;
  String? title;
  double? cost;
  String? duration;
  String? createdAt;
  String? updatedAt;
  String? optionKey;
  String? promiseMode;
  int? minimumBusinessDays;
  int? maximumBusinessDays;
  DateTime? estimatedFrom;
  DateTime? estimatedTo;
  String? estimatedLabel;

  ShippingMethodModel(
      {this.id,
        this.creatorType,
        this.title,
        this.cost,
        this.duration,
        this.createdAt,
        this.updatedAt,
        this.optionKey,
        this.promiseMode,
        this.minimumBusinessDays,
        this.maximumBusinessDays,
        this.estimatedFrom,
        this.estimatedTo,
        this.estimatedLabel});



  ShippingMethodModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    creatorType = json['creator_type'];
    title = json['title'];
    if(json['cost'] != null){
      try{
        cost = json['cost'].toDouble();
      }catch(e){
        cost = double.parse(json['cost'].toString());
      }
    }

    duration = json['duration'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    optionKey = json['option_key'];
    promiseMode = json['promise_mode'];
    minimumBusinessDays = int.tryParse('${json['minimum_business_days'] ?? ''}');
    maximumBusinessDays = int.tryParse('${json['maximum_business_days'] ?? ''}');
    estimatedFrom = DateTime.tryParse('${json['estimated_from'] ?? ''}');
    estimatedTo = DateTime.tryParse('${json['estimated_to'] ?? ''}');
    estimatedLabel = json['estimated_label'];
  }

}
