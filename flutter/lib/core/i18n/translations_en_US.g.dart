///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEnUs = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.enUs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en-US>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsAuthEnUs auth = TranslationsAuthEnUs._(_root);
	late final TranslationsAppEnUs app = TranslationsAppEnUs._(_root);
	late final TranslationsNavEnUs nav = TranslationsNavEnUs._(_root);
	late final TranslationsCommonEnUs common = TranslationsCommonEnUs._(_root);
	late final TranslationsTiersEnUs tiers = TranslationsTiersEnUs._(_root);
	late final TranslationsPostsEnUs posts = TranslationsPostsEnUs._(_root);
	late final TranslationsUserMenuEnUs userMenu = TranslationsUserMenuEnUs._(_root);
	late final TranslationsUsersEnUs users = TranslationsUsersEnUs._(_root);
}

// Path: auth
class TranslationsAuthEnUs {
	TranslationsAuthEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsAuthLoginEnUs login = TranslationsAuthLoginEnUs._(_root);
	late final TranslationsAuthLogoutEnUs logout = TranslationsAuthLogoutEnUs._(_root);

	/// en-US: 'Session expired. Please sign in again.'
	String get sessionExpired => 'Session expired. Please sign in again.';
}

// Path: app
class TranslationsAppEnUs {
	TranslationsAppEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Flutter App'
	String get title => 'Flutter App';
}

// Path: nav
class TranslationsNavEnUs {
	TranslationsNavEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Users'
	String get users => 'Users';

	/// en-US: 'Posts'
	String get posts => 'Posts';

	/// en-US: 'Tiers'
	String get tiers => 'Tiers';

	/// en-US: 'Pending'
	String get pending => 'Pending';
}

// Path: common
class TranslationsCommonEnUs {
	TranslationsCommonEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Loading...'
	String get loading => 'Loading...';

	/// en-US: 'Something went wrong'
	String get error => 'Something went wrong';

	/// en-US: 'Retry'
	String get retry => 'Retry';

	/// en-US: 'Back'
	String get back => 'Back';

	/// en-US: 'Cancel'
	String get cancel => 'Cancel';
}

// Path: tiers
class TranslationsTiersEnUs {
	TranslationsTiersEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsTiersListTiersEnUs listTiers = TranslationsTiersListTiersEnUs._(_root);
	late final TranslationsTiersCreateTierEnUs createTier = TranslationsTiersCreateTierEnUs._(_root);
	late final TranslationsTiersTierDetailsEnUs tierDetails = TranslationsTiersTierDetailsEnUs._(_root);
	late final TranslationsTiersEditTierEnUs editTier = TranslationsTiersEditTierEnUs._(_root);
	late final TranslationsTiersDeleteTierEnUs deleteTier = TranslationsTiersDeleteTierEnUs._(_root);
}

// Path: posts
class TranslationsPostsEnUs {
	TranslationsPostsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsPostsPostDetailsEnUs postDetails = TranslationsPostsPostDetailsEnUs._(_root);
	late final TranslationsPostsPostStatusEnUs postStatus = TranslationsPostsPostStatusEnUs._(_root);
	late final TranslationsPostsEditPostEnUs editPost = TranslationsPostsEditPostEnUs._(_root);
	late final TranslationsPostsListPostsEnUs listPosts = TranslationsPostsListPostsEnUs._(_root);
	late final TranslationsPostsUserPostsEnUs userPosts = TranslationsPostsUserPostsEnUs._(_root);
	late final TranslationsPostsDeletePostEnUs deletePost = TranslationsPostsDeletePostEnUs._(_root);
	late final TranslationsPostsEraseDbPostEnUs eraseDbPost = TranslationsPostsEraseDbPostEnUs._(_root);
	late final TranslationsPostsPendingPostsEnUs pendingPosts = TranslationsPostsPendingPostsEnUs._(_root);
	late final TranslationsPostsModeratePostEnUs moderatePost = TranslationsPostsModeratePostEnUs._(_root);
	late final TranslationsPostsCreatePostEnUs createPost = TranslationsPostsCreatePostEnUs._(_root);
}

// Path: userMenu
class TranslationsUserMenuEnUs {
	TranslationsUserMenuEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'My Profile'
	String get myProfile => 'My Profile';

	/// en-US: 'My Posts'
	String get myPosts => 'My Posts';
}

// Path: users
class TranslationsUsersEnUs {
	TranslationsUsersEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Users'
	String get title => 'Users';

	late final TranslationsUsersListEnUs list = TranslationsUsersListEnUs._(_root);
	late final TranslationsUsersDetailsEnUs details = TranslationsUsersDetailsEnUs._(_root);
	late final TranslationsUsersCreateEnUs create = TranslationsUsersCreateEnUs._(_root);
	late final TranslationsUsersDeleteEnUs delete = TranslationsUsersDeleteEnUs._(_root);
	late final TranslationsUsersEraseDbUserEnUs eraseDbUser = TranslationsUsersEraseDbUserEnUs._(_root);
	late final TranslationsUsersEditEnUs edit = TranslationsUsersEditEnUs._(_root);
	late final TranslationsUsersUpdateTierEnUs updateTier = TranslationsUsersUpdateTierEnUs._(_root);
	late final TranslationsUsersModeratorEnUs moderator = TranslationsUsersModeratorEnUs._(_root);
}

// Path: auth.login
class TranslationsAuthLoginEnUs {
	TranslationsAuthLoginEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Sign in'
	String get title => 'Sign in';

	/// en-US: 'Username'
	String get username => 'Username';

	/// en-US: 'Password'
	String get password => 'Password';

	/// en-US: 'Sign in'
	String get submit => 'Sign in';

	/// en-US: 'Sign in'
	String get signInButton => 'Sign in';

	late final TranslationsAuthLoginErrorsEnUs errors = TranslationsAuthLoginErrorsEnUs._(_root);
}

