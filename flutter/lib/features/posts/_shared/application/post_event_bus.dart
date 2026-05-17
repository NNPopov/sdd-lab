import 'dart:async';

import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PostEventBus {
  final _controller = StreamController<PostEvent>.broadcast();

  Stream<PostEvent> get stream => _controller.stream;

  void publish(PostEvent event) => _controller.add(event);

  @disposeMethod
  Future<void> dispose() => _controller.close();
}
