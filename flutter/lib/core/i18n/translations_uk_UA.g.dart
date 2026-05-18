///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsUkUa with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsUkUa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ukUa,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <uk-UA>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsUkUa _root = this; // ignore: unused_field

	@override 
	TranslationsUkUa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsUkUa(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAuthUkUa auth = _TranslationsAuthUkUa._(_root);
	@override late final _TranslationsAppUkUa app = _TranslationsAppUkUa._(_root);
	@override late final _TranslationsNavUkUa nav = _TranslationsNavUkUa._(_root);
	@override late final _TranslationsCommonUkUa common = _TranslationsCommonUkUa._(_root);
	@override late final _TranslationsTiersUkUa tiers = _TranslationsTiersUkUa._(_root);
	@override late final _TranslationsPostsUkUa posts = _TranslationsPostsUkUa._(_root);
	@override late final _TranslationsUsersUkUa users = _TranslationsUsersUkUa._(_root);
}

// Path: auth
class _TranslationsAuthUkUa implements TranslationsAuthEnUs {
	_TranslationsAuthUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsAuthLoginUkUa login = _TranslationsAuthLoginUkUa._(_root);
	@override late final _TranslationsAuthLogoutUkUa logout = _TranslationsAuthLogoutUkUa._(_root);
	@override String get sessionExpired => 'Сесія закінчилася. Увійдіть знову.';
}

// Path: app
class _TranslationsAppUkUa implements TranslationsAppEnUs {
	_TranslationsAppUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flutter App';
}

// Path: nav
class _TranslationsNavUkUa implements TranslationsNavEnUs {
	_TranslationsNavUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get users => 'Користувачі';
	@override String get posts => 'Публікації';
	@override String get tiers => 'Рівні';
	@override String get pending => 'Очікують';
}

// Path: common
class _TranslationsCommonUkUa implements TranslationsCommonEnUs {
	_TranslationsCommonUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Завантаження...';
	@override String get error => 'Щось пішло не так';
	@override String get retry => 'Повторити';
	@override String get back => 'Назад';
	@override String get cancel => 'Скасувати';
}

// Path: tiers
class _TranslationsTiersUkUa implements TranslationsTiersEnUs {
	_TranslationsTiersUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsTiersListTiersUkUa listTiers = _TranslationsTiersListTiersUkUa._(_root);
	@override late final _TranslationsTiersCreateTierUkUa createTier = _TranslationsTiersCreateTierUkUa._(_root);
	@override late final _TranslationsTiersTierDetailsUkUa tierDetails = _TranslationsTiersTierDetailsUkUa._(_root);
	@override late final _TranslationsTiersEditTierUkUa editTier = _TranslationsTiersEditTierUkUa._(_root);
	@override late final _TranslationsTiersDeleteTierUkUa deleteTier = _TranslationsTiersDeleteTierUkUa._(_root);
}

// Path: posts
class _TranslationsPostsUkUa implements TranslationsPostsEnUs {
	_TranslationsPostsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsPostsPostDetailsUkUa postDetails = _TranslationsPostsPostDetailsUkUa._(_root);
	@override late final _TranslationsPostsPostStatusUkUa postStatus = _TranslationsPostsPostStatusUkUa._(_root);
	@override late final _TranslationsPostsEditPostUkUa editPost = _TranslationsPostsEditPostUkUa._(_root);
	@override late final _TranslationsPostsListPostsUkUa listPosts = _TranslationsPostsListPostsUkUa._(_root);
	@override late final _TranslationsPostsUserPostsUkUa userPosts = _TranslationsPostsUserPostsUkUa._(_root);
	@override late final _TranslationsPostsDeletePostUkUa deletePost = _TranslationsPostsDeletePostUkUa._(_root);
	@override late final _TranslationsPostsEraseDbPostUkUa eraseDbPost = _TranslationsPostsEraseDbPostUkUa._(_root);
	@override late final _TranslationsPostsPendingPostsUkUa pendingPosts = _TranslationsPostsPendingPostsUkUa._(_root);
	@override late final _TranslationsPostsModeratePostUkUa moderatePost = _TranslationsPostsModeratePostUkUa._(_root);
	@override late final _TranslationsPostsCreatePostUkUa createPost = _TranslationsPostsCreatePostUkUa._(_root);
}

// Path: users
class _TranslationsUsersUkUa implements TranslationsUsersEnUs {
	_TranslationsUsersUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Користувачі';
	@override late final _TranslationsUsersListUkUa list = _TranslationsUsersListUkUa._(_root);
	@override late final _TranslationsUsersDetailsUkUa details = _TranslationsUsersDetailsUkUa._(_root);
	@override late final _TranslationsUsersCreateUkUa create = _TranslationsUsersCreateUkUa._(_root);
	@override late final _TranslationsUsersDeleteUkUa delete = _TranslationsUsersDeleteUkUa._(_root);
	@override late final _TranslationsUsersEraseDbUserUkUa eraseDbUser = _TranslationsUsersEraseDbUserUkUa._(_root);
	@override late final _TranslationsUsersEditUkUa edit = _TranslationsUsersEditUkUa._(_root);
	@override late final _TranslationsUsersUpdateTierUkUa updateTier = _TranslationsUsersUpdateTierUkUa._(_root);
	@override late final _TranslationsUsersModeratorUkUa moderator = _TranslationsUsersModeratorUkUa._(_root);
}

// Path: auth.login
class _TranslationsAuthLoginUkUa implements TranslationsAuthLoginEnUs {
	_TranslationsAuthLoginUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Увійти';
	@override String get username => 'Ім\'я користувача';
	@override String get password => 'Пароль';
	@override String get submit => 'Увійти';
	@override String get signInButton => 'Увійти';
	@override late final _TranslationsAuthLoginErrorsUkUa errors = _TranslationsAuthLoginErrorsUkUa._(_root);
}

