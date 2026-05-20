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
class TranslationsEsEs with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.esEs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es-ES>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsEsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsAuthEsEs auth = _TranslationsAuthEsEs._(_root);
	@override late final _TranslationsAppEsEs app = _TranslationsAppEsEs._(_root);
	@override late final _TranslationsNavEsEs nav = _TranslationsNavEsEs._(_root);
	@override late final _TranslationsCommonEsEs common = _TranslationsCommonEsEs._(_root);
	@override late final _TranslationsTiersEsEs tiers = _TranslationsTiersEsEs._(_root);
	@override late final _TranslationsPostsEsEs posts = _TranslationsPostsEsEs._(_root);
	@override late final _TranslationsUserMenuEsEs userMenu = _TranslationsUserMenuEsEs._(_root);
	@override late final _TranslationsUsersEsEs users = _TranslationsUsersEsEs._(_root);
}

// Path: auth
class _TranslationsAuthEsEs implements TranslationsAuthEnUs {
	_TranslationsAuthEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsAuthLoginEsEs login = _TranslationsAuthLoginEsEs._(_root);
	@override late final _TranslationsAuthLogoutEsEs logout = _TranslationsAuthLogoutEsEs._(_root);
	@override String get sessionExpired => 'Sesión expirada. Inicie sesión de nuevo.';
}

// Path: app
class _TranslationsAppEsEs implements TranslationsAppEnUs {
	_TranslationsAppEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flutter App';
}

// Path: nav
class _TranslationsNavEsEs implements TranslationsNavEnUs {
	_TranslationsNavEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get users => 'Usuarios';
	@override String get posts => 'Publicaciones';
	@override String get tiers => 'Niveles';
	@override String get pending => 'Pendiente';
}

// Path: common
class _TranslationsCommonEsEs implements TranslationsCommonEnUs {
	_TranslationsCommonEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Cargando...';
	@override String get error => 'Algo salió mal';
	@override String get retry => 'Reintentar';
	@override String get back => 'Atrás';
	@override String get cancel => 'Cancelar';
}

// Path: tiers
class _TranslationsTiersEsEs implements TranslationsTiersEnUs {
	_TranslationsTiersEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsTiersListTiersEsEs listTiers = _TranslationsTiersListTiersEsEs._(_root);
	@override late final _TranslationsTiersCreateTierEsEs createTier = _TranslationsTiersCreateTierEsEs._(_root);
	@override late final _TranslationsTiersTierDetailsEsEs tierDetails = _TranslationsTiersTierDetailsEsEs._(_root);
	@override late final _TranslationsTiersEditTierEsEs editTier = _TranslationsTiersEditTierEsEs._(_root);
	@override late final _TranslationsTiersDeleteTierEsEs deleteTier = _TranslationsTiersDeleteTierEsEs._(_root);
}

// Path: posts
class _TranslationsPostsEsEs implements TranslationsPostsEnUs {
	_TranslationsPostsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsPostsPostDetailsEsEs postDetails = _TranslationsPostsPostDetailsEsEs._(_root);
	@override late final _TranslationsPostsPostStatusEsEs postStatus = _TranslationsPostsPostStatusEsEs._(_root);
	@override late final _TranslationsPostsEditPostEsEs editPost = _TranslationsPostsEditPostEsEs._(_root);
	@override late final _TranslationsPostsListPostsEsEs listPosts = _TranslationsPostsListPostsEsEs._(_root);
	@override late final _TranslationsPostsUserPostsEsEs userPosts = _TranslationsPostsUserPostsEsEs._(_root);
	@override late final _TranslationsPostsDeletePostEsEs deletePost = _TranslationsPostsDeletePostEsEs._(_root);
	@override late final _TranslationsPostsEraseDbPostEsEs eraseDbPost = _TranslationsPostsEraseDbPostEsEs._(_root);
	@override late final _TranslationsPostsPendingPostsEsEs pendingPosts = _TranslationsPostsPendingPostsEsEs._(_root);
	@override late final _TranslationsPostsModeratePostEsEs moderatePost = _TranslationsPostsModeratePostEsEs._(_root);
	@override late final _TranslationsPostsCreatePostEsEs createPost = _TranslationsPostsCreatePostEsEs._(_root);
}

// Path: userMenu
class _TranslationsUserMenuEsEs implements TranslationsUserMenuEnUs {
	_TranslationsUserMenuEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get myProfile => 'Mi perfil';
	@override String get myPosts => 'Mis publicaciones';
}

// Path: users
class _TranslationsUsersEsEs implements TranslationsUsersEnUs {
	_TranslationsUsersEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Usuarios';
	@override late final _TranslationsUsersListEsEs list = _TranslationsUsersListEsEs._(_root);
	@override late final _TranslationsUsersDetailsEsEs details = _TranslationsUsersDetailsEsEs._(_root);
	@override late final _TranslationsUsersCreateEsEs create = _TranslationsUsersCreateEsEs._(_root);
	@override late final _TranslationsUsersDeleteEsEs delete = _TranslationsUsersDeleteEsEs._(_root);
	@override late final _TranslationsUsersEraseDbUserEsEs eraseDbUser = _TranslationsUsersEraseDbUserEsEs._(_root);
	@override late final _TranslationsUsersEditEsEs edit = _TranslationsUsersEditEsEs._(_root);
	@override late final _TranslationsUsersUpdateTierEsEs updateTier = _TranslationsUsersUpdateTierEsEs._(_root);
	@override late final _TranslationsUsersModeratorEsEs moderator = _TranslationsUsersModeratorEsEs._(_root);
}

// Path: auth.login
class _TranslationsAuthLoginEsEs implements TranslationsAuthLoginEnUs {
	_TranslationsAuthLoginEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Iniciar sesión';
	@override String get username => 'Nombre de usuario';
	@override String get password => 'Contraseña';
	@override String get submit => 'Iniciar sesión';
	@override String get signInButton => 'Iniciar sesión';
	@override late final _TranslationsAuthLoginErrorsEsEs errors = _TranslationsAuthLoginErrorsEsEs._(_root);
}