// Path: auth.logout
class TranslationsAuthLogoutEnUs {
	TranslationsAuthLogoutEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Sign out?'
	String get confirmTitle => 'Sign out?';

	/// en-US: 'You will need to sign in again.'
	String get confirmMessage => 'You will need to sign in again.';

	/// en-US: 'Sign out'
	String get confirm => 'Sign out';

	/// en-US: 'Cancel'
	String get cancel => 'Cancel';
}

// Path: tiers.listTiers
class TranslationsTiersListTiersEnUs {
	TranslationsTiersListTiersEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Tiers'
	String get title => 'Tiers';

	/// en-US: 'Failed to load tiers'
	String get loadError => 'Failed to load tiers';

	/// en-US: 'Failed to load more tiers'
	String get loadMoreError => 'Failed to load more tiers';

	/// en-US: 'No tiers found'
	String get empty => 'No tiers found';
}

// Path: tiers.createTier
class TranslationsTiersCreateTierEnUs {
	TranslationsTiersCreateTierEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Create Tier'
	String get title => 'Create Tier';

	/// en-US: 'Name'
	String get name => 'Name';

	/// en-US: 'Create'
	String get submit => 'Create';

	/// en-US: 'Add tier'
	String get fabTooltip => 'Add tier';

	/// en-US: 'Tier created'
	String get success => 'Tier created';

	late final TranslationsTiersCreateTierErrorsEnUs errors = TranslationsTiersCreateTierErrorsEnUs._(_root);
}

// Path: tiers.tierDetails
class TranslationsTiersTierDetailsEnUs {
	TranslationsTiersTierDetailsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Tier details'
	String get title => 'Tier details';

	/// en-US: 'ID'
	String get id => 'ID';

	/// en-US: 'Created'
	String get createdAt => 'Created';

	/// en-US: 'Tier not found'
	String get notFound => 'Tier not found';

	/// en-US: 'Failed to load tier'
	String get loadError => 'Failed to load tier';

	/// en-US: 'Access denied'
	String get permissionDenied => 'Access denied';
}

// Path: tiers.editTier
class TranslationsTiersEditTierEnUs {
	TranslationsTiersEditTierEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Edit Tier'
	String get title => 'Edit Tier';

	/// en-US: 'Name'
	String get name => 'Name';

	/// en-US: 'Save'
	String get save => 'Save';

	/// en-US: 'Tier updated'
	String get success => 'Tier updated';

	late final TranslationsTiersEditTierErrorsEnUs errors = TranslationsTiersEditTierErrorsEnUs._(_root);
}

// Path: tiers.deleteTier
class TranslationsTiersDeleteTierEnUs {
	TranslationsTiersDeleteTierEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Delete tier'
	String get tooltip => 'Delete tier';

	/// en-US: 'Delete tier'
	String get confirmTitle => 'Delete tier';

	/// en-US: 'Are you sure you want to delete tier "{name}"? This action cannot be undone.'
	String get confirmMessage => 'Are you sure you want to delete tier "{name}"? This action cannot be undone.';

	/// en-US: 'Delete'
	String get confirmButton => 'Delete';

	/// en-US: 'Cancel'
	String get cancelButton => 'Cancel';

	/// en-US: 'Tier deleted'
	String get success => 'Tier deleted';

	late final TranslationsTiersDeleteTierErrorsEnUs errors = TranslationsTiersDeleteTierErrorsEnUs._(_root);
}

// Path: posts.postDetails
class TranslationsPostsPostDetailsEnUs {
	TranslationsPostsPostDetailsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Post'
	String get title => 'Post';

	/// en-US: 'Failed to load post'
	String get loadError => 'Failed to load post';
}

// Path: posts.postStatus
class TranslationsPostsPostStatusEnUs {
	TranslationsPostsPostStatusEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Pending Review'
	String get pendingReview => 'Pending Review';

	/// en-US: 'Approved'
	String get approved => 'Approved';

	/// en-US: 'Changes Requested'
	String get changesRequested => 'Changes Requested';
}

// Path: posts.editPost
class TranslationsPostsEditPostEnUs {
	TranslationsPostsEditPostEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Edit Post'
	String get title => 'Edit Post';

	/// en-US: 'Title'
	String get titleLabel => 'Title';

	/// en-US: 'Post title'
	String get titleHint => 'Post title';

	/// en-US: 'Media URL (optional)'
	String get mediaUrlLabel => 'Media URL (optional)';

	/// en-US: 'https://...'
	String get mediaUrlHint => 'https://...';

	/// en-US: 'Text (Markdown)'
	String get textLabel => 'Text (Markdown)';

	/// en-US: 'Write your post...'
	String get textHint => 'Write your post...';

	/// en-US: 'Preview'
	String get previewLabel => 'Preview';

	/// en-US: 'Save'
	String get saveButton => 'Save';

	late final TranslationsPostsEditPostTabsEnUs tabs = TranslationsPostsEditPostTabsEnUs._(_root);
	late final TranslationsPostsEditPostRevisionMessageEnUs revisionMessage = TranslationsPostsEditPostRevisionMessageEnUs._(_root);

	/// en-US: 'This post is approved and can no longer be edited.'
	String get approvedHint => 'This post is approved and can no longer be edited.';

	late final TranslationsPostsEditPostLogEnUs log = TranslationsPostsEditPostLogEnUs._(_root);
	late final TranslationsPostsEditPostErrorsEnUs errors = TranslationsPostsEditPostErrorsEnUs._(_root);
}

// Path: posts.listPosts
class TranslationsPostsListPostsEnUs {
	TranslationsPostsListPostsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'No posts yet'
	String get empty => 'No posts yet';

	/// en-US: 'Failed to load posts'
	String get loadError => 'Failed to load posts';

	/// en-US: 'New post'
	String get fabTooltip => 'New post';

	/// en-US: 'Open'
	String get openPost => 'Open';
}

