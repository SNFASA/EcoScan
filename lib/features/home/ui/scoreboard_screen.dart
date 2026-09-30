import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/points_service.dart';
import '../../auth/logic/auth_provider.dart';

class ScoreboardScreen extends ConsumerStatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  ConsumerState<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends ConsumerState<ScoreboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(authProvider.notifier);
    final succeeded = _isRegistering
        ? await notifier.register(
            email: _emailController.text,
            password: _passwordController.text,
          )
        : await notifier.signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );

    if (succeeded) {
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F5),
      body: user.when(
        data: (currentUser) => currentUser == null
            ? _buildGuestGate(context)
            : _buildLeaderboard(context, currentUser),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.green)),
        error: (error, stackTrace) => _buildAuthUnavailable(context),
      ),
    );
  }

  Widget _buildGuestGate(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: Colors.green.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.green,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isRegistering
                            ? 'Join the leaderboard'
                            : 'Leaderboard members only',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Scanning, local points, and Impact stay available without an account. Sign in only to view Rankings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, height: 1.4),
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: _emailController,
                        enabled: !authState.isLoading,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        enabled: !authState.isLoading,
                        obscureText: _obscurePassword,
                        autofillHints: _isRegistering
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) => (value?.length ?? 0) < 6
                            ? 'Use at least 6 characters.'
                            : null,
                        onFieldSubmitted: (_) {
                          if (!_isRegistering) _submit();
                        },
                      ),
                      if (_isRegistering) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !authState.isLoading,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: const InputDecoration(
                            labelText: 'Confirm password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value != _passwordController.text
                              ? 'Passwords do not match.'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ],
                      if (authState.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            authState.errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: authState.isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: authState.isLoading
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isRegistering ? 'Create account' : 'Sign in',
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                ref.read(authProvider.notifier).clearError();
                                setState(
                                  () => _isRegistering = !_isRegistering,
                                );
                              },
                        child: Text(
                          _isRegistering
                              ? 'Already registered? Sign in'
                              : 'New here? Create an account',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, User user) {
    final points = ref.watch(pointsServiceProvider).totalPoints;
    final displayName = user.email?.split('@').first ?? 'EcoScan member';
    final entries = <_LeaderboardEntry>[
      const _LeaderboardEntry('Sarah Green', 2450),
      const _LeaderboardEntry('David Chen', 2300),
      const _LeaderboardEntry('Amirah Binti', 2150),
      _LeaderboardEntry(displayName, points, isCurrentUser: true),
      const _LeaderboardEntry('John Doe', 1100),
      const _LeaderboardEntry('Alice Smith', 950),
    ]..sort((a, b) => b.points.compareTo(a.points));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              pinned: true,
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              title: const Text('Leaderboard'),
              actions: [
                IconButton(
                  tooltip: 'Sign out of Rankings',
                  onPressed: ref.watch(authProvider).isLoading
                      ? null
                      : () => ref.read(authProvider.notifier).signOut(),
                  icon: const Icon(Icons.logout_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Preview rankings: your session points are shown locally. Shared, persistent scores still need Firestore.',
                          style: TextStyle(height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _LeaderboardTile(entry: entry, rank: index + 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthUnavailable(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Rankings are temporarily unavailable.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => ref.invalidate(authUserProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardEntry {
  const _LeaderboardEntry(this.name, this.points, {this.isCurrentUser = false});

  final String name;
  final int points;
  final bool isCurrentUser;
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.rank});

  final _LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final initials = entry.name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final medalColor = switch (rank) {
      1 => Colors.amber,
      2 => Colors.blueGrey.shade300,
      3 => Colors.brown.shade300,
      _ => Colors.green.shade700,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: entry.isCurrentUser ? Colors.green.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: entry.isCurrentUser ? Colors.green : Colors.transparent,
          width: entry.isCurrentUser ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: SizedBox(
          width: 82,
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    color: medalColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              CircleAvatar(
                backgroundColor: medalColor.withValues(alpha: 0.16),
                foregroundColor: Colors.black87,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: Text(
          entry.isCurrentUser ? '${entry.name} (You)' : entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Text(
          '${entry.points} pts',
          style: TextStyle(
            color: Colors.green.shade800,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
