#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "auth-client.h"
#include "auth-plugin.h"

#define NELT(x) (sizeof x / sizeof x[0])

static char *construct_xoauth2_string(const char *user, const char *token)
{
    if (!user || !token) {
        return NULL;
    }

    unsigned int required_size = snprintf(NULL, 0, "user=%s\001auth=Bearer %s\001\001", user, token);
    
    char *auth_str = (char *)malloc((required_size + 1) * sizeof(char));
    if (!auth_str) {
        return NULL;
    }

    int written = snprintf(auth_str, required_size + 1, "user=%s\001auth=Bearer %s\001\001", user, token);
    if (written != required_size) {
        free(auth_str);
        return NULL;
    }

    return auth_str;
}


static int xoauth2_init(void *pctx) {
    char **ctx = malloc(sizeof(char *));
    if (!ctx) return 0;
    *ctx = NULL;
    *(void **)pctx = ctx;
    return 1;
}

static void xoauth2_destroy(void *ctx) {
    char **p = (char **)ctx;
    if (p && *p) {
        memset(*p, 0, strlen(*p));
        free(*p);
    }
    free(p);
}

static const struct auth_client_request client_request[] = {
    { "user", AUTH_CLEARTEXT | AUTH_USER, "User Name", 255 },
    { "access_token", AUTH_CLEARTEXT | AUTH_PASS, "OAuth2 Access Token", 0},
};


static const char *xoauth2_response(void *ctx, const char *challenge __attribute__((unused)),
                                   int *len, auth_interact_t interact, void *arg) {
    char **response = (char **)ctx;
    char *result[NELT(client_request)] = {0};


    if (!(*interact)(client_request, result, NELT(client_request), arg)) {
        fprintf(stderr, "XOAUTH2: interact callback failed\n");
        return NULL;
    }

    const char *user = result[0];
    const char *token = result[1];

    if (!user || !token) {
        fprintf(stderr, "XOAUTH2: user or token is NULL\n");
        return NULL;
    }

    char *auth_str = construct_xoauth2_string(user, token);
    if (!auth_str) {
        return NULL;
    }

    if (*response)
    {
        free(*response); 
    }
    *response = auth_str;

    *len = strlen(auth_str);
    
    return auth_str;
}

const struct auth_client_plugin sasl_xoauth2_client = {
    "XOAUTH2",
    "XOAUTH2 mechanism for OAuth 2.0 authentication",
    xoauth2_init,
    xoauth2_destroy,
    xoauth2_response,
    AUTH_PLUGIN_XOAUTH2,
    0,
    NULL,
    NULL,
};
