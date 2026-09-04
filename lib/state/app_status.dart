enum AppStatus { initial, loading, success, error, empty }

extension AppStatusX on AppStatus {
  bool get isInitial => this == AppStatus.initial;
  bool get isLoading => this == AppStatus.loading;
  bool get isSuccess => this == AppStatus.success;
  bool get hasError => this == AppStatus.error;
  bool get isEmpty => this == AppStatus.empty;
}
