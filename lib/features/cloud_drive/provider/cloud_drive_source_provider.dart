import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kikoenai/core/service/site/site_api_provider.dart';
import 'package:kikoenai_sites/kikoenai_sites.dart';

import '../data/alist_api_cloud_drive_source.dart';
import '../data/cloud_drive_source.dart';
import '../data/webdav_cloud_drive_source.dart';
import '../model/cloud_drive_mode.dart';
import 'webdav_connection_controller.dart';

final cloudDriveSourceProvider =
    Provider.family<CloudDriveSource, CloudDriveMode>(
      (ref, mode) => switch (mode) {
        CloudDriveMode.alistApi => AlistApiCloudDriveSource(
          ref.watch(siteApiByIdProvider(AsmrGaySiteApi.info.id))
              as AlistSiteApi,
        ),
        CloudDriveMode.webDav => WebDavCloudDriveSource(
          ref.watch(webDavConnectionControllerProvider.notifier),
        ),
      },
    );
