// SPDX-License-Identifier: GPL-2.0-or-later
// Zig's MinGW import libraries lack these Windows 10 memory APIs.
// Resolve the actual OS implementations; preserve their signatures and behavior.
#include <windows.h>
#include <memoryapi.h>
#include <cstdlib>

namespace {
template <class T> T Resolve(const char* name) {
    const auto module = GetModuleHandleW(L"kernelbase.dll");
    const auto function = module ? GetProcAddress(module, name) : nullptr;
    if (!function) {
        OutputDebugStringA("X HD runtime requires Windows 10 memory placeholder APIs");
        std::abort();
    }
    return reinterpret_cast<T>(function);
}
}

extern "C" {
decltype(&VirtualAlloc2) __imp_VirtualAlloc2 = Resolve<decltype(&VirtualAlloc2)>("VirtualAlloc2");
decltype(&CreateFileMapping2) __imp_CreateFileMapping2 = Resolve<decltype(&CreateFileMapping2)>("CreateFileMapping2");
decltype(&MapViewOfFile3) __imp_MapViewOfFile3 = Resolve<decltype(&MapViewOfFile3)>("MapViewOfFile3");
decltype(&UnmapViewOfFile2) __imp_UnmapViewOfFile2 = Resolve<decltype(&UnmapViewOfFile2)>("UnmapViewOfFile2");
}