// Path: auth.logout
class _TranslationsAuthLogoutUkUa implements TranslationsAuthLogoutEnUs {
	_TranslationsAuthLogoutUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get confirmTitle => 'Вийти?';
	@override String get confirmMessage => 'Вам потрібно буде увійти знову.';
	@override String get confirm => 'Вийти';
	@override String get cancel => 'Скасувати';
}

// Path: tiers.listTiers
class _TranslationsTiersListTiersUkUa implements TranslationsTiersListTiersEnUs {
	_TranslationsTiersListTiersUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Рівні';
	@override String get loadError => 'Не вдалося завантажити рівні';
	@override String get loadMoreError => 'Не вдалося завантажити більше рівнів';
	@override String get empty => 'Рівні не знайдено';
}

// Path: tiers.createTier
class _TranslationsTiersCreateTierUkUa implements TranslationsTiersCreateTierEnUs {
	_TranslationsTiersCreateTierUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Створити рівень';
	@override String get name => 'Назва';
	@override String get submit => 'Створити';
	@override String get fabTooltip => 'Додати рівень';
	@override String get success => 'Рівень створено';
	@override late final _TranslationsTiersCreateTierErrorsUkUa errors = _TranslationsTiersCreateTierErrorsUkUa._(_root);
}

// Path: tiers.tierDetails
class _TranslationsTiersTierDetailsUkUa implements TranslationsTiersTierDetailsEnUs {
	_TranslationsTiersTierDetailsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Деталі рівня';
	@override String get id => 'ID';
	@override String get createdAt => 'Створено';
	@override String get notFound => 'Рівень не знайдено';
	@override String get loadError => 'Не вдалося завантажити рівень';
	@override String get permissionDenied => 'Доступ заборонено';
}

// Path: tiers.editTier
class _TranslationsTiersEditTierUkUa implements TranslationsTiersEditTierEnUs {
	_TranslationsTiersEditTierUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Редагувати рівень';
	@override String get name => 'Назва';
	@override String get save => 'Зберегти';
	@override String get success => 'Рівень оновлено';
	@override late final _TranslationsTiersEditTierErrorsUkUa errors = _TranslationsTiersEditTierErrorsUkUa._(_root);
}

// Path: tiers.deleteTier
class _TranslationsTiersDeleteTierUkUa implements TranslationsTiersDeleteTierEnUs {
	_TranslationsTiersDeleteTierUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Видалити рівень';
	@override String get confirmTitle => 'Видалити рівень';
	@override String get confirmMessage => 'Ви впевнені, що хочете видалити рівень "{name}"? Цю дію не можна скасувати.';
	@override String get confirmButton => 'Видалити';
	@override String get cancelButton => 'Скасувати';
	@override String get success => 'Рівень видалено';
	@override late final _TranslationsTiersDeleteTierErrorsUkUa errors = _TranslationsTiersDeleteTierErrorsUkUa._(_root);
}

// Path: posts.postDetails
class _TranslationsPostsPostDetailsUkUa implements TranslationsPostsPostDetailsEnUs {
	_TranslationsPostsPostDetailsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Публікація';
	@override String get loadError => 'Не вдалося завантажити публікацію';
}

// Path: posts.postStatus
class _TranslationsPostsPostStatusUkUa implements TranslationsPostsPostStatusEnUs {
	_TranslationsPostsPostStatusUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get pendingReview => 'Очікує перевірки';
	@override String get approved => 'Схвалено';
	@override String get changesRequested => 'Потрібні зміни';
}

// Path: posts.editPost
class _TranslationsPostsEditPostUkUa implements TranslationsPostsEditPostEnUs {
	_TranslationsPostsEditPostUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Редагувати публікацію';
	@override String get titleLabel => 'Заголовок';
	@override String get titleHint => 'Заголовок публікації';
	@override String get mediaUrlLabel => 'URL медіа (необов\'язково)';
	@override String get mediaUrlHint => 'https://...';
	@override String get textLabel => 'Текст (Markdown)';
	@override String get textHint => 'Напишіть публікацію...';
	@override String get previewLabel => 'Попередній перегляд';
	@override String get saveButton => 'Зберегти';
	@override late final _TranslationsPostsEditPostTabsUkUa tabs = _TranslationsPostsEditPostTabsUkUa._(_root);
	@override late final _TranslationsPostsEditPostRevisionMessageUkUa revisionMessage = _TranslationsPostsEditPostRevisionMessageUkUa._(_root);
	@override String get approvedHint => 'Цю публікацію схвалено і більше не можна редагувати.';
	@override late final _TranslationsPostsEditPostLogUkUa log = _TranslationsPostsEditPostLogUkUa._(_root);
	@override late final _TranslationsPostsEditPostErrorsUkUa errors = _TranslationsPostsEditPostErrorsUkUa._(_root);
}

// Path: posts.listPosts
class _TranslationsPostsListPostsUkUa implements TranslationsPostsListPostsEnUs {
	_TranslationsPostsListPostsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Публікацій ще немає';
	@override String get loadError => 'Не вдалося завантажити публікації';
	@override String get fabTooltip => 'Нова публікація';
	@override String get openPost => 'Відкрити';
}

// Path: posts.userPosts
class _TranslationsPostsUserPostsUkUa implements TranslationsPostsUserPostsEnUs {
	_TranslationsPostsUserPostsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String title({required Object username}) => 'Публікації ${username}';
	@override String get empty => 'Публікацій ще немає';
	@override String get loadError => 'Не вдалося завантажити публікації';
	@override String get openPost => 'Відкрити';
}

// Path: posts.deletePost
class _TranslationsPostsDeletePostUkUa implements TranslationsPostsDeletePostEnUs {
	_TranslationsPostsDeletePostUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Видалити публікацію';
	@override String get confirmTitle => 'Видалити публікацію?';
	@override String get confirmMessage => 'Ця дія незворотна. Публікацію буде видалено назавжди.';
	@override String get confirmButton => 'Видалити';
	@override String get cancelButton => 'Скасувати';
	@override String get success => 'Публікацію видалено';
	@override late final _TranslationsPostsDeletePostErrorsUkUa errors = _TranslationsPostsDeletePostErrorsUkUa._(_root);
}

