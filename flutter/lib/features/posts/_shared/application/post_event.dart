sealed class PostEvent {}

final class PostDeleted extends PostEvent {
  PostDeleted(this.id);
  final int id;
}

final class PostModeratedEvent extends PostEvent {
  PostModeratedEvent(this.postUuid);
  final String postUuid;
}

final class PostRevisedEvent extends PostEvent {
  PostRevisedEvent(this.postUuid);
  final String postUuid;
}
