/* SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later */

#include "mctp-app-log.hpp"

#include <stdarg.h>
#include <stdio.h>
#include <syslog.h>
#include <systemd/sd-journal.h>

// int command_line_mode = 0;
enum
{
    MCTP_LOG_NONE,
    MCTP_LOG_STDIO,
    MCTP_LOG_SYSLOG,
    MCTP_LOG_CUSTOM,
} logType = MCTP_LOG_NONE;

static int logStdioLevel;
static void (*logCustomFn)(int, const char*, va_list);

#define MAX_TRACE_BYTES 5120
#define TRACE_FORMAT "%02X "
#define TRACE_FORMAT_SIZE 3
#define FORMATTED_MSG_SIZE 4096

static bool trace_enable;

void mctpPrlog(bool raw, int level, const char* fmt, ...)
{
    static const char* syslog_identifier = NULL;
    if (syslog_identifier == NULL)
    {
        syslog_identifier = getenv("SYSLOG_IDENTIFIER");
        if (!syslog_identifier)
        {
            syslog_identifier = "mctp-i3c-app"; // Default value.
        }
    }
    va_list ap;
    va_start(ap, fmt);

    int syslog_level = LOG_INFO;
    switch (level)
    {
        case MCTP_LOG_ERR:
            syslog_level = LOG_ERR;
            break;
        case MCTP_LOG_WARNING:
            syslog_level = LOG_WARNING;
            break;
        case MCTP_LOG_NOTICE:
            syslog_level = LOG_NOTICE;
            break;
        case MCTP_LOG_INFO:
            syslog_level = LOG_INFO;
            break;
        case MCTP_LOG_DEBUG:
            syslog_level = LOG_DEBUG;
            break;
        default:
            syslog_level = LOG_INFO;
            break;
    }
    switch (logType)
    {
        case MCTP_LOG_NONE:
            break;
        case MCTP_LOG_STDIO:
        {
#ifdef MCTP_LOG_TO_JOURNAL
            {
                if (level <= logStdioLevel)
                {
                    char formatted_message[FORMATTED_MSG_SIZE];
                    vsnprintf(formatted_message, sizeof(formatted_message), fmt,
                              ap);
                    sd_journal_send("PRIORITY=%d", syslog_level,
                                    "SYSLOG_IDENTIFIER=%s", syslog_identifier,
                                    "MESSAGE=%s", formatted_message, NULL);
                }
            }
#else
            {
                if (level <= logStdioLevel)
                {
                    // struct timespec ts;
                    // clock_gettime(CLOCK_REALTIME, &ts);
                    /*if(!raw)
                    {
                    fprintf(stderr, "%llu-%llu ",
                        (unsigned long long)ts.tv_sec,
                        ts.tv_nsec / 1000000ULL);
                    }*/
                    vfprintf(stderr, fmt, ap);
                    if (!raw)
                        fputs("\n", stderr);
                    fflush(stderr);
                }
            }
#endif
        }
        break;
        case MCTP_LOG_SYSLOG:
            vsyslog(syslog_level, fmt, ap);
            break;
        case MCTP_LOG_CUSTOM:
            logCustomFn(level, fmt, ap);
            break;
    }
    va_end(ap);
}

void mctpSetLogStdio(int level)
{
    logType = MCTP_LOG_STDIO;
    logStdioLevel = level;
}

void mctpSetLogSyslog(void)
{
    logType = MCTP_LOG_SYSLOG;
}

void mctpSetLogCustom(void (*fn)(int, const char*, va_list))
{
    logType = MCTP_LOG_CUSTOM;
    logCustomFn = fn;
}

void mctpSetTracingEnabled(bool enable)
{
    trace_enable = enable;
}

void mctpTraceCommon(const char* tag, const void* const payload,
                     const size_t len)
{
    char tracebuf[MAX_TRACE_BYTES * TRACE_FORMAT_SIZE + sizeof('\0')];
    // if len is bigger than ::MAX_TRACE_BYTES, loop will leave place for '..'
    // at the end to indicate that whole payload didn't fit
    //
    const size_t limit = len > MAX_TRACE_BYTES ? MAX_TRACE_BYTES - 1 : len;
    char* ptr = tracebuf;
    unsigned int i;

    if (!trace_enable || len == 0)
        return;

    if ((MCTP_LOG_STDIO == logType) && (logStdioLevel < MCTP_LOG_TRACE))
        return;

    for (i = 0; i < limit; i++)
        ptr += sprintf(ptr, TRACE_FORMAT, ((uint8_t*)payload)[i]);

    // buffer saturated, probably need to increase the size
    if (limit < len)
        sprintf(ptr, "..");

    mctpPrDebug("%s %s", tag, tracebuf);
}
