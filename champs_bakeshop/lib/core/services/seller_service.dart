import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seller_session_model.dart';
import '../models/seller_remittance_model.dart';

class SellerService {
  final _db = Supabase.instance.client;

  // ── Table names ────────────────────────────────────────────
  static const _sessionTable     = 'seller_sessions';
  static const _remittanceTable  = 'seller_remittances';

  // ════════════════════════════════════════════════════════════
  //  SESSION  (morning — seller takes out pandesal)
  // ════════════════════════════════════════════════════════════

  /// Create a morning session (seller takes out plantsa + subra)
  Future<SellerSessionModel?> createSession({
    required String sellerId,
    required String date,
    required int    plantsaCount,
    required int    subraPieces,
    required String takenOutAt,
  }) async {
    try {
      final data = await _db
          .from(_sessionTable)
          .insert({
            'seller_id':     sellerId,
            'date':          date,
            'plantsa_count': plantsaCount,
            'subra_pieces':  subraPieces,
            'taken_out_at':  takenOutAt,
          })
          .select()
          .single();

      return SellerSessionModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  /// Fetch today's session for a seller (should be at most 1 per day)
  Future<SellerSessionModel?> getSessionByDate({
    required String sellerId,
    required String date,
  }) async {
    try {
      final data = await _db
          .from(_sessionTable)
          .select()
          .eq('seller_id', sellerId)
          .eq('date', date)
          .maybeSingle();

      if (data == null) return null;
      return SellerSessionModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch session: $e');
    }
  }

  /// Fetch all sessions within a date range
  Future<List<SellerSessionModel>> getSessionsByRange({
    required String sellerId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final data = await _db
          .from(_sessionTable)
          .select()
          .eq('seller_id', sellerId)
          .gte('date', fromDate)
          .lte('date', toDate)
          .order('date', ascending: false);

      return (data as List)
          .map((e) => SellerSessionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sessions: $e');
    }
  }

  /// Update a session (e.g. correction before remittance)
  Future<SellerSessionModel?> updateSession({
    required String sessionId,
    required int    plantsaCount,
    required int    subraPieces,
  }) async {
    try {
      final data = await _db
          .from(_sessionTable)
          .update({
            'plantsa_count': plantsaCount,
            'subra_pieces':  subraPieces,
          })
          .eq('id', sessionId)
          .select()
          .single();

      return SellerSessionModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  REMITTANCE  (evening — seller remits cash + declares returns)
  // ════════════════════════════════════════════════════════════

  /// Create evening remittance record
  Future<SellerRemittanceModel?> createRemittance({
    required String sellerId,
    required String sessionId,
    required String date,
    required int    returnPieces,
    required double actualRemittance,
    required int    totalPiecesTaken,
    required double expectedRemittance,
    required String remittedAt,
  }) async {
    try {
      final data = await _db
          .from(_remittanceTable)
          .insert({
            'seller_id':           sellerId,
            'session_id':          sessionId,
            'date':                date,
            'return_pieces':       returnPieces,
            'actual_remittance':   actualRemittance,
            'total_pieces_taken':  totalPiecesTaken,
            'expected_remittance': expectedRemittance,
            'remitted_at':         remittedAt,
          })
          .select()
          .single();

      return SellerRemittanceModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create remittance: $e');
    }
  }

  /// Fetch remittance for a specific date
  Future<SellerRemittanceModel?> getRemittanceByDate({
    required String sellerId,
    required String date,
  }) async {
    try {
      final data = await _db
          .from(_remittanceTable)
          .select()
          .eq('seller_id', sellerId)
          .eq('date', date)
          .maybeSingle();

      if (data == null) return null;
      return SellerRemittanceModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch remittance: $e');
    }
  }

  /// Fetch all remittances within a date range (weekly / monthly)
  Future<List<SellerRemittanceModel>> getRemittancesByRange({
    required String sellerId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final data = await _db
          .from(_remittanceTable)
          .select()
          .eq('seller_id', sellerId)
          .gte('date', fromDate)
          .lte('date', toDate)
          .order('date', ascending: false);

      return (data as List)
          .map((e) => SellerRemittanceModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch remittances: $e');
    }
  }

  /// Update remittance (e.g. seller corrects return count)
  Future<SellerRemittanceModel?> updateRemittance({
    required String remittanceId,
    required int    returnPieces,
    required double actualRemittance,
    required int    totalPiecesTaken,
  }) async {
    try {
      final adjustedRemittance = (totalPiecesTaken - returnPieces) * 5.0;

      final data = await _db
          .from(_remittanceTable)
          .update({
            'return_pieces':     returnPieces,
            'actual_remittance': actualRemittance,
          })
          .eq('id', remittanceId)
          .select()
          .single();

      return SellerRemittanceModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update remittance: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  COMBINED DAILY VIEW
  // ════════════════════════════════════════════════════════════

  /// Fetch both session and remittance for a date
  /// Returns a map with keys 'session' and 'remittance'
  Future<Map<String, dynamic>> getDailyRecord({
    required String sellerId,
    required String date,
  }) async {
    try {
      final results = await Future.wait([
        getSessionByDate(sellerId: sellerId, date: date),
        getRemittanceByDate(sellerId: sellerId, date: date),
      ]);

      return {
        'session':     results[0],   // SellerSessionModel?
        'remittance':  results[1],   // SellerRemittanceModel?
      };
    } catch (e) {
      throw Exception('Failed to fetch daily record: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  ADMIN VIEWS
  // ════════════════════════════════════════════════════════════

  /// Admin: fetch all seller remittances for a date range
  Future<List<SellerRemittanceModel>> getAllSellerRemittancesByRange({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final data = await _db
          .from(_remittanceTable)
          .select()
          .gte('date', fromDate)
          .lte('date', toDate)
          .order('date', ascending: false);

      return (data as List)
          .map((e) => SellerRemittanceModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all seller remittances: $e');
    }
  }

  /// Admin: fetch all seller sessions for a date range
  Future<List<SellerSessionModel>> getAllSellerSessionsByRange({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final data = await _db
          .from(_sessionTable)
          .select()
          .gte('date', fromDate)
          .lte('date', toDate)
          .order('date', ascending: false);

      return (data as List)
          .map((e) => SellerSessionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all seller sessions: $e');
    }
  }
}