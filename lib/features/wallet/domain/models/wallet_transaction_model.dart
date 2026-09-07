import 'package:flutter_sixvalley_ecommerce/helper/date_converter.dart';

class WalletTransactionModel {
  int? limit;
  int? offset;
  int? totalSize;
  double? totalWalletBalance;
  double? insuranceAvailableBalance;
  double? insuranceHeldBalance;
  String? insuranceNextMaturityAt;
  List<CustomerInsuranceLedgerEntry>? insuranceLedgerEntries;
  String? filterBy;
  DateTime? startDate;
  DateTime? endDate;
  List<String>? transactionTypes;
  List<WalletTransactionList>? walletTransactionList;
  

  WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    limit = int.tryParse('${json['limit']}');
    offset = int.tryParse('${json['offset']}');
    totalSize = int.tryParse('${json['total_size']}');
    filterBy = json['filter_by'];
    startDate = DateConverter.convertDurationDateTimeFromString(json['start_date']);
    endDate = DateConverter.convertDurationDateTimeFromString(json['end_date']);

    if (json['transaction_types'] != null) {
      transactionTypes = List<String>.from(json['transaction_types'].map((id) => id.toString()));
    }

    totalWalletBalance = double.tryParse('${json['total_wallet_balance'] ?? 0}') ?? 0;
    insuranceAvailableBalance = double.tryParse('${json['insurance_available_balance'] ?? 0}') ?? 0;
    insuranceHeldBalance = double.tryParse('${json['insurance_held_balance'] ?? 0}') ?? 0;
    insuranceNextMaturityAt = json['insurance_next_maturity_at'];
    insuranceLedgerEntries = (json['insurance_ledger_entries'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => CustomerInsuranceLedgerEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);

    if (json['wallet_transaction_list'] != null) {
      walletTransactionList = <WalletTransactionList>[];
      json['wallet_transaction_list'].forEach((v) {
        walletTransactionList!.add(WalletTransactionList.fromJson(v));
      });
    }
  }

}

class CustomerInsuranceLedgerEntry {
  final int id;
  final int? orderId;
  final String entryType;
  final double credit;
  final double debit;
  final String? createdAt;

  const CustomerInsuranceLedgerEntry({
    required this.id,
    this.orderId,
    required this.entryType,
    required this.credit,
    required this.debit,
    this.createdAt,
  });

  factory CustomerInsuranceLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CustomerInsuranceLedgerEntry(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      orderId: int.tryParse('${json['order_id'] ?? ''}'),
      entryType: json['entry_type']?.toString() ?? '',
      credit: double.tryParse('${json['credit'] ?? 0}') ?? 0,
      debit: double.tryParse('${json['debit'] ?? 0}') ?? 0,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class WalletTransactionList {
  int? _id;
  int? _userId;
  String? _transactionId;
  double? _credit;
  double? _debit;
  double? _adminBonus;
  double? _balance;
  String? _transactionType;
  String? _reference;
  String? _createdAt;
  String? _updatedAt;
  String? paymentMethod;

  WalletTransactionList(
      {int? id,
        int? userId,
        String? transactionId,
        double? credit,
        double? debit,
        double? adminBonus,
        double? balance,
        String? transactionType,
        String? reference,
        String? createdAt,
        String? updatedAt,
        String? paymentMethod
      }) {
    if (id != null) {
      _id = id;
    }
    if (userId != null) {
      _userId = userId;
    }
    if (transactionId != null) {
      _transactionId = transactionId;
    }
    if (credit != null) {
      _credit = credit;
    }
    if (debit != null) {
      _debit = debit;
    }
    if (adminBonus != null) {
      _adminBonus = adminBonus;
    }
    if (balance != null) {
      _balance = balance;
    }
    if (transactionType != null) {
      _transactionType = transactionType;
    }
    if (reference != null) {
      _reference = reference;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
    this.paymentMethod;
  }

  int? get id => _id;
  int? get userId => _userId;
  String? get transactionId => _transactionId;
  double? get credit => _credit;
  double? get debit => _debit;
  double? get adminBonus => _adminBonus;
  double? get balance => _balance;
  String? get transactionType => _transactionType;
  String? get reference => _reference;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;

  WalletTransactionList.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _userId = json['user_id'];
    _transactionId = json['transaction_id'];
    _credit = json['credit'].toDouble();
    _debit = json['debit'].toDouble();
    _adminBonus = json['admin_bonus'].toDouble();
    _balance = json['balance'].toDouble();
    _transactionType = json['transaction_type'];
    _reference = json['reference'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    paymentMethod = json['payment_method'];
  }

}
