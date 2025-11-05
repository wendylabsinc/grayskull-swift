# Swift Embedded & WASM Compatibility Guide

This document explains how grayskull-swift supports Swift Embedded and WebAssembly (WASM) environments.

## Overview

The grayskull-swift wrapper is designed to work across a wide range of platforms, from full-featured operating systems to resource-constrained embedded environments and WebAssembly.

## Conditional Compilation Features

### FoundationEssentials for Smaller Binaries

The library automatically uses `FoundationEssentials` instead of the full `Foundation` framework when available:

```swift
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
```

**Benefits:**
- Significantly smaller binary sizes on Linux
- Faster compilation times
- Reduced memory footprint
- Only includes essential Foundation types

### WASI Support

When building for WebAssembly System Interface (WASI), the library adapts:

#### File I/O Disabled
```swift
#if !os(WASI) && !os(Windows)
/// PGM file reading/writing is only available on Unix-like systems
public init(contentsOfPGM path: String) throws { ... }
public func write(toPGM path: String) throws { ... }
#endif
```

#### Lock-Free Operation
```swift
#if !os(WASI)
private let lock = NSLock()
#endif
```

WASI typically runs in single-threaded environments, so thread synchronization is unnecessary and adds overhead.

### Swift Embedded / No Standard Library

When `GS_NO_STDLIB` is defined in the C library, memory management adapts:

```swift
#if os(WASI) || GS_NO_STDLIB
// Manual memory allocation for embedded environments
let data = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(width * height))
data.initialize(repeating: 0, count: Int(width * height))
self.image = gs_image(w: width, h: height, data: data)
#else
// Use C library's malloc-based allocation
self.image = gs_alloc(width, height)
#endif
```

## Building for Different Targets

### Standard Build (Desktop/Server)
```bash
swift build -c release
```

This automatically uses:
- FoundationEssentials (if available)
- Full thread safety with NSLock
- File I/O support
- Standard library allocations

### WebAssembly (WASI)
```bash
# Install SwiftWasm toolchain first
# https://book.swiftwasm.org/getting-started/setup.html

swift build --triple wasm32-unknown-wasi -c release
```

This configuration:
- Disables file I/O
- Removes thread synchronization
- Uses manual memory allocation
- Produces a .wasm binary

### Swift Embedded (Hypothetical)
```bash
# When Swift Embedded is released, you might use:
swift build --embedded -c release
```

This would:
- Use minimal runtime
- Remove all Foundation dependencies
- Use manual memory management
- Optimize for size

## Memory Management Strategies

### Desktop/Server Environments
- Uses C library's `gs_alloc()` and `gs_free()`
- Automatic memory management via ARC
- Thread-safe access with platform-native mutex (os_unfair_lock on Darwin, pthread_mutex elsewhere)

### WASI Environments
- Manual `UnsafeMutablePointer` allocation
- Deallocates in deinit
- Single-threaded, no locking

### Embedded Environments (GS_NO_STDLIB)
- Direct pointer manipulation
- No malloc/free calls
- Minimal overhead

## Thread Safety Considerations

| Platform | Thread Safety | Mechanism |
|----------|--------------|-----------|
| macOS/iOS | ✅ Yes | os_unfair_lock |
| Linux | ✅ Yes | pthread_mutex |
| Windows | ✅ Yes | pthread_mutex |
| WASI | ⚠️ Manual | Single-threaded assumption |
| Embedded | ⚠️ Manual | User-provided synchronization |

### Thread Safety in WASI

WASI environments typically run single-threaded. The library omits locking overhead in these environments. If you need thread safety in WASI:

1. Ensure single-threaded access from JavaScript
2. Use external synchronization (e.g., JavaScript Promise queues)
3. Consider message-passing architectures

## Binary Size Comparison

Approximate binary sizes (release builds, stripped):

| Configuration | Estimated Size |
|--------------|----------------|
| macOS (Foundation) | ~200 KB |
| Linux (Foundation) | ~5-10 MB |
| Linux (FoundationEssentials) | ~500 KB - 1 MB |
| WASI | ~300-500 KB |
| Embedded | ~100-200 KB |

*Note: Actual sizes depend on optimization level and what features you use.*

## Platform Feature Matrix

| Feature | macOS/iOS | Linux | Windows | WASI | Embedded |
|---------|-----------|-------|---------|------|----------|
| Image Processing | ✅ | ✅ | ✅ | ✅ | ✅ |
| Feature Detection | ✅ | ✅ | ✅ | ✅ | ✅ |
| File I/O | ✅ | ✅ | ❌ | ❌ | ❌ |
| Thread Safety | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| FoundationEssentials | ❌ | ✅ | ❌ | ❌ | ❌ |

## Testing WASI Builds

To test a WASI build locally:

```bash
# Build for WASI
swift build --triple wasm32-unknown-wasi

# Run with wasmtime
wasmtime .build/wasm32-unknown-wasi/debug/YourExecutable.wasm

# Or use Node.js with WASI support
node --experimental-wasi-unstable-preview1 run-wasm.js
```

Example `run-wasm.js`:
```javascript
const { WASI } = require('wasi');
const fs = require('fs');

const wasi = new WASI({
  args: process.argv,
  env: process.env,
});

const importObject = { wasi_snapshot_preview1: wasi.wasiImport };

(async () => {
  const wasm = await WebAssembly.compile(
    fs.readFileSync('./.build/wasm32-unknown-wasi/debug/YourExecutable.wasm')
  );
  const instance = await WebAssembly.instantiate(wasm, importObject);
  wasi.start(instance);
})();
```

## Best Practices

### For Desktop/Server Applications
- Use standard builds - full thread safety and features
- Rely on automatic memory management
- Use file I/O for image loading

### For WASM Applications
- Process images passed from JavaScript
- Use typed arrays for data exchange
- Keep all processing synchronous in one call
- Return processed results immediately

### For Embedded Systems
- Pre-allocate image buffers when possible
- Avoid repeated allocations
- Use fixed-size image processing pipelines
- Profile memory usage carefully

## Limitations

### WASI
- No file system access (by design)
- Single-threaded (no locks)
- Limited debugging tools

### Swift Embedded
- No dynamic allocation (when GS_NO_STDLIB is set)
- No standard library types
- Manual error handling

## Future Enhancements

Potential improvements for embedded/WASM support:

1. **Static image buffers** - Pool of pre-allocated images
2. **Streaming processing** - Process image tiles instead of full images
3. **SIMD acceleration** - Platform-specific optimizations
4. **Custom allocators** - User-provided memory allocation strategies

## Contributing

If you're using grayskull-swift in embedded or WASM environments, please share your experience! Contributions for better embedded support are welcome.

## Resources

- [Swift WASM Book](https://book.swiftwasm.org/)
- [Swift Embedded Overview](https://www.swift.org/blog/embedded-swift-examples/)
- [Grayskull C Library](https://github.com/zserge/grayskull)
- [WebAssembly WASI](https://wasi.dev/)
