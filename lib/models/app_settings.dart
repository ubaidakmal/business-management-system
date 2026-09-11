class AppSettings {
  const AppSettings({
    required this.businessName,
    required this.defaultCurrency,
    required this.dateFormat,
    required this.numberFormat,
    this.logoUrl,
    this.contactEmail,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.marketEnabled = true,
    this.marketBaseCurrency = 'USD',
    this.marketQuoteCurrencies = 'PKR,EUR,GBP,AED',
    this.updatedAt,
    this.updatedBy,
  });

  final String businessName;
  final String? logoUrl;
  final String? contactEmail;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String defaultCurrency;
  final String dateFormat;
  final String numberFormat;
  final bool marketEnabled;
  final String marketBaseCurrency;
  final String marketQuoteCurrencies;
  final DateTime? updatedAt;
  final String? updatedBy;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      businessName:
          (json['business_name'] as String?)?.trim().isNotEmpty == true
          ? (json['business_name'] as String).trim()
          : 'Business Management',
      logoUrl: json['logo_url'] as String?,
      contactEmail: json['contact_email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      defaultCurrency: json['default_currency'] as String? ?? 'PKR',
      dateFormat: json['date_format'] as String? ?? 'yyyy-MM-dd',
      numberFormat: json['number_format'] as String? ?? '1,234.56',
      marketEnabled: json['market_enabled'] as bool? ?? true,
      marketBaseCurrency:
          (json['market_base_currency'] as String?)?.trim().isNotEmpty == true
          ? (json['market_base_currency'] as String).trim().toUpperCase()
          : 'USD',
      marketQuoteCurrencies:
          (json['market_quote_currencies'] as String?)?.trim().isNotEmpty ==
              true
          ? (json['market_quote_currencies'] as String).trim().toUpperCase()
          : 'PKR,EUR,GBP,AED',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'business_name': businessName.trim(),
      'logo_url': logoUrl?.trim().isEmpty == true ? null : logoUrl?.trim(),
      'contact_email': contactEmail?.trim().isEmpty == true
          ? null
          : contactEmail?.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'address': address?.trim().isEmpty == true ? null : address?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
      'country': country?.trim().isEmpty == true ? null : country?.trim(),
      'default_currency': defaultCurrency.trim().isEmpty
          ? 'PKR'
          : defaultCurrency.trim(),
      'date_format': dateFormat.trim().isEmpty
          ? 'yyyy-MM-dd'
          : dateFormat.trim(),
      'number_format': numberFormat.trim().isEmpty
          ? '1,234.56'
          : numberFormat.trim(),
      'market_enabled': marketEnabled,
      'market_base_currency': marketBaseCurrency.trim().isEmpty
          ? 'USD'
          : marketBaseCurrency.trim().toUpperCase(),
      'market_quote_currencies': marketQuoteCurrencies.trim().isEmpty
          ? 'PKR,EUR,GBP,AED'
          : marketQuoteCurrencies.trim().toUpperCase(),
    };
  }

  AppSettings copyWith({
    String? businessName,
    String? logoUrl,
    String? contactEmail,
    String? phone,
    String? address,
    String? city,
    String? country,
    String? defaultCurrency,
    String? dateFormat,
    String? numberFormat,
    bool? marketEnabled,
    String? marketBaseCurrency,
    String? marketQuoteCurrencies,
  }) {
    return AppSettings(
      businessName: businessName ?? this.businessName,
      logoUrl: logoUrl ?? this.logoUrl,
      contactEmail: contactEmail ?? this.contactEmail,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      dateFormat: dateFormat ?? this.dateFormat,
      numberFormat: numberFormat ?? this.numberFormat,
      marketEnabled: marketEnabled ?? this.marketEnabled,
      marketBaseCurrency: marketBaseCurrency ?? this.marketBaseCurrency,
      marketQuoteCurrencies:
          marketQuoteCurrencies ?? this.marketQuoteCurrencies,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }

  static const defaults = AppSettings(
    businessName: 'Business Management',
    defaultCurrency: 'PKR',
    dateFormat: 'yyyy-MM-dd',
    numberFormat: '1,234.56',
  );
}

class AdminOverview {
  const AdminOverview({
    required this.usersTotal,
    required this.usersActive,
    required this.usersAdmins,
    required this.companiesTotal,
    required this.companiesActive,
    required this.productsTotal,
    required this.productsActive,
  });

  final int usersTotal;
  final int usersActive;
  final int usersAdmins;
  final int companiesTotal;
  final int companiesActive;
  final int productsTotal;
  final int productsActive;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AdminOverview(
      usersTotal: read('users_total'),
      usersActive: read('users_active'),
      usersAdmins: read('users_admins'),
      companiesTotal: read('companies_total'),
      companiesActive: read('companies_active'),
      productsTotal: read('products_total'),
      productsActive: read('products_active'),
    );
  }

  static const empty = AdminOverview(
    usersTotal: 0,
    usersActive: 0,
    usersAdmins: 0,
    companiesTotal: 0,
    companiesActive: 0,
    productsTotal: 0,
    productsActive: 0,
  );
}