// Path: posts.userPosts
class TranslationsPostsUserPostsEnUs {
	TranslationsPostsUserPostsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: '$username's posts'
	String title({required Object username}) => '${username}\'s posts';

	/// en-US: 'No posts yet'
	String get empty => 'No posts yet';

	/// en-US: 'Failed to load posts'
	String get loadError => 'Failed to load posts';

	/// en-US: 'Open'
	String get openPost => 'Open';
}

// Path: posts.deletePost
class TranslationsPostsDeletePostEnUs {
	TranslationsPostsDeletePostEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Delete post'
	String get tooltip => 'Delete post';

	/// en-US: 'Delete post?'
	String get confirmTitle => 'Delete post?';

	/// en-US: 'This action is irreversible. The post will be permanently removed.'
	String get confirmMessage => 'This action is irreversible. The post will be permanently removed.';

	/// en-US: 'Delete'
	String get confirmButton => 'Delete';

	/// en-US: 'Cancel'
	String get cancelButton => 'Cancel';

	/// en-US: 'Post deleted'
	String get success => 'Post deleted';

	late final TranslationsPostsDeletePostErrorsEnUs errors = TranslationsPostsDeletePostErrorsEnUs._(_root);
}

// Path: posts.eraseDbPost
class TranslationsPostsEraseDbPostEnUs {
	TranslationsPostsEraseDbPostEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Erase post (superuser)'
	String get tooltip => 'Erase post (superuser)';

	/// en-US: 'Erase post?'
	String get confirmTitle => 'Erase post?';

	/// en-US: 'This post will be permanently erased. This action cannot be undone.'
	String get confirmMessage => 'This post will be permanently erased. This action cannot be undone.';

	/// en-US: 'Erase'
	String get confirmButton => 'Erase';

	/// en-US: 'Cancel'
	String get cancelButton => 'Cancel';

	/// en-US: 'Post erased'
	String get success => 'Post erased';

	late final TranslationsPostsEraseDbPostErrorsEnUs errors = TranslationsPostsEraseDbPostErrorsEnUs._(_root);
}

// Path: posts.pendingPosts
class TranslationsPostsPendingPostsEnUs {
	TranslationsPostsPendingPostsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Pending Posts'
	String get title => 'Pending Posts';

	/// en-US: 'No pending posts'
	String get empty => 'No pending posts';

	/// en-US: 'Failed to load pending posts'
	String get loadError => 'Failed to load pending posts';

	/// en-US: 'Failed to load more'
	String get loadMoreError => 'Failed to load more';

	/// en-US: 'Events'
	String get eventCount => 'Events';
}

// Path: posts.moderatePost
class TranslationsPostsModeratePostEnUs {
	TranslationsPostsModeratePostEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Moderate Post'
	String get title => 'Moderate Post';

	late final TranslationsPostsModeratePostTabsEnUs tabs = TranslationsPostsModeratePostTabsEnUs._(_root);
	late final TranslationsPostsModeratePostLogEnUs log = TranslationsPostsModeratePostLogEnUs._(_root);
	late final TranslationsPostsModeratePostActionsEnUs actions = TranslationsPostsModeratePostActionsEnUs._(_root);
	late final TranslationsPostsModeratePostErrorsEnUs errors = TranslationsPostsModeratePostErrorsEnUs._(_root);
}

// Path: posts.createPost
class TranslationsPostsCreatePostEnUs {
	TranslationsPostsCreatePostEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'New Post'
	String get title => 'New Post';

	/// en-US: 'Title'
	String get titleLabel => 'Title';

	/// en-US: 'Post title'
	String get titleHint => 'Post title';

	/// en-US: 'Media URL (optional)'
	String get mediaUrlLabel => 'Media URL (optional)';

	/// en-US: 'https://...'
	String get mediaUrlHint => 'https://...';

	/// en-US: 'Text (Markdown)'
	String get textLabel => 'Text (Markdown)';

	/// en-US: 'Write your post...'
	String get textHint => 'Write your post...';

	/// en-US: 'Preview'
	String get previewLabel => 'Preview';

	/// en-US: 'Publish'
	String get publishButton => 'Publish';

	/// en-US: 'New post'
	String get fabTooltip => 'New post';

	late final TranslationsPostsCreatePostErrorsEnUs errors = TranslationsPostsCreatePostErrorsEnUs._(_root);
}

// Path: users.list
class TranslationsUsersListEnUs {
	TranslationsUsersListEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Failed to load more users'
	String get loadMoreError => 'Failed to load more users';

	/// en-US: 'Details'
	String get userDetails => 'Details';

	/// en-US: 'Posts'
	String get userPosts => 'Posts';
}

// Path: users.details
class TranslationsUsersDetailsEnUs {
	TranslationsUsersDetailsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Email'
	String get email => 'Email';

	/// en-US: 'Tier'
	String get tier => 'Tier';

	/// en-US: 'Tier since'
	String get tierSince => 'Tier since';

	/// en-US: 'User not found'
	String get notFound => 'User not found';

	/// en-US: 'Failed to load user'
	String get loadError => 'Failed to load user';
}

// Path: users.create
class TranslationsUsersCreateEnUs {
	TranslationsUsersCreateEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Create User'
	String get title => 'Create User';

	/// en-US: 'Name'
	String get name => 'Name';

	/// en-US: 'Username'
	String get username => 'Username';

	/// en-US: 'Email'
	String get email => 'Email';

	/// en-US: 'Password'
	String get password => 'Password';

	/// en-US: 'Create'
	String get submit => 'Create';

	/// en-US: 'User created successfully'
	String get success => 'User created successfully';

	late final TranslationsUsersCreateErrorsEnUs errors = TranslationsUsersCreateErrorsEnUs._(_root);
}

// Path: users.delete
class TranslationsUsersDeleteEnUs {
	TranslationsUsersDeleteEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Delete account'
	String get tooltip => 'Delete account';

	/// en-US: 'Delete account?'
	String get confirmTitle => 'Delete account?';

