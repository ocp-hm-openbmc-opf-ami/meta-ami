/* SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later */

#ifndef _MCTP_APP_LOG_H
#define _MCTP_APP_LOG_H

#include <stdarg.h>
#include <stddef.h>
#include <stdlib.h>

/* environment-specific logging */

void mctpSetLogStdio(int level);
void mctpSetLogSyslog(void);
void mctpSetLogCustom(void (*fn)(int, const char*, va_list));
void mctpSetTracingEnabled(bool enable);

/* these should match the syslog-standard LOG_* definitions, for
 * easier use with syslog */
#define MCTP_LOG_ERR 3
#define MCTP_LOG_WARNING 4
#define MCTP_LOG_NOTICE 5
#define MCTP_LOG_INFO 6
#define MCTP_LOG_DEBUG 7
#define MCTP_LOG_TRACE 8

/* libmctp-internal logging */

void mctpPrlog(bool raw, int level, const char* fmt, ...)
    __attribute__((format(printf, 3, 4)));

void mctpTraceCommon(const char* tag, const void* const payload,
                     const size_t len);

#ifndef pr_fmt
#define pr_fmt(x) x
#endif

#define mctpPrErr(fmt, ...)                                                    \
    mctpPrlog(false, MCTP_LOG_ERR, pr_fmt(fmt), ##__VA_ARGS__)
#define mctpPrWarn(fmt, ...)                                                   \
    mctpPrlog(false, MCTP_LOG_WARNING, pr_fmt(fmt), ##__VA_ARGS__)
#define mctpPrInfo(fmt, ...)                                                   \
    mctpPrlog(false, MCTP_LOG_INFO, pr_fmt(fmt), ##__VA_ARGS__)
#define mctpPrDebug(fmt, ...)                                                  \
    mctpPrlog(false, MCTP_LOG_DEBUG, pr_fmt(fmt), ##__VA_ARGS__)
#define mctpPrDebugRaw(fmt, ...)                                               \
    mctpPrlog(true, MCTP_LOG_DEBUG, pr_fmt(fmt), ##__VA_ARGS__)

#define MCTP_ERR(fmt, ...)                                                     \
    do                                                                         \
    {                                                                          \
        mctpPrErr("at %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__);         \
    } while (0)

#define MCTP_ASSERT(cond, fmt, ...)                                            \
    do                                                                         \
    {                                                                          \
        if (!(cond))                                                           \
        {                                                                      \
            mctpPrErr("at %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__);     \
            abort();                                                           \
        }                                                                      \
    } while (0)

#define MCTP_ASSERT_RET(cond, ret, fmt, ...)                                   \
    do                                                                         \
    {                                                                          \
        if (!(cond))                                                           \
        {                                                                      \
            mctpPrErr("at %s:%d " fmt, __func__, __LINE__, ##__VA_ARGS__);     \
            return (ret);                                                      \
        }                                                                      \
    } while (0)

#define mctpTraceRx(payload, len)                                              \
    mctpTraceCommon(pr_fmt("<RX<"), (payload), (len))
#define mctpTraceTx(payload, len)                                              \
    mctpTraceCommon(pr_fmt(">TX>"), (payload), (len))

#endif /* _MCTP_APP_LOG_H */
