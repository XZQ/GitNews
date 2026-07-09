import '../domain/discover_entities.dart';

String discoverRepoDetailLocation(String fullName) => '/discover/detail/${Uri.encodeComponent(fullName)}';

String discoverProfileDetailLocation(DiscoverProfileEntity profile) => discoverRepoDetailLocation(profile.featuredRepoFullName);
