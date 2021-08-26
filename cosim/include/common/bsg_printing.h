// Copyright (c) 2019, University of Washington All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification,
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list
// of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this
// list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// Neither the name of the copyright holder nor the names of its contributors
// may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef _BSG_PRINTING_H
#define _BSG_PRINTING_H

#ifdef __cplusplus
#include <cstdint>
#include <cstddef>
#else
#include <stdint.h>
#include <stddef.h>
#endif

#include <sys/time.h>
#if defined(__cplusplus)
extern "C" {
#endif // #if defined(__cplusplus)

#define BSG_PRINT_PREFIX_DEBUG "DEBUG"
#define BSG_PRINT_PREFIX_ERROR "ERROR:   "
#define BSG_PRINT_PREFIX_WARN "WARNING: "
#define BSG_PRINT_PREFIX_INFO "INFO:    "

#define BSG_PRINT_STREAM_DEBUG stderr
#define BSG_PRINT_STREAM_ERROR stderr
#define BSG_PRINT_STREAM_WARN stderr
#define BSG_PRINT_STREAM_INFO stderr

static inline uint64_t bsg_utc() {
  struct timeval tv;
  gettimeofday(&tv, NULL);

  uint64_t ms = (uint64_t)(tv.tv_sec) * 1000 + (uint64_t)(tv.tv_usec) / 1000;

  return ms;
}

__attribute__((format(printf, 2, 3))) int bsg_pr_prefix(const char *prefix,
                                                        const char *fmt, ...);

#if defined(DEBUG)
#define bsg_pr_dbg(fmt, ...)                                                   \
  bsg_pr_prefix(BSG_PRINT_PREFIX_DEBUG, fmt, ##__VA_ARGS__)
#else
#define bsg_pr_dbg(...)
#endif

#define bsg_pr_err(fmt, ...)                                                   \
  bsg_pr_prefix(BSG_PRINT_PREFIX_ERROR, fmt, ##__VA_ARGS__)

#define bsg_pr_warn(fmt, ...)                                                  \
  bsg_pr_prefix(BSG_PRINT_PREFIX_WARN, fmt, ##__VA_ARGS__)

#define bsg_pr_info(fmt, ...)                                                  \
  bsg_pr_prefix(BSG_PRINT_PREFIX_INFO, fmt, ##__VA_ARGS__)

#if defined(__cplusplus)
}
#endif // #if defined(__cplusplus)

#endif
