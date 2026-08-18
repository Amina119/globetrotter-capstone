import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'GlobeTrotter'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDestinations.
  ///
  /// In en, this message translates to:
  /// **'Destinations'**
  String get navDestinations;

  /// No description provided for @navFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get navFeedback;

  /// No description provided for @navItineraries.
  ///
  /// In en, this message translates to:
  /// **'Itineraries'**
  String get navItineraries;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @titleMyItineraries.
  ///
  /// In en, this message translates to:
  /// **'My Itineraries'**
  String get titleMyItineraries;

  /// No description provided for @titleManageDestinations.
  ///
  /// In en, this message translates to:
  /// **'Manage Destinations'**
  String get titleManageDestinations;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// No description provided for @logoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutTooltip;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to keep exploring Cameroon and beyond'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccountRegister;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join travelers from Nkolmbong, Yaoundé and beyond'**
  String get registerSubtitle;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 4 characters'**
  String get passwordTooShort;

  /// No description provided for @travelPreferences.
  ///
  /// In en, this message translates to:
  /// **'Travel preferences'**
  String get travelPreferences;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccount;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profilePreferencesHint.
  ///
  /// In en, this message translates to:
  /// **'Used to personalize what you see around the app.'**
  String get profilePreferencesHint;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @feedbackRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate GlobeTrotter'**
  String get feedbackRateApp;

  /// No description provided for @feedbackUpdateRating.
  ///
  /// In en, this message translates to:
  /// **'Update your rating'**
  String get feedbackUpdateRating;

  /// No description provided for @feedbackComment.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get feedbackComment;

  /// No description provided for @feedbackCommentHint.
  ///
  /// In en, this message translates to:
  /// **'What do you like, or what should we fix?'**
  String get feedbackCommentHint;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get feedbackSubmit;

  /// No description provided for @feedbackCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get feedbackCancel;

  /// No description provided for @feedbackWhatPeopleSaying.
  ///
  /// In en, this message translates to:
  /// **'What people are saying'**
  String get feedbackWhatPeopleSaying;

  /// No description provided for @feedbackNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet — be the first to rate the app.'**
  String get feedbackNoneYet;

  /// No description provided for @feedbackRemoveMine.
  ///
  /// In en, this message translates to:
  /// **'Remove my feedback'**
  String get feedbackRemoveMine;

  /// No description provided for @dashboardSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search destinations, e.g. \"sansfrancisco\" or \"premiere_maison\"'**
  String get dashboardSearchHint;

  /// No description provided for @dashboardTopDestinations.
  ///
  /// In en, this message translates to:
  /// **'Places to visit in Nkolmbong'**
  String get dashboardTopDestinations;

  /// No description provided for @dashboardHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels in Nkolmbong'**
  String get dashboardHotels;

  /// No description provided for @dashboardYourItineraries.
  ///
  /// In en, this message translates to:
  /// **'Your itineraries'**
  String get dashboardYourItineraries;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @titleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleField;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @startDateField.
  ///
  /// In en, this message translates to:
  /// **'Start date (YYYY-MM-DD)'**
  String get startDateField;

  /// No description provided for @endDateField.
  ///
  /// In en, this message translates to:
  /// **'End date (YYYY-MM-DD)'**
  String get endDateField;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we\'ll get you a reset token'**
  String get forgotSubtitle;

  /// No description provided for @sendResetToken.
  ///
  /// In en, this message translates to:
  /// **'Send reset token'**
  String get sendResetToken;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get resetTitle;

  /// No description provided for @resetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This demo has no email server, so your reset token is filled in below automatically.'**
  String get resetSubtitle;

  /// No description provided for @resetTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset token'**
  String get resetTokenLabel;

  /// No description provided for @resetTokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Reset token is required'**
  String get resetTokenRequired;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'A new password is required'**
  String get newPasswordRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @resetPasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordButton;

  /// No description provided for @passwordUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please log in.'**
  String get passwordUpdatedSnack;

  /// No description provided for @welcomeDefault.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeDefault;

  /// No description provided for @welcomeNamed.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeNamed(String name);

  /// No description provided for @gettingTripReady.
  ///
  /// In en, this message translates to:
  /// **'Getting your trip ready...'**
  String get gettingTripReady;

  /// No description provided for @itinNew.
  ///
  /// In en, this message translates to:
  /// **'New itinerary'**
  String get itinNew;

  /// No description provided for @itinEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit itinerary'**
  String get itinEdit;

  /// No description provided for @itinPlacesToVisit.
  ///
  /// In en, this message translates to:
  /// **'Places to visit'**
  String get itinPlacesToVisit;

  /// No description provided for @itinSelectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one place'**
  String get itinSelectAtLeastOne;

  /// No description provided for @itinDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete itinerary?'**
  String get itinDeleteTitle;

  /// No description provided for @itinDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be permanently deleted.'**
  String itinDeleteBody(String title);

  /// No description provided for @itinShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share itinerary'**
  String get itinShareTitle;

  /// No description provided for @itinShareEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Friend or family member\'s email'**
  String get itinShareEmailLabel;

  /// No description provided for @itinShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get itinShare;

  /// No description provided for @itinTabMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get itinTabMine;

  /// No description provided for @itinTabShared.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get itinTabShared;

  /// No description provided for @itinNoneMine.
  ///
  /// In en, this message translates to:
  /// **'No itineraries yet. Tap + to create one.'**
  String get itinNoneMine;

  /// No description provided for @itinNoneShared.
  ///
  /// In en, this message translates to:
  /// **'No itineraries have been shared with you yet.'**
  String get itinNoneShared;

  /// No description provided for @itinShareTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get itinShareTooltip;

  /// No description provided for @itinEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get itinEditTooltip;

  /// No description provided for @itinDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get itinDeleteTooltip;

  /// No description provided for @itinSharedBy.
  ///
  /// In en, this message translates to:
  /// **'Shared by {email}'**
  String itinSharedBy(String email);

  /// No description provided for @couldNotLoadItineraries.
  ///
  /// In en, this message translates to:
  /// **'Could not load itineraries.'**
  String get couldNotLoadItineraries;

  /// No description provided for @searchPlacesHint.
  ///
  /// In en, this message translates to:
  /// **'Search places (name, category, sector)'**
  String get searchPlacesHint;

  /// No description provided for @exploreBySector.
  ///
  /// In en, this message translates to:
  /// **'Explore Nkolmbong by sector'**
  String get exploreBySector;

  /// No description provided for @noPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found.'**
  String get noPlacesFound;

  /// No description provided for @hotelsLabel.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get hotelsLabel;

  /// No description provided for @placesToVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Places to visit'**
  String get placesToVisitLabel;

  /// No description provided for @areasToVisitLabel.
  ///
  /// In en, this message translates to:
  /// **'Areas to visit'**
  String get areasToVisitLabel;

  /// No description provided for @noHotelsYet.
  ///
  /// In en, this message translates to:
  /// **'No hotels listed in this sector yet.'**
  String get noHotelsYet;

  /// No description provided for @noAttractionsYet.
  ///
  /// In en, this message translates to:
  /// **'No points of interest listed in this sector yet.'**
  String get noAttractionsYet;

  /// No description provided for @aboutThisPlace.
  ///
  /// In en, this message translates to:
  /// **'About this place'**
  String get aboutThisPlace;

  /// No description provided for @noDescriptionYet.
  ///
  /// In en, this message translates to:
  /// **'No description yet — check back soon for more details about this place.'**
  String get noDescriptionYet;

  /// No description provided for @minAmountToBeThere.
  ///
  /// In en, this message translates to:
  /// **'Minimum amount to be there'**
  String get minAmountToBeThere;

  /// No description provided for @reviewsLabel.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsLabel;

  /// No description provided for @rateThisPlace.
  ///
  /// In en, this message translates to:
  /// **'Rate this place'**
  String get rateThisPlace;

  /// No description provided for @editYourReview.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get editYourReview;

  /// No description provided for @removeMyReview.
  ///
  /// In en, this message translates to:
  /// **'Remove my review'**
  String get removeMyReview;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet — be the first to rate this place.'**
  String get noReviewsYet;

  /// No description provided for @rateXTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate {name}'**
  String rateXTitle(String name);

  /// No description provided for @updateYourReview.
  ///
  /// In en, this message translates to:
  /// **'Update your review'**
  String get updateYourReview;

  /// No description provided for @addToItineraryX.
  ///
  /// In en, this message translates to:
  /// **'Add {name} to...'**
  String addToItineraryX(String name);

  /// No description provided for @newItineraryOption.
  ///
  /// In en, this message translates to:
  /// **'New itinerary'**
  String get newItineraryOption;

  /// No description provided for @addedToItinerary.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to \"{title}\"'**
  String addedToItinerary(String name, String title);

  /// No description provided for @newItineraryWithX.
  ///
  /// In en, this message translates to:
  /// **'New itinerary with {name}'**
  String newItineraryWithX(String name);

  /// No description provided for @createdItinerary.
  ///
  /// In en, this message translates to:
  /// **'Created itinerary \"{title}\"'**
  String createdItinerary(String title);

  /// No description provided for @gettingYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get gettingYourLocation;

  /// No description provided for @addToItineraryButton.
  ///
  /// In en, this message translates to:
  /// **'Add to itinerary'**
  String get addToItineraryButton;

  /// No description provided for @couldNotLoadDestinations.
  ///
  /// In en, this message translates to:
  /// **'Could not load destinations.'**
  String get couldNotLoadDestinations;

  /// No description provided for @adminDeleteDestTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete destination?'**
  String get adminDeleteDestTitle;

  /// No description provided for @adminDeleteDestBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be permanently removed from the catalogue.'**
  String adminDeleteDestBody(String name);

  /// No description provided for @adminNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No destinations yet. Tap + to add one.'**
  String get adminNoneYet;

  /// No description provided for @adminNewDestination.
  ///
  /// In en, this message translates to:
  /// **'New destination'**
  String get adminNewDestination;

  /// No description provided for @adminEditDestination.
  ///
  /// In en, this message translates to:
  /// **'Edit destination'**
  String get adminEditDestination;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldTown.
  ///
  /// In en, this message translates to:
  /// **'Town'**
  String get fieldTown;

  /// No description provided for @fieldQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get fieldQuarter;

  /// No description provided for @fieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get fieldDescription;

  /// No description provided for @fieldTags.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get fieldTags;

  /// No description provided for @fieldAvgCost.
  ///
  /// In en, this message translates to:
  /// **'Average cost per day (FCFA)'**
  String get fieldAvgCost;

  /// No description provided for @mapPositionLabel.
  ///
  /// In en, this message translates to:
  /// **'Map position'**
  String get mapPositionLabel;

  /// No description provided for @tapMapToPlacePin.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to place the pin.'**
  String get tapMapToPlacePin;

  /// No description provided for @noMapPositionSet.
  ///
  /// In en, this message translates to:
  /// **' · no map position set'**
  String get noMapPositionSet;

  /// No description provided for @loadingProfileError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your profile.'**
  String get loadingProfileError;

  /// No description provided for @loadingFeedbackError.
  ///
  /// In en, this message translates to:
  /// **'Could not load feedback.'**
  String get loadingFeedbackError;

  /// No description provided for @nkolmbongSectorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nkolmbong sectors'**
  String get nkolmbongSectorsTitle;

  /// No description provided for @hotelCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 hotel} other{{count} hotels}}'**
  String hotelCount(int count);

  /// No description provided for @placeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 place} other{{count} places}}'**
  String placeCount(int count);

  /// No description provided for @aTraveler.
  ///
  /// In en, this message translates to:
  /// **'A traveler'**
  String get aTraveler;

  /// No description provided for @planFirstTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan your first trip'**
  String get planFirstTrip;

  /// No description provided for @byBikeSummary.
  ///
  /// In en, this message translates to:
  /// **'{distance} · {eta} · {price} by bike'**
  String byBikeSummary(String distance, String eta, String price);
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
