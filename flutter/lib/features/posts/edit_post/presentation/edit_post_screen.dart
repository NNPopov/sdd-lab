import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/core/theme/app_breakpoints.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_cubit.dart';
import 'package:flutter_application_1/features/posts/_shared/application/moderation_log_state.dart';
import 'package:flutter_application_1/core/di/injection.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/_shared/presentation/widgets/markdown_preview.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_cubit.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_state.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/presentation/widgets/moderation_log_panel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditPostScreen extends StatefulWidget {
  const EditPostScreen({
    required this.post,
    required this.username,
    super.key,
  });

  final Post post;
  final String username;

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _mediaUrlController;
  late final TextEditingController _textController;
  late final TextEditingController? _revisionMessageController;
  late TabController _tabController;

  bool get _isChangesRequested =>
      widget.post.status == PostStatus.changesRequested;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _mediaUrlController = TextEditingController(
      text: widget.post.mediaUrl ?? '',
    );
    _textController = TextEditingController(text: widget.post.text);
    _revisionMessageController = _isChangesRequested
        ? TextEditingController()
        : null;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final width = MediaQuery.of(context).size.width;
      if (width >= AppBreakpoints.medium) {
        unawaited(
          context.read<ModerationLogCubit>().load(widget.post.postUuid),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _titleController.dispose();
    _mediaUrlController.dispose();
    _textController.dispose();
    _revisionMessageController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      final logState = context.read<ModerationLogCubit>().state;
      if (logState is ModerationLogInitial) {
        unawaited(
          context.read<ModerationLogCubit>().load(widget.post.postUuid),
        );
      }
    }
  }

  void _onSubmit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final mediaUrl = _mediaUrlController.text.trim();
    unawaited(
      context.read<EditPostCubit>().submit(
        UpdatedPostData(
          username: widget.username,
          id: widget.post.id,
          postUuid: widget.post.postUuid,
          status: widget.post.status,
          title: _titleController.text.trim(),
          text: _textController.text.trim(),
          mediaUrl: mediaUrl.isEmpty ? null : mediaUrl,
          revisionMessage: _isChangesRequested
              ? _revisionMessageController!.text.trim()
              : null,
        ),
      ),
    );
  }

  String? _validateTitle(String? value, Translations t) {
    if (value == null || value.isEmpty) {
      return t.posts.editPost.errors.titleTooShort;
    }
    if (value.length < 2) return t.posts.editPost.errors.titleTooShort;
    if (value.length > 30) return t.posts.editPost.errors.titleTooLong;
    return null;
  }

  String? _validateMediaUrl(String? value, Translations t) {
    if (value == null || value.isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return t.posts.editPost.errors.mediaUrlEmpty;
    if (!RegExp(r'^(https?|ftp)://[^\s/$.?#].[^\s]*$').hasMatch(trimmed)) {
      return t.posts.editPost.errors.mediaUrlInvalid;
    }
    return null;
  }

  String? _validateText(String? value, Translations t) {
    if (value == null || value.isEmpty) {
      return t.posts.editPost.errors.textTooShort;
    }
    if (value.length < 100) return t.posts.editPost.errors.textTooShort;
    if (value.length > 63206) return t.posts.editPost.errors.textTooLong;
    return null;
  }

  String? _validateRevisionMessage(String? value, Translations t) {
    if (value == null || value.trim().isEmpty) {
      return t.posts.editPost.errors.revisionMessageRequired;
    }
    return null;
  }

  String _failureMessage(Failure failure, Translations t) {
    return switch (failure) {
      ForbiddenFailure() => t.posts.editPost.errors.forbidden,
      NotFoundFailure() => t.posts.editPost.errors.notFound,
      ConflictFailure() => t.posts.editPost.errors.conflict,
      _ => t.posts.editPost.errors.generic,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocConsumer<EditPostCubit, EditPostState>(
      listener: (context, state) {
        if (state is EditPostSuccess) {
          getIt<PostEventBus>().publish(PostRevisedEvent(widget.post.postUuid));
          unawaited(context.router.maybePop());
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(t.posts.editPost.title)),
          body: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= AppBreakpoints.medium) {
                return Row(
                  children: [
                    const Expanded(child: ModerationLogPanel()),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _EditForm(parent: this, state: state),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: t.posts.editPost.tabs.edit),
                      Tab(text: t.posts.editPost.tabs.log),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _EditForm(parent: this, state: state),
                        const ModerationLogPanel(),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({required this.parent, required this.state});

  final _EditPostScreenState parent;
  final EditPostState state;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isLoading = state is EditPostLoading;
    final isApproved = parent.widget.post.status == PostStatus.approved;

    return Form(
      key: parent._formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: parent._titleController,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: t.posts.editPost.titleLabel,
                hintText: t.posts.editPost.titleHint,
              ),
              validator: (v) => parent._validateTitle(v, t),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: parent._mediaUrlController,
              enabled: !isLoading,
              decoration: InputDecoration(
                labelText: t.posts.editPost.mediaUrlLabel,
                hintText: t.posts.editPost.mediaUrlHint,
              ),
              validator: (v) => parent._validateMediaUrl(v, t),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: parent._textController,
              enabled: !isLoading,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: t.posts.editPost.textLabel,
                hintText: t.posts.editPost.textHint,
                alignLabelWithHint: true,
              ),
              validator: (v) => parent._validateText(v, t),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: parent._textController,
              builder: (context, _) => MarkdownPreview(
                text: parent._textController.text,
                label: t.posts.editPost.previewLabel,
              ),
            ),
            if (parent._isChangesRequested) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: parent._revisionMessageController,
                enabled: !isLoading,
                minLines: 3,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: t.posts.editPost.revisionMessage.label,
                  hintText: t.posts.editPost.revisionMessage.hint,
                  alignLabelWithHint: true,
                ),
                validator: (v) => parent._validateRevisionMessage(v, t),
              ),
            ],
            const SizedBox(height: 16),
            if (state is EditPostError)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  parent._failureMessage((state as EditPostError).failure, t),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            FilledButton(
              onPressed: isApproved
                  ? null
                  : (isLoading ? null : () => parent._onSubmit(context)),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(t.posts.editPost.saveButton),
            ),
            if (isApproved) ...[
              const SizedBox(height: 8),
              Text(
                t.posts.editPost.approvedHint,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