// Path: posts.eraseDbPost
class _TranslationsPostsEraseDbPostUkUa implements TranslationsPostsEraseDbPostEnUs {
	_TranslationsPostsEraseDbPostUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Стерти публікацію (суперкористувач)';
	@override String get confirmTitle => 'Стерти публікацію?';
	@override String get confirmMessage => 'Цю публікацію буде стерто назавжди. Цю дію не можна скасувати.';
	@override String get confirmButton => 'Стерти';
	@override String get cancelButton => 'Скасувати';
	@override String get success => 'Публікацію стерто';
	@override late final _TranslationsPostsEraseDbPostErrorsUkUa errors = _TranslationsPostsEraseDbPostErrorsUkUa._(_root);
}

// Path: posts.pendingPosts
class _TranslationsPostsPendingPostsUkUa implements TranslationsPostsPendingPostsEnUs {
	_TranslationsPostsPendingPostsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Публікації на перевірці';
	@override String get empty => 'Немає публікацій на перевірці';
	@override String get loadError => 'Не вдалося завантажити публікації на перевірці';
	@override String get loadMoreError => 'Не вдалося завантажити більше';
	@override String get eventCount => 'Події';
}

// Path: posts.moderatePost
class _TranslationsPostsModeratePostUkUa implements TranslationsPostsModeratePostEnUs {
	_TranslationsPostsModeratePostUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Модерувати публікацію';
	@override late final _TranslationsPostsModeratePostTabsUkUa tabs = _TranslationsPostsModeratePostTabsUkUa._(_root);
	@override late final _TranslationsPostsModeratePostLogUkUa log = _TranslationsPostsModeratePostLogUkUa._(_root);
	@override late final _TranslationsPostsModeratePostActionsUkUa actions = _TranslationsPostsModeratePostActionsUkUa._(_root);
	@override late final _TranslationsPostsModeratePostErrorsUkUa errors = _TranslationsPostsModeratePostErrorsUkUa._(_root);
}

// Path: posts.createPost
class _TranslationsPostsCreatePostUkUa implements TranslationsPostsCreatePostEnUs {
	_TranslationsPostsCreatePostUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Нова публікація';
	@override String get titleLabel => 'Заголовок';
	@override String get titleHint => 'Заголовок публікації';
	@override String get mediaUrlLabel => 'URL медіа (необов\'язково)';
	@override String get mediaUrlHint => 'https://...';
	@override String get textLabel => 'Текст (Markdown)';
	@override String get textHint => 'Напишіть публікацію...';
	@override String get previewLabel => 'Попередній перегляд';
	@override String get publishButton => 'Опублікувати';
	@override String get fabTooltip => 'Нова публікація';
	@override late final _TranslationsPostsCreatePostErrorsUkUa errors = _TranslationsPostsCreatePostErrorsUkUa._(_root);
}

// Path: users.list
class _TranslationsUsersListUkUa implements TranslationsUsersListEnUs {
	_TranslationsUsersListUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get loadMoreError => 'Не вдалося завантажити більше користувачів';
	@override String get userDetails => 'Деталі';
	@override String get userPosts => 'Публікації';
}

// Path: users.details
class _TranslationsUsersDetailsUkUa implements TranslationsUsersDetailsEnUs {
	_TranslationsUsersDetailsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get email => 'Електронна пошта';
	@override String get tier => 'Рівень';
	@override String get tierSince => 'Рівень з';
	@override String get notFound => 'Користувача не знайдено';
	@override String get loadError => 'Не вдалося завантажити користувача';
}

// Path: users.create
class _TranslationsUsersCreateUkUa implements TranslationsUsersCreateEnUs {
	_TranslationsUsersCreateUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Створити користувача';
	@override String get name => 'Ім\'я';
	@override String get username => 'Ім\'я користувача';
	@override String get email => 'Електронна пошта';
	@override String get password => 'Пароль';
	@override String get submit => 'Створити';
	@override String get success => 'Користувача успішно створено';
	@override late final _TranslationsUsersCreateErrorsUkUa errors = _TranslationsUsersCreateErrorsUkUa._(_root);
}

// Path: users.delete
class _TranslationsUsersDeleteUkUa implements TranslationsUsersDeleteEnUs {
	_TranslationsUsersDeleteUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Видалити обліковий запис';
	@override String get confirmTitle => 'Видалити обліковий запис?';
	@override String get confirmMessage => 'Це назавжди видалить ваш обліковий запис. Цю дію не можна скасувати.';
	@override String get confirmButton => 'Видалити';
	@override String get success => 'Обліковий запис видалено';
	@override late final _TranslationsUsersDeleteErrorsUkUa errors = _TranslationsUsersDeleteErrorsUkUa._(_root);
}

// Path: users.eraseDbUser
class _TranslationsUsersEraseDbUserUkUa implements TranslationsUsersEraseDbUserEnUs {
	_TranslationsUsersEraseDbUserUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Стерти з бази даних';
	@override String get confirmTitle => 'Стерти обліковий запис назавжди?';
	@override String get confirmMessage => 'Це назавжди видалить ваш обліковий запис з бази даних. Цю дію не можна скасувати.';
	@override String get confirmButton => 'Стерти назавжди';
	@override String get success => 'Обліковий запис стерто з бази даних';
	@override late final _TranslationsUsersEraseDbUserErrorsUkUa errors = _TranslationsUsersEraseDbUserErrorsUkUa._(_root);
}

