class Comment {
  String author;
  String text;
  String timestamp;

  Comment({required this.author, required this.text, required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
