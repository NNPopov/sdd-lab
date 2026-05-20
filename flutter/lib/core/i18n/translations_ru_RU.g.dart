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
class TranslationsRuRu with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRuRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ruRu,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <ru-RU>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsRuRu _root = this; // ignore: unused_field

	@override 
	TranslationsRuRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRuRu(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAuthRuRu auth = _TranslationsAuthRuRu._(_root);
	@override late final _TranslationsAppRuRu app = _TranslationsAppRuRu._(_root);
	@override late final _TranslationsNavRuRu nav = _TranslationsNavRuRu._(_root);
	@override late final _TranslationsCommonRuRu common = _TranslationsCommonRuRu._(_root);
	@override late final _TranslationsTiersRuRu tiers = _TranslationsTiersRuRu._(_root);
	@override late final _TranslationsPostsRuRu posts = _TranslationsPostsRuRu._(_root);
	@override late final _TranslationsUserMenuRuRu userMenu = _TranslationsUserMenuRuRu._(_root);
	@override late final _TranslationsUsersRuRu users = _TranslationsUsersRuRu._(_root);
}

// Path: auth
class _TranslationsAuthRuRu implements TranslationsAuthEnUs {
	_TranslationsAuthRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsAuthLoginRuRu login = _TranslationsAuthLoginRuRu._(_root);
	@override late final _TranslationsAuthLogoutRuRu logout = _TranslationsAuthLogoutRuRu._(_root);
	@override String get sessionExpired => 'Сессия истекла. Войдите снова.';
}

// Path: app
class _TranslationsAppRuRu implements TranslationsAppEnUs {
	_TranslationsAppRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flutter App';
}

// Path: nav
class _TranslationsNavRuRu implements TranslationsNavEnUs {
	_TranslationsNavRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get users => 'Пользователи';
	@override String get posts => 'Посты';
	@override String get tiers => 'Тиры';
	@override String get pending => 'На проверке';
}

// Path: common
class _TranslationsCommonRuRu implements TranslationsCommonEnUs {
	_TranslationsCommonRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Загрузка...';
	@override String get error => 'Что-то пошло не так';
	@override String get retry => 'Повторить';
	@override String get back => 'Назад';
	@override String get cancel => 'Отмена';
}

// Path: tiers
class _TranslationsTiersRuRu implements TranslationsTiersEnUs {
	_TranslationsTiersRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsTiersListTiersRuRu listTiers = _TranslationsTiersListTiersRuRu._(_root);
	@override late final _TranslationsTiersCreateTierRuRu createTier = _TranslationsTiersCreateTierRuRu._(_root);
	@override late final _TranslationsTiersTierDetailsRuRu tierDetails = _TranslationsTiersTierDetailsRuRu._(_root);
	@override late final _TranslationsTiersEditTierRuRu editTier = _TranslationsTiersEditTierRuRu._(_root);
	@override late final _TranslationsTiersDeleteTierRuRu deleteTier = _TranslationsTiersDeleteTierRuRu._(_root);
}

// Path: posts
class _TranslationsPostsRuRu implements TranslationsPostsEnUs {
	_TranslationsPostsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsPostsPostDetailsRuRu postDetails = _TranslationsPostsPostDetailsRuRu._(_root);
	@override late final _TranslationsPostsPostStatusRuRu postStatus = _TranslationsPostsPostStatusRuRu._(_root);
	@override late final _TranslationsPostsEditPostRuRu editPost = _TranslationsPostsEditPostRuRu._(_root);
	@override late final _TranslationsPostsListPostsRuRu listPosts = _TranslationsPostsListPostsRuRu._(_root);
	@override late final _TranslationsPostsUserPostsRuRu userPosts = _TranslationsPostsUserPostsRuRu._(_root);
	@override late final _TranslationsPostsDeletePostRuRu deletePost = _TranslationsPostsDeletePostRuRu._(_root);
	@override late final _TranslationsPostsEraseDbPostRuRu eraseDbPost = _TranslationsPostsEraseDbPostRuRu._(_root);
	@override late final _TranslationsPostsPendingPostsRuRu pendingPosts = _TranslationsPostsPendingPostsRuRu._(_root);
	@override late final _TranslationsPostsModeratePostRuRu moderatePost = _TranslationsPostsModeratePostRuRu._(_root);
	@override late final _TranslationsPostsCreatePostRuRu createPost = _TranslationsPostsCreatePostRuRu._(_root);
}

// Path: userMenu
class _TranslationsUserMenuRuRu implements TranslationsUserMenuEnUs {
	_TranslationsUserMenuRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get myProfile => 'Мой профиль';
	@override String get myPosts => 'Мои публикации';
}

// Path: users
class _TranslationsUsersRuRu implements TranslationsUsersEnUs {
	_TranslationsUsersRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Пользователи';
	@override late final _TranslationsUsersListRuRu list = _TranslationsUsersListRuRu._(_root);
	@override late final _TranslationsUsersDetailsRuRu details = _TranslationsUsersDetailsRuRu._(_root);
	@override late final _TranslationsUsersCreateRuRu create = _TranslationsUsersCreateRuRu._(_root);
	@override late final _TranslationsUsersDeleteRuRu delete = _TranslationsUsersDeleteRuRu._(_root);
	@override late final _TranslationsUsersEraseDbUserRuRu eraseDbUser = _TranslationsUsersEraseDbUserRuRu._(_root);
	@override late final _TranslationsUsersEditRuRu edit = _TranslationsUsersEditRuRu._(_root);
	@override late final _TranslationsUsersUpdateTierRuRu updateTier = _TranslationsUsersUpdateTierRuRu._(_root);
	@override late final _TranslationsUsersModeratorRuRu moderator = _TranslationsUsersModeratorRuRu._(_root);
}