// Path: users.edit
class _TranslationsUsersEditUkUa implements TranslationsUsersEditEnUs {
	_TranslationsUsersEditUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Редагувати користувача';
	@override String get name => 'Ім\'я';
	@override String get username => 'Ім\'я користувача';
	@override String get email => 'Електронна пошта';
	@override String get profileImageUrl => 'URL зображення профілю';
	@override String get save => 'Зберегти';
	@override String get success => 'Користувача успішно оновлено';
	@override late final _TranslationsUsersEditErrorsUkUa errors = _TranslationsUsersEditErrorsUkUa._(_root);
}

// Path: users.updateTier
class _TranslationsUsersUpdateTierUkUa implements TranslationsUsersUpdateTierEnUs {
	_TranslationsUsersUpdateTierUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Змінити рівень';
	@override String get sheetTitle => 'Змінити рівень користувача';
	@override String get selectTier => 'Вибрати рівень';
	@override String get confirm => 'Підтвердити';
	@override String get success => 'Рівень користувача оновлено';
	@override late final _TranslationsUsersUpdateTierErrorsUkUa errors = _TranslationsUsersUpdateTierErrorsUkUa._(_root);
}

// Path: users.moderator
class _TranslationsUsersModeratorUkUa implements TranslationsUsersModeratorEnUs {
	_TranslationsUsersModeratorUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get badge => 'Модератор';
	@override String get assign => 'Призначити модератором';
	@override String get revoke => 'Скасувати права модератора';
	@override late final _TranslationsUsersModeratorErrorsUkUa errors = _TranslationsUsersModeratorErrorsUkUa._(_root);
}

// Path: auth.login.errors
class _TranslationsAuthLoginErrorsUkUa implements TranslationsAuthLoginErrorsEnUs {
	_TranslationsAuthLoginErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get required => 'Обов\'язкове поле';
	@override String get invalidCredentials => 'Невірне ім\'я користувача або пароль';
	@override String get generic => 'Помилка входу. Спробуйте ще раз.';
}

// Path: tiers.createTier.errors
class _TranslationsTiersCreateTierErrorsUkUa implements TranslationsTiersCreateTierErrorsEnUs {
	_TranslationsTiersCreateTierErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get required => 'Це поле обов\'язкове';
	@override String get generic => 'Не вдалося створити рівень';
}

// Path: tiers.editTier.errors
class _TranslationsTiersEditTierErrorsUkUa implements TranslationsTiersEditTierErrorsEnUs {
	_TranslationsTiersEditTierErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get required => 'Це поле обов\'язкове';
	@override String get notFound => 'Рівень не знайдено';
	@override String get permissionDenied => 'Доступ заборонено';
	@override String get generic => 'Не вдалося оновити рівень';
}

// Path: tiers.deleteTier.errors
class _TranslationsTiersDeleteTierErrorsUkUa implements TranslationsTiersDeleteTierErrorsEnUs {
	_TranslationsTiersDeleteTierErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get notFound => 'Рівень не знайдено';
	@override String get forbidden => 'Доступ заборонено';
	@override String get unauthorized => 'Сесія закінчилася';
	@override String get generic => 'Не вдалося видалити рівень';
}

// Path: posts.editPost.tabs
class _TranslationsPostsEditPostTabsUkUa implements TranslationsPostsEditPostTabsEnUs {
	_TranslationsPostsEditPostTabsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get edit => 'Редагувати';
	@override String get log => 'Журнал модерації';
}

// Path: posts.editPost.revisionMessage
class _TranslationsPostsEditPostRevisionMessageUkUa implements TranslationsPostsEditPostRevisionMessageEnUs {
	_TranslationsPostsEditPostRevisionMessageUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get label => 'Повідомлення про зміни';
	@override String get hint => 'Опишіть, що ви змінили відповідно до коментарів модератора';
}

// Path: posts.editPost.log
class _TranslationsPostsEditPostLogUkUa implements TranslationsPostsEditPostLogEnUs {
	_TranslationsPostsEditPostLogUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Журнал модерації порожній';
	@override String get loadError => 'Не вдалося завантажити журнал модерації';
}

// Path: posts.editPost.errors
class _TranslationsPostsEditPostErrorsUkUa implements TranslationsPostsEditPostErrorsEnUs {
	_TranslationsPostsEditPostErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get titleTooShort => 'Заголовок повинен містити щонайменше 2 символи';
	@override String get titleTooLong => 'Заголовок не може перевищувати 30 символів';
	@override String get mediaUrlEmpty => 'URL медіа не може бути порожнім, якщо вказано';
	@override String get textTooShort => 'Текст повинен містити щонайменше 100 символів';
	@override String get textTooLong => 'Текст не може перевищувати 63206 символів';
	@override String get forbidden => 'Ви можете редагувати лише свої публікації';
	@override String get generic => 'Не вдалося зберегти публікацію. Спробуйте ще раз.';
	@override String get revisionMessageRequired => 'Необхідне повідомлення про зміни.';
	@override String get conflict => 'Статус публікації змінився під час редагування. Перевірте поточний статус.';
	@override String get notFound => 'Публікацію не знайдено.';
}

// Path: posts.deletePost.errors
class _TranslationsPostsDeletePostErrorsUkUa implements TranslationsPostsDeletePostErrorsEnUs {
	_TranslationsPostsDeletePostErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Ви можете видаляти лише свої публікації';
	@override String get generic => 'Не вдалося видалити публікацію. Спробуйте ще раз.';
}

// Path: posts.eraseDbPost.errors
class _TranslationsPostsEraseDbPostErrorsUkUa implements TranslationsPostsEraseDbPostErrorsEnUs {
	_TranslationsPostsEraseDbPostErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'У вас немає дозволу на стирання публікацій';
	@override String get generic => 'Не вдалося стерти публікацію. Спробуйте ще раз.';
}

// Path: posts.moderatePost.tabs
class _TranslationsPostsModeratePostTabsUkUa implements TranslationsPostsModeratePostTabsEnUs {
	_TranslationsPostsModeratePostTabsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get post => 'Публікація';
	@override String get moderation => 'Модерація';
}