// Path: auth.logout
class _TranslationsAuthLogoutEsEs implements TranslationsAuthLogoutEnUs {
	_TranslationsAuthLogoutEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get confirmTitle => '¿Cerrar sesión?';
	@override String get confirmMessage => 'Tendrá que iniciar sesión de nuevo.';
	@override String get confirm => 'Cerrar sesión';
	@override String get cancel => 'Cancelar';
}

// Path: tiers.listTiers
class _TranslationsTiersListTiersEsEs implements TranslationsTiersListTiersEnUs {
	_TranslationsTiersListTiersEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Niveles';
	@override String get loadError => 'Error al cargar los niveles';
	@override String get loadMoreError => 'Error al cargar más niveles';
	@override String get empty => 'No se encontraron niveles';
}

// Path: tiers.createTier
class _TranslationsTiersCreateTierEsEs implements TranslationsTiersCreateTierEnUs {
	_TranslationsTiersCreateTierEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Crear nivel';
	@override String get name => 'Nombre';
	@override String get submit => 'Crear';
	@override String get fabTooltip => 'Añadir nivel';
	@override String get success => 'Nivel creado';
	@override late final _TranslationsTiersCreateTierErrorsEsEs errors = _TranslationsTiersCreateTierErrorsEsEs._(_root);
}

// Path: tiers.tierDetails
class _TranslationsTiersTierDetailsEsEs implements TranslationsTiersTierDetailsEnUs {
	_TranslationsTiersTierDetailsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Detalles del nivel';
	@override String get id => 'ID';
	@override String get createdAt => 'Creado';
	@override String get notFound => 'Nivel no encontrado';
	@override String get loadError => 'Error al cargar el nivel';
	@override String get permissionDenied => 'Acceso denegado';
}

// Path: tiers.editTier
class _TranslationsTiersEditTierEsEs implements TranslationsTiersEditTierEnUs {
	_TranslationsTiersEditTierEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Editar nivel';
	@override String get name => 'Nombre';
	@override String get save => 'Guardar';
	@override String get success => 'Nivel actualizado';
	@override late final _TranslationsTiersEditTierErrorsEsEs errors = _TranslationsTiersEditTierErrorsEsEs._(_root);
}

// Path: tiers.deleteTier
class _TranslationsTiersDeleteTierEsEs implements TranslationsTiersDeleteTierEnUs {
	_TranslationsTiersDeleteTierEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Eliminar nivel';
	@override String get confirmTitle => 'Eliminar nivel';
	@override String get confirmMessage => '¿Está seguro de que desea eliminar el nivel "{name}"? Esta acción no se puede deshacer.';
	@override String get confirmButton => 'Eliminar';
	@override String get cancelButton => 'Cancelar';
	@override String get success => 'Nivel eliminado';
	@override late final _TranslationsTiersDeleteTierErrorsEsEs errors = _TranslationsTiersDeleteTierErrorsEsEs._(_root);
}

// Path: posts.postDetails
class _TranslationsPostsPostDetailsEsEs implements TranslationsPostsPostDetailsEnUs {
	_TranslationsPostsPostDetailsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Publicación';
	@override String get loadError => 'Error al cargar la publicación';
}

// Path: posts.postStatus
class _TranslationsPostsPostStatusEsEs implements TranslationsPostsPostStatusEnUs {
	_TranslationsPostsPostStatusEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get pendingReview => 'Pendiente de revisión';
	@override String get approved => 'Aprobado';
	@override String get changesRequested => 'Se requieren cambios';
}

// Path: posts.editPost
class _TranslationsPostsEditPostEsEs implements TranslationsPostsEditPostEnUs {
	_TranslationsPostsEditPostEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Editar publicación';
	@override String get titleLabel => 'Título';
	@override String get titleHint => 'Título de la publicación';
	@override String get mediaUrlLabel => 'URL de medios (opcional)';
	@override String get mediaUrlHint => 'https://...';
	@override String get textLabel => 'Texto (Markdown)';
	@override String get textHint => 'Escriba su publicación...';
	@override String get previewLabel => 'Vista previa';
	@override String get saveButton => 'Guardar';
	@override late final _TranslationsPostsEditPostTabsEsEs tabs = _TranslationsPostsEditPostTabsEsEs._(_root);
	@override late final _TranslationsPostsEditPostRevisionMessageEsEs revisionMessage = _TranslationsPostsEditPostRevisionMessageEsEs._(_root);
	@override String get approvedHint => 'Esta publicación está aprobada y ya no puede editarse.';
	@override late final _TranslationsPostsEditPostLogEsEs log = _TranslationsPostsEditPostLogEsEs._(_root);
	@override late final _TranslationsPostsEditPostErrorsEsEs errors = _TranslationsPostsEditPostErrorsEsEs._(_root);
}

// Path: posts.listPosts
class _TranslationsPostsListPostsEsEs implements TranslationsPostsListPostsEnUs {
	_TranslationsPostsListPostsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Aún no hay publicaciones';
	@override String get loadError => 'Error al cargar las publicaciones';
	@override String get fabTooltip => 'Nueva publicación';
	@override String get openPost => 'Abrir';
}

// Path: posts.userPosts
class _TranslationsPostsUserPostsEsEs implements TranslationsPostsUserPostsEnUs {
	_TranslationsPostsUserPostsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object username}) => 'Publicaciones de ${username}';
	@override String get empty => 'Aún no hay publicaciones';
	@override String get loadError => 'Error al cargar las publicaciones';
	@override String get openPost => 'Abrir';
}

