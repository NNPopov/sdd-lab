import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/application/auth_event.dart';
import 'package:flutter_application_1/core/i18n/translations.g.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SessionExpiredListener extends StatefulWidget {
  const SessionExpiredListener({
    required this.scaffoldMessengerKey,
    required this.child,
    super.key,
  });

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  @override
  State<SessionExpiredListener> createState() => _SessionExpiredListenerState();
}

class _SessionExpiredListenerState extends State<SessionExpiredListener> {
  StreamSubscription<AuthEvent>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = context.read<AuthCubit>().events.listen(_handleEvent);
  }

  void _handleEvent(AuthEvent event) {
    if (event is SessionExpiredEvent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(context.t.auth.sessionExpired)),
        );
      });
    }
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel() ?? Future.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
