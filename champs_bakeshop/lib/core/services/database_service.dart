// ═══════════════════════════════════════════════════════════════════
//  database_service.dart  —  COMPATIBILITY SHIM
//
//  All existing viewmodels (admin, baker, auth) import DatabaseService.
//  Instead of editing every file, we just alias DatabaseService → SupabaseService.
//  No other file needs to change.
// ═══════════════════════════════════════════════════════════════════

// 1. IMPORT it so this file knows what 'SupabaseService' is for the typedef
import 'supabase_service.dart';

// 2. EXPORT it so files importing this one still get everything from supabase_service.dart
export 'supabase_service.dart';

// 3. TYPEDEF lets the old name compile everywhere it's used as a type.
typedef DatabaseService = SupabaseService;