// Path: auth.login
class _TranslationsAuthLoginRuRu implements TranslationsAuthLoginEnUs {
	_TranslationsAuthLoginRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Вход';
	@override String get username => 'Имя пользователя';
	@override String get password => 'Пароль';
	@override String get submit => 'Войти';
	@override String get signInButton => 'Войти';
	@override late final _TranslationsAuthLoginErrorsRuRu errors = _TranslationsAuthLoginErrorsRuRu._(_root);
}

// Path: auth.logout
class _TranslationsAuthLogoutRuRu implements TranslationsAuthLogoutEnUs {
	_TranslationsAuthLogoutRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get confirmTitle => 'Выйти?';
	@override String get confirmMessage => 'Потребуется снова войти.';
	@override String get confirm => 'Выйти';
	@override String get cancel => 'Отмена';
}

// Path: tiers.listTiers
class _TranslationsTiersListTiersRuRu implements TranslationsTiersListTiersEnUs {
	_TranslationsTiersListTiersRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Тиры';
	@override String get loadError => 'Не удалось загрузить тиры';
	@override String get loadMoreError => 'Не удалось загрузить следующую страницу';
	@override String get empty => 'Тиры не найдены';
}

// Path: tiers.createTier
class _TranslationsTiersCreateTierRuRu implements TranslationsTiersCreateTierEnUs {
	_TranslationsTiersCreateTierRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Создать тир';
	@override String get name => 'Название';
	@override String get submit => 'Создать';
	@override String get fabTooltip => 'Добавить тир';
	@override String get success => 'Тир создан';
	@override late final _TranslationsTiersCreateTierErrorsRuRu errors = _TranslationsTiersCreateTierErrorsRuRu._(_root);
}

// Path: tiers.tierDetails
class _TranslationsTiersTierDetailsRuRu implements TranslationsTiersTierDetailsEnUs {
	_TranslationsTiersTierDetailsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Детали уровня';
	@override String get id => 'ID';
	@override String get createdAt => 'Создан';
	@override String get notFound => 'Уровень не найден';
	@override String get loadError => 'Ошибка загрузки';
	@override String get permissionDenied => 'Нет доступа';
}

// Path: tiers.editTier
class _TranslationsTiersEditTierRuRu implements TranslationsTiersEditTierEnUs {
	_TranslationsTiersEditTierRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Редактировать тир';
	@override String get name => 'Название';
	@override String get save => 'Сохранить';
	@override String get success => 'Тир обновлён';
	@override late final _TranslationsTiersEditTierErrorsRuRu errors = _TranslationsTiersEditTierErrorsRuRu._(_root);
}

// Path: tiers.deleteTier
class _TranslationsTiersDeleteTierRuRu implements TranslationsTiersDeleteTierEnUs {
	_TranslationsTiersDeleteTierRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Удалить тир';
	@override String get confirmTitle => 'Удалить тир';
	@override String get confirmMessage => 'Вы уверены, что хотите удалить тир "{name}"? Это действие нельзя отменить.';
	@override String get confirmButton => 'Удалить';
	@override String get cancelButton => 'Отмена';
	@override String get success => 'Тир удалён';
	@override late final _TranslationsTiersDeleteTierErrorsRuRu errors = _TranslationsTiersDeleteTierErrorsRuRu._(_root);
}

// Path: posts.postDetails
class _TranslationsPostsPostDetailsRuRu implements TranslationsPostsPostDetailsEnUs {
	_TranslationsPostsPostDetailsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Пост';
	@override String get loadError => 'Не удалось загрузить пост';
}

// Path: posts.postStatus
class _TranslationsPostsPostStatusRuRu implements TranslationsPostsPostStatusEnUs {
	_TranslationsPostsPostStatusRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get pendingReview => 'На проверке';
	@override String get approved => 'Одобрено';
	@override String get changesRequested => 'Требуются изменения';
}

// Path: posts.editPost
class _TranslationsPostsEditPostRuRu implements TranslationsPostsEditPostEnUs {
	_TranslationsPostsEditPostRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Редактировать пост';
	@override String get titleLabel => 'Заголовок';
	@override String get titleHint => 'Заголовок поста';
	@override String get mediaUrlLabel => 'Ссылка на медиа (опционально)';
	@override String get mediaUrlHint => 'https://...';
	@override String get textLabel => 'Текст (Markdown)';
	@override String get textHint => 'Напишите пост...';
	@override String get previewLabel => 'Предпросмотр';
	@override String get saveButton => 'Сохранить';
	@override late final _TranslationsPostsEditPostTabsRuRu tabs = _TranslationsPostsEditPostTabsRuRu._(_root);
	@override late final _TranslationsPostsEditPostRevisionMessageRuRu revisionMessage = _TranslationsPostsEditPostRevisionMessageRuRu._(_root);
	@override String get approvedHint => 'Этот пост одобрен и больше не может быть изменён.';
	@override late final _TranslationsPostsEditPostLogRuRu log = _TranslationsPostsEditPostLogRuRu._(_root);
	@override late final _TranslationsPostsEditPostErrorsRuRu errors = _TranslationsPostsEditPostErrorsRuRu._(_root);
}

// Path: posts.listPosts
class _TranslationsPostsListPostsRuRu implements TranslationsPostsListPostsEnUs {
	_TranslationsPostsListPostsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Постов пока нет';
	@override String get loadError => 'Не удалось загрузить посты';
	@override String get fabTooltip => 'Новый пост';
	@override String get openPost => 'Открыть';
}

// Path: posts.userPosts
class _TranslationsPostsUserPostsRuRu implements TranslationsPostsUserPostsEnUs {
	_TranslationsPostsUserPostsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String title({required Object username}) => 'Посты ${username}';
	@override String get empty => 'Нет постов';
	@override String get loadError => 'Не удалось загрузить посты';
	@override String get openPost => 'Открыть';
}

