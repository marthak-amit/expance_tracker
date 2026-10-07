// PHASE 2 STUB - not implemented.

sealed class ModelDownloadState {
  const ModelDownloadState();
}

class ModelNotDownloaded extends ModelDownloadState {
  const ModelNotDownloaded();
}

/// Download requested but the device is not on Wi-Fi.
class ModelWaitingForWifi extends ModelDownloadState {
  const ModelWaitingForWifi();
}

class ModelDownloading extends ModelDownloadState {
  const ModelDownloading(this.progress);

  /// 0.0 - 1.0
  final double progress;
}

class ModelReady extends ModelDownloadState {
  const ModelReady();
}

class ModelDownloadFailed extends ModelDownloadState {
  const ModelDownloadFailed(this.message);
  final String message;
}

/// Downloads the on-device LLM weights (via flutter_gemma) on Wi-Fi only,
/// reporting progress. Intended behaviour:
/// - [start] checks connectivity (connectivity_plus); on mobile data it emits
///   [ModelWaitingForWifi] and resumes automatically when Wi-Fi returns.
/// - Progress is mapped from flutter_gemma's download callbacks to
///   [ModelDownloading]; [cancel] aborts and cleans up partial files.
class ModelDownloadManager {
  const ModelDownloadManager({this.wifiOnly = true});

  final bool wifiOnly;

  Stream<ModelDownloadState> get states =>
      throw UnimplementedError('ModelDownloadManager.states');

  Future<bool> isModelReady() =>
      throw UnimplementedError('ModelDownloadManager.isModelReady');

  Future<void> start() =>
      throw UnimplementedError('ModelDownloadManager.start');

  Future<void> cancel() =>
      throw UnimplementedError('ModelDownloadManager.cancel');
}
