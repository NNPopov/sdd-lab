import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/_shared/presentation/widgets/markdown_preview.dart';
import 'package:flutter_application_1/features/posts/create_post/application/create_post_cubit.dart';
import 'package:flutter_application_1/features/posts/create_post/application/create_post_state.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({required this.userId, super.key});

  final int userId;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _mediaUrlController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final mediaUrl = _mediaUrlController.text.trim();
    unawaited(
      context.read<CreatePostCubit>().submit(
        NewPostData(
          userId: widget.userId,
          title: _titleController.text.trim(),
          text: _textController.text.trim(),
          mediaUrl: mediaUrl.isEmpty ? null : mediaUrl,
        ),
      ),
    );
  }

  String? _validateTitle(String? value, Translations t) {
    if (value == null || value.isEmpty) {
      return t.posts.createPost.errors.titleTooShort;
    }
    if (value.length < 2) return t.posts.createPost.errors.titleTooShort;
    if (value.length > 30) return t.posts.createPost.errors.titleTooLong;
    return null;
  }

  String? _validateMediaUrl(String? value, Translations t) {
    if (value == null || value.isEmpty) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return t.posts.createPost.errors.mediaUrlEmpty;
    if (!RegExp(r'^(https?|ftp)://[^\s/$.?#].[^\s]*$').hasMatch(trimmed)) {
      return t.posts.createPost.errors.mediaUrlInvalid;
    }
    return null;
  }

  String? _validateText(String? value, Translations t) {
    if (value == null || value.isEmpty) {
      return t.posts.createPost.errors.textTooShort;
    }
    if (value.length < 100) return t.posts.createPost.errors.textTooShort;
    if (value.length > 63206) return t.posts.createPost.errors.textTooLong;
    return null;
  }

  String _failureMessage(Failure failure, Translations t) {
    return switch (failure) {
      ForbiddenFailure() => t.posts.createPost.errors.forbidden,
      _ => t.posts.createPost.errors.generic,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocConsumer<CreatePostCubit, CreatePostState>(
      listener: (context, state) {
        if (state is CreatePostSuccess) {
          unawaited(context.router.maybePop());
        }
      },
      builder: (context, state) {
        final isLoading = state is CreatePostLoading;
        return Scaffold(
          appBar: AppBar(title: Text(t.posts.createPost.title)),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: t.posts.createPost.titleLabel,
                      hintText: t.posts.createPost.titleHint,
                    ),
                    validator: (v) => _validateTitle(v, t),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mediaUrlController,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: t.posts.createPost.mediaUrlLabel,
                      hintText: t.posts.createPost.mediaUrlHint,
                    ),
                    validator: (v) => _validateMediaUrl(v, t),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _textController,
                    enabled: !isLoading,
                    maxLines: 8,
                    decoration: InputDecoration(
                      labelText: t.posts.createPost.textLabel,
                      hintText: t.posts.createPost.textHint,
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => _validateText(v, t),
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _textController,
                    builder: (context, _) => MarkdownPreview(
                      text: _textController.text,
                      label: t.posts.createPost.previewLabel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state is CreatePostError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _failureMessage(state.failure, t),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  FilledButton(
                    onPressed: isLoading ? null : () => _onSubmit(context),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.posts.createPost.publishButton),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
