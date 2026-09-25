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
  String get navOther => 'Other';

  @override
  String get navBack => 'Back';

  @override
  String get navGeneratorsGroup => 'Generators';

  @override
  String get navColourScheme => 'Colour Scheme';

  @override
  String get navAppIcon => 'App Icon';

  @override
  String get navSystemCleaner => 'System Cleaner';

  @override
  String get navSettings => 'Settings';

  @override
  String get comingSoonMessage => 'Will be available in a later release.';

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
  String get dashboardRecognisedLanguagesHeader => 'Recognised languages';

  @override
  String get dashboardRecognisedFrameworksHeader => 'Recognised frameworks';

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
  String get explorerGroupingNone => 'List';

  @override
  String get explorerGroupingByFolder => 'Folders';

  @override
  String get explorerGroupingByCollection => 'Collections';

  @override
  String get explorerUncategorizedCollection => 'Uncategorized';

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
  String get explorerRefreshTooltip => 'Refresh projects';

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
  String get systemCleanerTitle => 'System Cleaner';

  @override
  String get systemCleanerRescanTooltip => 'Rescan for reclaimable cache';

  @override
  String systemCleanerTotalLabel(String amount) {
    return 'Reclaimable: $amount';
  }

  @override
  String systemCleanerSelectedLabel(String amount) {
    return 'Selected: $amount';
  }

  @override
  String get systemCleanerCleanSelectedButton => 'Clean Selected';

  @override
  String get systemCleanerEmptyTitle => 'Nothing to clean';

  @override
  String get systemCleanerEmptyMessage =>
      'No reclaimable cache was found on this machine.';

  @override
  String get errorScanSystemCleaner => 'Couldn\'t scan for reclaimable caches.';

  @override
  String errorCleanSystemCleanerEntry(String name) {
    return 'Couldn\'t clean up \"$name\".';
  }

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
  String settingsShowMoreDirectoriesButton(int count) {
    return 'Show $count more';
  }

  @override
  String get settingsShowLessDirectoriesButton => 'Show less';

  @override
  String get settingsPreferredEditorsTitle => 'Preferred Editors';

  @override
  String get settingsCppXcodeNote =>
      'A C++ project already set up for Xcode (has its own .xcodeproj/.xcworkspace) always opens in Xcode instead, regardless of this setting.';

  @override
  String get colourSchemeGenTitle => 'Colour Scheme Generator';

  @override
  String get colourSchemeGenPickSeedButton => 'Pick Seed Colour';

  @override
  String get colourSchemeGenPickerDialogTitle => 'Select Seed Colour';

  @override
  String get colourSchemeGenPickerConfirm => 'Select';

  @override
  String colourSchemeGenCopiedMessage(String hex) {
    return 'Copied $hex to clipboard.';
  }

  @override
  String get appIconGenTitle => 'App Icon Generator';

  @override
  String get appIconGenGenerateButton => 'Generate';

  @override
  String get appIconGenPlatformsCardTitle => 'Platforms';

  @override
  String get appIconGenPlatformAndroid => 'Android';

  @override
  String get appIconGenPlatformIos => 'iOS';

  @override
  String get appIconGenPlatformBoth => 'Both';

  @override
  String get appIconGenSourceImagesCardTitle => 'Source Images';

  @override
  String get appIconGenIconSourceLabel => 'App Icon';

  @override
  String get appIconGenIconSourceHint => 'At least 192×192px';

  @override
  String get appIconGenAndroidBgLabel => 'Android Background';

  @override
  String get appIconGenAndroidBgHint =>
      'At least 432×432px — optional, pairs with Foreground for an adaptive icon';

  @override
  String get appIconGenAndroidFgLabel => 'Android Foreground';

  @override
  String get appIconGenAndroidFgHint =>
      'At least 432×432px — optional, pairs with Background for an adaptive icon';

  @override
  String get appIconGenChooseImageButton => 'Choose Image';

  @override
  String appIconGenGeneratedMessage(String path) {
    return 'Icons generated in $path.';
  }

  @override
  String get appIconGenGenerateErrorMessage => 'Couldn\'t generate icons.';

  @override
  String get appIconGenPickImageErrorMessage =>
      'Couldn\'t open the image picker.';

  @override
  String get menuOpen => 'Open';

  @override
  String get menuOpenInVsCode => 'Open in VS Code';

  @override
  String get menuOpenInFinder => 'Open in Finder';

  @override
  String get menuOpenInExplorer => 'Open in Explorer';

  @override
  String get menuOpenInFileManager => 'Open in File Manager';

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
  String get collectionsLabel => 'Collections';

  @override
  String get menuNewCollection => 'New Collection…';

  @override
  String get newCollectionDialogTitle => 'New Collection';

  @override
  String get newCollectionDialogHint => 'Collection name';

  @override
  String get newCollectionDialogConfirm => 'Create';

  @override
  String get menuRenameCollection => 'Rename Collection';

  @override
  String get menuDeleteCollection => 'Delete Collection';

  @override
  String get renameCollectionDialogTitle => 'Rename Collection';

  @override
  String get renameCollectionDialogConfirm => 'Rename';

  @override
  String get deleteCollectionDialogTitle => 'Delete Collection';

  @override
  String deleteCollectionDialogMessage(String name) {
    return 'Delete \"$name\"? Its projects will move to Uncategorized — nothing about them is deleted.';
  }

  @override
  String get deleteCollectionDialogConfirm => 'Delete';

  @override
  String collectionAlreadyExistsMessage(String name) {
    return '\"$name\" already exists.';
  }

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
  String workspaceFolderProjectCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count projects',
      one: '1 project',
    );
    return '$_temp0';
  }

  @override
  String openInIdeLabel(String ide) {
    return 'Open in $ide';
  }

  @override
  String get errorLoadProjects => 'Couldn\'t load projects.';

  @override
  String errorLoadSubPackages(String name) {
    return 'Couldn\'t load \"$name\"\'s sub-packages.';
  }

  @override
  String errorToggleFavourite(String name) {
    return 'Couldn\'t update favourite for \"$name\".';
  }

  @override
  String errorOpenProject(String name) {
    return 'Couldn\'t open \"$name\".';
  }

  @override
  String errorOpenInIde(String ide) {
    return 'Couldn\'t open in $ide.';
  }

  @override
  String errorOpenPlatformTarget(String target, String name) {
    return 'Couldn\'t open $target for \"$name\".';
  }

  @override
  String get errorOpenFileManager => 'Couldn\'t open the file manager.';

  @override
  String get errorAddDirectory => 'Couldn\'t add that directory.';

  @override
  String get errorRemoveDirectory => 'Couldn\'t remove that directory.';

  @override
  String get errorOpenFolderPicker => 'Couldn\'t open the folder picker.';

  @override
  String get errorCreateCollection => 'Couldn\'t create the collection.';

  @override
  String get errorUpdateCollection => 'Couldn\'t update the collection.';

  @override
  String get errorRenameCollection => 'Couldn\'t rename the collection.';

  @override
  String get errorDeleteCollection => 'Couldn\'t delete the collection.';

  @override
  String errorGetProjectSize(String name) {
    return 'Couldn\'t get \"$name\"\'s size.';
  }

  @override
  String errorGetLanguageComposition(String name) {
    return 'Couldn\'t get \"$name\"\'s language composition.';
  }

  @override
  String errorGetFrameworkComposition(String name) {
    return 'Couldn\'t get \"$name\"\'s framework composition.';
  }

  @override
  String errorCleanupProject(String name) {
    return 'Couldn\'t clean up \"$name\".';
  }

  @override
  String get projectDetailsBackTooltip => 'Back';

  @override
  String get projectDetailsGeneralTab => 'General';

  @override
  String get projectDetailsInternalProjectsTab => 'Internal Projects';

  @override
  String get projectDetailsGitTab => 'Git';

  @override
  String get projectDetailsGitPlaceholderTitle => 'Git integration';

  @override
  String get projectDetailsNoInternalProjectsTitle =>
      'No internal projects yet';

  @override
  String get projectDetailsNoInternalProjectsMessage =>
      'Member packages of a monorepo show up here.';

  @override
  String get projectDetailsLanguageCompositionTitle => 'Language Composition';

  @override
  String get projectDetailsLanguageCompositionInfo =>
      'How much of this tree\'s source code (by file size) is written in each language — the root project itself, plus every member package found inside it.';

  @override
  String get projectDetailsNoLanguagesTitle => 'Nothing to break down yet';

  @override
  String get projectDetailsNoLanguagesMessage =>
      'None of this tree\'s files match a language this app recognises.';

  @override
  String get projectDetailsFrameworkCompositionTitle => 'Framework Composition';

  @override
  String get projectDetailsFrameworkCompositionInfo =>
      'How much of this tree\'s source code (by file size) belongs to a project built on each framework — only those that actually use one are counted.';

  @override
  String get projectDetailsNoFrameworksTitle => 'No frameworks detected';

  @override
  String get projectDetailsNoFrameworksMessage =>
      'None of this tree\'s projects use a recognised framework.';

  @override
  String get projectDetailsStorageSectionTitle => 'Storage';

  @override
  String get projectDetailsCleanButton => 'Clean';

  @override
  String get projectDetailsOtherInfoTitle => 'Other Info';

  @override
  String get projectDetailsWorkspaceToolLabel => 'Workspace Tool';

  @override
  String get projectDetailsWorkspaceRootLabel => 'Workspace Root';
}
