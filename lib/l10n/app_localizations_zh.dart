// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '業務管理系統';

  @override
  String get tagline => '簡單好用的進貨、銷售、庫存與利潤工具。';

  @override
  String get splashMessage => '正在載入工作區…';

  @override
  String get loading => '載入中';

  @override
  String get retry => '再試一次';

  @override
  String get emptyTitle => '目前沒有資料';

  @override
  String get errorTitle => '發生錯誤';

  @override
  String get sessionExpired => '請登入後繼續。';

  @override
  String get welcome => '歡迎';

  @override
  String get phasePlaceholder => '此模組將於之後的階段建立。';

  @override
  String get all => '全部';

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get edit => '編輯';

  @override
  String get delete => '刪除';

  @override
  String get add => '新增';

  @override
  String get refresh => '重新整理';

  @override
  String get search => '搜尋';

  @override
  String get status => '狀態';

  @override
  String get date => '日期';

  @override
  String get notes => '備註';

  @override
  String get actions => '操作';

  @override
  String get complete => '完成';

  @override
  String get draft => '草稿';

  @override
  String get completed => '已完成';

  @override
  String get cancelled => '已取消';

  @override
  String get active => '啟用';

  @override
  String get inactive => '停用';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get back => '返回';

  @override
  String get emDash => '—';

  @override
  String get navDashboard => '儀表板';

  @override
  String get navCompanies => '公司';

  @override
  String get navProducts => '產品';

  @override
  String get navPurchases => '進貨';

  @override
  String get navSales => '銷售';

  @override
  String get navStock => '庫存';

  @override
  String get navMarket => '市場';

  @override
  String get navReports => '報表';

  @override
  String get navSettings => '設定';

  @override
  String get loginTitle => '登入';

  @override
  String get loginSubtitle => '請使用公司電子郵件繼續。';

  @override
  String get emailLabel => '電子郵件';

  @override
  String get passwordLabel => '密碼';

  @override
  String get confirmPasswordLabel => '確認密碼';

  @override
  String get signIn => '登入';

  @override
  String get signOut => '登出';

  @override
  String signOutConfirm(String businessName) {
    return '確定要登出 $businessName？';
  }

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get forgotPasswordTitle => '重設密碼';

  @override
  String get forgotPasswordSubtitle => '輸入電子郵件，我們將寄送重設連結。';

  @override
  String get sendResetLink => '寄送重設連結';

  @override
  String get resetEmailSent => '若該電子郵件已註冊帳號，重設連結已寄出。';

  @override
  String get backToLogin => '返回登入';

  @override
  String get newPasswordTitle => '設定新密碼';

  @override
  String get newPasswordSubtitle => '輸入並確認新密碼以完成重設。';

  @override
  String get updatePassword => '更新密碼';

  @override
  String get passwordUpdated => '密碼已成功更新。';

  @override
  String get nameLabel => '姓名';

  @override
  String get roleLabel => '角色';

  @override
  String get profileTitle => '個人資料';

  @override
  String get saveProfile => '儲存個人資料';

  @override
  String get profileUpdated => '個人資料已更新。';

  @override
  String get dashboardTitle => '儀表板';

  @override
  String get dashboardLoading => '正在載入儀表板…';

  @override
  String get dashboardEmptyTitle => '沒有儀表板資料';

  @override
  String get dashboardEmptyMessage => '下拉重新整理或調整篩選條件。';

  @override
  String get totalSales => '銷售總額';

  @override
  String get totalPurchases => '進貨總額';

  @override
  String get totalRevenue => '營業收入';

  @override
  String get totalCogs => '銷貨成本';

  @override
  String get totalProfit => '總利潤';

  @override
  String get numberOfSales => '銷售筆數';

  @override
  String get numberOfPurchases => '進貨筆數';

  @override
  String get salesAndProfitTrend => '銷售與利潤趨勢';

  @override
  String get salesAndProfitTrendSubtitle => '選定期間內已完成的銷售';

  @override
  String get inventory => '庫存';

  @override
  String get recentActivity => '最近活動';

  @override
  String get recentSales => '最近銷售';

  @override
  String get recentPurchases => '最近進貨';

  @override
  String get quickActions => '快捷操作';

  @override
  String get quickActionsSubtitle => '常用捷徑';

  @override
  String get addSale => '新增銷售';

  @override
  String get editSale => '編輯銷售';

  @override
  String get addPurchase => '新增進貨';

  @override
  String get editPurchase => '編輯進貨';

  @override
  String get addProduct => '新增產品';

  @override
  String get viewStock => '查看庫存';

  @override
  String get stockDetails => '庫存詳情';

  @override
  String get today => '今天';

  @override
  String get thisWeek => '本週';

  @override
  String get thisMonth => '本月';

  @override
  String get custom => '自訂';

  @override
  String get company => '公司';

  @override
  String get allCompanies => '全部公司';

  @override
  String get lowStock => '低庫存';

  @override
  String get outOfStock => '缺貨';

  @override
  String get productsCount => '產品數';

  @override
  String get inStock => '有庫存';

  @override
  String get companiesTitle => '公司';

  @override
  String get addCompany => '新增公司';

  @override
  String get editCompany => '編輯公司';

  @override
  String get companyDetails => '公司詳情';

  @override
  String get companyName => '公司名稱';

  @override
  String get companyCode => '公司代碼';

  @override
  String get companyNotFound => '找不到公司';

  @override
  String get noCompaniesYet => '尚無公司';

  @override
  String get phone => '電話';

  @override
  String get address => '地址';

  @override
  String get city => '城市';

  @override
  String get country => '國家';

  @override
  String get created => '建立時間';

  @override
  String get updated => '更新時間';

  @override
  String get productsTitle => '產品';

  @override
  String get product => '產品';

  @override
  String get productDetails => '產品詳情';

  @override
  String get editProduct => '編輯產品';

  @override
  String get productNotFound => '找不到產品';

  @override
  String get noProductsYet => '尚無產品';

  @override
  String get sku => 'SKU';

  @override
  String get category => '分類';

  @override
  String get unit => '單位';

  @override
  String get barcode => '條碼';

  @override
  String get openingStock => '期初庫存';

  @override
  String get reorderLevel => '再訂購水位';

  @override
  String get openingUnitCost => '期初單位成本';

  @override
  String get sellingPrice => '售價';

  @override
  String get purchasesTitle => '進貨';

  @override
  String get purchase => '進貨';

  @override
  String get purchaseDetails => '進貨詳情';

  @override
  String get purchaseNotFound => '找不到進貨單';

  @override
  String get noPurchasesYet => '尚無進貨';

  @override
  String get invoice => '發票';

  @override
  String get invoiceNumber => '發票號碼';

  @override
  String get referenceNumber => '參考編號';

  @override
  String get quantity => '數量';

  @override
  String get cost => '成本';

  @override
  String get unitCost => '單位成本';

  @override
  String get subtotal => '小計';

  @override
  String get discount => '折扣';

  @override
  String get otherCharges => '其他費用';

  @override
  String get total => '合計';

  @override
  String get saveDraft => '儲存草稿';

  @override
  String get completePurchase => '完成進貨';

  @override
  String get cancelPurchase => '取消進貨？';

  @override
  String get items => '項目';

  @override
  String get salesTitle => '銷售';

  @override
  String get sale => '銷售';

  @override
  String get saleDetails => '銷售詳情';

  @override
  String get saleNotFound => '找不到銷售單';

  @override
  String get noSalesYet => '尚無銷售';

  @override
  String get price => '價格';

  @override
  String get unitPrice => '單價';

  @override
  String get completeSale => '完成銷售';

  @override
  String get cancelSale => '取消銷售';

  @override
  String get cogs => '銷貨成本';

  @override
  String get profit => '利潤';

  @override
  String get revenue => '收入';

  @override
  String get grossProfit => '毛利';

  @override
  String get stockTitle => '庫存';

  @override
  String get stockInventory => '庫存清單';

  @override
  String get currentStock => '目前庫存';

  @override
  String get stockAdjustment => '庫存調整';

  @override
  String get adjustStock => '調整庫存';

  @override
  String get movementHistory => '異動紀錄';

  @override
  String get noStockRows => '沒有庫存資料';

  @override
  String get stockIn => '入庫';

  @override
  String get stockOut => '出庫';

  @override
  String get direction => '方向';

  @override
  String get reason => '原因';

  @override
  String get saveAdjustment => '儲存調整';

  @override
  String get stockAdjusted => '庫存已調整。';

  @override
  String get low => '偏低';

  @override
  String get reportsTitle => '報表';

  @override
  String get reportsSubtitle => '資料庫彙總報表，支援 PDF、Excel 與列印匯出。';

  @override
  String get salesReports => '銷售報表';

  @override
  String get salesReportsSubtitle => '依發票查看收入、成本與利潤';

  @override
  String get purchaseReports => '進貨報表';

  @override
  String get purchaseReportsSubtitle => '依日期與公司查看已完成進貨';

  @override
  String get profitReports => '利潤報表';

  @override
  String get profitReportsSubtitle => '以 FIFO 儲存的成本與毛利';

  @override
  String get stockReports => '庫存報表';

  @override
  String get stockReportsSubtitle => '餘額、低庫存與異動';

  @override
  String get productReports => '產品報表';

  @override
  String get productReportsSubtitle => '銷售數量與利潤貢獻';

  @override
  String get companyReports => '公司報表';

  @override
  String get companyReportsSubtitle => '依公司查看銷售、進貨與利潤';

  @override
  String get salesReport => '銷售報表';

  @override
  String get purchaseReport => '進貨報表';

  @override
  String get profitReport => '利潤報表';

  @override
  String get stockReport => '庫存報表';

  @override
  String get productReport => '產品報表';

  @override
  String get companyReport => '公司報表';

  @override
  String get exportPdf => '匯出 PDF';

  @override
  String get exportExcel => '匯出 Excel';

  @override
  String get print => '列印';

  @override
  String get printShare => '列印／分享';

  @override
  String get exportLoadFirst => '請先載入報表再匯出。';

  @override
  String get pdfReady => 'PDF 已準備完成。';

  @override
  String get excelSaved => 'Excel 檔案已儲存。';

  @override
  String get dateAll => '日期：全部';

  @override
  String dateRange(String from, String to) {
    return '日期：$from → $to';
  }

  @override
  String get companyAll => '公司：全部';

  @override
  String companyFilter(String name) {
    return '公司：$name';
  }

  @override
  String get productsShown => '顯示產品數';

  @override
  String get qtySold => '銷售數量';

  @override
  String get salesTotal => '銷售合計';

  @override
  String get purchasesTotal => '進貨合計';

  @override
  String get profitTotal => '利潤合計';

  @override
  String get code => '代碼';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '帳號、公司資料與管理功能';

  @override
  String get workspace => '工作區';

  @override
  String get security => '安全性';

  @override
  String get language => '語言';

  @override
  String get languageSubtitle => '選擇應用程式顯示語言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageSaved => '語言已更新。';

  @override
  String get businessProfile => '公司資料';

  @override
  String get businessProfileSubtitle => '用於報表匯出的名稱、聯絡與地址';

  @override
  String get preferences => '偏好設定';

  @override
  String get preferencesSubtitle => '貨幣與顯示格式';

  @override
  String get marketSettings => '市場設定';

  @override
  String get marketSettingsSubtitle => '啟用匯率並設定幣別';

  @override
  String get rolesPermissions => '角色與權限';

  @override
  String get rolesPermissionsSubtitle => '您的角色可執行的操作';

  @override
  String get administration => '系統管理';

  @override
  String get administrationSubtitle => '使用者與系統總覽';

  @override
  String get users => '使用者';

  @override
  String get roles => '角色';

  @override
  String get permissions => '權限';

  @override
  String get businessSettings => '公司設定';

  @override
  String get adminOverview => '系統管理';

  @override
  String get adminUsers => '使用者';

  @override
  String get userDetails => '使用者詳情';

  @override
  String get userNotFound => '找不到使用者';

  @override
  String get displayName => '顯示名稱';

  @override
  String get saveUser => '儲存使用者';

  @override
  String get marketTitle => '市場';

  @override
  String get exchangeRate => '匯率';

  @override
  String get exchangeRates => '匯率行情';

  @override
  String get lastUpdated => '最後更新';

  @override
  String get dataSource => '資料來源';

  @override
  String get marketDisabled => '市場資料已在設定中停用。';

  @override
  String get noMarketData => '尚無市場匯率';

  @override
  String get noMarketDataMessage => '點選重新整理以取得即時匯率。';

  @override
  String get marketHistory => '歷史紀錄';

  @override
  String get loadingMarket => '正在載入市場資料…';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appName => '業務管理系統';

  @override
  String get tagline => '簡單好用的進貨、銷售、庫存與利潤工具。';

  @override
  String get splashMessage => '正在載入工作區…';

  @override
  String get loading => '載入中';

  @override
  String get retry => '再試一次';

  @override
  String get emptyTitle => '目前沒有資料';

  @override
  String get errorTitle => '發生錯誤';

  @override
  String get sessionExpired => '請登入後繼續。';

  @override
  String get welcome => '歡迎';

  @override
  String get phasePlaceholder => '此模組將於之後的階段建立。';

  @override
  String get all => '全部';

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get edit => '編輯';

  @override
  String get delete => '刪除';

  @override
  String get add => '新增';

  @override
  String get refresh => '重新整理';

  @override
  String get search => '搜尋';

  @override
  String get status => '狀態';

  @override
  String get date => '日期';

  @override
  String get notes => '備註';

  @override
  String get actions => '操作';

  @override
  String get complete => '完成';

  @override
  String get draft => '草稿';

  @override
  String get completed => '已完成';

  @override
  String get cancelled => '已取消';

  @override
  String get active => '啟用';

  @override
  String get inactive => '停用';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get back => '返回';

  @override
  String get emDash => '—';

  @override
  String get navDashboard => '儀表板';

  @override
  String get navCompanies => '公司';

  @override
  String get navProducts => '產品';

  @override
  String get navPurchases => '進貨';

  @override
  String get navSales => '銷售';

  @override
  String get navStock => '庫存';

  @override
  String get navMarket => '市場';

  @override
  String get navReports => '報表';

  @override
  String get navSettings => '設定';

  @override
  String get loginTitle => '登入';

  @override
  String get loginSubtitle => '請使用公司電子郵件繼續。';

  @override
  String get emailLabel => '電子郵件';

  @override
  String get passwordLabel => '密碼';

  @override
  String get confirmPasswordLabel => '確認密碼';

  @override
  String get signIn => '登入';

  @override
  String get signOut => '登出';

  @override
  String signOutConfirm(String businessName) {
    return '確定要登出 $businessName？';
  }

  @override
  String get forgotPassword => '忘記密碼？';

  @override
  String get forgotPasswordTitle => '重設密碼';

  @override
  String get forgotPasswordSubtitle => '輸入電子郵件，我們將寄送重設連結。';

  @override
  String get sendResetLink => '寄送重設連結';

  @override
  String get resetEmailSent => '若該電子郵件已註冊帳號，重設連結已寄出。';

  @override
  String get backToLogin => '返回登入';

  @override
  String get newPasswordTitle => '設定新密碼';

  @override
  String get newPasswordSubtitle => '輸入並確認新密碼以完成重設。';

  @override
  String get updatePassword => '更新密碼';

  @override
  String get passwordUpdated => '密碼已成功更新。';

  @override
  String get nameLabel => '姓名';

  @override
  String get roleLabel => '角色';

  @override
  String get profileTitle => '個人資料';

  @override
  String get saveProfile => '儲存個人資料';

  @override
  String get profileUpdated => '個人資料已更新。';

  @override
  String get dashboardTitle => '儀表板';

  @override
  String get dashboardLoading => '正在載入儀表板…';

  @override
  String get dashboardEmptyTitle => '沒有儀表板資料';

  @override
  String get dashboardEmptyMessage => '下拉重新整理或調整篩選條件。';

  @override
  String get totalSales => '銷售總額';

  @override
  String get totalPurchases => '進貨總額';

  @override
  String get totalRevenue => '營業收入';

  @override
  String get totalCogs => '銷貨成本';

  @override
  String get totalProfit => '總利潤';

  @override
  String get numberOfSales => '銷售筆數';

  @override
  String get numberOfPurchases => '進貨筆數';

  @override
  String get salesAndProfitTrend => '銷售與利潤趨勢';

  @override
  String get salesAndProfitTrendSubtitle => '選定期間內已完成的銷售';

  @override
  String get inventory => '庫存';

  @override
  String get recentActivity => '最近活動';

  @override
  String get recentSales => '最近銷售';

  @override
  String get recentPurchases => '最近進貨';

  @override
  String get quickActions => '快捷操作';

  @override
  String get quickActionsSubtitle => '常用捷徑';

  @override
  String get addSale => '新增銷售';

  @override
  String get editSale => '編輯銷售';

  @override
  String get addPurchase => '新增進貨';

  @override
  String get editPurchase => '編輯進貨';

  @override
  String get addProduct => '新增產品';

  @override
  String get viewStock => '查看庫存';

  @override
  String get stockDetails => '庫存詳情';

  @override
  String get today => '今天';

  @override
  String get thisWeek => '本週';

  @override
  String get thisMonth => '本月';

  @override
  String get custom => '自訂';

  @override
  String get company => '公司';

  @override
  String get allCompanies => '全部公司';

  @override
  String get lowStock => '低庫存';

  @override
  String get outOfStock => '缺貨';

  @override
  String get productsCount => '產品數';

  @override
  String get inStock => '有庫存';

  @override
  String get companiesTitle => '公司';

  @override
  String get addCompany => '新增公司';

  @override
  String get editCompany => '編輯公司';

  @override
  String get companyDetails => '公司詳情';

  @override
  String get companyName => '公司名稱';

  @override
  String get companyCode => '公司代碼';

  @override
  String get companyNotFound => '找不到公司';

  @override
  String get noCompaniesYet => '尚無公司';

  @override
  String get phone => '電話';

  @override
  String get address => '地址';

  @override
  String get city => '城市';

  @override
  String get country => '國家';

  @override
  String get created => '建立時間';

  @override
  String get updated => '更新時間';

  @override
  String get productsTitle => '產品';

  @override
  String get product => '產品';

  @override
  String get productDetails => '產品詳情';

  @override
  String get editProduct => '編輯產品';

  @override
  String get productNotFound => '找不到產品';

  @override
  String get noProductsYet => '尚無產品';

  @override
  String get sku => 'SKU';

  @override
  String get category => '分類';

  @override
  String get unit => '單位';

  @override
  String get barcode => '條碼';

  @override
  String get openingStock => '期初庫存';

  @override
  String get reorderLevel => '再訂購水位';

  @override
  String get openingUnitCost => '期初單位成本';

  @override
  String get sellingPrice => '售價';

  @override
  String get purchasesTitle => '進貨';

  @override
  String get purchase => '進貨';

  @override
  String get purchaseDetails => '進貨詳情';

  @override
  String get purchaseNotFound => '找不到進貨單';

  @override
  String get noPurchasesYet => '尚無進貨';

  @override
  String get invoice => '發票';

  @override
  String get invoiceNumber => '發票號碼';

  @override
  String get referenceNumber => '參考編號';

  @override
  String get quantity => '數量';

  @override
  String get cost => '成本';

  @override
  String get unitCost => '單位成本';

  @override
  String get subtotal => '小計';

  @override
  String get discount => '折扣';

  @override
  String get otherCharges => '其他費用';

  @override
  String get total => '合計';

  @override
  String get saveDraft => '儲存草稿';

  @override
  String get completePurchase => '完成進貨';

  @override
  String get cancelPurchase => '取消進貨？';

  @override
  String get items => '項目';

  @override
  String get salesTitle => '銷售';

  @override
  String get sale => '銷售';

  @override
  String get saleDetails => '銷售詳情';

  @override
  String get saleNotFound => '找不到銷售單';

  @override
  String get noSalesYet => '尚無銷售';

  @override
  String get price => '價格';

  @override
  String get unitPrice => '單價';

  @override
  String get completeSale => '完成銷售';

  @override
  String get cancelSale => '取消銷售';

  @override
  String get cogs => '銷貨成本';

  @override
  String get profit => '利潤';

  @override
  String get revenue => '收入';

  @override
  String get grossProfit => '毛利';

  @override
  String get stockTitle => '庫存';

  @override
  String get stockInventory => '庫存清單';

  @override
  String get currentStock => '目前庫存';

  @override
  String get stockAdjustment => '庫存調整';

  @override
  String get adjustStock => '調整庫存';

  @override
  String get movementHistory => '異動紀錄';

  @override
  String get noStockRows => '沒有庫存資料';

  @override
  String get stockIn => '入庫';

  @override
  String get stockOut => '出庫';

  @override
  String get direction => '方向';

  @override
  String get reason => '原因';

  @override
  String get saveAdjustment => '儲存調整';

  @override
  String get stockAdjusted => '庫存已調整。';

  @override
  String get low => '偏低';

  @override
  String get reportsTitle => '報表';

  @override
  String get reportsSubtitle => '資料庫彙總報表，支援 PDF、Excel 與列印匯出。';

  @override
  String get salesReports => '銷售報表';

  @override
  String get salesReportsSubtitle => '依發票查看收入、成本與利潤';

  @override
  String get purchaseReports => '進貨報表';

  @override
  String get purchaseReportsSubtitle => '依日期與公司查看已完成進貨';

  @override
  String get profitReports => '利潤報表';

  @override
  String get profitReportsSubtitle => '以 FIFO 儲存的成本與毛利';

  @override
  String get stockReports => '庫存報表';

  @override
  String get stockReportsSubtitle => '餘額、低庫存與異動';

  @override
  String get productReports => '產品報表';

  @override
  String get productReportsSubtitle => '銷售數量與利潤貢獻';

  @override
  String get companyReports => '公司報表';

  @override
  String get companyReportsSubtitle => '依公司查看銷售、進貨與利潤';

  @override
  String get salesReport => '銷售報表';

  @override
  String get purchaseReport => '進貨報表';

  @override
  String get profitReport => '利潤報表';

  @override
  String get stockReport => '庫存報表';

  @override
  String get productReport => '產品報表';

  @override
  String get companyReport => '公司報表';

  @override
  String get exportPdf => '匯出 PDF';

  @override
  String get exportExcel => '匯出 Excel';

  @override
  String get print => '列印';

  @override
  String get printShare => '列印／分享';

  @override
  String get exportLoadFirst => '請先載入報表再匯出。';

  @override
  String get pdfReady => 'PDF 已準備完成。';

  @override
  String get excelSaved => 'Excel 檔案已儲存。';

  @override
  String get dateAll => '日期：全部';

  @override
  String dateRange(String from, String to) {
    return '日期：$from → $to';
  }

  @override
  String get companyAll => '公司：全部';

  @override
  String companyFilter(String name) {
    return '公司：$name';
  }

  @override
  String get productsShown => '顯示產品數';

  @override
  String get qtySold => '銷售數量';

  @override
  String get salesTotal => '銷售合計';

  @override
  String get purchasesTotal => '進貨合計';

  @override
  String get profitTotal => '利潤合計';

  @override
  String get code => '代碼';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '帳號、公司資料與管理功能';

  @override
  String get workspace => '工作區';

  @override
  String get security => '安全性';

  @override
  String get language => '語言';

  @override
  String get languageSubtitle => '選擇應用程式顯示語言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTraditionalChinese => '繁體中文';

  @override
  String get languageSaved => '語言已更新。';

  @override
  String get businessProfile => '公司資料';

  @override
  String get businessProfileSubtitle => '用於報表匯出的名稱、聯絡與地址';

  @override
  String get preferences => '偏好設定';

  @override
  String get preferencesSubtitle => '貨幣與顯示格式';

  @override
  String get marketSettings => '市場設定';

  @override
  String get marketSettingsSubtitle => '啟用匯率並設定幣別';

  @override
  String get rolesPermissions => '角色與權限';

  @override
  String get rolesPermissionsSubtitle => '您的角色可執行的操作';

  @override
  String get administration => '系統管理';

  @override
  String get administrationSubtitle => '使用者與系統總覽';

  @override
  String get users => '使用者';

  @override
  String get roles => '角色';

  @override
  String get permissions => '權限';

  @override
  String get businessSettings => '公司設定';

  @override
  String get adminOverview => '系統管理';

  @override
  String get adminUsers => '使用者';

  @override
  String get userDetails => '使用者詳情';

  @override
  String get userNotFound => '找不到使用者';

  @override
  String get displayName => '顯示名稱';

  @override
  String get saveUser => '儲存使用者';

  @override
  String get marketTitle => '市場';

  @override
  String get exchangeRate => '匯率';

  @override
  String get exchangeRates => '匯率行情';

  @override
  String get lastUpdated => '最後更新';

  @override
  String get dataSource => '資料來源';

  @override
  String get marketDisabled => '市場資料已在設定中停用。';

  @override
  String get noMarketData => '尚無市場匯率';

  @override
  String get noMarketDataMessage => '點選重新整理以取得即時匯率。';

  @override
  String get marketHistory => '歷史紀錄';

  @override
  String get loadingMarket => '正在載入市場資料…';
}