	/// en-US: 'This will permanently delete your account. This action cannot be undone.'
	String get confirmMessage => 'This will permanently delete your account. This action cannot be undone.';

	/// en-US: 'Delete'
	String get confirmButton => 'Delete';

	/// en-US: 'Account deleted'
	String get success => 'Account deleted';

	late final TranslationsUsersDeleteErrorsEnUs errors = TranslationsUsersDeleteErrorsEnUs._(_root);
}

// Path: users.eraseDbUser
class TranslationsUsersEraseDbUserEnUs {
	TranslationsUsersEraseDbUserEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Erase from database'
	String get tooltip => 'Erase from database';

	/// en-US: 'Erase account permanently?'
	String get confirmTitle => 'Erase account permanently?';

	/// en-US: 'This will permanently delete your account from the database. This action cannot be undone.'
	String get confirmMessage => 'This will permanently delete your account from the database. This action cannot be undone.';

	/// en-US: 'Erase permanently'
	String get confirmButton => 'Erase permanently';

	/// en-US: 'Account erased from the database'
	String get success => 'Account erased from the database';

	late final TranslationsUsersEraseDbUserErrorsEnUs errors = TranslationsUsersEraseDbUserErrorsEnUs._(_root);
}

// Path: users.edit
class TranslationsUsersEditEnUs {
	TranslationsUsersEditEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Edit User'
	String get title => 'Edit User';

	/// en-US: 'Name'
	String get name => 'Name';

	/// en-US: 'Username'
	String get username => 'Username';

	/// en-US: 'Email'
	String get email => 'Email';

	/// en-US: 'Profile Image URL'
	String get profileImageUrl => 'Profile Image URL';

	/// en-US: 'Save'
	String get save => 'Save';

	/// en-US: 'User updated successfully'
	String get success => 'User updated successfully';

	late final TranslationsUsersEditErrorsEnUs errors = TranslationsUsersEditErrorsEnUs._(_root);
}

// Path: users.updateTier
class TranslationsUsersUpdateTierEnUs {
	TranslationsUsersUpdateTierEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Change tier'
	String get tooltip => 'Change tier';

	/// en-US: 'Change User Tier'
	String get sheetTitle => 'Change User Tier';

	/// en-US: 'Select tier'
	String get selectTier => 'Select tier';

	/// en-US: 'Confirm'
	String get confirm => 'Confirm';

	/// en-US: 'User tier updated'
	String get success => 'User tier updated';

	late final TranslationsUsersUpdateTierErrorsEnUs errors = TranslationsUsersUpdateTierErrorsEnUs._(_root);
}

// Path: users.moderator
class TranslationsUsersModeratorEnUs {
	TranslationsUsersModeratorEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Moderator'
	String get badge => 'Moderator';

	/// en-US: 'Assign Moderator'
	String get assign => 'Assign Moderator';

	/// en-US: 'Revoke Moderator'
	String get revoke => 'Revoke Moderator';

	late final TranslationsUsersModeratorErrorsEnUs errors = TranslationsUsersModeratorErrorsEnUs._(_root);
}

// Path: auth.login.errors
class TranslationsAuthLoginErrorsEnUs {
	TranslationsAuthLoginErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Required'
	String get required => 'Required';

	/// en-US: 'Invalid username or password'
	String get invalidCredentials => 'Invalid username or password';

	/// en-US: 'Sign in failed. Try again.'
	String get generic => 'Sign in failed. Try again.';
}

// Path: tiers.createTier.errors
class TranslationsTiersCreateTierErrorsEnUs {
	TranslationsTiersCreateTierErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'This field is required'
	String get required => 'This field is required';

	/// en-US: 'Failed to create tier'
	String get generic => 'Failed to create tier';
}

// Path: tiers.editTier.errors
class TranslationsTiersEditTierErrorsEnUs {
	TranslationsTiersEditTierErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'This field is required'
	String get required => 'This field is required';

	/// en-US: 'Tier not found'
	String get notFound => 'Tier not found';

	/// en-US: 'Access denied'
	String get permissionDenied => 'Access denied';

	/// en-US: 'Failed to update tier'
	String get generic => 'Failed to update tier';
}

// Path: tiers.deleteTier.errors
class TranslationsTiersDeleteTierErrorsEnUs {
	TranslationsTiersDeleteTierErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Tier not found'
	String get notFound => 'Tier not found';

	/// en-US: 'Access denied'
	String get forbidden => 'Access denied';

	/// en-US: 'Session expired'
	String get unauthorized => 'Session expired';

	/// en-US: 'Failed to delete tier'
	String get generic => 'Failed to delete tier';
}

// Path: posts.editPost.tabs
class TranslationsPostsEditPostTabsEnUs {
	TranslationsPostsEditPostTabsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Edit'
	String get edit => 'Edit';

	/// en-US: 'Moderation Log'
	String get log => 'Moderation Log';
}

// Path: posts.editPost.revisionMessage
class TranslationsPostsEditPostRevisionMessageEnUs {
	TranslationsPostsEditPostRevisionMessageEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Revision message'
	String get label => 'Revision message';

	/// en-US: 'Describe what you changed to address the moderator's feedback'
	String get hint => 'Describe what you changed to address the moderator\'s feedback';
}

// Path: posts.editPost.log
class TranslationsPostsEditPostLogEnUs {
	TranslationsPostsEditPostLogEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'No moderation history yet'
	String get empty => 'No moderation history yet';

	/// en-US: 'Failed to load moderation history'
	String get loadError => 'Failed to load moderation history';
}

// Path: posts.editPost.errors
class TranslationsPostsEditPostErrorsEnUs {
	TranslationsPostsEditPostErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Title must be at least 2 characters'
	String get titleTooShort => 'Title must be at least 2 characters';

	/// en-US: 'Title must be at most 30 characters'
	String get titleTooLong => 'Title must be at most 30 characters';

