///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
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
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsAuthEn auth = TranslationsAuthEn._(_root);
	late final TranslationsAppEn app = TranslationsAppEn._(_root);
	late final TranslationsNavEn nav = TranslationsNavEn._(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn._(_root);
	late final TranslationsTiersEn tiers = TranslationsTiersEn._(_root);
	late final TranslationsPostsEn posts = TranslationsPostsEn._(_root);
	late final TranslationsUsersEn users = TranslationsUsersEn._(_root);
}

// Path: auth
class TranslationsAuthEn {
	TranslationsAuthEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsAuthLoginEn login = TranslationsAuthLoginEn._(_root);
	late final TranslationsAuthLogoutEn logout = TranslationsAuthLogoutEn._(_root);

	/// en: 'Session expired. Please sign in again.'
	String get sessionExpired => 'Session expired. Please sign in again.';
}

// Path: app
class TranslationsAppEn {
	TranslationsAppEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flutter App'
	String get title => 'Flutter App';
}

// Path: nav
class TranslationsNavEn {
	TranslationsNavEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Users'
	String get users => 'Users';

	/// en: 'Posts'
	String get posts => 'Posts';

	/// en: 'Tiers'
	String get tiers => 'Tiers';

	/// en: 'Pending'
	String get pending => 'Pending';
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Something went wrong'
	String get error => 'Something went wrong';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Cancel'
	String get cancel => 'Cancel';
}

// Path: tiers
class TranslationsTiersEn {
	TranslationsTiersEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsTiersListTiersEn listTiers = TranslationsTiersListTiersEn._(_root);
	late final TranslationsTiersCreateTierEn createTier = TranslationsTiersCreateTierEn._(_root);
	late final TranslationsTiersTierDetailsEn tierDetails = TranslationsTiersTierDetailsEn._(_root);
	late final TranslationsTiersEditTierEn editTier = TranslationsTiersEditTierEn._(_root);
	late final TranslationsTiersDeleteTierEn deleteTier = TranslationsTiersDeleteTierEn._(_root);
}

// Path: posts
class TranslationsPostsEn {
	TranslationsPostsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsPostsPostDetailsEn postDetails = TranslationsPostsPostDetailsEn._(_root);
	late final TranslationsPostsPostStatusEn postStatus = TranslationsPostsPostStatusEn._(_root);
	late final TranslationsPostsEditPostEn editPost = TranslationsPostsEditPostEn._(_root);
	late final TranslationsPostsListPostsEn listPosts = TranslationsPostsListPostsEn._(_root);
	late final TranslationsPostsUserPostsEn userPosts = TranslationsPostsUserPostsEn._(_root);
	late final TranslationsPostsDeletePostEn deletePost = TranslationsPostsDeletePostEn._(_root);
	late final TranslationsPostsEraseDbPostEn eraseDbPost = TranslationsPostsEraseDbPostEn._(_root);
	late final TranslationsPostsPendingPostsEn pendingPosts = TranslationsPostsPendingPostsEn._(_root);
	late final TranslationsPostsModeratePostEn moderatePost = TranslationsPostsModeratePostEn._(_root);
	late final TranslationsPostsCreatePostEn createPost = TranslationsPostsCreatePostEn._(_root);
}

// Path: users
class TranslationsUsersEn {
	TranslationsUsersEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Users'
	String get title => 'Users';

	late final TranslationsUsersListEn list = TranslationsUsersListEn._(_root);
	late final TranslationsUsersDetailsEn details = TranslationsUsersDetailsEn._(_root);
	late final TranslationsUsersCreateEn create = TranslationsUsersCreateEn._(_root);
	late final TranslationsUsersDeleteEn delete = TranslationsUsersDeleteEn._(_root);
	late final TranslationsUsersEraseDbUserEn eraseDbUser = TranslationsUsersEraseDbUserEn._(_root);
	late final TranslationsUsersEditEn edit = TranslationsUsersEditEn._(_root);
	late final TranslationsUsersUpdateTierEn updateTier = TranslationsUsersUpdateTierEn._(_root);
	late final TranslationsUsersModeratorEn moderator = TranslationsUsersModeratorEn._(_root);
}

