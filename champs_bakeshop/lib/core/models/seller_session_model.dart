class SellerSessionModel {
  final String id;
  final String sellerId;
  final String date;           // 'YYYY-MM-DD'
  final String sessionType;    // 'morning' | 'afternoon'

  // ── Morning/Afternoon input ────────────────────────────────
  final int plantsaCount;      // number of plantsa taken out
  final int subraPieces;       // extra loose pieces

  /// Each plantsa holds 25 pieces
  static const int piecesPerPlantsa = 25;

  // ── Computed totals ────────────────────────────────────────
  int get totalPiecesTaken =>
      (plantsaCount * piecesPerPlantsa) + subraPieces;

  double get expectedRemittance => totalPiecesTaken * 5.0;

  bool get isMorning   => sessionType == 'morning';
  bool get isAfternoon => sessionType == 'afternoon';

  final String takenOutAt;   // timestamp when seller left
  final DateTime createdAt;

  const SellerSessionModel({
    required this.id,
    required this.sellerId,
    required this.date,
    required this.sessionType,
    required this.plantsaCount,
    required this.subraPieces,
    required this.takenOutAt,
    required this.createdAt,
  });

  // ── Serialization ──────────────────────────────────────────
  factory SellerSessionModel.fromJson(Map<String, dynamic> json) {
    return SellerSessionModel(
      id:           json['id'] as String,
      sellerId:     json['seller_id'] as String,
      date:         json['date'] as String,
      sessionType:  (json['session_type'] as String?) ?? 'morning',
      plantsaCount: (json['plantsa_count'] as num).toInt(),
      subraPieces:  (json['subra_pieces'] as num).toInt(),
      takenOutAt:   json['taken_out_at'] as String,
      createdAt:    DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':           id,
        'seller_id':    sellerId,
        'date':         date,
        'session_type': sessionType,
        'plantsa_count': plantsaCount,
        'subra_pieces': subraPieces,
        'taken_out_at': takenOutAt,
        'created_at':   createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'seller_id':    sellerId,
        'date':         date,
        'session_type': sessionType,
        'plantsa_count': plantsaCount,
        'subra_pieces': subraPieces,
        'taken_out_at': takenOutAt,
      };

  SellerSessionModel copyWith({
    String?   id,
    String?   sellerId,
    String?   date,
    String?   sessionType,
    int?      plantsaCount,
    int?      subraPieces,
    String?   takenOutAt,
    DateTime? createdAt,
  }) {
    return SellerSessionModel(
      id:           id           ?? this.id,
      sellerId:     sellerId     ?? this.sellerId,
      date:         date         ?? this.date,
      sessionType:  sessionType  ?? this.sessionType,
      plantsaCount: plantsaCount ?? this.plantsaCount,
      subraPieces:  subraPieces  ?? this.subraPieces,
      takenOutAt:   takenOutAt   ?? this.takenOutAt,
      createdAt:    createdAt    ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'SellerSessionModel(id: $id, date: $date, type: $sessionType, '
      'plantsa: $plantsaCount, subra: $subraPieces, total: $totalPiecesTaken)';
}