	/// en-US: 'Media URL cannot be empty if provided'
	String get mediaUrlEmpty => 'Media URL cannot be empty if provided';

	/// en-US: 'Text must be at least 100 characters'
	String get textTooShort => 'Text must be at least 100 characters';

	/// en-US: 'Text must be at most 63206 characters'
	String get textTooLong => 'Text must be at most 63206 characters';

	/// en-US: 'You can only edit your own posts'
	String get forbidden => 'You can only edit your own posts';

	/// en-US: 'Failed to save post. Please try again.'
	String get generic => 'Failed to save post. Please try again.';

	/// en-US: 'A revision message is required.'
	String get revisionMessageRequired => 'A revision message is required.';

	/// en-US: 'The post status changed while you were editing. Check the current status.'
	String get conflict => 'The post status changed while you were editing. Check the current status.';

	/// en-US: 'Post not found.'
	String get notFound => 'Post not found.';
}

// Path: posts.deletePost.errors
class TranslationsPostsDeletePostErrorsEnUs {
	TranslationsPostsDeletePostErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'You can only delete your own posts'
	String get forbidden => 'You can only delete your own posts';

	/// en-US: 'Failed to delete post. Please try again.'
	String get generic => 'Failed to delete post. Please try again.';
}

// Path: posts.eraseDbPost.errors
class TranslationsPostsEraseDbPostErrorsEnUs {
	TranslationsPostsEraseDbPostErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'You do not have permission to erase posts'
	String get forbidden => 'You do not have permission to erase posts';

	/// en-US: 'Failed to erase post. Please try again.'
	String get generic => 'Failed to erase post. Please try again.';
}

// Path: posts.moderatePost.tabs
class TranslationsPostsModeratePostTabsEnUs {
	TranslationsPostsModeratePostTabsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Post'
	String get post => 'Post';

	/// en-US: 'Moderation'
	String get moderation => 'Moderation';
}

// Path: posts.moderatePost.log
class TranslationsPostsModeratePostLogEnUs {
	TranslationsPostsModeratePostLogEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'No moderation history yet'
	String get empty => 'No moderation history yet';

	/// en-US: 'Failed to load moderation history'
	String get loadError => 'Failed to load moderation history';

	late final TranslationsPostsModeratePostLogEventTypesEnUs eventTypes = TranslationsPostsModeratePostLogEventTypesEnUs._(_root);
	late final TranslationsPostsModeratePostLogActionsEnUs actions = TranslationsPostsModeratePostLogActionsEnUs._(_root);
}

// Path: posts.moderatePost.actions
class TranslationsPostsModeratePostActionsEnUs {
	TranslationsPostsModeratePostActionsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Approve'
	String get approve => 'Approve';

	/// en-US: 'Request Changes'
	String get requestChanges => 'Request Changes';

	/// en-US: 'Add a comment (required for rejection)'
	String get messageHint => 'Add a comment (required for rejection)';

	/// en-US: 'A message is required when requesting changes'
	String get messageRequiredError => 'A message is required when requesting changes';
}

// Path: posts.moderatePost.errors
class TranslationsPostsModeratePostErrorsEnUs {
	TranslationsPostsModeratePostErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'You do not have permission to moderate this post'
	String get forbidden => 'You do not have permission to moderate this post';

	/// en-US: 'Post not found'
	String get notFound => 'Post not found';

	/// en-US: 'This post has already been moderated. Return to the queue.'
	String get conflict => 'This post has already been moderated. Return to the queue.';

	/// en-US: 'Failed to submit. Please try again.'
	String get generic => 'Failed to submit. Please try again.';
}

// Path: posts.createPost.errors
class TranslationsPostsCreatePostErrorsEnUs {
	TranslationsPostsCreatePostErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Title must be at least 2 characters'
	String get titleTooShort => 'Title must be at least 2 characters';

	/// en-US: 'Title must be at most 30 characters'
	String get titleTooLong => 'Title must be at most 30 characters';

	/// en-US: 'Media URL cannot be empty if provided'
	String get mediaUrlEmpty => 'Media URL cannot be empty if provided';

	/// en-US: 'Text must be at least 100 characters'
	String get textTooShort => 'Text must be at least 100 characters';

	/// en-US: 'Text must be at most 63206 characters'
	String get textTooLong => 'Text must be at most 63206 characters';

	/// en-US: 'You can only publish posts as yourself'
	String get forbidden => 'You can only publish posts as yourself';

	/// en-US: 'Failed to publish post. Please try again.'
	String get generic => 'Failed to publish post. Please try again.';
}

// Path: users.create.errors
class TranslationsUsersCreateErrorsEnUs {
	TranslationsUsersCreateErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'This field is required'
	String get required => 'This field is required';

	/// en-US: 'Please enter a valid email address'
	String get emailInvalid => 'Please enter a valid email address';

	/// en-US: 'Password must be at least 8 characters'
	String get passwordTooShort => 'Password must be at least 8 characters';

	/// en-US: 'Username already taken'
	String get usernameTaken => 'Username already taken';

	/// en-US: 'Email already taken'
	String get emailTaken => 'Email already taken';

	/// en-US: 'Something went wrong. Please try again.'
	String get generic => 'Something went wrong. Please try again.';
}

// Path: users.delete.errors
class TranslationsUsersDeleteErrorsEnUs {
	TranslationsUsersDeleteErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'You can only delete your own account.'
	String get forbidden => 'You can only delete your own account.';

	/// en-US: 'Session expired.'
	String get unauthorized => 'Session expired.';

	/// en-US: 'User not found.'
	String get notFound => 'User not found.';

	/// en-US: 'Failed to delete account.'
	String get generic => 'Failed to delete account.';
}

// Path: users.eraseDbUser.errors
class TranslationsUsersEraseDbUserErrorsEnUs {
	TranslationsUsersEraseDbUserErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'You can only erase your own account'
	String get forbidden => 'You can only erase your own account';