// Path: posts.deletePost
class _TranslationsPostsDeletePostRuRu implements TranslationsPostsDeletePostEnUs {
	_TranslationsPostsDeletePostRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Удалить пост';
	@override String get confirmTitle => 'Удалить пост?';
	@override String get confirmMessage => 'Это действие необратимо. Пост будет удалён навсегда.';
	@override String get confirmButton => 'Удалить';
	@override String get cancelButton => 'Отмена';
	@override String get success => 'Пост удалён';
	@override late final _TranslationsPostsDeletePostErrorsRuRu errors = _TranslationsPostsDeletePostErrorsRuRu._(_root);
}

// Path: posts.eraseDbPost
class _TranslationsPostsEraseDbPostRuRu implements TranslationsPostsEraseDbPostEnUs {
	_TranslationsPostsEraseDbPostRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Удалить пост (суперпользователь)';
	@override String get confirmTitle => 'Удалить пост?';
	@override String get confirmMessage => 'Этот пост будет удалён безвозвратно. Действие нельзя отменить.';
	@override String get confirmButton => 'Удалить';
	@override String get cancelButton => 'Отмена';
	@override String get success => 'Пост удалён';
	@override late final _TranslationsPostsEraseDbPostErrorsRuRu errors = _TranslationsPostsEraseDbPostErrorsRuRu._(_root);
}

// Path: posts.pendingPosts
class _TranslationsPostsPendingPostsRuRu implements TranslationsPostsPendingPostsEnUs {
	_TranslationsPostsPendingPostsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Посты на проверке';
	@override String get empty => 'Нет постов на проверке';
	@override String get loadError => 'Не удалось загрузить посты';
	@override String get loadMoreError => 'Не удалось загрузить ещё';
	@override String get eventCount => 'Событий';
}

// Path: posts.moderatePost
class _TranslationsPostsModeratePostRuRu implements TranslationsPostsModeratePostEnUs {
	_TranslationsPostsModeratePostRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Модерация поста';
	@override late final _TranslationsPostsModeratePostTabsRuRu tabs = _TranslationsPostsModeratePostTabsRuRu._(_root);
	@override late final _TranslationsPostsModeratePostLogRuRu log = _TranslationsPostsModeratePostLogRuRu._(_root);
	@override late final _TranslationsPostsModeratePostActionsRuRu actions = _TranslationsPostsModeratePostActionsRuRu._(_root);
	@override late final _TranslationsPostsModeratePostErrorsRuRu errors = _TranslationsPostsModeratePostErrorsRuRu._(_root);
}

// Path: posts.createPost
class _TranslationsPostsCreatePostRuRu implements TranslationsPostsCreatePostEnUs {
	_TranslationsPostsCreatePostRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Новый пост';
	@override String get titleLabel => 'Заголовок';
	@override String get titleHint => 'Заголовок поста';
	@override String get mediaUrlLabel => 'Ссылка на медиа (опционально)';
	@override String get mediaUrlHint => 'https://...';
	@override String get textLabel => 'Текст (Markdown)';
	@override String get textHint => 'Напишите пост...';
	@override String get previewLabel => 'Предпросмотр';
	@override String get publishButton => 'Опубликовать';
	@override String get fabTooltip => 'Новый пост';
	@override late final _TranslationsPostsCreatePostErrorsRuRu errors = _TranslationsPostsCreatePostErrorsRuRu._(_root);
}

// Path: users.list
class _TranslationsUsersListRuRu implements TranslationsUsersListEnUs {
	_TranslationsUsersListRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get loadMoreError => 'Не удалось загрузить больше пользователей';
	@override String get userDetails => 'Детали';
	@override String get userPosts => 'Статьи';
}

// Path: users.details
class _TranslationsUsersDetailsRuRu implements TranslationsUsersDetailsEnUs {
	_TranslationsUsersDetailsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get email => 'Email';
	@override String get tier => 'Уровень';
	@override String get tierSince => 'Тариф с';
	@override String get notFound => 'Пользователь не найден';
	@override String get loadError => 'Не удалось загрузить пользователя';
}

// Path: users.create
class _TranslationsUsersCreateRuRu implements TranslationsUsersCreateEnUs {
	_TranslationsUsersCreateRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Создать пользователя';
	@override String get name => 'Имя';
	@override String get username => 'Имя пользователя';
	@override String get email => 'Email';
	@override String get password => 'Пароль';
	@override String get submit => 'Создать';
	@override String get success => 'Пользователь успешно создан';
	@override late final _TranslationsUsersCreateErrorsRuRu errors = _TranslationsUsersCreateErrorsRuRu._(_root);
}

// Path: users.delete
class _TranslationsUsersDeleteRuRu implements TranslationsUsersDeleteEnUs {
	_TranslationsUsersDeleteRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Удалить аккаунт';
	@override String get confirmTitle => 'Удалить аккаунт?';
	@override String get confirmMessage => 'Аккаунт будет удалён навсегда. Действие нельзя отменить.';
	@override String get confirmButton => 'Удалить';
	@override String get success => 'Аккаунт удалён';
	@override late final _TranslationsUsersDeleteErrorsRuRu errors = _TranslationsUsersDeleteErrorsRuRu._(_root);
}

// Path: users.eraseDbUser
class _TranslationsUsersEraseDbUserRuRu implements TranslationsUsersEraseDbUserEnUs {
	_TranslationsUsersEraseDbUserRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Удалить из базы данных';
	@override String get confirmTitle => 'Удалить аккаунт навсегда?';
	@override String get confirmMessage => 'Аккаунт будет физически удалён из базы данных. Это действие необратимо.';
	@override String get confirmButton => 'Удалить навсегда';
	@override String get success => 'Аккаунт удалён из базы данных';
	@override late final _TranslationsUsersEraseDbUserErrorsRuRu errors = _TranslationsUsersEraseDbUserErrorsRuRu._(_root);
}

