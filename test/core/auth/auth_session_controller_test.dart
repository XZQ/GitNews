import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/auth/auth_models.dart';
import 'package:github_news/core/auth/auth_repository.dart';
import 'package:github_news/core/auth/auth_session_controller.dart';

import 'fake_auth_repository.dart';

void main() {
  test('email OTP signs in with a normalized address and signs out', () async {
    final repository = FakeAuthRepository(capabilities: const AuthCapabilities(isConfigured: true));
    addTearDown(repository.dispose);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.sendEmailCode(' Developer@Example.com ');

    expect(repository.sentEmail, 'developer@example.com');
    expect(container.read(authSessionControllerProvider).operation, AuthOperation.codeSent);
    expect(container.read(authSessionControllerProvider).maskedPendingEmail, 'de***@example.com');

    await controller.verifyCode('123456');

    expect(container.read(authSessionControllerProvider).isAuthenticated, isTrue);
    expect(container.read(authSessionControllerProvider).identity?.userId, 'user-email');

    await controller.signOut();

    expect(repository.signOutCalls, 1);
    expect(container.read(authSessionControllerProvider).isAuthenticated, isFalse);
  });

  test('invalid email and OTP stay recoverable without calling remote verification', () async {
    final repository = FakeAuthRepository(capabilities: const AuthCapabilities(isConfigured: true));
    addTearDown(repository.dispose);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.sendEmailCode('not-an-email');

    expect(repository.sentEmail, isNull);
    expect(container.read(authSessionControllerProvider).failure, AppAuthFailureKind.invalidInput);

    await controller.sendEmailCode('developer@example.com');
    await controller.verifyCode('000000');

    expect(container.read(authSessionControllerProvider).operation, AuthOperation.codeSent);
    expect(container.read(authSessionControllerProvider).failure, AppAuthFailureKind.invalidOtp);
    expect(container.read(authSessionControllerProvider).isAuthenticated, isFalse);
  });

  test('unconfigured repository keeps the app anonymous with an explicit failure', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(authSessionControllerProvider.notifier).sendEmailCode('developer@example.com');

    expect(container.read(authSessionControllerProvider).isAuthenticated, isFalse);
    expect(container.read(authSessionControllerProvider).failure, AppAuthFailureKind.unconfigured);
  });
}