	/// en-US: 'Session expired. Please log in again'
	String get unauthorized => 'Session expired. Please log in again';

	/// en-US: 'User not found'
	String get notFound => 'User not found';

	/// en-US: 'Failed to erase account. Please try again'
	String get generic => 'Failed to erase account. Please try again';
}

// Path: users.edit.errors
class TranslationsUsersEditErrorsEnUs {
	TranslationsUsersEditErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'This field is required'
	String get required => 'This field is required';

	/// en-US: 'Please enter a valid email address'
	String get emailInvalid => 'Please enter a valid email address';

	/// en-US: 'Username already taken'
	String get usernameTaken => 'Username already taken';

	/// en-US: 'User not found'
	String get notFound => 'User not found';

	/// en-US: 'No changes to save'
	String get nothingToUpdate => 'No changes to save';

	/// en-US: 'You can only edit your own profile.'
	String get forbidden => 'You can only edit your own profile.';

	/// en-US: 'Session expired.'
	String get unauthorized => 'Session expired.';

	/// en-US: 'Something went wrong. Please try again.'
	String get generic => 'Something went wrong. Please try again.';
}

// Path: users.updateTier.errors
class TranslationsUsersUpdateTierErrorsEnUs {
	TranslationsUsersUpdateTierErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'You don't have permission to change tiers.'
	String get permissionDenied => 'You don\'t have permission to change tiers.';

	/// en-US: 'User or tier not found.'
	String get notFound => 'User or tier not found.';

	/// en-US: 'Permission denied.'
	String get forbidden => 'Permission denied.';

	/// en-US: 'Session expired.'
	String get unauthorized => 'Session expired.';

	/// en-US: 'Failed to update tier. Please try again.'
	String get generic => 'Failed to update tier. Please try again.';
}

// Path: users.moderator.errors
class TranslationsUsersModeratorErrorsEnUs {
	TranslationsUsersModeratorErrorsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Action not applicable — moderator status is already in sync.'
	String get conflict => 'Action not applicable — moderator status is already in sync.';

	/// en-US: 'You do not have permission to manage moderators.'
	String get forbidden => 'You do not have permission to manage moderators.';

	/// en-US: 'Failed to update moderator status. Please try again.'
	String get generic => 'Failed to update moderator status. Please try again.';
}

// Path: posts.moderatePost.log.eventTypes
class TranslationsPostsModeratePostLogEventTypesEnUs {
	TranslationsPostsModeratePostLogEventTypesEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Moderator Review'
	String get moderatorReview => 'Moderator Review';

	/// en-US: 'Author Revision'
	String get authorRevision => 'Author Revision';
}

// Path: posts.moderatePost.log.actions
class TranslationsPostsModeratePostLogActionsEnUs {
	TranslationsPostsModeratePostLogActionsEnUs._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en-US: 'Approved'
	String get approved => 'Approved';

	/// en-US: 'Changes Requested'
	String get changesRequested => 'Changes Requested';
}

