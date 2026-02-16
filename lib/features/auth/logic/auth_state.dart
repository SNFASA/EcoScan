// defines what ui can see 
class AuthState {
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.error,
  });
}