// Path: users.edit
class _TranslationsUsersEditRuRu implements TranslationsUsersEditEnUs {
	_TranslationsUsersEditRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Редактировать пользователя';
	@override String get name => 'Имя';
	@override String get username => 'Имя пользователя';
	@override String get email => 'Email';
	@override String get profileImageUrl => 'URL фото профиля';
	@override String get save => 'Сохранить';
	@override String get success => 'Пользователь успешно обновлён';
	@override late final _TranslationsUsersEditErrorsRuRu errors = _TranslationsUsersEditErrorsRuRu._(_root);
}

// Path: users.updateTier
class _TranslationsUsersUpdateTierRuRu implements TranslationsUsersUpdateTierEnUs {
	_TranslationsUsersUpdateTierRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Изменить тир';
	@override String get sheetTitle => 'Изменить тир пользователя';
	@override String get selectTier => 'Выберите тир';
	@override String get confirm => 'Подтвердить';
	@override String get success => 'Тир пользователя обновлён';
	@override late final _TranslationsUsersUpdateTierErrorsRuRu errors = _TranslationsUsersUpdateTierErrorsRuRu._(_root);
}

// Path: users.moderator
class _TranslationsUsersModeratorRuRu implements TranslationsUsersModeratorEnUs {
	_TranslationsUsersModeratorRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get badge => 'Модератор';
	@override String get assign => 'Назначить модератором';
	@override String get revoke => 'Снять права модератора';
	@override late final _TranslationsUsersModeratorErrorsRuRu errors = _TranslationsUsersModeratorErrorsRuRu._(_root);
}

// Path: auth.login.errors
class _TranslationsAuthLoginErrorsRuRu implements TranslationsAuthLoginErrorsEnUs {
	_TranslationsAuthLoginErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get required => 'Обязательное поле';
	@override String get invalidCredentials => 'Неверные учётные данные';
	@override String get generic => 'Ошибка входа. Попробуйте ещё раз.';
}

// Path: tiers.createTier.errors
class _TranslationsTiersCreateTierErrorsRuRu implements TranslationsTiersCreateTierErrorsEnUs {
	_TranslationsTiersCreateTierErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get required => 'Это поле обязательно';
	@override String get generic => 'Не удалось создать тир';
}

// Path: tiers.editTier.errors
class _TranslationsTiersEditTierErrorsRuRu implements TranslationsTiersEditTierErrorsEnUs {
	_TranslationsTiersEditTierErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get required => 'Это поле обязательно';
	@override String get notFound => 'Тир не найден';
	@override String get permissionDenied => 'Нет доступа';
	@override String get generic => 'Не удалось обновить тир';
}

// Path: tiers.deleteTier.errors
class _TranslationsTiersDeleteTierErrorsRuRu implements TranslationsTiersDeleteTierErrorsEnUs {
	_TranslationsTiersDeleteTierErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get notFound => 'Тир не найден';
	@override String get forbidden => 'Нет доступа';
	@override String get unauthorized => 'Сессия истекла';
	@override String get generic => 'Не удалось удалить тир';
}

// Path: posts.editPost.tabs
class _TranslationsPostsEditPostTabsRuRu implements TranslationsPostsEditPostTabsEnUs {
	_TranslationsPostsEditPostTabsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get edit => 'Редактировать';
	@override String get log => 'История модерации';
}

// Path: posts.editPost.revisionMessage
class _TranslationsPostsEditPostRevisionMessageRuRu implements TranslationsPostsEditPostRevisionMessageEnUs {
	_TranslationsPostsEditPostRevisionMessageRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get label => 'Сообщение о правках';
	@override String get hint => 'Опишите, что вы изменили, чтобы учесть замечания модератора';
}

// Path: posts.editPost.log
class _TranslationsPostsEditPostLogRuRu implements TranslationsPostsEditPostLogEnUs {
	_TranslationsPostsEditPostLogRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get empty => 'История модерации пуста';
	@override String get loadError => 'Не удалось загрузить историю модерации';
}

// Path: posts.editPost.errors
class _TranslationsPostsEditPostErrorsRuRu implements TranslationsPostsEditPostErrorsEnUs {
	_TranslationsPostsEditPostErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get titleTooShort => 'Заголовок должен содержать не менее 2 символов';
	@override String get titleTooLong => 'Заголовок не должен превышать 30 символов';
	@override String get mediaUrlEmpty => 'Ссылка на медиа не может быть пустой, если указана';
	@override String get textTooShort => 'Текст должен содержать не менее 100 символов';
	@override String get textTooLong => 'Текст не должен превышать 63206 символов';
	@override String get forbidden => 'Вы можете редактировать только свои посты';
	@override String get generic => 'Не удалось сохранить пост. Попробуйте ещё раз.';
	@override String get revisionMessageRequired => 'Сообщение о правках обязательно.';
	@override String get conflict => 'Статус поста изменился во время редактирования. Проверьте текущий статус.';
	@override String get notFound => 'Пост не найден.';
}

// Path: posts.deletePost.errors
class _TranslationsPostsDeletePostErrorsRuRu implements TranslationsPostsDeletePostErrorsEnUs {
	_TranslationsPostsDeletePostErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Вы можете удалять только свои посты';
	@override String get generic => 'Не удалось удалить пост. Попробуйте ещё раз.';
}

// Path: posts.eraseDbPost.errors
class _TranslationsPostsEraseDbPostErrorsRuRu implements TranslationsPostsEraseDbPostErrorsEnUs {
	_TranslationsPostsEraseDbPostErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Недостаточно прав для удаления поста';
	@override String get generic => 'Не удалось удалить пост. Попробуйте снова.';
}

