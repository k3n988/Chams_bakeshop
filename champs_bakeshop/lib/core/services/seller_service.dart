import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/seller_session_model.dart';
import '../models/seller_remittance_model.dart';

class SellerService {
  final _db = Supabase.instance.client;

  static const _sessionTable    = 'seller_sessions';
  static const _remittanceTable = 'seller_remittances';

  // ════════════════════════════════════════════════════════════
  //  SESSION
  // ════════════════════════════════════════════════════════════

  /// Create a session — morning or afternoon
  Future<SellerSessionModel?> createSession({
    required String sellerId,
    required String date,
    required int    plantsaCount,
    required int    subraPieces,
    required String takenOutAt,
    String sessionType = 'morning',   // 'morning' | 'afternoon'
  }) async {
    try {
      final data = await _db
          .from(_sessionTable)
          .insert({
            'seller_id':    sellerId,
            'date':         date,
            'session_type': sessionType,
            'plantsa_count': plantsaCount,
            'subra_pieces': subraPieces,
            'taken_out_at': takenOutAt,
          })
          .select()
          .single();

      return SellerSessionModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }

  /// Fetch today's session for a seller by type
  Future<SellerSessionModel?> getSessionByDateAndType({
    required String sellerId,
    required String date,
    required String sessionType,
  }) async {
    try {
      final data = await _db
          .from(_sessionTable)
          .select()
          .eq('seller_id', sellerId)
          .eq('date', date)
          .eq('session_type', sessionType)
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
          .order('date', ascending: false)
          .order('session_type', ascending: true); // morning first

      return (data as List)
          .map((e) => SellerSessionModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sessions: $e');
    }
  }

  /// Check if a session already exists for seller/date/type
  Future<bool> sessionExistsForDate({
    required String sellerId,
    required String date,
    required String sessionType,
  }) async {
    try {
      final data = await _db
          .from(_sessionTable)
          .select('id')
          .eq('seller_id', sellerId)
          .eq('date', date)
          .eq('session_type', sessionType)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  /// Delete a session by id
  Future<void> deleteSession(String sessionId) async {
    try {
      await _db.from(_sessionTable).delete().eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  /// Delete a remittance by id
  Future<void> deleteRemittance(String remittanceId) async {
    try {
      await _db.from(_remittanceTable).delete().eq('id', remittanceId);
    } catch (e) {
      throw Exception('Failed to delete remittance: $e');
    }
  }

  /// Update a session
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
  //  REMITTANCE
  // ════════════════════════════════════════════════════════════



  /// Fetch remittance by session_id
  Future<SellerRemittanceModel?> getRemittanceBySession({
    required String sessionId,
  }) async {
    try {
      final data = await _db
          .from(_remittanceTable)
          .select()
          .eq('session_id', sessionId)
          .maybeSingle();

      if (data == null) return null;
      return SellerRemittanceModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch remittance: $e');
    }
  }

  /// Fetch all remittances within a date range
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

  /// Update remittance
  // ════════════════════════════════════════════════════════════
  //  REMITTANCE
  // ════════════════════════════════════════════════════════════

  /// Create remittance record
  Future<SellerRemittanceModel?> createRemittance({
    required String sellerId,
    required String sessionId,
    required String date,
    required int    returnPieces,
    required double actualRemittance,
    required int    totalPiecesTaken,
    required double expectedRemittance,
    required double salary, // 👈 ADDED SALARY HERE
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
            'salary':              salary, // 👈 ADDED TO SUPABASE INSERT
            'remitted_at':         remittedAt,
          })
          .select()
          .single();

      return SellerRemittanceModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create remittance: $e');
    }
  }

  // ... (keep your getRemittanceBySession and getRemittancesByRange as they are) ...

  /// Update remittance
  Future<SellerRemittanceModel?> updateRemittance({
    required String remittanceId,
    required int    returnPieces,
    required double actualRemittance,
    required int    totalPiecesTaken,
    required double salary, // 👈 ADDED SALARY HERE
  }) async {
    try {
      final data = await _db
          .from(_remittanceTable)
          .update({
            'return_pieces':     returnPieces,
            'actual_remittance': actualRemittance,
            'salary':            salary, // 👈 ADDED TO SUPABASE UPDATE
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

  Future<Map<String, dynamic>> getDailyRecord({
    required String sellerId,
    required String date,
  }) async {
    try {
      final sessions = await getSessionsByRange(
        sellerId: sellerId,
        fromDate: date,
        toDate:   date,
      );

      final morning   = sessions.where((s) => s.sessionType == 'morning').firstOrNull;
      final afternoon = sessions.where((s) => s.sessionType == 'afternoon').firstOrNull;

      SellerRemittanceModel? morningRemit;
      SellerRemittanceModel? afternoonRemit;

      if (morning != null) {
        morningRemit = await getRemittanceBySession(sessionId: morning.id);
      }
      if (afternoon != null) {
        afternoonRemit = await getRemittanceBySession(sessionId: afternoon.id);
      }

      return {
        'morning_session':    morning,
        'afternoon_session':  afternoon,
        'morning_remittance': morningRemit,
        'afternoon_remittance': afternoonRemit,
      };
    } catch (e) {
      throw Exception('Failed to fetch daily record: $e');
    }
  }

  // ════════════════════════════════════════════════════════════
  //  ADMIN VIEWS
  // ════════════════════════════════════════════════════════════

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