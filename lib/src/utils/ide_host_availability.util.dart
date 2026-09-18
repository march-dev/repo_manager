import 'dart:io';

import '../models/ide.enum.dart';

/// Whether [ide] can actually run on the OS this app is currently running
/// on. Most IDEs here are cross-platform (VS Code, every JetBrains one),
/// but Xcode is macOS-only and Visual Studio (the real Microsoft one,
/// distinct from Visual Studio *Code*) is Windows-only — Visual Studio for
/// Mac was discontinued, so offering [Ide.visualStudio] as a candidate or
/// default on a Mac host would recommend something that doesn't exist
/// there at all. Used to filter [LanguageGroup.candidateIdes]/derive its
/// [LanguageGroup.defaultIde], and [ProjectLanguage.supportedIdes]'s "Open
/// With" list, down to what could actually launch on this host.
bool isIdeAvailableOnHost(Ide ide) {
  switch (ide) {
    case Ide.xcode:
      return Platform.isMacOS;
    case Ide.visualStudio:
      return Platform.isWindows;
    default:
      return true;
  }
}