// Path: posts.deletePost
class _TranslationsPostsDeletePostEsEs implements TranslationsPostsDeletePostEnUs {
	_TranslationsPostsDeletePostEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Eliminar publicación';
	@override String get confirmTitle => '¿Eliminar publicación?';
	@override String get confirmMessage => 'Esta acción es irreversible. La publicación se eliminará permanentemente.';
	@override String get confirmButton => 'Eliminar';
	@override String get cancelButton => 'Cancelar';
	@override String get success => 'Publicación eliminada';
	@override late final _TranslationsPostsDeletePostErrorsEsEs errors = _TranslationsPostsDeletePostErrorsEsEs._(_root);
}

// Path: posts.eraseDbPost
class _TranslationsPostsEraseDbPostEsEs implements TranslationsPostsEraseDbPostEnUs {
	_TranslationsPostsEraseDbPostEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Borrar publicación (superusuario)';
	@override String get confirmTitle => '¿Borrar publicación?';
	@override String get confirmMessage => 'Esta publicación se borrará permanentemente. Esta acción no se puede deshacer.';
	@override String get confirmButton => 'Borrar';
	@override String get cancelButton => 'Cancelar';
	@override String get success => 'Publicación borrada';
	@override late final _TranslationsPostsEraseDbPostErrorsEsEs errors = _TranslationsPostsEraseDbPostErrorsEsEs._(_root);
}

// Path: posts.pendingPosts
class _TranslationsPostsPendingPostsEsEs implements TranslationsPostsPendingPostsEnUs {
	_TranslationsPostsPendingPostsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Publicaciones pendientes';
	@override String get empty => 'No hay publicaciones pendientes';
	@override String get loadError => 'Error al cargar las publicaciones pendientes';
	@override String get loadMoreError => 'Error al cargar más';
	@override String get eventCount => 'Eventos';
}

// Path: posts.moderatePost
class _TranslationsPostsModeratePostEsEs implements TranslationsPostsModeratePostEnUs {
	_TranslationsPostsModeratePostEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Moderar publicación';
	@override late final _TranslationsPostsModeratePostTabsEsEs tabs = _TranslationsPostsModeratePostTabsEsEs._(_root);
	@override late final _TranslationsPostsModeratePostLogEsEs log = _TranslationsPostsModeratePostLogEsEs._(_root);
	@override late final _TranslationsPostsModeratePostActionsEsEs actions = _TranslationsPostsModeratePostActionsEsEs._(_root);
	@override late final _TranslationsPostsModeratePostErrorsEsEs errors = _TranslationsPostsModeratePostErrorsEsEs._(_root);
}

// Path: posts.createPost
class _TranslationsPostsCreatePostEsEs implements TranslationsPostsCreatePostEnUs {
	_TranslationsPostsCreatePostEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nueva publicación';
	@override String get titleLabel => 'Título';
	@override String get titleHint => 'Título de la publicación';
	@override String get mediaUrlLabel => 'URL de medios (opcional)';
	@override String get mediaUrlHint => 'https://...';
	@override String get textLabel => 'Texto (Markdown)';
	@override String get textHint => 'Escriba su publicación...';
	@override String get previewLabel => 'Vista previa';
	@override String get publishButton => 'Publicar';
	@override String get fabTooltip => 'Nueva publicación';
	@override late final _TranslationsPostsCreatePostErrorsEsEs errors = _TranslationsPostsCreatePostErrorsEsEs._(_root);
}

// Path: users.list
class _TranslationsUsersListEsEs implements TranslationsUsersListEnUs {
	_TranslationsUsersListEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get loadMoreError => 'Error al cargar más usuarios';
	@override String get userDetails => 'Detalles';
	@override String get userPosts => 'Publicaciones';
}

// Path: users.details
class _TranslationsUsersDetailsEsEs implements TranslationsUsersDetailsEnUs {
	_TranslationsUsersDetailsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get email => 'Correo electrónico';
	@override String get tier => 'Nivel';
	@override String get tierSince => 'Nivel desde';
	@override String get notFound => 'Usuario no encontrado';
	@override String get loadError => 'Error al cargar el usuario';
}

// Path: users.create
class _TranslationsUsersCreateEsEs implements TranslationsUsersCreateEnUs {
	_TranslationsUsersCreateEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Crear usuario';
	@override String get name => 'Nombre';
	@override String get username => 'Nombre de usuario';
	@override String get email => 'Correo electrónico';
	@override String get password => 'Contraseña';
	@override String get submit => 'Crear';
	@override String get success => 'Usuario creado correctamente';
	@override late final _TranslationsUsersCreateErrorsEsEs errors = _TranslationsUsersCreateErrorsEsEs._(_root);
}

// Path: users.delete
class _TranslationsUsersDeleteEsEs implements TranslationsUsersDeleteEnUs {
	_TranslationsUsersDeleteEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Eliminar cuenta';
	@override String get confirmTitle => '¿Eliminar cuenta?';
	@override String get confirmMessage => 'Esto eliminará permanentemente su cuenta. Esta acción no se puede deshacer.';
	@override String get confirmButton => 'Eliminar';
	@override String get success => 'Cuenta eliminada';
	@override late final _TranslationsUsersDeleteErrorsEsEs errors = _TranslationsUsersDeleteErrorsEsEs._(_root);
}

// Path: users.eraseDbUser
class _TranslationsUsersEraseDbUserEsEs implements TranslationsUsersEraseDbUserEnUs {
	_TranslationsUsersEraseDbUserEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Borrar de la base de datos';
	@override String get confirmTitle => '¿Borrar cuenta permanentemente?';
	@override String get confirmMessage => 'Esto eliminará permanentemente su cuenta de la base de datos. Esta acción no se puede deshacer.';
	@override String get confirmButton => 'Borrar permanentemente';
	@override String get success => 'Cuenta borrada de la base de datos';
	@override late final _TranslationsUsersEraseDbUserErrorsEsEs errors = _TranslationsUsersEraseDbUserErrorsEsEs._(_root);
}