/// The flat map containing all translations for locale <en-US>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'auth.login.title' => 'Sign in',
			'auth.login.username' => 'Username',
			'auth.login.password' => 'Password',
			'auth.login.submit' => 'Sign in',
			'auth.login.signInButton' => 'Sign in',
			'auth.login.errors.required' => 'Required',
			'auth.login.errors.invalidCredentials' => 'Invalid username or password',
			'auth.login.errors.generic' => 'Sign in failed. Try again.',
			'auth.logout.confirmTitle' => 'Sign out?',
			'auth.logout.confirmMessage' => 'You will need to sign in again.',
			'auth.logout.confirm' => 'Sign out',
			'auth.logout.cancel' => 'Cancel',
			'auth.sessionExpired' => 'Session expired. Please sign in again.',
			'app.title' => 'Flutter App',
			'nav.users' => 'Users',
			'nav.posts' => 'Posts',
			'nav.tiers' => 'Tiers',
			'nav.pending' => 'Pending',
			'common.loading' => 'Loading...',
			'common.error' => 'Something went wrong',
			'common.retry' => 'Retry',
			'common.back' => 'Back',
			'common.cancel' => 'Cancel',
			'tiers.listTiers.title' => 'Tiers',
			'tiers.listTiers.loadError' => 'Failed to load tiers',
			'tiers.listTiers.loadMoreError' => 'Failed to load more tiers',
			'tiers.listTiers.empty' => 'No tiers found',
			'tiers.createTier.title' => 'Create Tier',
			'tiers.createTier.name' => 'Name',
			'tiers.createTier.submit' => 'Create',
			'tiers.createTier.fabTooltip' => 'Add tier',
			'tiers.createTier.success' => 'Tier created',
			'tiers.createTier.errors.required' => 'This field is required',
			'tiers.createTier.errors.generic' => 'Failed to create tier',
			'tiers.tierDetails.title' => 'Tier details',
			'tiers.tierDetails.id' => 'ID',
			'tiers.tierDetails.createdAt' => 'Created',
			'tiers.tierDetails.notFound' => 'Tier not found',
			'tiers.tierDetails.loadError' => 'Failed to load tier',
			'tiers.tierDetails.permissionDenied' => 'Access denied',
			'tiers.editTier.title' => 'Edit Tier',
			'tiers.editTier.name' => 'Name',
			'tiers.editTier.save' => 'Save',
			'tiers.editTier.success' => 'Tier updated',
			'tiers.editTier.errors.required' => 'This field is required',
			'tiers.editTier.errors.notFound' => 'Tier not found',
			'tiers.editTier.errors.permissionDenied' => 'Access denied',
			'tiers.editTier.errors.generic' => 'Failed to update tier',
			'tiers.deleteTier.tooltip' => 'Delete tier',
			'tiers.deleteTier.confirmTitle' => 'Delete tier',
			'tiers.deleteTier.confirmMessage' => 'Are you sure you want to delete tier "{name}"? This action cannot be undone.',
			'tiers.deleteTier.confirmButton' => 'Delete',
			'tiers.deleteTier.cancelButton' => 'Cancel',
			'tiers.deleteTier.success' => 'Tier deleted',
			'tiers.deleteTier.errors.notFound' => 'Tier not found',
			'tiers.deleteTier.errors.forbidden' => 'Access denied',
			'tiers.deleteTier.errors.unauthorized' => 'Session expired',
			'tiers.deleteTier.errors.generic' => 'Failed to delete tier',
			'posts.postDetails.title' => 'Post',
			'posts.postDetails.loadError' => 'Failed to load post',
			'posts.postStatus.pendingReview' => 'Pending Review',
			'posts.postStatus.approved' => 'Approved',
			'posts.postStatus.changesRequested' => 'Changes Requested',
			'posts.editPost.title' => 'Edit Post',
			'posts.editPost.titleLabel' => 'Title',
			'posts.editPost.titleHint' => 'Post title',
			'posts.editPost.mediaUrlLabel' => 'Media URL (optional)',
			'posts.editPost.mediaUrlHint' => 'https://...',
			'posts.editPost.textLabel' => 'Text (Markdown)',
			'posts.editPost.textHint' => 'Write your post...',
			'posts.editPost.previewLabel' => 'Preview',
			'posts.editPost.saveButton' => 'Save',
			'posts.editPost.tabs.edit' => 'Edit',
			'posts.editPost.tabs.log' => 'Moderation Log',
			'posts.editPost.revisionMessage.label' => 'Revision message',
			'posts.editPost.revisionMessage.hint' => 'Describe what you changed to address the moderator\'s feedback',
			'posts.editPost.approvedHint' => 'This post is approved and can no longer be edited.',
			'posts.editPost.log.empty' => 'No moderation history yet',
			'posts.editPost.log.loadError' => 'Failed to load moderation history',
			'posts.editPost.errors.titleTooShort' => 'Title must be at least 2 characters',
			'posts.editPost.errors.titleTooLong' => 'Title must be at most 30 characters',
			'posts.editPost.errors.mediaUrlEmpty' => 'Media URL cannot be empty if provided',
			'posts.editPost.errors.textTooShort' => 'Text must be at least 100 characters',
			'posts.editPost.errors.textTooLong' => 'Text must be at most 63206 characters',
			'posts.editPost.errors.forbidden' => 'You can only edit your own posts',
			'posts.editPost.errors.generic' => 'Failed to save post. Please try again.',
			'posts.editPost.errors.revisionMessageRequired' => 'A revision message is required.',
			'posts.editPost.errors.conflict' => 'The post status changed while you were editing. Check the current status.',
			'posts.editPost.errors.notFound' => 'Post not found.',
			'posts.listPosts.empty' => 'No posts yet',
			'posts.listPosts.loadError' => 'Failed to load posts',
			'posts.listPosts.fabTooltip' => 'New post',
			'posts.listPosts.openPost' => 'Open',
			'posts.userPosts.title' => ({required Object username}) => '${username}\'s posts',
			'posts.userPosts.empty' => 'No posts yet',
			'posts.userPosts.loadError' => 'Failed to load posts',
			'posts.userPosts.openPost' => 'Open',
			'posts.deletePost.tooltip' => 'Delete post',
			'posts.deletePost.confirmTitle' => 'Delete post?',
			'posts.deletePost.confirmMessage' => 'This action is irreversible. The post will be permanently removed.',
			'posts.deletePost.confirmButton' => 'Delete',
			'posts.deletePost.cancelButton' => 'Cancel',
			'posts.deletePost.success' => 'Post deleted',
			'posts.deletePost.errors.forbidden' => 'You can only delete your own posts',
			'posts.deletePost.errors.generic' => 'Failed to delete post. Please try again.',
			'posts.eraseDbPost.tooltip' => 'Erase post (superuser)',
			'posts.eraseDbPost.confirmTitle' => 'Erase post?',
			'posts.eraseDbPost.confirmMessage' => 'This post will be permanently erased. This action cannot be undone.',
			'posts.eraseDbPost.confirmButton' => 'Erase',
			'posts.eraseDbPost.cancelButton' => 'Cancel',
			'posts.eraseDbPost.success' => 'Post erased',
			'posts.eraseDbPost.errors.forbidden' => 'You do not have permission to erase posts',
			'posts.eraseDbPost.errors.generic' => 'Failed to erase post. Please try again.',
			'posts.pendingPosts.title' => 'Pending Posts',
			'posts.pendingPosts.empty' => 'No pending posts',
			'posts.pendingPosts.loadError' => 'Failed to load pending posts',
			'posts.pendingPosts.loadMoreError' => 'Failed to load more',
			'posts.pendingPosts.eventCount' => 'Events',
			'posts.moderatePost.title' => 'Moderate Post',
			'posts.moderatePost.tabs.post' => 'Post',
			'posts.moderatePost.tabs.moderation' => 'Moderation',
			'posts.moderatePost.log.empty' => 'No moderation history yet',
			'posts.moderatePost.log.loadError' => 'Failed to load moderation history',
			'posts.moderatePost.log.eventTypes.moderatorReview' => 'Moderator Review',
			'posts.moderatePost.log.eventTypes.authorRevision' => 'Author Revision',
			'posts.moderatePost.log.actions.approved' => 'Approved',
			'posts.moderatePost.log.actions.changesRequested' => 'Changes Requested',
			'posts.moderatePost.actions.approve' => 'Approve',
			'posts.moderatePost.actions.requestChanges' => 'Request Changes',
			'posts.moderatePost.actions.messageHint' => 'Add a comment (required for rejection)',
			'posts.moderatePost.actions.messageRequiredError' => 'A message is required when requesting changes',
			'posts.moderatePost.errors.forbidden' => 'You do not have permission to moderate this post',
			'posts.moderatePost.errors.notFound' => 'Post not found',
			'posts.moderatePost.errors.conflict' => 'This post has already been moderated. Return to the queue.',
			'posts.moderatePost.errors.generic' => 'Failed to submit. Please try again.',
			'posts.createPost.title' => 'New Post',
			'posts.createPost.titleLabel' => 'Title',
			'posts.createPost.titleHint' => 'Post title',
			'posts.createPost.mediaUrlLabel' => 'Media URL (optional)',
			'posts.createPost.mediaUrlHint' => 'https://...',
			'posts.createPost.textLabel' => 'Text (Markdown)',
			'posts.createPost.textHint' => 'Write your post...',
			'posts.createPost.previewLabel' => 'Preview',
			'posts.createPost.publishButton' => 'Publish',
			'posts.createPost.fabTooltip' => 'New post',
			'posts.createPost.errors.titleTooShort' => 'Title must be at least 2 characters',
			'posts.createPost.errors.titleTooLong' => 'Title must be at most 30 characters',
			'posts.createPost.errors.mediaUrlEmpty' => 'Media URL cannot be empty if provided',
			'posts.createPost.errors.textTooShort' => 'Text must be at least 100 characters',
			'posts.createPost.errors.textTooLong' => 'Text must be at most 63206 characters',
			'posts.createPost.errors.forbidden' => 'You can only publish posts as yourself',
			'posts.createPost.errors.generic' => 'Failed to publish post. Please try again.',
			'userMenu.myProfile' => 'My Profile',
			'userMenu.myPosts' => 'My Posts',
			'users.title' => 'Users',
			'users.list.loadMoreError' => 'Failed to load more users',
			'users.list.userDetails' => 'Details',
			'users.list.userPosts' => 'Posts',
			'users.details.email' => 'Email',
			'users.details.tier' => 'Tier',
			'users.details.tierSince' => 'Tier since',
			'users.details.notFound' => 'User not found',
			'users.details.loadError' => 'Failed to load user',
			'users.create.title' => 'Create User',
			'users.create.name' => 'Name',
			'users.create.username' => 'Username',
			'users.create.email' => 'Email',
			'users.create.password' => 'Password',
			'users.create.submit' => 'Create',
			'users.create.success' => 'User created successfully',
			'users.create.errors.required' => 'This field is required',
			'users.create.errors.emailInvalid' => 'Please enter a valid email address',
			'users.create.errors.passwordTooShort' => 'Password must be at least 8 characters',
			'users.create.errors.usernameTaken' => 'Username already taken',
			'users.create.errors.emailTaken' => 'Email already taken',
			'users.create.errors.generic' => 'Something went wrong. Please try again.',
			'users.delete.tooltip' => 'Delete account',
			'users.delete.confirmTitle' => 'Delete account?',
			'users.delete.confirmMessage' => 'This will permanently delete your account. This action cannot be undone.',
			'users.delete.confirmButton' => 'Delete',
			'users.delete.success' => 'Account deleted',
			'users.delete.errors.forbidden' => 'You can only delete your own account.',
			'users.delete.errors.unauthorized' => 'Session expired.',
			'users.delete.errors.notFound' => 'User not found.',
			'users.delete.errors.generic' => 'Failed to delete account.',
			'users.eraseDbUser.tooltip' => 'Erase from database',
			'users.eraseDbUser.confirmTitle' => 'Erase account permanently?',
			'users.eraseDbUser.confirmMessage' => 'This will permanently delete your account from the database. This action cannot be undone.',
			'users.eraseDbUser.confirmButton' => 'Erase permanently',
			'users.eraseDbUser.success' => 'Account erased from the database',
			'users.eraseDbUser.errors.forbidden' => 'You can only erase your own account',
			'users.eraseDbUser.errors.unauthorized' => 'Session expired. Please log in again',
			'users.eraseDbUser.errors.notFound' => 'User not found',
			'users.eraseDbUser.errors.generic' => 'Failed to erase account. Please try again',
			'users.edit.title' => 'Edit User',
			'users.edit.name' => 'Name',
			'users.edit.username' => 'Username',
			'users.edit.email' => 'Email',
			'users.edit.profileImageUrl' => 'Profile Image URL',
			'users.edit.save' => 'Save',
			'users.edit.success' => 'User updated successfully',
			'users.edit.errors.required' => 'This field is required',
			'users.edit.errors.emailInvalid' => 'Please enter a valid email address',
			'users.edit.errors.usernameTaken' => 'Username already taken',
			'users.edit.errors.notFound' => 'User not found',
			'users.edit.errors.nothingToUpdate' => 'No changes to save',
			'users.edit.errors.forbidden' => 'You can only edit your own profile.',
			'users.edit.errors.unauthorized' => 'Session expired.',
			'users.edit.errors.generic' => 'Something went wrong. Please try again.',
			'users.updateTier.tooltip' => 'Change tier',
			'users.updateTier.sheetTitle' => 'Change User Tier',
			'users.updateTier.selectTier' => 'Select tier',
			'users.updateTier.confirm' => 'Confirm',
			'users.updateTier.success' => 'User tier updated',
			'users.updateTier.errors.permissionDenied' => 'You don\'t have permission to change tiers.',
			'users.updateTier.errors.notFound' => 'User or tier not found.',
			'users.updateTier.errors.forbidden' => 'Permission denied.',
			'users.updateTier.errors.unauthorized' => 'Session expired.',
			'users.updateTier.errors.generic' => 'Failed to update tier. Please try again.',
			'users.moderator.badge' => 'Moderator',
			'users.moderator.assign' => 'Assign Moderator',
			'users.moderator.revoke' => 'Revoke Moderator',
			'users.moderator.errors.conflict' => 'Action not applicable — moderator status is already in sync.',
			'users.moderator.errors.forbidden' => 'You do not have permission to manage moderators.',
			'users.moderator.errors.generic' => 'Failed to update moderator status. Please try again.',
			_ => null,
		};
	}
}