// Path: posts.moderatePost.tabs
class _TranslationsPostsModeratePostTabsRuRu implements TranslationsPostsModeratePostTabsEnUs {
	_TranslationsPostsModeratePostTabsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get post => 'Пост';
	@override String get moderation => 'Модерация';
}

// Path: posts.moderatePost.log
class _TranslationsPostsModeratePostLogRuRu implements TranslationsPostsModeratePostLogEnUs {
	_TranslationsPostsModeratePostLogRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get empty => 'История модерации пуста';
	@override String get loadError => 'Не удалось загрузить историю модерации';
	@override late final _TranslationsPostsModeratePostLogEventTypesRuRu eventTypes = _TranslationsPostsModeratePostLogEventTypesRuRu._(_root);
	@override late final _TranslationsPostsModeratePostLogActionsRuRu actions = _TranslationsPostsModeratePostLogActionsRuRu._(_root);
}

// Path: posts.moderatePost.actions
class _TranslationsPostsModeratePostActionsRuRu implements TranslationsPostsModeratePostActionsEnUs {
	_TranslationsPostsModeratePostActionsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get approve => 'Одобрить';
	@override String get requestChanges => 'Запросить правки';
	@override String get messageHint => 'Добавьте комментарий (обязателен при отклонении)';
	@override String get messageRequiredError => 'Комментарий обязателен при запросе правок';
}

// Path: posts.moderatePost.errors
class _TranslationsPostsModeratePostErrorsRuRu implements TranslationsPostsModeratePostErrorsEnUs {
	_TranslationsPostsModeratePostErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'У вас нет прав на модерацию этого поста';
	@override String get notFound => 'Пост не найден';
	@override String get conflict => 'Этот пост уже был промодерирован. Вернитесь в очередь.';
	@override String get generic => 'Не удалось отправить решение. Попробуйте ещё раз.';
}

// Path: posts.createPost.errors
class _TranslationsPostsCreatePostErrorsRuRu implements TranslationsPostsCreatePostErrorsEnUs {
	_TranslationsPostsCreatePostErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get titleTooShort => 'Заголовок должен содержать не менее 2 символов';
	@override String get titleTooLong => 'Заголовок не должен превышать 30 символов';
	@override String get mediaUrlEmpty => 'Ссылка на медиа не может быть пустой, если указана';
	@override String get textTooShort => 'Текст должен содержать не менее 100 символов';
	@override String get textTooLong => 'Текст не должен превышать 63206 символов';
	@override String get forbidden => 'Вы можете публиковать посты только от своего имени';
	@override String get generic => 'Не удалось опубликовать пост. Попробуйте ещё раз.';
}

// Path: users.create.errors
class _TranslationsUsersCreateErrorsRuRu implements TranslationsUsersCreateErrorsEnUs {
	_TranslationsUsersCreateErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get required => 'Это поле обязательно';
	@override String get emailInvalid => 'Введите корректный адрес email';
	@override String get passwordTooShort => 'Пароль должен содержать не менее 8 символов';
	@override String get usernameTaken => 'Имя пользователя уже занято';
	@override String get emailTaken => 'Email уже занят';
	@override String get generic => 'Что-то пошло не так. Попробуйте ещё раз.';
}

// Path: users.delete.errors
class _TranslationsUsersDeleteErrorsRuRu implements TranslationsUsersDeleteErrorsEnUs {
	_TranslationsUsersDeleteErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Можно удалить только свой аккаунт.';
	@override String get unauthorized => 'Сессия истекла.';
	@override String get notFound => 'Пользователь не найден.';
	@override String get generic => 'Не удалось удалить аккаунт.';
}

// Path: users.eraseDbUser.errors
class _TranslationsUsersEraseDbUserErrorsRuRu implements TranslationsUsersEraseDbUserErrorsEnUs {
	_TranslationsUsersEraseDbUserErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Можно удалить только свой аккаунт';
	@override String get unauthorized => 'Сессия истекла. Войдите снова';
	@override String get notFound => 'Пользователь не найден';
	@override String get generic => 'Не удалось удалить аккаунт. Попробуйте ещё раз';
}

// Path: users.edit.errors
class _TranslationsUsersEditErrorsRuRu implements TranslationsUsersEditErrorsEnUs {
	_TranslationsUsersEditErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get required => 'Это поле обязательно';
	@override String get emailInvalid => 'Введите корректный адрес email';
	@override String get usernameTaken => 'Имя пользователя уже занято';
	@override String get notFound => 'Пользователь не найден';
	@override String get nothingToUpdate => 'Нет изменений для сохранения';
	@override String get forbidden => 'Можно редактировать только свой профиль.';
	@override String get unauthorized => 'Сессия истекла.';
	@override String get generic => 'Что-то пошло не так. Попробуйте ещё раз.';
}

// Path: users.updateTier.errors
class _TranslationsUsersUpdateTierErrorsRuRu implements TranslationsUsersUpdateTierErrorsEnUs {
	_TranslationsUsersUpdateTierErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get permissionDenied => 'У вас нет прав для изменения тира.';
	@override String get notFound => 'Пользователь или тир не найден.';
	@override String get forbidden => 'Доступ запрещён.';
	@override String get unauthorized => 'Сессия истекла.';
	@override String get generic => 'Не удалось обновить тир. Попробуйте ещё раз.';
}

// Path: users.moderator.errors
class _TranslationsUsersModeratorErrorsRuRu implements TranslationsUsersModeratorErrorsEnUs {
	_TranslationsUsersModeratorErrorsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get conflict => 'Действие неприменимо — статус модератора уже актуален.';
	@override String get forbidden => 'У вас нет прав для управления модераторами.';
	@override String get generic => 'Не удалось обновить статус модератора. Попробуйте ещё раз.';
}