// Path: auth.login
class TranslationsAuthLoginEn {
	TranslationsAuthLoginEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sign in'
	String get title => 'Sign in';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Sign in'
	String get submit => 'Sign in';

	/// en: 'Sign in'
	String get signInButton => 'Sign in';

	late final TranslationsAuthLoginErrorsEn errors = TranslationsAuthLoginErrorsEn._(_root);
}

// Path: auth.logout
class TranslationsAuthLogoutEn {
	TranslationsAuthLogoutEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sign out?'
	String get confirmTitle => 'Sign out?';

	/// en: 'You will need to sign in again.'
	String get confirmMessage => 'You will need to sign in again.';

	/// en: 'Sign out'
	String get confirm => 'Sign out';

	/// en: 'Cancel'
	String get cancel => 'Cancel';
}

// Path: tiers.listTiers
class TranslationsTiersListTiersEn {
	TranslationsTiersListTiersEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Tiers'
	String get title => 'Tiers';

	/// en: 'Failed to load tiers'
	String get loadError => 'Failed to load tiers';

	/// en: 'Failed to load more tiers'
	String get loadMoreError => 'Failed to load more tiers';

	/// en: 'No tiers found'
	String get empty => 'No tiers found';
}

// Path: tiers.createTier
class TranslationsTiersCreateTierEn {
	TranslationsTiersCreateTierEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create Tier'
	String get title => 'Create Tier';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Create'
	String get submit => 'Create';

	/// en: 'Add tier'
	String get fabTooltip => 'Add tier';

	/// en: 'Tier created'
	String get success => 'Tier created';

	late final TranslationsTiersCreateTierErrorsEn errors = TranslationsTiersCreateTierErrorsEn._(_root);
}

// Path: tiers.tierDetails
class TranslationsTiersTierDetailsEn {
	TranslationsTiersTierDetailsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Tier details'
	String get title => 'Tier details';

	/// en: 'ID'
	String get id => 'ID';

	/// en: 'Created'
	String get createdAt => 'Created';

	/// en: 'Tier not found'
	String get notFound => 'Tier not found';

	/// en: 'Failed to load tier'
	String get loadError => 'Failed to load tier';

	/// en: 'Access denied'
	String get permissionDenied => 'Access denied';
}

// Path: tiers.editTier
class TranslationsTiersEditTierEn {
	TranslationsTiersEditTierEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Edit Tier'
	String get title => 'Edit Tier';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Tier updated'
	String get success => 'Tier updated';

	late final TranslationsTiersEditTierErrorsEn errors = TranslationsTiersEditTierErrorsEn._(_root);
}

// Path: tiers.deleteTier
class TranslationsTiersDeleteTierEn {
	TranslationsTiersDeleteTierEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete tier'
	String get tooltip => 'Delete tier';

	/// en: 'Delete tier'
	String get confirmTitle => 'Delete tier';

	/// en: 'Are you sure you want to delete tier "{name}"? This action cannot be undone.'
	String get confirmMessage => 'Are you sure you want to delete tier "{name}"? This action cannot be undone.';

	/// en: 'Delete'
	String get confirmButton => 'Delete';

	/// en: 'Cancel'
	String get cancelButton => 'Cancel';

	/// en: 'Tier deleted'
	String get success => 'Tier deleted';

	late final TranslationsTiersDeleteTierErrorsEn errors = TranslationsTiersDeleteTierErrorsEn._(_root);
}

// Path: posts.postDetails
class TranslationsPostsPostDetailsEn {
	TranslationsPostsPostDetailsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Post'
	String get title => 'Post';

	/// en: 'Failed to load post'
	String get loadError => 'Failed to load post';
}

// Path: posts.postStatus
class TranslationsPostsPostStatusEn {
	TranslationsPostsPostStatusEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Pending Review'
	String get pendingReview => 'Pending Review';

	/// en: 'Approved'
	String get approved => 'Approved';

	/// en: 'Changes Requested'
	String get changesRequested => 'Changes Requested';
}

// Path: posts.editPost
class TranslationsPostsEditPostEn {
	TranslationsPostsEditPostEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Edit Post'
	String get title => 'Edit Post';

	/// en: 'Title'
	String get titleLabel => 'Title';

