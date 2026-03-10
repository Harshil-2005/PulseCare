class RatingModel {
  final int fullStars;
  final bool hasHalfStar;
  final int emptyStars;

  RatingModel({
    required this.fullStars,
    required this.hasHalfStar,
    required this.emptyStars,
  });

  factory RatingModel.fromRating(double rating) {
    int full = rating.floor();
    bool half = rating % 1 != 0;
    int empty = 5 - full - (half ? 1 : 0);

    return RatingModel(
      fullStars: full,
      hasHalfStar: half,
      emptyStars: empty,
    );
  }
}
