import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../data/local_project_repository.dart';
import '../domain/project_repository.dart';

export '../domain/project_repository.dart' show ProjectDigest;

final projectDigestProvider = FutureProvider<ProjectDigest>((ref) async {
  try {
    return await ref.watch(projectRepositoryProvider).getDigest();
  } on AppException {
    rethrow;
  } catch (error, stack) {
    throw error.asAppException(stack);
  }
});