	/// en: 'Post title'
	String get titleHint => 'Post title';

	/// en: 'Media URL (optional)'
	String get mediaUrlLabel => 'Media URL (optional)';

	/// en: 'https://...'
	String get mediaUrlHint => 'https://...';

	/// en: 'Text (Markdown)'
	String get textLabel => 'Text (Markdown)';

	/// en: 'Write your post...'
	String get textHint => 'Write your post...';

	/// en: 'Preview'
	String get previewLabel => 'Preview';

	/// en: 'Save'
	String get saveButton => 'Save';

	late final TranslationsPostsEditPostTabsEn tabs = TranslationsPostsEditPostTabsEn._(_root);
	late final TranslationsPostsEditPostRevisionMessageEn revisionMessage = TranslationsPostsEditPostRevisionMessageEn._(_root);

	/// en: 'This post is approved and can no longer be edited.'
	String get approvedHint => 'This post is approved and can no longer be edited.';

	late final TranslationsPostsEditPostLogEn log = TranslationsPostsEditPostLogEn._(_root);
	late final TranslationsPostsEditPostErrorsEn errors = TranslationsPostsEditPostErrorsEn._(_root);
}

// Path: posts.listPosts
class TranslationsPostsListPostsEn {
	TranslationsPostsListPostsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No posts yet'
	String get empty => 'No posts yet';

	/// en: 'Failed to load posts'
	String get loadError => 'Failed to load posts';

	/// en: 'New post'
	String get fabTooltip => 'New post';

	/// en: 'Open'
	String get openPost => 'Open';
}

// Path: posts.userPosts
class TranslationsPostsUserPostsEn {
	TranslationsPostsUserPostsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '$username's posts'
	String title({required Object username}) => '${username}\'s posts';

	/// en: 'No posts yet'
	String get empty => 'No posts yet';

	/// en: 'Failed to load posts'
	String get loadError => 'Failed to load posts';

	/// en: 'Open'
	String get openPost => 'Open';
}

// Path: posts.deletePost
class TranslationsPostsDeletePostEn {
	TranslationsPostsDeletePostEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete post'
	String get tooltip => 'Delete post';

	/// en: 'Delete post?'
	String get confirmTitle => 'Delete post?';

	/// en: 'This action is irreversible. The post will be permanently removed.'
	String get confirmMessage => 'This action is irreversible. The post will be permanently removed.';

	/// en: 'Delete'
	String get confirmButton => 'Delete';

	/// en: 'Cancel'
	String get cancelButton => 'Cancel';

	/// en: 'Post deleted'
	String get success => 'Post deleted';

	late final TranslationsPostsDeletePostErrorsEn errors = TranslationsPostsDeletePostErrorsEn._(_root);
}

// Path: posts.eraseDbPost
class TranslationsPostsEraseDbPostEn {
	TranslationsPostsEraseDbPostEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Erase post (superuser)'
	String get tooltip => 'Erase post (superuser)';

	/// en: 'Erase post?'
	String get confirmTitle => 'Erase post?';

	/// en: 'This post will be permanently erased. This action cannot be undone.'
	String get confirmMessage => 'This post will be permanently erased. This action cannot be undone.';

	/// en: 'Erase'
	String get confirmButton => 'Erase';

	/// en: 'Cancel'
	String get cancelButton => 'Cancel';

	/// en: 'Post erased'
	String get success => 'Post erased';

	late final TranslationsPostsEraseDbPostErrorsEn errors = TranslationsPostsEraseDbPostErrorsEn._(_root);
}

// Path: posts.pendingPosts
class TranslationsPostsPendingPostsEn {
	TranslationsPostsPendingPostsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Pending Posts'
	String get title => 'Pending Posts';

	/// en: 'No pending posts'
	String get empty => 'No pending posts';

	/// en: 'Failed to load pending posts'
	String get loadError => 'Failed to load pending posts';

	/// en: 'Failed to load more'
	String get loadMoreError => 'Failed to load more';

	/// en: 'Events'
	String get eventCount => 'Events';
}

// Path: posts.moderatePost
class TranslationsPostsModeratePostEn {
	TranslationsPostsModeratePostEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Moderate Post'
	String get title => 'Moderate Post';

