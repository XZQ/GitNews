import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/auth/auth_models.dart';
import 'package:github_news/core/auth/auth_repository.dart';
import 'package:github_news/core/auth/auth_session_controller.dart';

import 'fake_auth_repository.dart';

void main() {
  test('phone OTP signs in with a normalized +86 number and signs out', () async {
    final repository = FakeAuthRepository(capabilities: const AuthCapabilities(isConfigured: true, phone: true));
    addTearDown(repository.dispose);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.sendPhoneCode('138 1234 5678');

    expect(repository.sentPhone, '+8613812345678');
    expect(container.read(authSessionControllerProvider).operation, AuthOperation.codeSent);
    expect(container.read(authSessionControllerProvider).maskedPendingTarget, '+86 138****5678');

    await controller.verifyCode('123456');

    expect(container.read(authSessionControllerProvider).isAuthenticated, isTrue);
    expect(container.read(authSessionControllerProvider).identity?.userId, 'user-phone');

    await controller.signOut();

    expect(repository.signOutCalls, 1);
    expect(container.read(authSessionControllerProvider).isAuthenticated, isFalse);
  });

  test('invalid phone and OTP stay recoverable without calling remote verification', () async {
    final repository = FakeAuthRepository(capabilities: const AuthCapabilities(isConfigured: true, phone: true));
    addTearDown(repository.dispose);
    final container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    final controller = container.read(authSessionControllerProvider.notifier);

    await controller.sendPhoneCode('10086');

    expect(repository.sentPhone, isNull);
    expect(container.read(authSessionControllerProvider).failure, AppAuthFailureKind.invalidInput);

    await controller.sendPhoneCode('13912345678');
    await controller.verifyCode('000000');

    expect(container.read(authSessionControllerProvider).operation, AuthOperation.codeSent);
    expect(container.read(authSessionControllerProvider).failure, AppAuthFailureKind.invalidOtp);
    expect(container.read(authSessionControllerProvider).isAuthenticated, isFalse);
  });

  test('unconfigured repository keeps the app anonymous with an explicit failure', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(authSessionControllerProvider.notifier).sendPhoneCode('13812345678');

    expect(container.read(authSessionControllerProvider).isAuthenticated, isFalse);
    expect(container.read(authSessionControllerProvider).failure, AppAuthFailureKind.unconfigured);
  });
}
