import CGrayskull

#if !os(WASI)
#if canImport(Darwin)
import Darwin
import os.lock
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import WinSDK
#elseif canImport(ucrt)
import ucrt
#endif
#endif

#if !os(WASI)
/// A lightweight, cross-platform mutex for thread synchronization.
///
/// Uses the most efficient synchronization primitive available on each platform:
/// - Darwin (macOS/iOS/tvOS/watchOS/visionOS): `os_unfair_lock` for minimal overhead
/// - Linux/Windows: `pthread_mutex` for reliable cross-platform synchronization
///
/// This implementation avoids Objective-C dependencies (NSLock) for better performance
/// and compatibility with pure Swift environments.
private final class Mutex: @unchecked Sendable {
    #if canImport(Darwin)
    private var unfairLock = os_unfair_lock()

    func lock() {
        os_unfair_lock_lock(&unfairLock)
    }

    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }
    #elseif os(Windows)
    private var criticalSection = CRITICAL_SECTION()

    init() {
        InitializeCriticalSection(&criticalSection)
    }

    deinit {
        DeleteCriticalSection(&criticalSection)
    }

    func lock() {
        EnterCriticalSection(&criticalSection)
    }

    func unlock() {
        LeaveCriticalSection(&criticalSection)
    }
    #else
    // pthread_mutex for Linux and other POSIX systems
    private var mutex = pthread_mutex_t()

    init() {
        pthread_mutex_init(&mutex, nil)
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    func lock() {
        pthread_mutex_lock(&mutex)
    }

    func unlock() {
        pthread_mutex_unlock(&mutex)
    }
    #endif
}
#endif

/// Internal storage backing for `GrayskullImage`.
///
/// Manages lifetime of the underlying `gs_image` and provides thread-safe access to
/// the C image object. Exposed internally so the higher-level Swift wrapper can
/// delegate to the C implementation without leaking implementation details.
final class ImageStorage: @unchecked Sendable {
    private var image: gs_image

    #if !os(WASI)
    private let mutex = Mutex()
    #endif

    var width: UInt32 { UInt32(image.w) }
    var height: UInt32 { UInt32(image.h) }
    var isValid: Bool { gs_valid(image) != 0 }

    init(width: UInt32, height: UInt32) {
        #if os(WASI) || GS_NO_STDLIB
        // Allocate manually for embedded/WASM environments
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(width * height))
        data.initialize(repeating: 0, count: Int(width * height))
        self.image = gs_image(w: width, h: height, data: data)
        #else
        self.image = gs_alloc(width, height)
        #endif
    }

    init(takingOwnership image: gs_image) {
        self.image = image
    }

    deinit {
        #if os(WASI) || GS_NO_STDLIB
        image.data.deallocate()
        #else
        gs_free(image)
        #endif
    }

    func withUnsafeImage<T>(_ body: (gs_image) throws -> T) rethrows -> T {
        #if !os(WASI)
        mutex.lock()
        defer { mutex.unlock() }
        #endif
        return try body(image)
    }

    func withPixelData<T>(_ body: ([UInt8]) throws -> T) rethrows -> T {
        try withUnsafeImage { img in
            let buffer = UnsafeBufferPointer(start: img.data, count: Int(img.w * img.h))
            return try body(Array(buffer))
        }
    }
}