	late final TranslationsPostsModeratePostTabsEn tabs = TranslationsPostsModeratePostTabsEn._(_root);
	late final TranslationsPostsModeratePostLogEn log = TranslationsPostsModeratePostLogEn._(_root);
	late final TranslationsPostsModeratePostActionsEn actions = TranslationsPostsModeratePostActionsEn._(_root);
	late final TranslationsPostsModeratePostErrorsEn errors = TranslationsPostsModeratePostErrorsEn._(_root);
}

// Path: posts.createPost
class TranslationsPostsCreatePostEn {
	TranslationsPostsCreatePostEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'New Post'
	String get title => 'New Post';

	/// en: 'Title'
	String get titleLabel => 'Title';

	/// en: 'Post title'
	String get titleHint => 'Post title';

	/// en: 'Media URL (optional)'
	String get mediaUrlLabel => 'Media URL (optional)';

	/// en: 'https://...'
	String get mediaUrlHint => 'https://...';

	/// en: 'Text (Markdown)'
	String get textLabel => 'Text (Markdown)';

	/// en: 'Write your post...'
	String get textHint => 'Write your post...';

	/// en: 'Preview'
	String get previewLabel => 'Preview';

	/// en: 'Publish'
	String get publishButton => 'Publish';

	/// en: 'New post'
	String get fabTooltip => 'New post';

	late final TranslationsPostsCreatePostErrorsEn errors = TranslationsPostsCreatePostErrorsEn._(_root);
}

// Path: users.list
class TranslationsUsersListEn {
	TranslationsUsersListEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Failed to load more users'
	String get loadMoreError => 'Failed to load more users';

	/// en: 'Details'
	String get userDetails => 'Details';

	/// en: 'Posts'
	String get userPosts => 'Posts';
}

// Path: users.details
class TranslationsUsersDetailsEn {
	TranslationsUsersDetailsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'Tier'
	String get tier => 'Tier';

	/// en: 'Tier since'
	String get tierSince => 'Tier since';

	/// en: 'User not found'
	String get notFound => 'User not found';

	/// en: 'Failed to load user'
	String get loadError => 'Failed to load user';
}

// Path: users.create
class TranslationsUsersCreateEn {
	TranslationsUsersCreateEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create User'
	String get title => 'Create User';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Create'
	String get submit => 'Create';

	/// en: 'User created successfully'
	String get success => 'User created successfully';

	late final TranslationsUsersCreateErrorsEn errors = TranslationsUsersCreateErrorsEn._(_root);
}

// Path: users.delete
class TranslationsUsersDeleteEn {
	TranslationsUsersDeleteEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete account'
	String get tooltip => 'Delete account';

	/// en: 'Delete account?'
	String get confirmTitle => 'Delete account?';

	/// en: 'This will permanently delete your account. This action cannot be undone.'
	String get confirmMessage => 'This will permanently delete your account. This action cannot be undone.';

	/// en: 'Delete'
	String get confirmButton => 'Delete';

	/// en: 'Account deleted'
	String get success => 'Account deleted';

	late final TranslationsUsersDeleteErrorsEn errors = TranslationsUsersDeleteErrorsEn._(_root);
}

// Path: users.eraseDbUser
class TranslationsUsersEraseDbUserEn {
	TranslationsUsersEraseDbUserEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Erase from database'
	String get tooltip => 'Erase from database';

	/// en: 'Erase account permanently?'
	String get confirmTitle => 'Erase account permanently?';

	/// en: 'This will permanently delete your account from the database. This action cannot be undone.'
	String get confirmMessage => 'This will permanently delete your account from the database. This action cannot be undone.';

	/// en: 'Erase permanently'
	String get confirmButton => 'Erase permanently';

	/// en: 'Account erased from the database'
	String get success => 'Account erased from the database';

	late final TranslationsUsersEraseDbUserErrorsEn errors = TranslationsUsersEraseDbUserErrorsEn._(_root);
}

// Path: users.edit
class TranslationsUsersEditEn {
	TranslationsUsersEditEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Edit User'
	String get title => 'Edit User';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Username'
	String get username => 'Username';

	/// en: 'Email'
	String get email => 'Email';

