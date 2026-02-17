/// AppRouter controls navigation between screens.
///
/// This minimal implementation centralizes how route names are chosen,
/// especially in response to authentication state. It is intentionally
/// framework-agnostic so it can be used from UI code without imposing
/// a specific navigation library.
class AppRouter {
  const AppRouter();

  /// Returns the initial route for the application based on whether the
  /// user is currently authenticated.
  ///
  /// - If [isAuthenticated] is `true`, the user is sent to the home screen.
  /// - If [isAuthenticated] is `false`, the user is sent to the login screen.
  String getInitialRoute({required bool isAuthenticated}) {
    return isAuthenticated ? '/home' : '/login';
  }

  /// Route that should be used after a successful login.
  String routeAfterLogin() => '/home';

  /// Route that should be used after a logout operation.
  String routeAfterLogout() => '/login';
}
