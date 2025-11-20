enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

extension AuthStateExtension on AuthState {
  bool get isLoading => this == AuthState.loading;
  bool get isAuthenticated => this == AuthState.authenticated;
  bool get isUnauthenticated => this == AuthState.unauthenticated;
  bool get hasError => this == AuthState.error;
  bool get isInitial => this == AuthState.initial;
}













