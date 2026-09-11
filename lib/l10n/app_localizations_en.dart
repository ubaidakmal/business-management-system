// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Business Management';

  @override
  String get tagline => 'Simple tools for purchases, sales, stock, and profit.';

  @override
  String get splashMessage => 'Loading workspace…';

  @override
  String get loading => 'Loading';

  @override
  String get retry => 'Try again';

  @override
  String get emptyTitle => 'Nothing here yet';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get sessionExpired => 'Please sign in to continue.';

  @override
  String get welcome => 'Welcome';

  @override
  String get phasePlaceholder => 'This module will be built in a later phase.';

  @override
  String get all => 'All';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get add => 'Add';

  @override
  String get refresh => 'Refresh';

  @override
  String get search => 'Search';

  @override
  String get status => 'Status';

  @override
  String get date => 'Date';

  @override
  String get notes => 'Notes';

  @override
  String get actions => 'Actions';

  @override
  String get complete => 'Complete';

  @override
  String get draft => 'Draft';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get back => 'Back';

  @override
  String get emDash => '—';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navCompanies => 'Companies';

  @override
  String get navProducts => 'Products';

  @override
  String get navPurchases => 'Purchases';

  @override
  String get navSales => 'Sales';

  @override
  String get navStock => 'Stock';

  @override
  String get navMarket => 'Market';

  @override
  String get navReports => 'Reports';

  @override
  String get navSettings => 'Settings';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Use your work email to continue.';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String signOutConfirm(String businessName) {
    return 'Sign out of $businessName?';
  }

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we will send a reset link.';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get resetEmailSent =>
      'If an account exists for that email, a reset link has been sent.';

  @override
  String get backToLogin => 'Back to sign in';

  @override
  String get newPasswordTitle => 'Choose a new password';

  @override
  String get newPasswordSubtitle =>
      'Enter and confirm your new password to finish resetting.';

  @override
  String get updatePassword => 'Update password';

  @override
  String get passwordUpdated => 'Password updated successfully.';

  @override
  String get nameLabel => 'Name';

  @override
  String get roleLabel => 'Role';

  @override
  String get profileTitle => 'Profile';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get profileUpdated => 'Profile updated.';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardLoading => 'Loading dashboard…';

  @override
  String get dashboardEmptyTitle => 'No dashboard data';

  @override
  String get dashboardEmptyMessage => 'Pull to refresh or adjust filters.';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get totalPurchases => 'Total Purchases';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get totalCogs => 'Total COGS';

  @override
  String get totalProfit => 'Total Profit';

  @override
  String get numberOfSales => 'Number of Sales';

  @override
  String get numberOfPurchases => 'Number of Purchases';

  @override
  String get salesAndProfitTrend => 'Sales & profit trend';

  @override
  String get salesAndProfitTrendSubtitle =>
      'Completed sales in the selected range';

  @override
  String get inventory => 'Inventory';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get recentSales => 'Recent sales';

  @override
  String get recentPurchases => 'Recent purchases';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get quickActionsSubtitle => 'Common shortcuts';

  @override
  String get addSale => 'Add Sale';

  @override
  String get editSale => 'Edit Sale';

  @override
  String get addPurchase => 'Add Purchase';

  @override
  String get editPurchase => 'Edit Purchase';

  @override
  String get addProduct => 'Add Product';

  @override
  String get viewStock => 'View Stock';

  @override
  String get stockDetails => 'Stock Details';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This week';

  @override
  String get thisMonth => 'This month';

  @override
  String get custom => 'Custom';

  @override
  String get company => 'Company';

  @override
  String get allCompanies => 'All companies';

  @override
  String get lowStock => 'Low stock';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get productsCount => 'Products';

  @override
  String get inStock => 'In stock';

  @override
  String get companiesTitle => 'Companies';

  @override
  String get addCompany => 'Add Company';

  @override
  String get editCompany => 'Edit company';

  @override
  String get companyDetails => 'Company Details';

  @override
  String get companyName => 'Company name';

  @override
  String get companyCode => 'Company code';

  @override
  String get companyNotFound => 'Company not found';

  @override
  String get noCompaniesYet => 'No companies yet';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get city => 'City';

  @override
  String get country => 'Country';

  @override
  String get created => 'Created';

  @override
  String get updated => 'Updated';

  @override
  String get productsTitle => 'Products';

  @override
  String get product => 'Product';

  @override
  String get productDetails => 'Product Details';

  @override
  String get editProduct => 'Edit product';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get noProductsYet => 'No products yet';

  @override
  String get sku => 'SKU';

  @override
  String get category => 'Category';

  @override
  String get unit => 'Unit';

  @override
  String get barcode => 'Barcode';

  @override
  String get openingStock => 'Opening stock';

  @override
  String get reorderLevel => 'Reorder level';

  @override
  String get openingUnitCost => 'Opening unit cost';

  @override
  String get sellingPrice => 'Selling price';

  @override
  String get purchasesTitle => 'Purchases';

  @override
  String get purchase => 'Purchase';

  @override
  String get purchaseDetails => 'Purchase Details';

  @override
  String get purchaseNotFound => 'Purchase not found';

  @override
  String get noPurchasesYet => 'No purchases yet';

  @override
  String get invoice => 'Invoice';

  @override
  String get invoiceNumber => 'Invoice number';

  @override
  String get referenceNumber => 'Reference number';

  @override
  String get quantity => 'Quantity';

  @override
  String get cost => 'Cost';

  @override
  String get unitCost => 'Unit cost';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get discount => 'Discount';

  @override
  String get otherCharges => 'Other charges';

  @override
  String get total => 'Total';

  @override
  String get saveDraft => 'Save draft';

  @override
  String get completePurchase => 'Complete purchase';

  @override
  String get cancelPurchase => 'Cancel purchase?';

  @override
  String get items => 'Items';

  @override
  String get salesTitle => 'Sales';

  @override
  String get sale => 'Sale';

  @override
  String get saleDetails => 'Sale Details';

  @override
  String get saleNotFound => 'Sale not found';

  @override
  String get noSalesYet => 'No sales yet';

  @override
  String get price => 'Price';

  @override
  String get unitPrice => 'Unit price';

  @override
  String get completeSale => 'Complete sale';

  @override
  String get cancelSale => 'Cancel sale';

  @override
  String get cogs => 'COGS';

  @override
  String get profit => 'Profit';

  @override
  String get revenue => 'Revenue';

  @override
  String get grossProfit => 'Gross Profit';

  @override
  String get stockTitle => 'Stock';

  @override
  String get stockInventory => 'Inventory';

  @override
  String get currentStock => 'Current stock';

  @override
  String get stockAdjustment => 'Stock Adjustment';

  @override
  String get adjustStock => 'Adjust stock';

  @override
  String get movementHistory => 'Movement history';

  @override
  String get noStockRows => 'No stock rows';

  @override
  String get stockIn => 'Stock in';

  @override
  String get stockOut => 'Stock out';

  @override
  String get direction => 'Direction';

  @override
  String get reason => 'Reason';

  @override
  String get saveAdjustment => 'Save adjustment';

  @override
  String get stockAdjusted => 'Stock adjusted.';

  @override
  String get low => 'Low';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get reportsSubtitle =>
      'Database-driven summaries with PDF, Excel, and print export.';

  @override
  String get salesReports => 'Sales Reports';

  @override
  String get salesReportsSubtitle => 'Revenue, COGS, and profit by invoice';

  @override
  String get purchaseReports => 'Purchase Reports';

  @override
  String get purchaseReportsSubtitle =>
      'Completed purchases by date and company';

  @override
  String get profitReports => 'Profit Reports';

  @override
  String get profitReportsSubtitle => 'Stored FIFO COGS and gross profit';

  @override
  String get stockReports => 'Stock Reports';

  @override
  String get stockReportsSubtitle => 'Balances, low stock, and movements';

  @override
  String get productReports => 'Product Reports';

  @override
  String get productReportsSubtitle => 'Quantity sold and profit contribution';

  @override
  String get companyReports => 'Company Reports';

  @override
  String get companyReportsSubtitle =>
      'Sales, purchases, and profit by company';

  @override
  String get salesReport => 'Sales Report';

  @override
  String get purchaseReport => 'Purchase Report';

  @override
  String get profitReport => 'Profit Report';

  @override
  String get stockReport => 'Stock Report';

  @override
  String get productReport => 'Product Report';

  @override
  String get companyReport => 'Company Report';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get print => 'Print';

  @override
  String get printShare => 'Print / Share';

  @override
  String get exportLoadFirst => 'Load the report before exporting.';

  @override
  String get pdfReady => 'PDF ready.';

  @override
  String get excelSaved => 'Excel file saved.';

  @override
  String get dateAll => 'Date: All';

  @override
  String dateRange(String from, String to) {
    return 'Date: $from → $to';
  }

  @override
  String get companyAll => 'Company: All';

  @override
  String companyFilter(String name) {
    return 'Company: $name';
  }

  @override
  String get productsShown => 'Products shown';

  @override
  String get qtySold => 'Qty Sold';

  @override
  String get salesTotal => 'Sales Total';

  @override
  String get purchasesTotal => 'Purchases Total';

  @override
  String get profitTotal => 'Profit Total';

  @override
  String get code => 'Code';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Account, business profile, and administration';

  @override
  String get workspace => 'Workspace';

  @override
  String get security => 'Security';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Choose the app display language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageSaved => 'Language updated.';

  @override
  String get businessProfile => 'Business profile';

  @override
  String get businessProfileSubtitle =>
      'Name, contact, and address used in reports';

  @override
  String get preferences => 'Preferences';

  @override
  String get preferencesSubtitle => 'Currency and display formats';

  @override
  String get marketSettings => 'Market settings';

  @override
  String get marketSettingsSubtitle => 'Enable rates and configure currencies';

  @override
  String get rolesPermissions => 'Roles & permissions';

  @override
  String get rolesPermissionsSubtitle => 'What your role can do in the app';

  @override
  String get administration => 'Administration';

  @override
  String get administrationSubtitle => 'Users and system overview';

  @override
  String get users => 'Users';

  @override
  String get roles => 'Roles';

  @override
  String get permissions => 'Permissions';

  @override
  String get businessSettings => 'Business settings';

  @override
  String get adminOverview => 'Administration';

  @override
  String get adminUsers => 'Users';

  @override
  String get userDetails => 'User details';

  @override
  String get userNotFound => 'User not found';

  @override
  String get displayName => 'Display name';

  @override
  String get saveUser => 'Save user';

  @override
  String get marketTitle => 'Market';

  @override
  String get exchangeRate => 'Exchange rate';

  @override
  String get exchangeRates => 'Exchange rates';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get dataSource => 'Source';

  @override
  String get marketDisabled => 'Market data is disabled in settings.';

  @override
  String get noMarketData => 'No market rates yet';

  @override
  String get noMarketDataMessage => 'Tap Refresh to fetch live rates.';

  @override
  String get marketHistory => 'History';

  @override
  String get loadingMarket => 'Loading market data…';
}
