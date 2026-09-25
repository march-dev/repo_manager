import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application window title.
  ///
  /// In en, this message translates to:
  /// **'Repo Manager'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navProjectGroup.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get navProjectGroup;

  /// No description provided for @navExplorer.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get navExplorer;

  /// No description provided for @navStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get navStorage;

  /// No description provided for @navToolsGroup.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navToolsGroup;

  /// No description provided for @navOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get navOther;

  /// No description provided for @navBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get navBack;

  /// No description provided for @navGeneratorsGroup.
  ///
  /// In en, this message translates to:
  /// **'Generators'**
  String get navGeneratorsGroup;

  /// No description provided for @navColourScheme.
  ///
  /// In en, this message translates to:
  /// **'Colour Scheme'**
  String get navColourScheme;

  /// No description provided for @navAppIcon.
  ///
  /// In en, this message translates to:
  /// **'App Icon'**
  String get navAppIcon;

  /// No description provided for @navSystemCleaner.
  ///
  /// In en, this message translates to:
  /// **'System Cleaner'**
  String get navSystemCleaner;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @comingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Will be available in a later release.'**
  String get comingSoonMessage;

  /// No description provided for @nameColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameColumnHeader;

  /// No description provided for @sizeColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeColumnHeader;

  /// No description provided for @pathLabel.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get pathLabel;

  /// No description provided for @openWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Open With'**
  String get openWithLabel;

  /// No description provided for @openInLabel.
  ///
  /// In en, this message translates to:
  /// **'Open In'**
  String get openInLabel;

  /// No description provided for @noProjectsFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No projects found. Add a directory in Settings.'**
  String get noProjectsFoundMessage;

  /// No description provided for @nothingToShowMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show.'**
  String get nothingToShowMessage;

  /// No description provided for @statTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotalLabel;

  /// No description provided for @statPinnedLabel.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get statPinnedLabel;

  /// No description provided for @statMonorepoLabel.
  ///
  /// In en, this message translates to:
  /// **'Monorepos'**
  String get statMonorepoLabel;

  /// No description provided for @statReclaimableLabel.
  ///
  /// In en, this message translates to:
  /// **'Reclaimable'**
  String get statReclaimableLabel;

  /// No description provided for @dashboardProjectsOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects Overview'**
  String get dashboardProjectsOverviewTitle;

  /// No description provided for @dashboardSizeOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Size Overview'**
  String get dashboardSizeOverviewTitle;

  /// No description provided for @dashboardLanguageDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Distribution'**
  String get dashboardLanguageDistributionTitle;

  /// No description provided for @dashboardFrameworkDistributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Framework Distribution'**
  String get dashboardFrameworkDistributionTitle;

  /// Header text atop the Language Distribution card's info popover, above the chip grid listing every language this app can detect.
  ///
  /// In en, this message translates to:
  /// **'Recognised languages'**
  String get dashboardRecognisedLanguagesHeader;

  /// Header text atop the Framework Distribution card's info popover, above the chip grid listing every framework this app can detect.
  ///
  /// In en, this message translates to:
  /// **'Recognised frameworks'**
  String get dashboardRecognisedFrameworksHeader;

  /// No description provided for @dashboardPinnedProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned Projects'**
  String get dashboardPinnedProjectsTitle;

  /// No description provided for @dashboardRecentlyOpenedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently Opened'**
  String get dashboardRecentlyOpenedTitle;

  /// No description provided for @dashboardNoPinnedTitle.
  ///
  /// In en, this message translates to:
  /// **'No pinned projects yet'**
  String get dashboardNoPinnedTitle;

  /// No description provided for @dashboardNoPinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Star a project in Explorer to pin it here for quick launch.'**
  String get dashboardNoPinnedMessage;

  /// No description provided for @dashboardNoRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing opened yet'**
  String get dashboardNoRecentTitle;

  /// No description provided for @dashboardNoRecentMessage.
  ///
  /// In en, this message translates to:
  /// **'Projects you open show up here for quick relaunch.'**
  String get dashboardNoRecentMessage;

  /// No description provided for @dashboardNoLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to break down yet'**
  String get dashboardNoLanguagesTitle;

  /// No description provided for @dashboardNoLanguagesMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a directory in Settings to start finding projects.'**
  String get dashboardNoLanguagesMessage;

  /// No description provided for @dashboardNoFrameworksTitle.
  ///
  /// In en, this message translates to:
  /// **'No frameworks detected yet'**
  String get dashboardNoFrameworksTitle;

  /// No description provided for @dashboardNoFrameworksMessage.
  ///
  /// In en, this message translates to:
  /// **'Projects built on a recognised framework show up here.'**
  String get dashboardNoFrameworksMessage;

  /// No description provided for @explorerTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects Explorer'**
  String get explorerTitle;

  /// No description provided for @explorerGroupingNone.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get explorerGroupingNone;

  /// No description provided for @explorerGroupingByFolder.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get explorerGroupingByFolder;

  /// No description provided for @explorerGroupingByCollection.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get explorerGroupingByCollection;

  /// No description provided for @explorerUncategorizedCollection.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get explorerUncategorizedCollection;

  /// No description provided for @explorerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search projects'**
  String get explorerSearchHint;

  /// No description provided for @explorerPinFavouritesOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Favourites pinned to top'**
  String get explorerPinFavouritesOnTooltip;

  /// No description provided for @explorerPinFavouritesOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'No pinning'**
  String get explorerPinFavouritesOffTooltip;

  /// No description provided for @explorerRemoveFavouriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get explorerRemoveFavouriteTooltip;

  /// No description provided for @explorerAddFavouriteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get explorerAddFavouriteTooltip;

  /// No description provided for @explorerRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh projects'**
  String get explorerRefreshTooltip;

  /// No description provided for @storageTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects Storage'**
  String get storageTitle;

  /// Total size shown in the Storage screen's header.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String storageTotalLabel(String amount);

  /// No description provided for @storageRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh projects'**
  String get storageRefreshTooltip;

  /// No description provided for @storageCoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get storageCoreLabel;

  /// No description provided for @storageCacheLabel.
  ///
  /// In en, this message translates to:
  /// **'Cache'**
  String get storageCacheLabel;

  /// No description provided for @storageCleanAllButton.
  ///
  /// In en, this message translates to:
  /// **'Clean All'**
  String get storageCleanAllButton;

  /// No description provided for @storageCleanupProjectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cleanup the project'**
  String get storageCleanupProjectTooltip;

  /// No description provided for @systemCleanerTitle.
  ///
  /// In en, this message translates to:
  /// **'System Cleaner'**
  String get systemCleanerTitle;

  /// No description provided for @systemCleanerRescanTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rescan for reclaimable cache'**
  String get systemCleanerRescanTooltip;

  /// Total reclaimable size shown in the System Cleaner header.
  ///
  /// In en, this message translates to:
  /// **'Reclaimable: {amount}'**
  String systemCleanerTotalLabel(String amount);

  /// Currently-selected size shown in the System Cleaner header.
  ///
  /// In en, this message translates to:
  /// **'Selected: {amount}'**
  String systemCleanerSelectedLabel(String amount);

  /// No description provided for @systemCleanerCleanSelectedButton.
  ///
  /// In en, this message translates to:
  /// **'Clean Selected'**
  String get systemCleanerCleanSelectedButton;

  /// No description provided for @systemCleanerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to clean'**
  String get systemCleanerEmptyTitle;

  /// No description provided for @systemCleanerEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No reclaimable cache was found on this machine.'**
  String get systemCleanerEmptyMessage;

  /// No description provided for @errorScanSystemCleaner.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t scan for reclaimable caches.'**
  String get errorScanSystemCleaner;

  /// Snackbar shown when deleting one System Cleaner entry's own path(s) fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clean up \"{name}\".'**
  String errorCleanSystemCleanerEntry(String name);

  /// No description provided for @settingsProjectDirectoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Project Directories'**
  String get settingsProjectDirectoriesTitle;

  /// No description provided for @settingsNoDirectoriesMessage.
  ///
  /// In en, this message translates to:
  /// **'No directories added yet.'**
  String get settingsNoDirectoriesMessage;

  /// No description provided for @settingsAddDirectoryButton.
  ///
  /// In en, this message translates to:
  /// **'Add Directory'**
  String get settingsAddDirectoryButton;

  /// No description provided for @settingsAddDirectoryMoreTooltip.
  ///
  /// In en, this message translates to:
  /// **'More ways to add'**
  String get settingsAddDirectoryMoreTooltip;

  /// No description provided for @settingsAddDirectoryRecursiveMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add Directory (with subdirectories)'**
  String get settingsAddDirectoryRecursiveMenuItem;

  /// No description provided for @settingsRemoveDirectoryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove directory'**
  String get settingsRemoveDirectoryTooltip;

  /// Toggle that expands the project directories list past its collapsed preview.
  ///
  /// In en, this message translates to:
  /// **'Show {count} more'**
  String settingsShowMoreDirectoriesButton(int count);

  /// No description provided for @settingsShowLessDirectoriesButton.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get settingsShowLessDirectoriesButton;

  /// No description provided for @settingsPreferredEditorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferred Editors'**
  String get settingsPreferredEditorsTitle;

  /// No description provided for @settingsCppXcodeNote.
  ///
  /// In en, this message translates to:
  /// **'A C++ project already set up for Xcode (has its own .xcodeproj/.xcworkspace) always opens in Xcode instead, regardless of this setting.'**
  String get settingsCppXcodeNote;

  /// No description provided for @colourSchemeGenTitle.
  ///
  /// In en, this message translates to:
  /// **'Colour Scheme Generator'**
  String get colourSchemeGenTitle;

  /// No description provided for @colourSchemeGenPickSeedButton.
  ///
  /// In en, this message translates to:
  /// **'Pick Seed Colour'**
  String get colourSchemeGenPickSeedButton;

  /// No description provided for @colourSchemeGenPickerDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Seed Colour'**
  String get colourSchemeGenPickerDialogTitle;

  /// No description provided for @colourSchemeGenPickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get colourSchemeGenPickerConfirm;

  /// Snackbar shown after tapping a color swatch copies its hex value.
  ///
  /// In en, this message translates to:
  /// **'Copied {hex} to clipboard.'**
  String colourSchemeGenCopiedMessage(String hex);

  /// No description provided for @appIconGenTitle.
  ///
  /// In en, this message translates to:
  /// **'App Icon Generator'**
  String get appIconGenTitle;

  /// No description provided for @appIconGenGenerateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get appIconGenGenerateButton;

  /// No description provided for @appIconGenPlatformsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Platforms'**
  String get appIconGenPlatformsCardTitle;

  /// No description provided for @appIconGenPlatformAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get appIconGenPlatformAndroid;

  /// No description provided for @appIconGenPlatformIos.
  ///
  /// In en, this message translates to:
  /// **'iOS'**
  String get appIconGenPlatformIos;

  /// No description provided for @appIconGenPlatformBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get appIconGenPlatformBoth;

  /// No description provided for @appIconGenSourceImagesCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Source Images'**
  String get appIconGenSourceImagesCardTitle;

  /// No description provided for @appIconGenIconSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'App Icon'**
  String get appIconGenIconSourceLabel;

  /// No description provided for @appIconGenIconSourceHint.
  ///
  /// In en, this message translates to:
  /// **'At least 192×192px'**
  String get appIconGenIconSourceHint;

  /// No description provided for @appIconGenAndroidBgLabel.
  ///
  /// In en, this message translates to:
  /// **'Android Background'**
  String get appIconGenAndroidBgLabel;

  /// No description provided for @appIconGenAndroidBgHint.
  ///
  /// In en, this message translates to:
  /// **'At least 432×432px — optional, pairs with Foreground for an adaptive icon'**
  String get appIconGenAndroidBgHint;

  /// No description provided for @appIconGenAndroidFgLabel.
  ///
  /// In en, this message translates to:
  /// **'Android Foreground'**
  String get appIconGenAndroidFgLabel;

  /// No description provided for @appIconGenAndroidFgHint.
  ///
  /// In en, this message translates to:
  /// **'At least 432×432px — optional, pairs with Background for an adaptive icon'**
  String get appIconGenAndroidFgHint;

  /// No description provided for @appIconGenChooseImageButton.
  ///
  /// In en, this message translates to:
  /// **'Choose Image'**
  String get appIconGenChooseImageButton;

  /// Snackbar shown after icons finish generating into the chosen destination directory.
  ///
  /// In en, this message translates to:
  /// **'Icons generated in {path}.'**
  String appIconGenGeneratedMessage(String path);

  /// No description provided for @appIconGenGenerateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t generate icons.'**
  String get appIconGenGenerateErrorMessage;

  /// No description provided for @appIconGenPickImageErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the image picker.'**
  String get appIconGenPickImageErrorMessage;

  /// No description provided for @menuOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get menuOpen;

  /// No description provided for @menuOpenInVsCode.
  ///
  /// In en, this message translates to:
  /// **'Open in VS Code'**
  String get menuOpenInVsCode;

  /// No description provided for @menuOpenInFinder.
  ///
  /// In en, this message translates to:
  /// **'Open in Finder'**
  String get menuOpenInFinder;

  /// No description provided for @menuOpenInExplorer.
  ///
  /// In en, this message translates to:
  /// **'Open in Explorer'**
  String get menuOpenInExplorer;

  /// No description provided for @menuOpenInFileManager.
  ///
  /// In en, this message translates to:
  /// **'Open in File Manager'**
  String get menuOpenInFileManager;

  /// An IDE's own entry in the Open With submenu, marked as the resolved default.
  ///
  /// In en, this message translates to:
  /// **'{ide} (default)'**
  String menuOpenDefault(String ide);

  /// A platform target's entry in a framework's submenu, e.g. "Open ios".
  ///
  /// In en, this message translates to:
  /// **'Open {target}'**
  String menuOpenTarget(String target);

  /// No description provided for @menuViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get menuViewDetails;

  /// No description provided for @collectionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collectionsLabel;

  /// No description provided for @menuNewCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection…'**
  String get menuNewCollection;

  /// No description provided for @newCollectionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get newCollectionDialogTitle;

  /// No description provided for @newCollectionDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get newCollectionDialogHint;

  /// No description provided for @newCollectionDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get newCollectionDialogConfirm;

  /// No description provided for @menuRenameCollection.
  ///
  /// In en, this message translates to:
  /// **'Rename Collection'**
  String get menuRenameCollection;

  /// No description provided for @menuDeleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get menuDeleteCollection;

  /// No description provided for @renameCollectionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Collection'**
  String get renameCollectionDialogTitle;

  /// No description provided for @renameCollectionDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameCollectionDialogConfirm;

  /// No description provided for @deleteCollectionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get deleteCollectionDialogTitle;

  /// Confirmation dialog body shown before deleting a collection.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? Its projects will move to Uncategorized — nothing about them is deleted.'**
  String deleteCollectionDialogMessage(String name);

  /// No description provided for @deleteCollectionDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteCollectionDialogConfirm;

  /// Snackbar shown when the name typed into the New Collection dialog matches a collection that already exists.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" already exists.'**
  String collectionAlreadyExistsMessage(String name);

  /// A monorepo badge's label once its member-package count is known, e.g. "Melos · 12 packages".
  ///
  /// In en, this message translates to:
  /// **'{tool} · {count, plural, one{1 package} other{{count} packages}}'**
  String monorepoBadgeCount(String tool, int count);

  /// A plain grouping folder's subtitle in a monorepo's member-package tree, naming how many real projects it contains (recursively).
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 project} other{{count} projects}}'**
  String workspaceFolderProjectCount(int count);

  /// A hover hint on a Dashboard quick-launch tile naming the IDE a tap would open the project in.
  ///
  /// In en, this message translates to:
  /// **'Open in {ide}'**
  String openInIdeLabel(String ide);

  /// No description provided for @errorLoadProjects.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load projects.'**
  String get errorLoadProjects;

  /// Snackbar shown when a monorepo's member-package tree fails to load.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load \"{name}\"\'s sub-packages.'**
  String errorLoadSubPackages(String name);

  /// Snackbar shown when toggling a project's favourite status fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update favourite for \"{name}\".'**
  String errorToggleFavourite(String name);

  /// Snackbar shown when opening a project in its IDE fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open \"{name}\".'**
  String errorOpenProject(String name);

  /// Snackbar shown when opening a path in a specific IDE fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open in {ide}.'**
  String errorOpenInIde(String ide);

  /// Snackbar shown when opening a project's native platform target (e.g. ios/android) fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open {target} for \"{name}\".'**
  String errorOpenPlatformTarget(String target, String name);

  /// No description provided for @errorOpenFileManager.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the file manager.'**
  String get errorOpenFileManager;

  /// No description provided for @errorAddDirectory.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t add that directory.'**
  String get errorAddDirectory;

  /// No description provided for @errorRemoveDirectory.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove that directory.'**
  String get errorRemoveDirectory;

  /// No description provided for @errorOpenFolderPicker.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the folder picker.'**
  String get errorOpenFolderPicker;

  /// No description provided for @errorCreateCollection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the collection.'**
  String get errorCreateCollection;

  /// No description provided for @errorUpdateCollection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the collection.'**
  String get errorUpdateCollection;

  /// No description provided for @errorRenameCollection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t rename the collection.'**
  String get errorRenameCollection;

  /// No description provided for @errorDeleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete the collection.'**
  String get errorDeleteCollection;

  /// Snackbar shown when computing a project's on-disk size fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get \"{name}\"\'s size.'**
  String errorGetProjectSize(String name);

  /// Snackbar shown when computing a project's byte-based language composition fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get \"{name}\"\'s language composition.'**
  String errorGetLanguageComposition(String name);

  /// Snackbar shown when computing a project's byte-based framework composition fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get \"{name}\"\'s framework composition.'**
  String errorGetFrameworkComposition(String name);

  /// Snackbar shown when cleaning up a project's reclaimable cache/build output fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t clean up \"{name}\".'**
  String errorCleanupProject(String name);

  /// No description provided for @projectDetailsBackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get projectDetailsBackTooltip;

  /// No description provided for @projectDetailsGeneralTab.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get projectDetailsGeneralTab;

  /// No description provided for @projectDetailsInternalProjectsTab.
  ///
  /// In en, this message translates to:
  /// **'Internal Projects'**
  String get projectDetailsInternalProjectsTab;

  /// No description provided for @projectDetailsGitTab.
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get projectDetailsGitTab;

  /// No description provided for @projectDetailsGitPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'Git integration'**
  String get projectDetailsGitPlaceholderTitle;

  /// No description provided for @projectDetailsNoInternalProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'No internal projects yet'**
  String get projectDetailsNoInternalProjectsTitle;

  /// No description provided for @projectDetailsNoInternalProjectsMessage.
  ///
  /// In en, this message translates to:
  /// **'Member packages of a monorepo show up here.'**
  String get projectDetailsNoInternalProjectsMessage;

  /// No description provided for @projectDetailsLanguageCompositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Composition'**
  String get projectDetailsLanguageCompositionTitle;

  /// No description provided for @projectDetailsLanguageCompositionInfo.
  ///
  /// In en, this message translates to:
  /// **'How much of this tree\'s source code (by file size) is written in each language — the root project itself, plus every member package found inside it.'**
  String get projectDetailsLanguageCompositionInfo;

  /// No description provided for @projectDetailsNoLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to break down yet'**
  String get projectDetailsNoLanguagesTitle;

  /// No description provided for @projectDetailsNoLanguagesMessage.
  ///
  /// In en, this message translates to:
  /// **'None of this tree\'s files match a language this app recognises.'**
  String get projectDetailsNoLanguagesMessage;

  /// No description provided for @projectDetailsFrameworkCompositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Framework Composition'**
  String get projectDetailsFrameworkCompositionTitle;

  /// No description provided for @projectDetailsFrameworkCompositionInfo.
  ///
  /// In en, this message translates to:
  /// **'How much of this tree\'s source code (by file size) belongs to a project built on each framework — only those that actually use one are counted.'**
  String get projectDetailsFrameworkCompositionInfo;

  /// No description provided for @projectDetailsNoFrameworksTitle.
  ///
  /// In en, this message translates to:
  /// **'No frameworks detected'**
  String get projectDetailsNoFrameworksTitle;

  /// No description provided for @projectDetailsNoFrameworksMessage.
  ///
  /// In en, this message translates to:
  /// **'None of this tree\'s projects use a recognised framework.'**
  String get projectDetailsNoFrameworksMessage;

  /// No description provided for @projectDetailsStorageSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get projectDetailsStorageSectionTitle;

  /// No description provided for @projectDetailsCleanButton.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get projectDetailsCleanButton;

  /// No description provided for @projectDetailsOtherInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Other Info'**
  String get projectDetailsOtherInfoTitle;

  /// No description provided for @projectDetailsWorkspaceToolLabel.
  ///
  /// In en, this message translates to:
  /// **'Workspace Tool'**
  String get projectDetailsWorkspaceToolLabel;

  /// No description provided for @projectDetailsWorkspaceRootLabel.
  ///
  /// In en, this message translates to:
  /// **'Workspace Root'**
  String get projectDetailsWorkspaceRootLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
