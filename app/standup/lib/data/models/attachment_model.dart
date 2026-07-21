class AttachmentModel {
  final String id;
  final String fileName;
  final String fileType; // pdf, image, doc
  final String fileSize;

  const AttachmentModel({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });
}