// Path: posts.moderatePost.log
class _TranslationsPostsModeratePostLogUkUa implements TranslationsPostsModeratePostLogEnUs {
	_TranslationsPostsModeratePostLogUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Журнал модерації порожній';
	@override String get loadError => 'Не вдалося завантажити журнал модерації';
	@override late final _TranslationsPostsModeratePostLogEventTypesUkUa eventTypes = _TranslationsPostsModeratePostLogEventTypesUkUa._(_root);
	@override late final _TranslationsPostsModeratePostLogActionsUkUa actions = _TranslationsPostsModeratePostLogActionsUkUa._(_root);
}

// Path: posts.moderatePost.actions
class _TranslationsPostsModeratePostActionsUkUa implements TranslationsPostsModeratePostActionsEnUs {
	_TranslationsPostsModeratePostActionsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get approve => 'Схвалити';
	@override String get requestChanges => 'Запросити зміни';
	@override String get messageHint => 'Додайте коментар (обов\'язковий для відхилення)';
	@override String get messageRequiredError => 'Коментар обов\'язковий при запиті змін';
}

// Path: posts.moderatePost.errors
class _TranslationsPostsModeratePostErrorsUkUa implements TranslationsPostsModeratePostErrorsEnUs {
	_TranslationsPostsModeratePostErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'У вас немає дозволу на модерацію цієї публікації';
	@override String get notFound => 'Публікацію не знайдено';
	@override String get conflict => 'Цю публікацію вже промодеровано. Поверніться до черги.';
	@override String get generic => 'Не вдалося надіслати рішення. Спробуйте ще раз.';
}

// Path: posts.createPost.errors
class _TranslationsPostsCreatePostErrorsUkUa implements TranslationsPostsCreatePostErrorsEnUs {
	_TranslationsPostsCreatePostErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get titleTooShort => 'Заголовок повинен містити щонайменше 2 символи';
	@override String get titleTooLong => 'Заголовок не може перевищувати 30 символів';
	@override String get mediaUrlEmpty => 'URL медіа не може бути порожнім, якщо вказано';
	@override String get textTooShort => 'Текст повинен містити щонайменше 100 символів';
	@override String get textTooLong => 'Текст не може перевищувати 63206 символів';
	@override String get forbidden => 'Ви можете публікувати лише від свого імені';
	@override String get generic => 'Не вдалося опублікувати. Спробуйте ще раз.';
}

// Path: users.create.errors
class _TranslationsUsersCreateErrorsUkUa implements TranslationsUsersCreateErrorsEnUs {
	_TranslationsUsersCreateErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get required => 'Це поле обов\'язкове';
	@override String get emailInvalid => 'Введіть дійсну адресу електронної пошти';
	@override String get passwordTooShort => 'Пароль повинен містити щонайменше 8 символів';
	@override String get usernameTaken => 'Ім\'я користувача вже зайнято';
	@override String get emailTaken => 'Електронна пошта вже зайнята';
	@override String get generic => 'Щось пішло не так. Спробуйте ще раз.';
}

// Path: users.delete.errors
class _TranslationsUsersDeleteErrorsUkUa implements TranslationsUsersDeleteErrorsEnUs {
	_TranslationsUsersDeleteErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Ви можете видалити лише свій обліковий запис.';
	@override String get unauthorized => 'Сесія закінчилася.';
	@override String get notFound => 'Користувача не знайдено.';
	@override String get generic => 'Не вдалося видалити обліковий запис.';
}

// Path: users.eraseDbUser.errors
class _TranslationsUsersEraseDbUserErrorsUkUa implements TranslationsUsersEraseDbUserErrorsEnUs {
	_TranslationsUsersEraseDbUserErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Ви можете стерти лише свій обліковий запис';
	@override String get unauthorized => 'Сесія закінчилася. Увійдіть знову';
	@override String get notFound => 'Користувача не знайдено';
	@override String get generic => 'Не вдалося стерти обліковий запис. Спробуйте ще раз';
}

// Path: users.edit.errors
class _TranslationsUsersEditErrorsUkUa implements TranslationsUsersEditErrorsEnUs {
	_TranslationsUsersEditErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get required => 'Це поле обов\'язкове';
	@override String get emailInvalid => 'Введіть дійсну адресу електронної пошти';
	@override String get usernameTaken => 'Ім\'я користувача вже зайнято';
	@override String get notFound => 'Користувача не знайдено';
	@override String get nothingToUpdate => 'Немає змін для збереження';
	@override String get forbidden => 'Ви можете редагувати лише свій профіль.';
	@override String get unauthorized => 'Сесія закінчилася.';
	@override String get generic => 'Щось пішло не так. Спробуйте ще раз.';
}

// Path: users.updateTier.errors
class _TranslationsUsersUpdateTierErrorsUkUa implements TranslationsUsersUpdateTierErrorsEnUs {
	_TranslationsUsersUpdateTierErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get permissionDenied => 'У вас немає дозволу на зміну рівнів.';
	@override String get notFound => 'Користувача або рівень не знайдено.';
	@override String get forbidden => 'Доступ заборонено.';
	@override String get unauthorized => 'Сесія закінчилася.';
	@override String get generic => 'Не вдалося оновити рівень. Спробуйте ще раз.';
}

// Path: users.moderator.errors
class _TranslationsUsersModeratorErrorsUkUa implements TranslationsUsersModeratorErrorsEnUs {
	_TranslationsUsersModeratorErrorsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get conflict => 'Дія неприйнятна — статус модератора вже синхронізовано.';
	@override String get forbidden => 'У вас немає дозволу на управління модераторами.';
	@override String get generic => 'Не вдалося оновити статус модератора. Спробуйте ще раз.';
}

// Path: posts.moderatePost.log.eventTypes
class _TranslationsPostsModeratePostLogEventTypesUkUa implements TranslationsPostsModeratePostLogEventTypesEnUs {
	_TranslationsPostsModeratePostLogEventTypesUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get moderatorReview => 'Перевірка модератора';
	@override String get authorRevision => 'Правка автора';
}

