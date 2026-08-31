// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GlobeTrotter';

  @override
  String get navHome => 'Home';

  @override
  String get navDestinations => 'Destinations';

  @override
  String get navFeedback => 'Feedback';

  @override
  String get navItineraries => 'Itineraries';

  @override
  String get navMap => 'Map';

  @override
  String get navAdmin => 'Admin';

  @override
  String get titleMyItineraries => 'My Itineraries';

  @override
  String get titleManageDestinations => 'Manage Destinations';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get logoutTooltip => 'Log out';

  @override
  String get loginWelcomeBack => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in to keep exploring Cameroon and beyond';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get logIn => 'Log in';

  @override
  String get or => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccountRegister => 'Don\'t have an account? Register';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Join travelers from Nkolmbong, Yaoundé and beyond';

  @override
  String get fullName => 'Full name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get passwordTooShort => 'Use at least 4 characters';

  @override
  String get travelPreferences => 'Travel preferences';

  @override
  String get createAccount => 'Create account';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get profileName => 'Name';

  @override
  String get profilePreferencesHint =>
      'Used to personalize what you see around the app.';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get feedbackRateApp => 'Rate GlobeTrotter';

  @override
  String get feedbackUpdateRating => 'Update your rating';

  @override
  String get feedbackComment => 'Comment (optional)';

  @override
  String get feedbackCommentHint => 'What do you like, or what should we fix?';

  @override
  String get feedbackSubmit => 'Submit';

  @override
  String get feedbackCancel => 'Cancel';

  @override
  String get feedbackWhatPeopleSaying => 'What people are saying';

  @override
  String get feedbackNoneYet =>
      'No feedback yet — be the first to rate the app.';

  @override
  String get feedbackRemoveMine => 'Remove my feedback';

  @override
  String get dashboardSearchHint =>
      'Search destinations, e.g. \"sansfrancisco\" or \"premiere_maison\"';

  @override
  String get dashboardTopDestinations => 'Places to visit in Nkolmbong';

  @override
  String get dashboardHotels => 'Hotels in Nkolmbong';

  @override
  String get dashboardYourItineraries => 'Your itineraries';

  @override
  String get seeAll => 'See all';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get required => 'Required';

  @override
  String get titleField => 'Title';

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get startDateField => 'Start date (YYYY-MM-DD)';

  @override
  String get endDateField => 'End date (YYYY-MM-DD)';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotSubtitle =>
      'Enter your account email and we\'ll get you a reset token';

  @override
  String get sendResetToken => 'Send reset token';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get resetTitle => 'Choose a new password';

  @override
  String get resetSubtitle =>
      'This demo has no email server, so your reset token is filled in below automatically.';

  @override
  String get resetTokenLabel => 'Reset token';

  @override
  String get resetTokenRequired => 'Reset token is required';

  @override
  String get newPassword => 'New password';

  @override
  String get newPasswordRequired => 'A new password is required';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get resetPasswordButton => 'Reset password';

  @override
  String get passwordUpdatedSnack => 'Password updated. Please log in.';

  @override
  String get welcomeDefault => 'Welcome!';

  @override
  String welcomeNamed(String name) {
    return 'Welcome, $name!';
  }

  @override
  String get gettingTripReady => 'Getting your trip ready...';

  @override
  String get itinNew => 'New itinerary';

  @override
  String get itinEdit => 'Edit itinerary';

  @override
  String get itinPlacesToVisit => 'Places to visit';

  @override
  String get itinSelectAtLeastOne => 'Select at least one place';

  @override
  String get itinDeleteTitle => 'Delete itinerary?';

  @override
  String itinDeleteBody(String title) {
    return '\"$title\" will be permanently deleted.';
  }

  @override
  String get itinShareTitle => 'Share itinerary';

  @override
  String get itinShareEmailLabel => 'Friend or family member\'s email';

  @override
  String get itinShare => 'Share';

  @override
  String get itinTabMine => 'Mine';

  @override
  String get itinTabShared => 'Shared with me';

  @override
  String get itinNoneMine => 'No itineraries yet. Tap + to create one.';

  @override
  String get itinNoneShared => 'No itineraries have been shared with you yet.';

  @override
  String get itinShareTooltip => 'Share';

  @override
  String get itinEditTooltip => 'Edit';

  @override
  String get itinDeleteTooltip => 'Delete';

  @override
  String itinSharedBy(String email) {
    return 'Shared by $email';
  }

  @override
  String get couldNotLoadItineraries => 'Could not load itineraries.';

  @override
  String get searchPlacesHint => 'Search places (name, category, sector)';

  @override
  String get exploreBySector => 'Explore Nkolmbong by sector';

  @override
  String get noPlacesFound => 'No places found.';

  @override
  String get hotelsLabel => 'Hotels';

  @override
  String get placesToVisitLabel => 'Places to visit';

  @override
  String get areasToVisitLabel => 'Areas to visit';

  @override
  String get noHotelsYet => 'No hotels listed in this sector yet.';

  @override
  String get noAttractionsYet =>
      'No points of interest listed in this sector yet.';

  @override
  String get aboutThisPlace => 'About this place';

  @override
  String get noDescriptionYet =>
      'No description yet — check back soon for more details about this place.';

  @override
  String get minAmountToBeThere => 'Minimum amount to be there';

  @override
  String get reviewsLabel => 'Reviews';

  @override
  String get rateThisPlace => 'Rate this place';

  @override
  String get editYourReview => 'Edit your review';

  @override
  String get removeMyReview => 'Remove my review';

  @override
  String get noReviewsYet =>
      'No reviews yet — be the first to rate this place.';

  @override
  String rateXTitle(String name) {
    return 'Rate $name';
  }

  @override
  String get updateYourReview => 'Update your review';

  @override
  String addToItineraryX(String name) {
    return 'Add $name to...';
  }

  @override
  String get newItineraryOption => 'New itinerary';

  @override
  String addedToItinerary(String name, String title) {
    return 'Added $name to \"$title\"';
  }

  @override
  String newItineraryWithX(String name) {
    return 'New itinerary with $name';
  }

  @override
  String createdItinerary(String title) {
    return 'Created itinerary \"$title\"';
  }

  @override
  String get gettingYourLocation => 'Getting your location…';

  @override
  String get addToItineraryButton => 'Add to itinerary';

  @override
  String get couldNotLoadDestinations => 'Could not load destinations.';

  @override
  String get adminDeleteDestTitle => 'Delete destination?';

  @override
  String adminDeleteDestBody(String name) {
    return '\"$name\" will be permanently removed from the catalogue.';
  }

  @override
  String get adminNoneYet => 'No destinations yet. Tap + to add one.';

  @override
  String get adminNewDestination => 'New destination';

  @override
  String get adminEditDestination => 'Edit destination';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldTown => 'Town';

  @override
  String get fieldQuarter => 'Quarter';

  @override
  String get fieldDescription => 'Description';

  @override
  String get fieldTags => 'Tags (comma separated)';

  @override
  String get fieldAvgCost => 'Average cost per day (FCFA)';

  @override
  String get mapPositionLabel => 'Map position';

  @override
  String get tapMapToPlacePin =>
      'Tap the map to place the pin, or type the coordinates directly.';

  @override
  String get fieldLatitude => 'Latitude';

  @override
  String get fieldLongitude => 'Longitude';

  @override
  String get invalidCoordinate => 'Enter a valid number';

  @override
  String get noMapPositionSet => ' · no map position set';

  @override
  String get loadingProfileError => 'Could not load your profile.';

  @override
  String get loadingFeedbackError => 'Could not load feedback.';

  @override
  String get nkolmbongSectorsTitle => 'Nkolmbong sectors';

  @override
  String hotelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hotels',
      one: '1 hotel',
    );
    return '$_temp0';
  }

  @override
  String placeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get aTraveler => 'A traveler';

  @override
  String get planFirstTrip => 'Plan your first trip';

  @override
  String byBikeSummary(String distance, String eta, String price) {
    return '$distance · $eta · $price by bike';
  }

  @override
  String get showOnMap => 'Show on map';

  @override
  String placeMapTitle(String name) {
    return '$name on the map';
  }

  @override
  String get noLocationSetForPlace =>
      'This place\'s location hasn\'t been added to the map yet.';

  @override
  String get itineraryFromYou => 'Itinerary from your location';

  @override
  String get travelModeWalking => 'Walking';

  @override
  String get travelModeBike => 'Bike';

  @override
  String get travelModeCar => 'Car';

  @override
  String get travelFree => 'Free';

  @override
  String get bestRoute => 'Best route';

  @override
  String get dateAlreadyPassed => 'Sorry, this date has passed.';

  @override
  String get selectDate => 'Select a date';
}
