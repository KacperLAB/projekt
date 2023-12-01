class Rating {
  String author;
  int rating;
  String timestamp;

  Rating({required this.author, required this.rating, required this.timestamp});

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'rating': rating,
      'timestamp': timestamp,
    };
  }
}