// Path: posts.moderatePost.log.actions
class _TranslationsPostsModeratePostLogActionsUkUa implements TranslationsPostsModeratePostLogActionsEnUs {
	_TranslationsPostsModeratePostLogActionsUkUa._(this._root);

	final TranslationsUkUa _root; // ignore: unused_field

	// Translations
	@override String get approved => 'Схвалено';
	@override String get changesRequested => 'Запитано зміни';
}

/// The flat map containing all translations for locale <uk-UA>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsUkUa {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'auth.login.title' => 'Увійти',
			'auth.login.username' => 'Ім\'я користувача',
			'auth.login.password' => 'Пароль',
			'auth.login.submit' => 'Увійти',
			'auth.login.signInButton' => 'Увійти',
			'auth.login.errors.required' => 'Обов\'язкове поле',
			'auth.login.errors.invalidCredentials' => 'Невірне ім\'я користувача або пароль',
			'auth.login.errors.generic' => 'Помилка входу. Спробуйте ще раз.',
			'auth.logout.confirmTitle' => 'Вийти?',
			'auth.logout.confirmMessage' => 'Вам потрібно буде увійти знову.',
			'auth.logout.confirm' => 'Вийти',
			'auth.logout.cancel' => 'Скасувати',
			'auth.sessionExpired' => 'Сесія закінчилася. Увійдіть знову.',
			'app.title' => 'Flutter App',
			'nav.users' => 'Користувачі',
			'nav.posts' => 'Публікації',
			'nav.tiers' => 'Рівні',
			'nav.pending' => 'Очікують',
			'common.loading' => 'Завантаження...',
			'common.error' => 'Щось пішло не так',
			'common.retry' => 'Повторити',
			'common.back' => 'Назад',
			'common.cancel' => 'Скасувати',
			'tiers.listTiers.title' => 'Рівні',
			'tiers.listTiers.loadError' => 'Не вдалося завантажити рівні',
			'tiers.listTiers.loadMoreError' => 'Не вдалося завантажити більше рівнів',
			'tiers.listTiers.empty' => 'Рівні не знайдено',
			'tiers.createTier.title' => 'Створити рівень',
			'tiers.createTier.name' => 'Назва',
			'tiers.createTier.submit' => 'Створити',
			'tiers.createTier.fabTooltip' => 'Додати рівень',
			'tiers.createTier.success' => 'Рівень створено',
			'tiers.createTier.errors.required' => 'Це поле обов\'язкове',
			'tiers.createTier.errors.generic' => 'Не вдалося створити рівень',
			'tiers.tierDetails.title' => 'Деталі рівня',
			'tiers.tierDetails.id' => 'ID',
			'tiers.tierDetails.createdAt' => 'Створено',
			'tiers.tierDetails.notFound' => 'Рівень не знайдено',
			'tiers.tierDetails.loadError' => 'Не вдалося завантажити рівень',
			'tiers.tierDetails.permissionDenied' => 'Доступ заборонено',
			'tiers.editTier.title' => 'Редагувати рівень',
			'tiers.editTier.name' => 'Назва',
			'tiers.editTier.save' => 'Зберегти',
			'tiers.editTier.success' => 'Рівень оновлено',
			'tiers.editTier.errors.required' => 'Це поле обов\'язкове',
			'tiers.editTier.errors.notFound' => 'Рівень не знайдено',
			'tiers.editTier.errors.permissionDenied' => 'Доступ заборонено',
			'tiers.editTier.errors.generic' => 'Не вдалося оновити рівень',
			'tiers.deleteTier.tooltip' => 'Видалити рівень',
			'tiers.deleteTier.confirmTitle' => 'Видалити рівень',
			'tiers.deleteTier.confirmMessage' => 'Ви впевнені, що хочете видалити рівень "{name}"? Цю дію не можна скасувати.',
			'tiers.deleteTier.confirmButton' => 'Видалити',
			'tiers.deleteTier.cancelButton' => 'Скасувати',
			'tiers.deleteTier.success' => 'Рівень видалено',
			'tiers.deleteTier.errors.notFound' => 'Рівень не знайдено',
			'tiers.deleteTier.errors.forbidden' => 'Доступ заборонено',
			'tiers.deleteTier.errors.unauthorized' => 'Сесія закінчилася',
			'tiers.deleteTier.errors.generic' => 'Не вдалося видалити рівень',
			'posts.postDetails.title' => 'Публікація',
			'posts.postDetails.loadError' => 'Не вдалося завантажити публікацію',
			'posts.postStatus.pendingReview' => 'Очікує перевірки',
			'posts.postStatus.approved' => 'Схвалено',
			'posts.postStatus.changesRequested' => 'Потрібні зміни',
			'posts.editPost.title' => 'Редагувати публікацію',
			'posts.editPost.titleLabel' => 'Заголовок',
			'posts.editPost.titleHint' => 'Заголовок публікації',
			'posts.editPost.mediaUrlLabel' => 'URL медіа (необов\'язково)',
			'posts.editPost.mediaUrlHint' => 'https://...',
			'posts.editPost.textLabel' => 'Текст (Markdown)',
			'posts.editPost.textHint' => 'Напишіть публікацію...',
			'posts.editPost.previewLabel' => 'Попередній перегляд',
			'posts.editPost.saveButton' => 'Зберегти',
			'posts.editPost.tabs.edit' => 'Редагувати',
			'posts.editPost.tabs.log' => 'Журнал модерації',
			'posts.editPost.revisionMessage.label' => 'Повідомлення про зміни',
			'posts.editPost.revisionMessage.hint' => 'Опишіть, що ви змінили відповідно до коментарів модератора',
			'posts.editPost.approvedHint' => 'Цю публікацію схвалено і більше не можна редагувати.',
			'posts.editPost.log.empty' => 'Журнал модерації порожній',
			'posts.editPost.log.loadError' => 'Не вдалося завантажити журнал модерації',
			'posts.editPost.errors.titleTooShort' => 'Заголовок повинен містити щонайменше 2 символи',
			'posts.editPost.errors.titleTooLong' => 'Заголовок не може перевищувати 30 символів',
			'posts.editPost.errors.mediaUrlEmpty' => 'URL медіа не може бути порожнім, якщо вказано',
			'posts.editPost.errors.textTooShort' => 'Текст повинен містити щонайменше 100 символів',
			'posts.editPost.errors.textTooLong' => 'Текст не може перевищувати 63206 символів',
			'posts.editPost.errors.forbidden' => 'Ви можете редагувати лише свої публікації',
			'posts.editPost.errors.generic' => 'Не вдалося зберегти публікацію. Спробуйте ще раз.',
			'posts.editPost.errors.revisionMessageRequired' => 'Необхідне повідомлення про зміни.',
			'posts.editPost.errors.conflict' => 'Статус публікації змінився під час редагування. Перевірте поточний статус.',
			'posts.editPost.errors.notFound' => 'Публікацію не знайдено.',
			'posts.listPosts.empty' => 'Публікацій ще немає',
			'posts.listPosts.loadError' => 'Не вдалося завантажити публікації',
			'posts.listPosts.fabTooltip' => 'Нова публікація',
			'posts.listPosts.openPost' => 'Відкрити',
			'posts.userPosts.title' => ({required Object username}) => 'Публікації ${username}',
			'posts.userPosts.empty' => 'Публікацій ще немає',
			'posts.userPosts.loadError' => 'Не вдалося завантажити публікації',
			'posts.userPosts.openPost' => 'Відкрити',
			'posts.deletePost.tooltip' => 'Видалити публікацію',
			'posts.deletePost.confirmTitle' => 'Видалити публікацію?',
			'posts.deletePost.confirmMessage' => 'Ця дія незворотна. Публікацію буде видалено назавжди.',
			'posts.deletePost.confirmButton' => 'Видалити',
			'posts.deletePost.cancelButton' => 'Скасувати',
			'posts.deletePost.success' => 'Публікацію видалено',
			'posts.deletePost.errors.forbidden' => 'Ви можете видаляти лише свої публікації',
			'posts.deletePost.errors.generic' => 'Не вдалося видалити публікацію. Спробуйте ще раз.',
			'posts.eraseDbPost.tooltip' => 'Стерти публікацію (суперкористувач)',
			'posts.eraseDbPost.confirmTitle' => 'Стерти публікацію?',
			'posts.eraseDbPost.confirmMessage' => 'Цю публікацію буде стерто назавжди. Цю дію не можна скасувати.',
			'posts.eraseDbPost.confirmButton' => 'Стерти',
			'posts.eraseDbPost.cancelButton' => 'Скасувати',
			'posts.eraseDbPost.success' => 'Публікацію стерто',
			'posts.eraseDbPost.errors.forbidden' => 'У вас немає дозволу на стирання публікацій',
			'posts.eraseDbPost.errors.generic' => 'Не вдалося стерти публікацію. Спробуйте ще раз.',
			'posts.pendingPosts.title' => 'Публікації на перевірці',
			'posts.pendingPosts.empty' => 'Немає публікацій на перевірці',
			'posts.pendingPosts.loadError' => 'Не вдалося завантажити публікації на перевірці',
			'posts.pendingPosts.loadMoreError' => 'Не вдалося завантажити більше',
			'posts.pendingPosts.eventCount' => 'Події',
			'posts.moderatePost.title' => 'Модерувати публікацію',
			'posts.moderatePost.tabs.post' => 'Публікація',
			'posts.moderatePost.tabs.moderation' => 'Модерація',
			'posts.moderatePost.log.empty' => 'Журнал модерації порожній',
			'posts.moderatePost.log.loadError' => 'Не вдалося завантажити журнал модерації',
			'posts.moderatePost.log.eventTypes.moderatorReview' => 'Перевірка модератора',
			'posts.moderatePost.log.eventTypes.authorRevision' => 'Правка автора',
			'posts.moderatePost.log.actions.approved' => 'Схвалено',
			'posts.moderatePost.log.actions.changesRequested' => 'Запитано зміни',
			'posts.moderatePost.actions.approve' => 'Схвалити',
			'posts.moderatePost.actions.requestChanges' => 'Запросити зміни',
			'posts.moderatePost.actions.messageHint' => 'Додайте коментар (обов\'язковий для відхилення)',
			'posts.moderatePost.actions.messageRequiredError' => 'Коментар обов\'язковий при запиті змін',
			'posts.moderatePost.errors.forbidden' => 'У вас немає дозволу на модерацію цієї публікації',
			'posts.moderatePost.errors.notFound' => 'Публікацію не знайдено',
			'posts.moderatePost.errors.conflict' => 'Цю публікацію вже промодеровано. Поверніться до черги.',
			'posts.moderatePost.errors.generic' => 'Не вдалося надіслати рішення. Спробуйте ще раз.',
			'posts.createPost.title' => 'Нова публікація',
			'posts.createPost.titleLabel' => 'Заголовок',
			'posts.createPost.titleHint' => 'Заголовок публікації',
			'posts.createPost.mediaUrlLabel' => 'URL медіа (необов\'язково)',
			'posts.createPost.mediaUrlHint' => 'https://...',
			'posts.createPost.textLabel' => 'Текст (Markdown)',
			'posts.createPost.textHint' => 'Напишіть публікацію...',
			'posts.createPost.previewLabel' => 'Попередній перегляд',
			'posts.createPost.publishButton' => 'Опублікувати',
			'posts.createPost.fabTooltip' => 'Нова публікація',
			'posts.createPost.errors.titleTooShort' => 'Заголовок повинен містити щонайменше 2 символи',
			'posts.createPost.errors.titleTooLong' => 'Заголовок не може перевищувати 30 символів',
			'posts.createPost.errors.mediaUrlEmpty' => 'URL медіа не може бути порожнім, якщо вказано',
			'posts.createPost.errors.textTooShort' => 'Текст повинен містити щонайменше 100 символів',
			'posts.createPost.errors.textTooLong' => 'Текст не може перевищувати 63206 символів',
			'posts.createPost.errors.forbidden' => 'Ви можете публікувати лише від свого імені',
			'posts.createPost.errors.generic' => 'Не вдалося опублікувати. Спробуйте ще раз.',
			'users.title' => 'Користувачі',
			'users.list.loadMoreError' => 'Не вдалося завантажити більше користувачів',
			'users.list.userDetails' => 'Деталі',
			'users.list.userPosts' => 'Публікації',
			'users.details.email' => 'Електронна пошта',
			'users.details.tier' => 'Рівень',
			'users.details.tierSince' => 'Рівень з',
			'users.details.notFound' => 'Користувача не знайдено',
			'users.details.loadError' => 'Не вдалося завантажити користувача',
			'users.create.title' => 'Створити користувача',
			'users.create.name' => 'Ім\'я',
			'users.create.username' => 'Ім\'я користувача',
			'users.create.email' => 'Електронна пошта',
			'users.create.password' => 'Пароль',
			'users.create.submit' => 'Створити',
			'users.create.success' => 'Користувача успішно створено',
			'users.create.errors.required' => 'Це поле обов\'язкове',
			'users.create.errors.emailInvalid' => 'Введіть дійсну адресу електронної пошти',
			'users.create.errors.passwordTooShort' => 'Пароль повинен містити щонайменше 8 символів',
			'users.create.errors.usernameTaken' => 'Ім\'я користувача вже зайнято',
			'users.create.errors.emailTaken' => 'Електронна пошта вже зайнята',
			'users.create.errors.generic' => 'Щось пішло не так. Спробуйте ще раз.',
			'users.delete.tooltip' => 'Видалити обліковий запис',
			'users.delete.confirmTitle' => 'Видалити обліковий запис?',
			'users.delete.confirmMessage' => 'Це назавжди видалить ваш обліковий запис. Цю дію не можна скасувати.',
			'users.delete.confirmButton' => 'Видалити',
			'users.delete.success' => 'Обліковий запис видалено',
			'users.delete.errors.forbidden' => 'Ви можете видалити лише свій обліковий запис.',
			'users.delete.errors.unauthorized' => 'Сесія закінчилася.',
			'users.delete.errors.notFound' => 'Користувача не знайдено.',
			'users.delete.errors.generic' => 'Не вдалося видалити обліковий запис.',
			'users.eraseDbUser.tooltip' => 'Стерти з бази даних',
			'users.eraseDbUser.confirmTitle' => 'Стерти обліковий запис назавжди?',
			'users.eraseDbUser.confirmMessage' => 'Це назавжди видалить ваш обліковий запис з бази даних. Цю дію не можна скасувати.',
			'users.eraseDbUser.confirmButton' => 'Стерти назавжди',
			'users.eraseDbUser.success' => 'Обліковий запис стерто з бази даних',
			'users.eraseDbUser.errors.forbidden' => 'Ви можете стерти лише свій обліковий запис',
			'users.eraseDbUser.errors.unauthorized' => 'Сесія закінчилася. Увійдіть знову',
			'users.eraseDbUser.errors.notFound' => 'Користувача не знайдено',
			'users.eraseDbUser.errors.generic' => 'Не вдалося стерти обліковий запис. Спробуйте ще раз',
			'users.edit.title' => 'Редагувати користувача',
			'users.edit.name' => 'Ім\'я',
			'users.edit.username' => 'Ім\'я користувача',
			'users.edit.email' => 'Електронна пошта',
			'users.edit.profileImageUrl' => 'URL зображення профілю',
			'users.edit.save' => 'Зберегти',
			'users.edit.success' => 'Користувача успішно оновлено',
			'users.edit.errors.required' => 'Це поле обов\'язкове',
			'users.edit.errors.emailInvalid' => 'Введіть дійсну адресу електронної пошти',
			'users.edit.errors.usernameTaken' => 'Ім\'я користувача вже зайнято',
			'users.edit.errors.notFound' => 'Користувача не знайдено',
			'users.edit.errors.nothingToUpdate' => 'Немає змін для збереження',
			'users.edit.errors.forbidden' => 'Ви можете редагувати лише свій профіль.',
			'users.edit.errors.unauthorized' => 'Сесія закінчилася.',
			'users.edit.errors.generic' => 'Щось пішло не так. Спробуйте ще раз.',
			'users.updateTier.tooltip' => 'Змінити рівень',
			'users.updateTier.sheetTitle' => 'Змінити рівень користувача',
			'users.updateTier.selectTier' => 'Вибрати рівень',
			'users.updateTier.confirm' => 'Підтвердити',
			'users.updateTier.success' => 'Рівень користувача оновлено',
			'users.updateTier.errors.permissionDenied' => 'У вас немає дозволу на зміну рівнів.',
			'users.updateTier.errors.notFound' => 'Користувача або рівень не знайдено.',
			'users.updateTier.errors.forbidden' => 'Доступ заборонено.',
			'users.updateTier.errors.unauthorized' => 'Сесія закінчилася.',
			'users.updateTier.errors.generic' => 'Не вдалося оновити рівень. Спробуйте ще раз.',
			'users.moderator.badge' => 'Модератор',
			'users.moderator.assign' => 'Призначити модератором',
			'users.moderator.revoke' => 'Скасувати права модератора',
			'users.moderator.errors.conflict' => 'Дія неприйнятна — статус модератора вже синхронізовано.',
			'users.moderator.errors.forbidden' => 'У вас немає дозволу на управління модераторами.',
			'users.moderator.errors.generic' => 'Не вдалося оновити статус модератора. Спробуйте ще раз.',
			_ => null,
		};
	}
}
