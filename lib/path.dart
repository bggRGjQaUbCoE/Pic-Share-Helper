class Path {
  Path(
    this.origin,
    this.cropped,
  );
  String origin;
  String? cropped;

  String get valid => cropped ?? origin;

  bool get isCropped => cropped != null;
}
