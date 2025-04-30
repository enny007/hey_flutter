import 'package:heyflutter/core/services/package_integration_service.dart';
import 'package:heyflutter/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:heyflutter/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:heyflutter/ui/views/package_integration/package_integration_view.dart';
import 'package:heyflutter/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: StartupView),
    MaterialRoute(page: PackageIntegrationView),
    // @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: SnackbarService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: PackageIntegrationService),
    // @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