	/// en: 'Profile Image URL'
	String get profileImageUrl => 'Profile Image URL';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'User updated successfully'
	String get success => 'User updated successfully';

	late final TranslationsUsersEditErrorsEn errors = TranslationsUsersEditErrorsEn._(_root);
}

// Path: users.updateTier
class TranslationsUsersUpdateTierEn {
	TranslationsUsersUpdateTierEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Change tier'
	String get tooltip => 'Change tier';

	/// en: 'Change User Tier'
	String get sheetTitle => 'Change User Tier';

	/// en: 'Select tier'
	String get selectTier => 'Select tier';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'User tier updated'
	String get success => 'User tier updated';

	late final TranslationsUsersUpdateTierErrorsEn errors = TranslationsUsersUpdateTierErrorsEn._(_root);
}

// Path: users.moderator
class TranslationsUsersModeratorEn {
	TranslationsUsersModeratorEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Moderator'
	String get badge => 'Moderator';

	/// en: 'Assign Moderator'
	String get assign => 'Assign Moderator';

	/// en: 'Revoke Moderator'
	String get revoke => 'Revoke Moderator';

	late final TranslationsUsersModeratorErrorsEn errors = TranslationsUsersModeratorErrorsEn._(_root);
}

// Path: auth.login.errors
class TranslationsAuthLoginErrorsEn {
	TranslationsAuthLoginErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Required'
	String get required => 'Required';

	/// en: 'Invalid username or password'
	String get invalidCredentials => 'Invalid username or password';

	/// en: 'Sign in failed. Try again.'
	String get generic => 'Sign in failed. Try again.';
}

// Path: tiers.createTier.errors
class TranslationsTiersCreateTierErrorsEn {
	TranslationsTiersCreateTierErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This field is required'
	String get required => 'This field is required';

	/// en: 'Failed to create tier'
	String get generic => 'Failed to create tier';
}

// Path: tiers.editTier.errors
class TranslationsTiersEditTierErrorsEn {
	TranslationsTiersEditTierErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This field is required'
	String get required => 'This field is required';

	/// en: 'Tier not found'
	String get notFound => 'Tier not found';

	/// en: 'Access denied'
	String get permissionDenied => 'Access denied';

	/// en: 'Failed to update tier'
	String get generic => 'Failed to update tier';
}

// Path: tiers.deleteTier.errors
class TranslationsTiersDeleteTierErrorsEn {
	TranslationsTiersDeleteTierErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Tier not found'
	String get notFound => 'Tier not found';

	/// en: 'Access denied'
	String get forbidden => 'Access denied';

	/// en: 'Session expired'
	String get unauthorized => 'Session expired';

	/// en: 'Failed to delete tier'
	String get generic => 'Failed to delete tier';
}

// Path: posts.editPost.tabs
class TranslationsPostsEditPostTabsEn {
	TranslationsPostsEditPostTabsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Moderation Log'
	String get log => 'Moderation Log';
}

// Path: posts.editPost.revisionMessage
class TranslationsPostsEditPostRevisionMessageEn {
	TranslationsPostsEditPostRevisionMessageEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Revision message'
	String get label => 'Revision message';

	/// en: 'Describe what you changed to address the moderator's feedback'
	String get hint => 'Describe what you changed to address the moderator\'s feedback';
}

// Path: posts.editPost.log
class TranslationsPostsEditPostLogEn {
	TranslationsPostsEditPostLogEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No moderation history yet'
	String get empty => 'No moderation history yet';

	/// en: 'Failed to load moderation history'
	String get loadError => 'Failed to load moderation history';
}

// Path: posts.editPost.errors
class TranslationsPostsEditPostErrorsEn {
	TranslationsPostsEditPostErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Title must be at least 2 characters'
	String get titleTooShort => 'Title must be at least 2 characters';

	/// en: 'Title must be at most 30 characters'
	String get titleTooLong => 'Title must be at most 30 characters';

	/// en: 'Media URL cannot be empty if provided'
	String get mediaUrlEmpty => 'Media URL cannot be empty if provided';

	/// en: 'Text must be at least 100 characters'
	String get textTooShort => 'Text must be at least 100 characters';

