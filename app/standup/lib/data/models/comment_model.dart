class CommentModel {
  final String id;
  final String author;
  final String text;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
  });
}
