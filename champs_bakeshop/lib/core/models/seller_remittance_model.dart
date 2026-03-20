class SellerRemittanceModel {
  final String id;
  final String sellerId;
  final String sessionId;        // links to SellerSessionModel

  final String date;             // 'YYYY-MM-DD'

  // ── Evening input ──────────────────────────────────────────
  final int    returnPieces;     // unsold pandesal returned
  final double actualRemittance; // cash actually handed over

  // ── From session (denormalized for easy reads) ─────────────
  final int    totalPiecesTaken;    // from morning session
  final double expectedRemittance;  // totalPiecesTaken * ₱5

  // ── Computed ───────────────────────────────────────────────
  /// Pieces actually sold
  int get piecesSold => totalPiecesTaken - returnPieces;

  /// What seller should have remitted after returns
  double get adjustedRemittance => piecesSold * 5.0;

  /// Positive = seller owes more | Negative = seller overpaid
  double get variance => actualRemittance - adjustedRemittance;

  /// Seller daily salary = adjusted remittance (they earn on what they sell)
  /// Adjust this formula to match your actual salary scheme
  double get dailySalary => adjustedRemittance;

  final String remittedAt;   // timestamp when remittance was done
  final DateTime createdAt;

  const SellerRemittanceModel({
    required this.id,
    required this.sellerId,
    required this.sessionId,
    required this.date,
    required this.returnPieces,
    required this.actualRemittance,
    required this.totalPiecesTaken,
    required this.expectedRemittance,
    required this.remittedAt,
    required this.createdAt,
  });

  // ── Serialization ──────────────────────────────────────────
  factory SellerRemittanceModel.fromJson(Map<String, dynamic> json) {
    return SellerRemittanceModel(
      id:                  json['id'] as String,
      sellerId:            json['seller_id'] as String,
      sessionId:           json['session_id'] as String,
      date:                json['date'] as String,
      returnPieces:        (json['return_pieces'] as num).toInt(),
      actualRemittance:    (json['actual_remittance'] as num).toDouble(),
      totalPiecesTaken:    (json['total_pieces_taken'] as num).toInt(),
      expectedRemittance:  (json['expected_remittance'] as num).toDouble(),
      remittedAt:          json['remitted_at'] as String,
      createdAt:           DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id':                  id,
        'seller_id':           sellerId,
        'session_id':          sessionId,
        'date':                date,
        'return_pieces':       returnPieces,
        'actual_remittance':   actualRemittance,
        'total_pieces_taken':  totalPiecesTaken,
        'expected_remittance': expectedRemittance,
        'remitted_at':         remittedAt,
        'created_at':          createdAt.toIso8601String(),
      };

  Map<String, dynamic> toInsertJson() => {
        'seller_id':           sellerId,
        'session_id':          sessionId,
        'date':                date,
        'return_pieces':       returnPieces,
        'actual_remittance':   actualRemittance,
        'total_pieces_taken':  totalPiecesTaken,
        'expected_remittance': expectedRemittance,
        'remitted_at':         remittedAt,
      };

  SellerRemittanceModel copyWith({
    String?   id,
    String?   sellerId,
    String?   sessionId,
    String?   date,
    int?      returnPieces,
    double?   actualRemittance,
    int?      totalPiecesTaken,
    double?   expectedRemittance,
    String?   remittedAt,
    DateTime? createdAt,
  }) {
    return SellerRemittanceModel(
      id:                  id                  ?? this.id,
      sellerId:            sellerId            ?? this.sellerId,
      sessionId:           sessionId           ?? this.sessionId,
      date:                date                ?? this.date,
      returnPieces:        returnPieces        ?? this.returnPieces,
      actualRemittance:    actualRemittance    ?? this.actualRemittance,
      totalPiecesTaken:    totalPiecesTaken    ?? this.totalPiecesTaken,
      expectedRemittance:  expectedRemittance  ?? this.expectedRemittance,
      remittedAt:          remittedAt          ?? this.remittedAt,
      createdAt:           createdAt           ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'SellerRemittanceModel(id: $id, date: $date, sold: $piecesSold, actual: $actualRemittance, variance: $variance)';
}