import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:github_news/core/config/api_endpoints_config.dart';
import 'package:github_news/core/github/github_device_flow_controller.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    registerFallbackValue(Options());
  });

  test('unconfigured OAuth fails locally without making a network request', () async {
    final dio = _MockDio();
    final container = ProviderContainer(overrides: [githubDeviceFlowDioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);

    expect(ApiEndpointsConfig.githubOAuthConfigured, isFalse);
    await container.read(githubDeviceFlowProvider.notifier).start();

    expect(container.read(githubDeviceFlowProvider).status, DeviceFlowStatus.error);
    expect(container.read(githubDeviceFlowProvider).error, 'not_configured');
    verifyNever(() => dio.post<Map<String, Object?>>(any(), data: any(named: 'data'), options: any(named: 'options')));
  });
}
