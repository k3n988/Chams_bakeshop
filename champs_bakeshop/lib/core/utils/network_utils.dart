import 'dart:io';

/// Returns true if the device can reach the internet.
Future<bool> hasInternet() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Shows a standard no-internet snackbar.
/// Import this and call it before any critical write operation.
const String kNoInternetMsg =
    'No internet connection. Please check your network and try again.';
