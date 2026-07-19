/* 保留 Riverpod 2 的失败语义，避免与仓库层重试、缓存及兜底策略重复请求。 */
Duration? noProviderRetry(int retryCount, Object error) => null;
