class AuthState {
  final bool isLoading;
  final String? token;
  final String? error;

  const AuthState({this.isLoading = false, this.token, this.error});

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    bool? isLoading,
    String? token,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      token: token ?? this.token,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
