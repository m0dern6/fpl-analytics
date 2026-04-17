class ElementType {
  final int id;
  final String pluralName;
  final String singularName;
  final String singularNameShort;
  final int squadSelect;
  final int squadMinPlay;
  final int squadMaxPlay;
  final int elementCount;

  const ElementType({
    required this.id,
    required this.pluralName,
    required this.singularName,
    required this.singularNameShort,
    required this.squadSelect,
    required this.squadMinPlay,
    required this.squadMaxPlay,
    required this.elementCount,
  });

  factory ElementType.fromJson(Map<String, dynamic> json) {
    return ElementType(
      id: json['id'] as int,
      pluralName: json['plural_name'] as String? ?? '',
      singularName: json['singular_name'] as String? ?? '',
      singularNameShort: json['singular_name_short'] as String? ?? '',
      squadSelect: json['squad_select'] as int? ?? 0,
      squadMinPlay: json['squad_min_play'] as int? ?? 0,
      squadMaxPlay: json['squad_max_play'] as int? ?? 0,
      elementCount: json['element_count'] as int? ?? 0,
    );
  }
}