// Path: posts.moderatePost.log.eventTypes
class _TranslationsPostsModeratePostLogEventTypesRuRu implements TranslationsPostsModeratePostLogEventTypesEnUs {
	_TranslationsPostsModeratePostLogEventTypesRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get moderatorReview => 'Проверка модератора';
	@override String get authorRevision => 'Правка автора';
}

// Path: posts.moderatePost.log.actions
class _TranslationsPostsModeratePostLogActionsRuRu implements TranslationsPostsModeratePostLogActionsEnUs {
	_TranslationsPostsModeratePostLogActionsRuRu._(this._root);

	final TranslationsRuRu _root; // ignore: unused_field

	// Translations
	@override String get approved => 'Одобрено';
	@override String get changesRequested => 'Запрошены правки';
}

/// The flat map containing all translations for locale <ru-RU>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsRuRu {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'auth.login.title' => 'Вход',
			'auth.login.username' => 'Имя пользователя',
			'auth.login.password' => 'Пароль',
			'auth.login.submit' => 'Войти',
			'auth.login.signInButton' => 'Войти',
			'auth.login.errors.required' => 'Обязательное поле',
			'auth.login.errors.invalidCredentials' => 'Неверные учётные данные',
			'auth.login.errors.generic' => 'Ошибка входа. Попробуйте ещё раз.',
			'auth.logout.confirmTitle' => 'Выйти?',
			'auth.logout.confirmMessage' => 'Потребуется снова войти.',
			'auth.logout.confirm' => 'Выйти',
			'auth.logout.cancel' => 'Отмена',
			'auth.sessionExpired' => 'Сессия истекла. Войдите снова.',
			'app.title' => 'Flutter App',
			'nav.users' => 'Пользователи',
			'nav.posts' => 'Посты',
			'nav.tiers' => 'Тиры',
			'nav.pending' => 'На проверке',
			'common.loading' => 'Загрузка...',
			'common.error' => 'Что-то пошло не так',
			'common.retry' => 'Повторить',
			'common.back' => 'Назад',
			'common.cancel' => 'Отмена',
			'tiers.listTiers.title' => 'Тиры',
			'tiers.listTiers.loadError' => 'Не удалось загрузить тиры',
			'tiers.listTiers.loadMoreError' => 'Не удалось загрузить следующую страницу',
			'tiers.listTiers.empty' => 'Тиры не найдены',
			'tiers.createTier.title' => 'Создать тир',
			'tiers.createTier.name' => 'Название',
			'tiers.createTier.submit' => 'Создать',
			'tiers.createTier.fabTooltip' => 'Добавить тир',
			'tiers.createTier.success' => 'Тир создан',
			'tiers.createTier.errors.required' => 'Это поле обязательно',
			'tiers.createTier.errors.generic' => 'Не удалось создать тир',
			'tiers.tierDetails.title' => 'Детали уровня',
			'tiers.tierDetails.id' => 'ID',
			'tiers.tierDetails.createdAt' => 'Создан',
			'tiers.tierDetails.notFound' => 'Уровень не найден',
			'tiers.tierDetails.loadError' => 'Ошибка загрузки',
			'tiers.tierDetails.permissionDenied' => 'Нет доступа',
			'tiers.editTier.title' => 'Редактировать тир',
			'tiers.editTier.name' => 'Название',
			'tiers.editTier.save' => 'Сохранить',
			'tiers.editTier.success' => 'Тир обновлён',
			'tiers.editTier.errors.required' => 'Это поле обязательно',
			'tiers.editTier.errors.notFound' => 'Тир не найден',
			'tiers.editTier.errors.permissionDenied' => 'Нет доступа',
			'tiers.editTier.errors.generic' => 'Не удалось обновить тир',
			'tiers.deleteTier.tooltip' => 'Удалить тир',
			'tiers.deleteTier.confirmTitle' => 'Удалить тир',
			'tiers.deleteTier.confirmMessage' => 'Вы уверены, что хотите удалить тир "{name}"? Это действие нельзя отменить.',
			'tiers.deleteTier.confirmButton' => 'Удалить',
			'tiers.deleteTier.cancelButton' => 'Отмена',
			'tiers.deleteTier.success' => 'Тир удалён',
			'tiers.deleteTier.errors.notFound' => 'Тир не найден',
			'tiers.deleteTier.errors.forbidden' => 'Нет доступа',
			'tiers.deleteTier.errors.unauthorized' => 'Сессия истекла',
			'tiers.deleteTier.errors.generic' => 'Не удалось удалить тир',
			'posts.postDetails.title' => 'Пост',
			'posts.postDetails.loadError' => 'Не удалось загрузить пост',
			'posts.postStatus.pendingReview' => 'На проверке',
			'posts.postStatus.approved' => 'Одобрено',
			'posts.postStatus.changesRequested' => 'Требуются изменения',
			'posts.editPost.title' => 'Редактировать пост',
			'posts.editPost.titleLabel' => 'Заголовок',
			'posts.editPost.titleHint' => 'Заголовок поста',
			'posts.editPost.mediaUrlLabel' => 'Ссылка на медиа (опционально)',
			'posts.editPost.mediaUrlHint' => 'https://...',
			'posts.editPost.textLabel' => 'Текст (Markdown)',
			'posts.editPost.textHint' => 'Напишите пост...',
			'posts.editPost.previewLabel' => 'Предпросмотр',
			'posts.editPost.saveButton' => 'Сохранить',
			'posts.editPost.tabs.edit' => 'Редактировать',
			'posts.editPost.tabs.log' => 'История модерации',
			'posts.editPost.revisionMessage.label' => 'Сообщение о правках',
			'posts.editPost.revisionMessage.hint' => 'Опишите, что вы изменили, чтобы учесть замечания модератора',
			'posts.editPost.approvedHint' => 'Этот пост одобрен и больше не может быть изменён.',
			'posts.editPost.log.empty' => 'История модерации пуста',
			'posts.editPost.log.loadError' => 'Не удалось загрузить историю модерации',
			'posts.editPost.errors.titleTooShort' => 'Заголовок должен содержать не менее 2 символов',
			'posts.editPost.errors.titleTooLong' => 'Заголовок не должен превышать 30 символов',
			'posts.editPost.errors.mediaUrlEmpty' => 'Ссылка на медиа не может быть пустой, если указана',
			'posts.editPost.errors.textTooShort' => 'Текст должен содержать не менее 100 символов',
			'posts.editPost.errors.textTooLong' => 'Текст не должен превышать 63206 символов',
			'posts.editPost.errors.forbidden' => 'Вы можете редактировать только свои посты',
			'posts.editPost.errors.generic' => 'Не удалось сохранить пост. Попробуйте ещё раз.',
			'posts.editPost.errors.revisionMessageRequired' => 'Сообщение о правках обязательно.',
			'posts.editPost.errors.conflict' => 'Статус поста изменился во время редактирования. Проверьте текущий статус.',
			'posts.editPost.errors.notFound' => 'Пост не найден.',
			'posts.listPosts.empty' => 'Постов пока нет',
			'posts.listPosts.loadError' => 'Не удалось загрузить посты',
			'posts.listPosts.fabTooltip' => 'Новый пост',
			'posts.listPosts.openPost' => 'Открыть',
			'posts.userPosts.title' => ({required Object username}) => 'Посты ${username}',
			'posts.userPosts.empty' => 'Нет постов',
			'posts.userPosts.loadError' => 'Не удалось загрузить посты',
			'posts.userPosts.openPost' => 'Открыть',
			'posts.deletePost.tooltip' => 'Удалить пост',
			'posts.deletePost.confirmTitle' => 'Удалить пост?',
			'posts.deletePost.confirmMessage' => 'Это действие необратимо. Пост будет удалён навсегда.',
			'posts.deletePost.confirmButton' => 'Удалить',
			'posts.deletePost.cancelButton' => 'Отмена',
			'posts.deletePost.success' => 'Пост удалён',
			'posts.deletePost.errors.forbidden' => 'Вы можете удалять только свои посты',
			'posts.deletePost.errors.generic' => 'Не удалось удалить пост. Попробуйте ещё раз.',
			'posts.eraseDbPost.tooltip' => 'Удалить пост (суперпользователь)',
			'posts.eraseDbPost.confirmTitle' => 'Удалить пост?',
			'posts.eraseDbPost.confirmMessage' => 'Этот пост будет удалён безвозвратно. Действие нельзя отменить.',
			'posts.eraseDbPost.confirmButton' => 'Удалить',
			'posts.eraseDbPost.cancelButton' => 'Отмена',
			'posts.eraseDbPost.success' => 'Пост удалён',
			'posts.eraseDbPost.errors.forbidden' => 'Недостаточно прав для удаления поста',
			'posts.eraseDbPost.errors.generic' => 'Не удалось удалить пост. Попробуйте снова.',
			'posts.pendingPosts.title' => 'Посты на проверке',
			'posts.pendingPosts.empty' => 'Нет постов на проверке',
			'posts.pendingPosts.loadError' => 'Не удалось загрузить посты',
			'posts.pendingPosts.loadMoreError' => 'Не удалось загрузить ещё',
			'posts.pendingPosts.eventCount' => 'Событий',
			'posts.moderatePost.title' => 'Модерация поста',
			'posts.moderatePost.tabs.post' => 'Пост',
			'posts.moderatePost.tabs.moderation' => 'Модерация',
			'posts.moderatePost.log.empty' => 'История модерации пуста',
			'posts.moderatePost.log.loadError' => 'Не удалось загрузить историю модерации',
			'posts.moderatePost.log.eventTypes.moderatorReview' => 'Проверка модератора',
			'posts.moderatePost.log.eventTypes.authorRevision' => 'Правка автора',
			'posts.moderatePost.log.actions.approved' => 'Одобрено',
			'posts.moderatePost.log.actions.changesRequested' => 'Запрошены правки',
			'posts.moderatePost.actions.approve' => 'Одобрить',
			'posts.moderatePost.actions.requestChanges' => 'Запросить правки',
			'posts.moderatePost.actions.messageHint' => 'Добавьте комментарий (обязателен при отклонении)',
			'posts.moderatePost.actions.messageRequiredError' => 'Комментарий обязателен при запросе правок',
			'posts.moderatePost.errors.forbidden' => 'У вас нет прав на модерацию этого поста',
			'posts.moderatePost.errors.notFound' => 'Пост не найден',
			'posts.moderatePost.errors.conflict' => 'Этот пост уже был промодерирован. Вернитесь в очередь.',
			'posts.moderatePost.errors.generic' => 'Не удалось отправить решение. Попробуйте ещё раз.',
			'posts.createPost.title' => 'Новый пост',
			'posts.createPost.titleLabel' => 'Заголовок',
			'posts.createPost.titleHint' => 'Заголовок поста',
			'posts.createPost.mediaUrlLabel' => 'Ссылка на медиа (опционально)',
			'posts.createPost.mediaUrlHint' => 'https://...',
			'posts.createPost.textLabel' => 'Текст (Markdown)',
			'posts.createPost.textHint' => 'Напишите пост...',
			'posts.createPost.previewLabel' => 'Предпросмотр',
			'posts.createPost.publishButton' => 'Опубликовать',
			'posts.createPost.fabTooltip' => 'Новый пост',
			'posts.createPost.errors.titleTooShort' => 'Заголовок должен содержать не менее 2 символов',
			'posts.createPost.errors.titleTooLong' => 'Заголовок не должен превышать 30 символов',
			'posts.createPost.errors.mediaUrlEmpty' => 'Ссылка на медиа не может быть пустой, если указана',
			'posts.createPost.errors.textTooShort' => 'Текст должен содержать не менее 100 символов',
			'posts.createPost.errors.textTooLong' => 'Текст не должен превышать 63206 символов',
			'posts.createPost.errors.forbidden' => 'Вы можете публиковать посты только от своего имени',
			'posts.createPost.errors.generic' => 'Не удалось опубликовать пост. Попробуйте ещё раз.',
			'userMenu.myProfile' => 'Мой профиль',
			'userMenu.myPosts' => 'Мои публикации',
			'users.title' => 'Пользователи',
			'users.list.loadMoreError' => 'Не удалось загрузить больше пользователей',
			'users.list.userDetails' => 'Детали',
			'users.list.userPosts' => 'Статьи',
			'users.details.email' => 'Email',
			'users.details.tier' => 'Уровень',
			'users.details.tierSince' => 'Тариф с',
			'users.details.notFound' => 'Пользователь не найден',
			'users.details.loadError' => 'Не удалось загрузить пользователя',
			'users.create.title' => 'Создать пользователя',
			'users.create.name' => 'Имя',
			'users.create.username' => 'Имя пользователя',
			'users.create.email' => 'Email',
			'users.create.password' => 'Пароль',
			'users.create.submit' => 'Создать',
			'users.create.success' => 'Пользователь успешно создан',
			'users.create.errors.required' => 'Это поле обязательно',
			'users.create.errors.emailInvalid' => 'Введите корректный адрес email',
			'users.create.errors.passwordTooShort' => 'Пароль должен содержать не менее 8 символов',
			'users.create.errors.usernameTaken' => 'Имя пользователя уже занято',
			'users.create.errors.emailTaken' => 'Email уже занят',
			'users.create.errors.generic' => 'Что-то пошло не так. Попробуйте ещё раз.',
			'users.delete.tooltip' => 'Удалить аккаунт',
			'users.delete.confirmTitle' => 'Удалить аккаунт?',
			'users.delete.confirmMessage' => 'Аккаунт будет удалён навсегда. Действие нельзя отменить.',
			'users.delete.confirmButton' => 'Удалить',
			'users.delete.success' => 'Аккаунт удалён',
			'users.delete.errors.forbidden' => 'Можно удалить только свой аккаунт.',
			'users.delete.errors.unauthorized' => 'Сессия истекла.',
			'users.delete.errors.notFound' => 'Пользователь не найден.',
			'users.delete.errors.generic' => 'Не удалось удалить аккаунт.',
			'users.eraseDbUser.tooltip' => 'Удалить из базы данных',
			'users.eraseDbUser.confirmTitle' => 'Удалить аккаунт навсегда?',
			'users.eraseDbUser.confirmMessage' => 'Аккаунт будет физически удалён из базы данных. Это действие необратимо.',
			'users.eraseDbUser.confirmButton' => 'Удалить навсегда',
			'users.eraseDbUser.success' => 'Аккаунт удалён из базы данных',
			'users.eraseDbUser.errors.forbidden' => 'Можно удалить только свой аккаунт',
			'users.eraseDbUser.errors.unauthorized' => 'Сессия истекла. Войдите снова',
			'users.eraseDbUser.errors.notFound' => 'Пользователь не найден',
			'users.eraseDbUser.errors.generic' => 'Не удалось удалить аккаунт. Попробуйте ещё раз',
			'users.edit.title' => 'Редактировать пользователя',
			'users.edit.name' => 'Имя',
			'users.edit.username' => 'Имя пользователя',
			'users.edit.email' => 'Email',
			'users.edit.profileImageUrl' => 'URL фото профиля',
			'users.edit.save' => 'Сохранить',
			'users.edit.success' => 'Пользователь успешно обновлён',
			'users.edit.errors.required' => 'Это поле обязательно',
			'users.edit.errors.emailInvalid' => 'Введите корректный адрес email',
			'users.edit.errors.usernameTaken' => 'Имя пользователя уже занято',
			'users.edit.errors.notFound' => 'Пользователь не найден',
			'users.edit.errors.nothingToUpdate' => 'Нет изменений для сохранения',
			'users.edit.errors.forbidden' => 'Можно редактировать только свой профиль.',
			'users.edit.errors.unauthorized' => 'Сессия истекла.',
			'users.edit.errors.generic' => 'Что-то пошло не так. Попробуйте ещё раз.',
			'users.updateTier.tooltip' => 'Изменить тир',
			'users.updateTier.sheetTitle' => 'Изменить тир пользователя',
			'users.updateTier.selectTier' => 'Выберите тир',
			'users.updateTier.confirm' => 'Подтвердить',
			'users.updateTier.success' => 'Тир пользователя обновлён',
			'users.updateTier.errors.permissionDenied' => 'У вас нет прав для изменения тира.',
			'users.updateTier.errors.notFound' => 'Пользователь или тир не найден.',
			'users.updateTier.errors.forbidden' => 'Доступ запрещён.',
			'users.updateTier.errors.unauthorized' => 'Сессия истекла.',
			'users.updateTier.errors.generic' => 'Не удалось обновить тир. Попробуйте ещё раз.',
			'users.moderator.badge' => 'Модератор',
			'users.moderator.assign' => 'Назначить модератором',
			'users.moderator.revoke' => 'Снять права модератора',
			'users.moderator.errors.conflict' => 'Действие неприменимо — статус модератора уже актуален.',
			'users.moderator.errors.forbidden' => 'У вас нет прав для управления модераторами.',
			'users.moderator.errors.generic' => 'Не удалось обновить статус модератора. Попробуйте ещё раз.',
			_ => null,
		};
	}
}