// Path: users.edit
class _TranslationsUsersEditEsEs implements TranslationsUsersEditEnUs {
	_TranslationsUsersEditEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Editar usuario';
	@override String get name => 'Nombre';
	@override String get username => 'Nombre de usuario';
	@override String get email => 'Correo electrónico';
	@override String get profileImageUrl => 'URL de imagen de perfil';
	@override String get save => 'Guardar';
	@override String get success => 'Usuario actualizado correctamente';
	@override late final _TranslationsUsersEditErrorsEsEs errors = _TranslationsUsersEditErrorsEsEs._(_root);
}

// Path: users.updateTier
class _TranslationsUsersUpdateTierEsEs implements TranslationsUsersUpdateTierEnUs {
	_TranslationsUsersUpdateTierEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get tooltip => 'Cambiar nivel';
	@override String get sheetTitle => 'Cambiar nivel de usuario';
	@override String get selectTier => 'Seleccionar nivel';
	@override String get confirm => 'Confirmar';
	@override String get success => 'Nivel de usuario actualizado';
	@override late final _TranslationsUsersUpdateTierErrorsEsEs errors = _TranslationsUsersUpdateTierErrorsEsEs._(_root);
}

// Path: users.moderator
class _TranslationsUsersModeratorEsEs implements TranslationsUsersModeratorEnUs {
	_TranslationsUsersModeratorEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get badge => 'Moderador';
	@override String get assign => 'Asignar moderador';
	@override String get revoke => 'Revocar moderador';
	@override late final _TranslationsUsersModeratorErrorsEsEs errors = _TranslationsUsersModeratorErrorsEsEs._(_root);
}

// Path: auth.login.errors
class _TranslationsAuthLoginErrorsEsEs implements TranslationsAuthLoginErrorsEnUs {
	_TranslationsAuthLoginErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get required => 'Obligatorio';
	@override String get invalidCredentials => 'Nombre de usuario o contraseña incorrectos';
	@override String get generic => 'Error al iniciar sesión. Inténtelo de nuevo.';
}

// Path: tiers.createTier.errors
class _TranslationsTiersCreateTierErrorsEsEs implements TranslationsTiersCreateTierErrorsEnUs {
	_TranslationsTiersCreateTierErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get required => 'Este campo es obligatorio';
	@override String get generic => 'Error al crear el nivel';
}

// Path: tiers.editTier.errors
class _TranslationsTiersEditTierErrorsEsEs implements TranslationsTiersEditTierErrorsEnUs {
	_TranslationsTiersEditTierErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get required => 'Este campo es obligatorio';
	@override String get notFound => 'Nivel no encontrado';
	@override String get permissionDenied => 'Acceso denegado';
	@override String get generic => 'Error al actualizar el nivel';
}

// Path: tiers.deleteTier.errors
class _TranslationsTiersDeleteTierErrorsEsEs implements TranslationsTiersDeleteTierErrorsEnUs {
	_TranslationsTiersDeleteTierErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get notFound => 'Nivel no encontrado';
	@override String get forbidden => 'Acceso denegado';
	@override String get unauthorized => 'Sesión expirada';
	@override String get generic => 'Error al eliminar el nivel';
}

// Path: posts.editPost.tabs
class _TranslationsPostsEditPostTabsEsEs implements TranslationsPostsEditPostTabsEnUs {
	_TranslationsPostsEditPostTabsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get edit => 'Editar';
	@override String get log => 'Historial de moderación';
}

// Path: posts.editPost.revisionMessage
class _TranslationsPostsEditPostRevisionMessageEsEs implements TranslationsPostsEditPostRevisionMessageEnUs {
	_TranslationsPostsEditPostRevisionMessageEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get label => 'Mensaje de revisión';
	@override String get hint => 'Describa los cambios realizados para atender los comentarios del moderador';
}

// Path: posts.editPost.log
class _TranslationsPostsEditPostLogEsEs implements TranslationsPostsEditPostLogEnUs {
	_TranslationsPostsEditPostLogEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Sin historial de moderación aún';
	@override String get loadError => 'Error al cargar el historial de moderación';
}

// Path: posts.editPost.errors
class _TranslationsPostsEditPostErrorsEsEs implements TranslationsPostsEditPostErrorsEnUs {
	_TranslationsPostsEditPostErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get titleTooShort => 'El título debe tener al menos 2 caracteres';
	@override String get titleTooLong => 'El título no puede superar los 30 caracteres';
	@override String get mediaUrlEmpty => 'La URL de medios no puede estar vacía si se proporciona';
	@override String get textTooShort => 'El texto debe tener al menos 100 caracteres';
	@override String get textTooLong => 'El texto no puede superar los 63206 caracteres';
	@override String get forbidden => 'Solo puede editar sus propias publicaciones';
	@override String get generic => 'Error al guardar la publicación. Inténtelo de nuevo.';
	@override String get revisionMessageRequired => 'Se requiere un mensaje de revisión.';
	@override String get conflict => 'El estado de la publicación cambió mientras la editaba. Compruebe el estado actual.';
	@override String get notFound => 'Publicación no encontrada.';
}

// Path: posts.deletePost.errors
class _TranslationsPostsDeletePostErrorsEsEs implements TranslationsPostsDeletePostErrorsEnUs {
	_TranslationsPostsDeletePostErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Solo puede eliminar sus propias publicaciones';
	@override String get generic => 'Error al eliminar la publicación. Inténtelo de nuevo.';
}

// Path: posts.eraseDbPost.errors
class _TranslationsPostsEraseDbPostErrorsEsEs implements TranslationsPostsEraseDbPostErrorsEnUs {
	_TranslationsPostsEraseDbPostErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'No tiene permiso para borrar publicaciones';
	@override String get generic => 'Error al borrar la publicación. Inténtelo de nuevo.';
}

// Path: posts.moderatePost.tabs
class _TranslationsPostsModeratePostTabsEsEs implements TranslationsPostsModeratePostTabsEnUs {
	_TranslationsPostsModeratePostTabsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get post => 'Publicación';
	@override String get moderation => 'Moderación';
}

