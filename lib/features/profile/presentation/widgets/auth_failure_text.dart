import '../../../../core/auth/auth_models.dart';

/* 把稳定认证失败映射为本地化 key。 */
String authFailureKey(AppAuthFailureKind kind) {
  return switch (kind) {
    AppAuthFailureKind.unconfigured => 'auth.error.unconfigured',
    AppAuthFailureKind.invalidInput => 'auth.error.invalid_input',
    AppAuthFailureKind.invalidOtp => 'auth.error.invalid_otp',
    AppAuthFailureKind.otpExpired => 'auth.error.otp_expired',
    AppAuthFailureKind.rateLimited => 'auth.error.rate_limited',
    AppAuthFailureKind.network => 'auth.error.network',
    AppAuthFailureKind.serviceUnavailable => 'auth.error.service_unavailable',
    AppAuthFailureKind.providerUnavailable => 'auth.error.provider_unavailable',
    AppAuthFailureKind.unknown => 'auth.error.unknown',
  };
}