	/// en: 'Text must be at most 63206 characters'
	String get textTooLong => 'Text must be at most 63206 characters';

	/// en: 'You can only edit your own posts'
	String get forbidden => 'You can only edit your own posts';

	/// en: 'Failed to save post. Please try again.'
	String get generic => 'Failed to save post. Please try again.';

	/// en: 'A revision message is required.'
	String get revisionMessageRequired => 'A revision message is required.';

	/// en: 'The post status changed while you were editing. Check the current status.'
	String get conflict => 'The post status changed while you were editing. Check the current status.';

	/// en: 'Post not found.'
	String get notFound => 'Post not found.';
}

// Path: posts.deletePost.errors
class TranslationsPostsDeletePostErrorsEn {
	TranslationsPostsDeletePostErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'You can only delete your own posts'
	String get forbidden => 'You can only delete your own posts';

	/// en: 'Failed to delete post. Please try again.'
	String get generic => 'Failed to delete post. Please try again.';
}

// Path: posts.eraseDbPost.errors
class TranslationsPostsEraseDbPostErrorsEn {
	TranslationsPostsEraseDbPostErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'You do not have permission to erase posts'
	String get forbidden => 'You do not have permission to erase posts';

	/// en: 'Failed to erase post. Please try again.'
	String get generic => 'Failed to erase post. Please try again.';
}

// Path: posts.moderatePost.tabs
class TranslationsPostsModeratePostTabsEn {
	TranslationsPostsModeratePostTabsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Post'
	String get post => 'Post';

	/// en: 'Moderation'
	String get moderation => 'Moderation';
}

// Path: posts.moderatePost.log
class TranslationsPostsModeratePostLogEn {
	TranslationsPostsModeratePostLogEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'No moderation history yet'
	String get empty => 'No moderation history yet';

	/// en: 'Failed to load moderation history'
	String get loadError => 'Failed to load moderation history';

	late final TranslationsPostsModeratePostLogEventTypesEn eventTypes = TranslationsPostsModeratePostLogEventTypesEn._(_root);
	late final TranslationsPostsModeratePostLogActionsEn actions = TranslationsPostsModeratePostLogActionsEn._(_root);
}

// Path: posts.moderatePost.actions
class TranslationsPostsModeratePostActionsEn {
	TranslationsPostsModeratePostActionsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Approve'
	String get approve => 'Approve';

	/// en: 'Request Changes'
	String get requestChanges => 'Request Changes';

	/// en: 'Add a comment (required for rejection)'
	String get messageHint => 'Add a comment (required for rejection)';

	/// en: 'A message is required when requesting changes'
	String get messageRequiredError => 'A message is required when requesting changes';
}

// Path: posts.moderatePost.errors
class TranslationsPostsModeratePostErrorsEn {
	TranslationsPostsModeratePostErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'You do not have permission to moderate this post'
	String get forbidden => 'You do not have permission to moderate this post';

	/// en: 'Post not found'
	String get notFound => 'Post not found';

	/// en: 'This post has already been moderated. Return to the queue.'
	String get conflict => 'This post has already been moderated. Return to the queue.';

	/// en: 'Failed to submit. Please try again.'
	String get generic => 'Failed to submit. Please try again.';
}

// Path: posts.createPost.errors
class TranslationsPostsCreatePostErrorsEn {
	TranslationsPostsCreatePostErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Title must be at least 2 characters'
	String get titleTooShort => 'Title must be at least 2 characters';

	/// en: 'Title must be at most 30 characters'
	String get titleTooLong => 'Title must be at most 30 characters';

	/// en: 'Media URL cannot be empty if provided'
	String get mediaUrlEmpty => 'Media URL cannot be empty if provided';

	/// en: 'Text must be at least 100 characters'
	String get textTooShort => 'Text must be at least 100 characters';

	/// en: 'Text must be at most 63206 characters'
	String get textTooLong => 'Text must be at most 63206 characters';

	/// en: 'You can only publish posts as yourself'
	String get forbidden => 'You can only publish posts as yourself';

	/// en: 'Failed to publish post. Please try again.'
	String get generic => 'Failed to publish post. Please try again.';
}