// Path: posts.moderatePost.log
class _TranslationsPostsModeratePostLogEsEs implements TranslationsPostsModeratePostLogEnUs {
	_TranslationsPostsModeratePostLogEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get empty => 'Sin historial de moderación aún';
	@override String get loadError => 'Error al cargar el historial de moderación';
	@override late final _TranslationsPostsModeratePostLogEventTypesEsEs eventTypes = _TranslationsPostsModeratePostLogEventTypesEsEs._(_root);
	@override late final _TranslationsPostsModeratePostLogActionsEsEs actions = _TranslationsPostsModeratePostLogActionsEsEs._(_root);
}

// Path: posts.moderatePost.actions
class _TranslationsPostsModeratePostActionsEsEs implements TranslationsPostsModeratePostActionsEnUs {
	_TranslationsPostsModeratePostActionsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get approve => 'Aprobar';
	@override String get requestChanges => 'Solicitar cambios';
	@override String get messageHint => 'Añadir un comentario (obligatorio para rechazar)';
	@override String get messageRequiredError => 'Se requiere un mensaje al solicitar cambios';
}

// Path: posts.moderatePost.errors
class _TranslationsPostsModeratePostErrorsEsEs implements TranslationsPostsModeratePostErrorsEnUs {
	_TranslationsPostsModeratePostErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'No tiene permiso para moderar esta publicación';
	@override String get notFound => 'Publicación no encontrada';
	@override String get conflict => 'Esta publicación ya ha sido moderada. Vuelva a la cola.';
	@override String get generic => 'Error al enviar. Inténtelo de nuevo.';
}

// Path: posts.createPost.errors
class _TranslationsPostsCreatePostErrorsEsEs implements TranslationsPostsCreatePostErrorsEnUs {
	_TranslationsPostsCreatePostErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get titleTooShort => 'El título debe tener al menos 2 caracteres';
	@override String get titleTooLong => 'El título no puede superar los 30 caracteres';
	@override String get mediaUrlEmpty => 'La URL de medios no puede estar vacía si se proporciona';
	@override String get textTooShort => 'El texto debe tener al menos 100 caracteres';
	@override String get textTooLong => 'El texto no puede superar los 63206 caracteres';
	@override String get forbidden => 'Solo puede publicar como usted mismo';
	@override String get generic => 'Error al publicar. Inténtelo de nuevo.';
}

// Path: users.create.errors
class _TranslationsUsersCreateErrorsEsEs implements TranslationsUsersCreateErrorsEnUs {
	_TranslationsUsersCreateErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get required => 'Este campo es obligatorio';
	@override String get emailInvalid => 'Introduzca una dirección de correo válida';
	@override String get passwordTooShort => 'La contraseña debe tener al menos 8 caracteres';
	@override String get usernameTaken => 'Nombre de usuario ya en uso';
	@override String get emailTaken => 'Correo electrónico ya en uso';
	@override String get generic => 'Algo salió mal. Inténtelo de nuevo.';
}

// Path: users.delete.errors
class _TranslationsUsersDeleteErrorsEsEs implements TranslationsUsersDeleteErrorsEnUs {
	_TranslationsUsersDeleteErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Solo puede eliminar su propia cuenta.';
	@override String get unauthorized => 'Sesión expirada.';
	@override String get notFound => 'Usuario no encontrado.';
	@override String get generic => 'Error al eliminar la cuenta.';
}

// Path: users.eraseDbUser.errors
class _TranslationsUsersEraseDbUserErrorsEsEs implements TranslationsUsersEraseDbUserErrorsEnUs {
	_TranslationsUsersEraseDbUserErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get forbidden => 'Solo puede borrar su propia cuenta';
	@override String get unauthorized => 'Sesión expirada. Inicie sesión de nuevo';
	@override String get notFound => 'Usuario no encontrado';
	@override String get generic => 'Error al borrar la cuenta. Inténtelo de nuevo';
}

// Path: users.edit.errors
class _TranslationsUsersEditErrorsEsEs implements TranslationsUsersEditErrorsEnUs {
	_TranslationsUsersEditErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get required => 'Este campo es obligatorio';
	@override String get emailInvalid => 'Introduzca una dirección de correo válida';
	@override String get usernameTaken => 'Nombre de usuario ya en uso';
	@override String get notFound => 'Usuario no encontrado';
	@override String get nothingToUpdate => 'No hay cambios que guardar';
	@override String get forbidden => 'Solo puede editar su propio perfil.';
	@override String get unauthorized => 'Sesión expirada.';
	@override String get generic => 'Algo salió mal. Inténtelo de nuevo.';
}

// Path: users.updateTier.errors
class _TranslationsUsersUpdateTierErrorsEsEs implements TranslationsUsersUpdateTierErrorsEnUs {
	_TranslationsUsersUpdateTierErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get permissionDenied => 'No tiene permiso para cambiar niveles.';
	@override String get notFound => 'Usuario o nivel no encontrado.';
	@override String get forbidden => 'Permiso denegado.';
	@override String get unauthorized => 'Sesión expirada.';
	@override String get generic => 'Error al actualizar el nivel. Inténtelo de nuevo.';
}

// Path: users.moderator.errors
class _TranslationsUsersModeratorErrorsEsEs implements TranslationsUsersModeratorErrorsEnUs {
	_TranslationsUsersModeratorErrorsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get conflict => 'Acción no aplicable: el estado de moderador ya está sincronizado.';
	@override String get forbidden => 'No tiene permiso para gestionar moderadores.';
	@override String get generic => 'Error al actualizar el estado de moderador. Inténtelo de nuevo.';
}

// Path: posts.moderatePost.log.eventTypes
class _TranslationsPostsModeratePostLogEventTypesEsEs implements TranslationsPostsModeratePostLogEventTypesEnUs {
	_TranslationsPostsModeratePostLogEventTypesEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get moderatorReview => 'Revisión del moderador';
	@override String get authorRevision => 'Revisión del autor';
}

