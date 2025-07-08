class Voucher {
  final String code;
  final int discount;
  final int quota;
  final int used;
  final DateTime? expiredAt;

  Voucher({
    required this.code,
    required this.discount,
    required this.quota,
    required this.used,
    this.expiredAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      code: json['code'] ?? '',
      discount: _parseToInt(json['discount']),
      quota: _parseToInt(json['quota']),
      used: _parseToInt(json['used']),
      expiredAt: json['expired_at'] != null
          ? DateTime.tryParse(json['expired_at'])
          : null,
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return double.tryParse(value)?.round() ?? 0;
    return 0;
  }
}
