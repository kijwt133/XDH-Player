// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once
#include <array>
#include <xxhash.h>
#include "shader_recompiler/profile.h"

namespace Vulkan::Xhd {
inline u64 StableProfileHash(const Shader::Profile& profile) {
    // Canonical values exclude padding, which must not change the cache namespace.
    const std::array<u32, 44> values{
        profile.max_viewport_width,
        profile.max_viewport_height,
        profile.max_shared_memory_size,
        profile.supported_spirv,
        profile.subgroup_size,
        profile.sparse_page_shift,
        profile.support_int8,
        profile.support_int16,
        profile.support_int64,
        profile.support_float16,
        profile.support_float64,
        profile.supports_denorm_behavior_independence,
        profile.supports_rounding_mode_independence,
        profile.support_fp16_denorm_preserve,
        profile.support_fp16_denorm_flush,
        profile.support_fp16_round_to_zero,
        profile.support_fp32_denorm_preserve,
        profile.support_fp32_denorm_flush,
        profile.support_fp32_round_to_zero,
        profile.support_fp64_denorm_preserve,
        profile.support_fp64_denorm_flush,
        profile.support_fp64_round_to_zero,
        profile.support_fp16_signed_zero_inf_nan_preserve,
        profile.support_fp32_signed_zero_inf_nan_preserve,
        profile.support_fp64_signed_zero_inf_nan_preserve,
        profile.supports_image_load_store_lod,
        profile.supports_native_cube_calc,
        profile.supports_trinary_minmax,
        profile.supports_buffer_fp32_atomic_min_max,
        profile.supports_image_fp32_atomic_min_max,
        profile.supports_buffer_int64_atomics,
        profile.supports_shared_int64_atomics,
        profile.supports_workgroup_explicit_memory_layout,
        profile.supports_amd_shader_explicit_vertex_parameter,
        profile.supports_fragment_shader_barycentric,
        profile.supports_shader_subgroup_clock,
        profile.has_broken_spirv_clamp,
        profile.lower_left_origin_mode,
        profile.needs_manual_interpolation,
        profile.needs_lds_barriers,
        profile.needs_buffer_offsets,
        profile.needs_unorm_fixup,
        profile.needs_clip_distance_emulation,
        profile.supports_shader_stencil_export,
    };
    return XXH3_64bits(values.data(), sizeof(values));
}
}