// Path: users.create.errors
class TranslationsUsersCreateErrorsEn {
	TranslationsUsersCreateErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This field is required'
	String get required => 'This field is required';

	/// en: 'Please enter a valid email address'
	String get emailInvalid => 'Please enter a valid email address';

	/// en: 'Password must be at least 8 characters'
	String get passwordTooShort => 'Password must be at least 8 characters';

	/// en: 'Username already taken'
	String get usernameTaken => 'Username already taken';

	/// en: 'Email already taken'
	String get emailTaken => 'Email already taken';

	/// en: 'Something went wrong. Please try again.'
	String get generic => 'Something went wrong. Please try again.';
}

// Path: users.delete.errors
class TranslationsUsersDeleteErrorsEn {
	TranslationsUsersDeleteErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'You can only delete your own account.'
	String get forbidden => 'You can only delete your own account.';

	/// en: 'Session expired.'
	String get unauthorized => 'Session expired.';

	/// en: 'User not found.'
	String get notFound => 'User not found.';

	/// en: 'Failed to delete account.'
	String get generic => 'Failed to delete account.';
}

// Path: users.eraseDbUser.errors
class TranslationsUsersEraseDbUserErrorsEn {
	TranslationsUsersEraseDbUserErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'You can only erase your own account'
	String get forbidden => 'You can only erase your own account';

	/// en: 'Session expired. Please log in again'
	String get unauthorized => 'Session expired. Please log in again';

	/// en: 'User not found'
	String get notFound => 'User not found';

	/// en: 'Failed to erase account. Please try again'
	String get generic => 'Failed to erase account. Please try again';
}

// Path: users.edit.errors
class TranslationsUsersEditErrorsEn {
	TranslationsUsersEditErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This field is required'
	String get required => 'This field is required';

	/// en: 'Please enter a valid email address'
	String get emailInvalid => 'Please enter a valid email address';

	/// en: 'Username already taken'
	String get usernameTaken => 'Username already taken';

	/// en: 'User not found'
	String get notFound => 'User not found';

	/// en: 'No changes to save'
	String get nothingToUpdate => 'No changes to save';

	/// en: 'You can only edit your own profile.'
	String get forbidden => 'You can only edit your own profile.';

	/// en: 'Session expired.'
	String get unauthorized => 'Session expired.';

	/// en: 'Something went wrong. Please try again.'
	String get generic => 'Something went wrong. Please try again.';
}

// Path: users.updateTier.errors
class TranslationsUsersUpdateTierErrorsEn {
	TranslationsUsersUpdateTierErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'You don't have permission to change tiers.'
	String get permissionDenied => 'You don\'t have permission to change tiers.';

	/// en: 'User or tier not found.'
	String get notFound => 'User or tier not found.';

	/// en: 'Permission denied.'
	String get forbidden => 'Permission denied.';

	/// en: 'Session expired.'
	String get unauthorized => 'Session expired.';

	/// en: 'Failed to update tier. Please try again.'
	String get generic => 'Failed to update tier. Please try again.';
}

// Path: users.moderator.errors
class TranslationsUsersModeratorErrorsEn {
	TranslationsUsersModeratorErrorsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Action not applicable — moderator status is already in sync.'
	String get conflict => 'Action not applicable — moderator status is already in sync.';

	/// en: 'You do not have permission to manage moderators.'
	String get forbidden => 'You do not have permission to manage moderators.';

	/// en: 'Failed to update moderator status. Please try again.'
	String get generic => 'Failed to update moderator status. Please try again.';
}

// Path: posts.moderatePost.log.eventTypes
class TranslationsPostsModeratePostLogEventTypesEn {
	TranslationsPostsModeratePostLogEventTypesEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Moderator Review'
	String get moderatorReview => 'Moderator Review';

	/// en: 'Author Revision'
	String get authorRevision => 'Author Revision';
}

// Path: posts.moderatePost.log.actions
class TranslationsPostsModeratePostLogActionsEn {
	TranslationsPostsModeratePostLogActionsEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Approved'
	String get approved => 'Approved';

	/// en: 'Changes Requested'
	String get changesRequested => 'Changes Requested';
}

/// The flat map containing all translations for locale <en>.
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
