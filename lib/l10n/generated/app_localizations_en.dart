// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Repo Manager';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navProjectGroup => 'Project';

  @override
  String get navExplorer => 'Explorer';

  @override
  String get navStorage => 'Storage';

  @override
  String get navToolsGroup => 'Tools';

  @override
  String get navColourScheme => 'Colour Scheme';

  @override
  String get navAppIcon => 'App Icon';

  @override
  String get navSettings => 'Settings';

  @override
  String get comingSoonMessage => 'Coming soon.';

  @override
  String get nameColumnHeader => 'Name';

  @override
  String get sizeColumnHeader => 'Size';

  @override
  String get pathLabel => 'Path';

  @override
  String get openWithLabel => 'Open With';

  @override
  String get openInLabel => 'Open In';

  @override
  String get closeTooltip => 'Close';

  @override
  String get noProjectsFoundMessage =>
      'No projects found. Add a directory in Settings.';

  @override
  String get nothingToShowMessage => 'Nothing to show.';

  @override
  String get statTotalLabel => 'Total';

  @override
  String get statPinnedLabel => 'Pinned';

  @override
  String get statMonorepoLabel => 'Monorepos';

  @override
  String get statReclaimableLabel => 'Reclaimable';

  @override
  String get dashboardProjectsOverviewTitle => 'Projects Overview';

  @override
  String get dashboardSizeOverviewTitle => 'Size Overview';

  @override
  String get dashboardLanguageDistributionTitle => 'Language Distribution';

  @override
  String get dashboardFrameworkDistributionTitle => 'Framework Distribution';

  @override
  String get dashboardPinnedProjectsTitle => 'Pinned Projects';

  @override
  String get dashboardRecentlyOpenedTitle => 'Recently Opened';

  @override
  String get dashboardNoPinnedTitle => 'No pinned projects yet';

  @override
  String get dashboardNoPinnedMessage =>
      'Star a project in Explorer to pin it here for quick launch.';

  @override
  String get dashboardNoRecentTitle => 'Nothing opened yet';

  @override
  String get dashboardNoRecentMessage =>
      'Projects you open show up here for quick relaunch.';

  @override
  String get dashboardNoLanguagesTitle => 'Nothing to break down yet';

  @override
  String get dashboardNoLanguagesMessage =>
      'Add a directory in Settings to start finding projects.';

  @override
  String get dashboardNoFrameworksTitle => 'No frameworks detected yet';

  @override
  String get dashboardNoFrameworksMessage =>
      'Projects built on a recognised framework show up here.';

  @override
  String get explorerTitle => 'Projects Explorer';

  @override
  String get explorerGroupingNone => 'None';

  @override
  String get explorerGroupingByFolder => 'By Folder';

  @override
  String get explorerSearchHint => 'Search projects';

  @override
  String get explorerPinFavouritesOnTooltip => 'Favourites pinned to top';

  @override
  String get explorerPinFavouritesOffTooltip => 'No pinning';

  @override
  String get explorerRemoveFavouriteTooltip => 'Remove from favourites';

  @override
  String get explorerAddFavouriteTooltip => 'Add to favourites';

  @override
  String get storageTitle => 'Projects Storage';

  @override
  String storageTotalLabel(String amount) {
    return 'Total: $amount';
  }

  @override
  String get storageRefreshTooltip => 'Refresh projects';

  @override
  String get storageCoreLabel => 'Core';

  @override
  String get storageCacheLabel => 'Cache';

  @override
  String get storageCleanAllButton => 'Clean All';

  @override
  String get storageCleanupProjectTooltip => 'Cleanup the project';

  @override
  String get settingsProjectDirectoriesTitle => 'Project Directories';

  @override
  String get settingsNoDirectoriesMessage => 'No directories added yet.';

  @override
  String get settingsAddDirectoryButton => 'Add Directory';

  @override
  String get settingsAddDirectoryMoreTooltip => 'More ways to add';

  @override
  String get settingsAddDirectoryRecursiveMenuItem =>
      'Add Directory (with subdirectories)';

  @override
  String get settingsRemoveDirectoryTooltip => 'Remove directory';

  @override
  String get settingsPreferredEditorsTitle => 'Preferred Editors';

  @override
  String get settingsCppXcodeNote =>
      'A C++ project already set up for Xcode (has its own .xcodeproj/.xcworkspace) always opens in Xcode instead, regardless of this setting.';

  @override
  String get menuOpen => 'Open';

  @override
  String get menuOpenInVsCode => 'Open in VS Code';

  @override
  String menuOpenDefault(String ide) {
    return '$ide (default)';
  }

  @override
  String menuOpenTarget(String target) {
    return 'Open $target';
  }

  @override
  String get menuViewDetails => 'View Details';

  @override
  String monorepoBadgeCount(String tool, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packages',
      one: '1 package',
    );
    return '$tool · $_temp0';
  }

  @override
  String openInIdeLabel(String ide) {
    return 'Open in $ide';
  }
}
