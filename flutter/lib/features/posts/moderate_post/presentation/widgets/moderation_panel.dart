import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_cubit.dart';
import 'package:flutter_application_1/features/posts/moderate_post/application/moderate_post_state.dart';
import 'package:flutter_application_1/features/posts/moderate_post/presentation/widgets/moderation_log_list_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModerationPanel extends StatefulWidget {
  const ModerationPanel({required this.postUuid, super.key});

  final String postUuid;

  @override
  State<ModerationPanel> createState() => _ModerationPanelState();
}

class _ModerationPanelState extends State<ModerationPanel> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return BlocBuilder<ModeratePostCubit, ModeratePostState>(
      builder: (context, state) {
        final isLoading = state is ModeratePostLoading;
        return Column(
          children: [
            const Expanded(child: ModerationLogListView()),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: t.posts.moderatePost.actions.messageHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: isLoading
                              ? null
                              : () =>
                                    context.read<ModeratePostCubit>().moderate(
                                      postUuid: widget.postUuid,
                                      action: 'approved',
                                      message: _controller.text.isEmpty
                                          ? null
                                          : _controller.text,
                                    ),
                          child: Text(t.posts.moderatePost.actions.approve),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () =>
                                    context.read<ModeratePostCubit>().moderate(
                                      postUuid: widget.postUuid,
                                      action: 'changes_requested',
                                      message: _controller.text,
                                    ),
                          child: Text(
                            t.posts.moderatePost.actions.requestChanges,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