// Path: posts.moderatePost.log.actions
class _TranslationsPostsModeratePostLogActionsEsEs implements TranslationsPostsModeratePostLogActionsEnUs {
	_TranslationsPostsModeratePostLogActionsEsEs._(this._root);

	final TranslationsEsEs _root; // ignore: unused_field

	// Translations
	@override String get approved => 'Aprobado';
	@override String get changesRequested => 'Cambios solicitados';
}

/// The flat map containing all translations for locale <es-ES>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'auth.login.title' => 'Iniciar sesión',
			'auth.login.username' => 'Nombre de usuario',
			'auth.login.password' => 'Contraseña',
			'auth.login.submit' => 'Iniciar sesión',
			'auth.login.signInButton' => 'Iniciar sesión',
			'auth.login.errors.required' => 'Obligatorio',
			'auth.login.errors.invalidCredentials' => 'Nombre de usuario o contraseña incorrectos',
			'auth.login.errors.generic' => 'Error al iniciar sesión. Inténtelo de nuevo.',
			'auth.logout.confirmTitle' => '¿Cerrar sesión?',
			'auth.logout.confirmMessage' => 'Tendrá que iniciar sesión de nuevo.',
			'auth.logout.confirm' => 'Cerrar sesión',
			'auth.logout.cancel' => 'Cancelar',
			'auth.sessionExpired' => 'Sesión expirada. Inicie sesión de nuevo.',
			'app.title' => 'Flutter App',
			'nav.users' => 'Usuarios',
			'nav.posts' => 'Publicaciones',
			'nav.tiers' => 'Niveles',
			'nav.pending' => 'Pendiente',
			'common.loading' => 'Cargando...',
			'common.error' => 'Algo salió mal',
			'common.retry' => 'Reintentar',
			'common.back' => 'Atrás',
			'common.cancel' => 'Cancelar',
			'tiers.listTiers.title' => 'Niveles',
			'tiers.listTiers.loadError' => 'Error al cargar los niveles',
			'tiers.listTiers.loadMoreError' => 'Error al cargar más niveles',
			'tiers.listTiers.empty' => 'No se encontraron niveles',
			'tiers.createTier.title' => 'Crear nivel',
			'tiers.createTier.name' => 'Nombre',
			'tiers.createTier.submit' => 'Crear',
			'tiers.createTier.fabTooltip' => 'Añadir nivel',
			'tiers.createTier.success' => 'Nivel creado',
			'tiers.createTier.errors.required' => 'Este campo es obligatorio',
			'tiers.createTier.errors.generic' => 'Error al crear el nivel',
			'tiers.tierDetails.title' => 'Detalles del nivel',
			'tiers.tierDetails.id' => 'ID',
			'tiers.tierDetails.createdAt' => 'Creado',
			'tiers.tierDetails.notFound' => 'Nivel no encontrado',
			'tiers.tierDetails.loadError' => 'Error al cargar el nivel',
			'tiers.tierDetails.permissionDenied' => 'Acceso denegado',
			'tiers.editTier.title' => 'Editar nivel',
			'tiers.editTier.name' => 'Nombre',
			'tiers.editTier.save' => 'Guardar',
			'tiers.editTier.success' => 'Nivel actualizado',
			'tiers.editTier.errors.required' => 'Este campo es obligatorio',
			'tiers.editTier.errors.notFound' => 'Nivel no encontrado',
			'tiers.editTier.errors.permissionDenied' => 'Acceso denegado',
			'tiers.editTier.errors.generic' => 'Error al actualizar el nivel',
			'tiers.deleteTier.tooltip' => 'Eliminar nivel',
			'tiers.deleteTier.confirmTitle' => 'Eliminar nivel',
			'tiers.deleteTier.confirmMessage' => '¿Está seguro de que desea eliminar el nivel "{name}"? Esta acción no se puede deshacer.',
			'tiers.deleteTier.confirmButton' => 'Eliminar',
			'tiers.deleteTier.cancelButton' => 'Cancelar',
			'tiers.deleteTier.success' => 'Nivel eliminado',
			'tiers.deleteTier.errors.notFound' => 'Nivel no encontrado',
			'tiers.deleteTier.errors.forbidden' => 'Acceso denegado',
			'tiers.deleteTier.errors.unauthorized' => 'Sesión expirada',
			'tiers.deleteTier.errors.generic' => 'Error al eliminar el nivel',
			'posts.postDetails.title' => 'Publicación',
			'posts.postDetails.loadError' => 'Error al cargar la publicación',
			'posts.postStatus.pendingReview' => 'Pendiente de revisión',
			'posts.postStatus.approved' => 'Aprobado',
			'posts.postStatus.changesRequested' => 'Se requieren cambios',
			'posts.editPost.title' => 'Editar publicación',
			'posts.editPost.titleLabel' => 'Título',
			'posts.editPost.titleHint' => 'Título de la publicación',
			'posts.editPost.mediaUrlLabel' => 'URL de medios (opcional)',
			'posts.editPost.mediaUrlHint' => 'https://...',
			'posts.editPost.textLabel' => 'Texto (Markdown)',
			'posts.editPost.textHint' => 'Escriba su publicación...',
			'posts.editPost.previewLabel' => 'Vista previa',
			'posts.editPost.saveButton' => 'Guardar',
			'posts.editPost.tabs.edit' => 'Editar',
			'posts.editPost.tabs.log' => 'Historial de moderación',
			'posts.editPost.revisionMessage.label' => 'Mensaje de revisión',
			'posts.editPost.revisionMessage.hint' => 'Describa los cambios realizados para atender los comentarios del moderador',
			'posts.editPost.approvedHint' => 'Esta publicación está aprobada y ya no puede editarse.',
			'posts.editPost.log.empty' => 'Sin historial de moderación aún',
			'posts.editPost.log.loadError' => 'Error al cargar el historial de moderación',
			'posts.editPost.errors.titleTooShort' => 'El título debe tener al menos 2 caracteres',
			'posts.editPost.errors.titleTooLong' => 'El título no puede superar los 30 caracteres',
			'posts.editPost.errors.mediaUrlEmpty' => 'La URL de medios no puede estar vacía si se proporciona',
			'posts.editPost.errors.textTooShort' => 'El texto debe tener al menos 100 caracteres',
			'posts.editPost.errors.textTooLong' => 'El texto no puede superar los 63206 caracteres',
			'posts.editPost.errors.forbidden' => 'Solo puede editar sus propias publicaciones',
			'posts.editPost.errors.generic' => 'Error al guardar la publicación. Inténtelo de nuevo.',
			'posts.editPost.errors.revisionMessageRequired' => 'Se requiere un mensaje de revisión.',
			'posts.editPost.errors.conflict' => 'El estado de la publicación cambió mientras la editaba. Compruebe el estado actual.',
			'posts.editPost.errors.notFound' => 'Publicación no encontrada.',
			'posts.listPosts.empty' => 'Aún no hay publicaciones',
			'posts.listPosts.loadError' => 'Error al cargar las publicaciones',
			'posts.listPosts.fabTooltip' => 'Nueva publicación',
			'posts.listPosts.openPost' => 'Abrir',
			'posts.userPosts.title' => ({required Object username}) => 'Publicaciones de ${username}',
			'posts.userPosts.empty' => 'Aún no hay publicaciones',
			'posts.userPosts.loadError' => 'Error al cargar las publicaciones',
			'posts.userPosts.openPost' => 'Abrir',
			'posts.deletePost.tooltip' => 'Eliminar publicación',
			'posts.deletePost.confirmTitle' => '¿Eliminar publicación?',
			'posts.deletePost.confirmMessage' => 'Esta acción es irreversible. La publicación se eliminará permanentemente.',
			'posts.deletePost.confirmButton' => 'Eliminar',
			'posts.deletePost.cancelButton' => 'Cancelar',
			'posts.deletePost.success' => 'Publicación eliminada',
			'posts.deletePost.errors.forbidden' => 'Solo puede eliminar sus propias publicaciones',
			'posts.deletePost.errors.generic' => 'Error al eliminar la publicación. Inténtelo de nuevo.',
			'posts.eraseDbPost.tooltip' => 'Borrar publicación (superusuario)',
			'posts.eraseDbPost.confirmTitle' => '¿Borrar publicación?',
			'posts.eraseDbPost.confirmMessage' => 'Esta publicación se borrará permanentemente. Esta acción no se puede deshacer.',
			'posts.eraseDbPost.confirmButton' => 'Borrar',
			'posts.eraseDbPost.cancelButton' => 'Cancelar',
			'posts.eraseDbPost.success' => 'Publicación borrada',
			'posts.eraseDbPost.errors.forbidden' => 'No tiene permiso para borrar publicaciones',
			'posts.eraseDbPost.errors.generic' => 'Error al borrar la publicación. Inténtelo de nuevo.',
			'posts.pendingPosts.title' => 'Publicaciones pendientes',
			'posts.pendingPosts.empty' => 'No hay publicaciones pendientes',
			'posts.pendingPosts.loadError' => 'Error al cargar las publicaciones pendientes',
			'posts.pendingPosts.loadMoreError' => 'Error al cargar más',
			'posts.pendingPosts.eventCount' => 'Eventos',
			'posts.moderatePost.title' => 'Moderar publicación',
			'posts.moderatePost.tabs.post' => 'Publicación',
			'posts.moderatePost.tabs.moderation' => 'Moderación',
			'posts.moderatePost.log.empty' => 'Sin historial de moderación aún',
			'posts.moderatePost.log.loadError' => 'Error al cargar el historial de moderación',
			'posts.moderatePost.log.eventTypes.moderatorReview' => 'Revisión del moderador',
			'posts.moderatePost.log.eventTypes.authorRevision' => 'Revisión del autor',
			'posts.moderatePost.log.actions.approved' => 'Aprobado',
			'posts.moderatePost.log.actions.changesRequested' => 'Cambios solicitados',
			'posts.moderatePost.actions.approve' => 'Aprobar',
			'posts.moderatePost.actions.requestChanges' => 'Solicitar cambios',
			'posts.moderatePost.actions.messageHint' => 'Añadir un comentario (obligatorio para rechazar)',
			'posts.moderatePost.actions.messageRequiredError' => 'Se requiere un mensaje al solicitar cambios',
			'posts.moderatePost.errors.forbidden' => 'No tiene permiso para moderar esta publicación',
			'posts.moderatePost.errors.notFound' => 'Publicación no encontrada',
			'posts.moderatePost.errors.conflict' => 'Esta publicación ya ha sido moderada. Vuelva a la cola.',
			'posts.moderatePost.errors.generic' => 'Error al enviar. Inténtelo de nuevo.',
			'posts.createPost.title' => 'Nueva publicación',
			'posts.createPost.titleLabel' => 'Título',
			'posts.createPost.titleHint' => 'Título de la publicación',
			'posts.createPost.mediaUrlLabel' => 'URL de medios (opcional)',
			'posts.createPost.mediaUrlHint' => 'https://...',
			'posts.createPost.textLabel' => 'Texto (Markdown)',
			'posts.createPost.textHint' => 'Escriba su publicación...',
			'posts.createPost.previewLabel' => 'Vista previa',
			'posts.createPost.publishButton' => 'Publicar',
			'posts.createPost.fabTooltip' => 'Nueva publicación',
			'posts.createPost.errors.titleTooShort' => 'El título debe tener al menos 2 caracteres',
			'posts.createPost.errors.titleTooLong' => 'El título no puede superar los 30 caracteres',
			'posts.createPost.errors.mediaUrlEmpty' => 'La URL de medios no puede estar vacía si se proporciona',
			'posts.createPost.errors.textTooShort' => 'El texto debe tener al menos 100 caracteres',
			'posts.createPost.errors.textTooLong' => 'El texto no puede superar los 63206 caracteres',
			'posts.createPost.errors.forbidden' => 'Solo puede publicar como usted mismo',
			'posts.createPost.errors.generic' => 'Error al publicar. Inténtelo de nuevo.',
			'userMenu.myProfile' => 'Mi perfil',
			'userMenu.myPosts' => 'Mis publicaciones',
			'users.title' => 'Usuarios',
			'users.list.loadMoreError' => 'Error al cargar más usuarios',
			'users.list.userDetails' => 'Detalles',
			'users.list.userPosts' => 'Publicaciones',
			'users.details.email' => 'Correo electrónico',
			'users.details.tier' => 'Nivel',
			'users.details.tierSince' => 'Nivel desde',
			'users.details.notFound' => 'Usuario no encontrado',
			'users.details.loadError' => 'Error al cargar el usuario',
			'users.create.title' => 'Crear usuario',
			'users.create.name' => 'Nombre',
			'users.create.username' => 'Nombre de usuario',
			'users.create.email' => 'Correo electrónico',
			'users.create.password' => 'Contraseña',
			'users.create.submit' => 'Crear',
			'users.create.success' => 'Usuario creado correctamente',
			'users.create.errors.required' => 'Este campo es obligatorio',
			'users.create.errors.emailInvalid' => 'Introduzca una dirección de correo válida',
			'users.create.errors.passwordTooShort' => 'La contraseña debe tener al menos 8 caracteres',
			'users.create.errors.usernameTaken' => 'Nombre de usuario ya en uso',
			'users.create.errors.emailTaken' => 'Correo electrónico ya en uso',
			'users.create.errors.generic' => 'Algo salió mal. Inténtelo de nuevo.',
			'users.delete.tooltip' => 'Eliminar cuenta',
			'users.delete.confirmTitle' => '¿Eliminar cuenta?',
			'users.delete.confirmMessage' => 'Esto eliminará permanentemente su cuenta. Esta acción no se puede deshacer.',
			'users.delete.confirmButton' => 'Eliminar',
			'users.delete.success' => 'Cuenta eliminada',
			'users.delete.errors.forbidden' => 'Solo puede eliminar su propia cuenta.',
			'users.delete.errors.unauthorized' => 'Sesión expirada.',
			'users.delete.errors.notFound' => 'Usuario no encontrado.',
			'users.delete.errors.generic' => 'Error al eliminar la cuenta.',
			'users.eraseDbUser.tooltip' => 'Borrar de la base de datos',
			'users.eraseDbUser.confirmTitle' => '¿Borrar cuenta permanentemente?',
			'users.eraseDbUser.confirmMessage' => 'Esto eliminará permanentemente su cuenta de la base de datos. Esta acción no se puede deshacer.',
			'users.eraseDbUser.confirmButton' => 'Borrar permanentemente',
			'users.eraseDbUser.success' => 'Cuenta borrada de la base de datos',
			'users.eraseDbUser.errors.forbidden' => 'Solo puede borrar su propia cuenta',
			'users.eraseDbUser.errors.unauthorized' => 'Sesión expirada. Inicie sesión de nuevo',
			'users.eraseDbUser.errors.notFound' => 'Usuario no encontrado',
			'users.eraseDbUser.errors.generic' => 'Error al borrar la cuenta. Inténtelo de nuevo',
			'users.edit.title' => 'Editar usuario',
			'users.edit.name' => 'Nombre',
			'users.edit.username' => 'Nombre de usuario',
			'users.edit.email' => 'Correo electrónico',
			'users.edit.profileImageUrl' => 'URL de imagen de perfil',
			'users.edit.save' => 'Guardar',
			'users.edit.success' => 'Usuario actualizado correctamente',
			'users.edit.errors.required' => 'Este campo es obligatorio',
			'users.edit.errors.emailInvalid' => 'Introduzca una dirección de correo válida',
			'users.edit.errors.usernameTaken' => 'Nombre de usuario ya en uso',
			'users.edit.errors.notFound' => 'Usuario no encontrado',
			'users.edit.errors.nothingToUpdate' => 'No hay cambios que guardar',
			'users.edit.errors.forbidden' => 'Solo puede editar su propio perfil.',
			'users.edit.errors.unauthorized' => 'Sesión expirada.',
			'users.edit.errors.generic' => 'Algo salió mal. Inténtelo de nuevo.',
			'users.updateTier.tooltip' => 'Cambiar nivel',
			'users.updateTier.sheetTitle' => 'Cambiar nivel de usuario',
			'users.updateTier.selectTier' => 'Seleccionar nivel',
			'users.updateTier.confirm' => 'Confirmar',
			'users.updateTier.success' => 'Nivel de usuario actualizado',
			'users.updateTier.errors.permissionDenied' => 'No tiene permiso para cambiar niveles.',
			'users.updateTier.errors.notFound' => 'Usuario o nivel no encontrado.',
			'users.updateTier.errors.forbidden' => 'Permiso denegado.',
			'users.updateTier.errors.unauthorized' => 'Sesión expirada.',
			'users.updateTier.errors.generic' => 'Error al actualizar el nivel. Inténtelo de nuevo.',
			'users.moderator.badge' => 'Moderador',
			'users.moderator.assign' => 'Asignar moderador',
			'users.moderator.revoke' => 'Revocar moderador',
			'users.moderator.errors.conflict' => 'Acción no aplicable: el estado de moderador ya está sincronizado.',
			'users.moderator.errors.forbidden' => 'No tiene permiso para gestionar moderadores.',
			'users.moderator.errors.generic' => 'Error al actualizar el estado de moderador. Inténtelo de nuevo.',
			_ => null,
		};
	}
}
