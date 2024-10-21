export 'blur_detector_unsupported.dart'
    if (dart.library.html) 'blur_detector_web.dart'
    if (dart.library.io) 'blur_detector_io.dart';