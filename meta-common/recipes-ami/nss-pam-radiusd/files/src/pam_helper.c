#include "pam_helper.h"
#include "nss.h"
#include <errno.h>
#include <pwd.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <unistd.h>
#define MAX_USER_NAME_LEN 255

typedef enum nss_status nss_status_t;

unsigned int calculate_checksum(const pamusrpkt_t *pkt)
{
	unsigned int checksum = 0;
	pamusrpkt_t temp_pkt = *pkt;
	temp_pkt.checksum = 0;

	const unsigned char *data = (const unsigned char *)&temp_pkt;
	size_t len = sizeof(pamusrpkt_t) - sizeof(unsigned int);

	for (size_t i = 0; i < len; ++i)
	{
		checksum = (checksum << 1) ^ data[i];
	}
	return checksum;
}
/*
 * @ fn         - _nss_radius_getpwent_r
 * @ brief      - get passwd file entry reentrantly
 * @ return     - always success
 */
enum nss_status _nss_radius_getpwent_r(struct passwd *pwd, char *buffer,
                                       size_t buflen, int *errnop) {
  enum nss_status result = NSS_STATUS_SUCCESS;
  *errnop = 0;
  if (0) {
    buffer = buffer;
    buflen = buflen;
  }
  return result;
}

/*
 * @ fn                 - _nss_radius_getpwnam_r
 * @ brief              - Get User Info using user name.
 * @ name               - logged user name
 * @ pwd                - Passwd structure to fill
 */
nss_status_t _nss_radius_getpwnam_r(char *name, struct passwd *pwd,
                                    char *buffer, size_t buflen, int *errnop) {

  enum nss_status result = NSS_STATUS_SUCCESS;
  int ret = 0;
  char *init_buf = NULL;
  pamusrpkt_t nss_req, nss_res;
  int radius_handle;
  char defshell[MAX_SHELL_NAME_LENGTH];
  unsigned int calculated_checksum = 0;

  if (name == NULL || name[0] == '\0') {
    return NSS_STATUS_NOTFOUND;
  }
  /* Retrieve user by name */
  memset(&nss_req, 0, sizeof(pamusrpkt_t));
  memset(&nss_res, 0, sizeof(pamusrpkt_t));

  nss_req.action = GET_USERINFO_BY_NAME;
  nss_req.pt = PAM_RADIUS_TBL;
  ret = snprintf(nss_req.usr.name, sizeof(nss_req.usr.name), "%s", name);
  if (ret < 0 || ret >= (signed)sizeof(nss_req.usr.name)) {
    syslog(LOG_WARNING, "Buffer Overflow\n");
    return NSS_STATUS_UNAVAIL;
  }
  ret = snprintf(nss_req.srcq, sizeof(nss_req.srcq), "%s", NSS_RADIUS_Q);
  if (ret < 0 || ret >= (signed)sizeof(nss_req.srcq)) {
    syslog(LOG_WARNING, "Buffer Overflow\n");
    return NSS_STATUS_UNAVAIL;
  }
  PAMH_CREATE_Q(NSS_RADIUS_Q);
  PAMH_OPEN_Q(NSS_RADIUS_Q, radius_handle);
  if (radius_handle == -1) {
    syslog(LOG_WARNING, "error openig queue %s \n", NSS_RADIUS_Q);
    result = NSS_STATUS_UNAVAIL;
    return result;
  }
  nss_req.checksum = 0;
  nss_req.checksum = calculate_checksum(&nss_req);
  ret = post_pam_userinfo(&nss_req, PAM_HELPER_Q);
  if (ret < 0) {
    syslog(LOG_WARNING, "error openig queue %s \n", PAM_HELPER_Q);
    result = NSS_STATUS_UNAVAIL;
    pipe_close(radius_handle);
    return result;
  }
  nss_res.checksum = 0;
  ret = get_pam_userinfo(&nss_res, NSS_RADIUS_Q, radius_handle, WAIT_1000_MS);
  calculated_checksum = calculate_checksum(&nss_res);
  if (calculated_checksum != nss_res.checksum)
  {
	  fprintf(stderr, " ***failed in get_pam_userinfo . Checksum mismatch! Expected %d, got %d\n",calculated_checksum, nss_res.checksum);
	  result = NSS_STATUS_UNAVAIL;
	  pipe_close(radius_handle);
	  return result;
  }
  pipe_close(radius_handle);
  if (nss_res.action == PAM_RESPONSE) {
    if (nss_res.ret == PAM_USER_RETRIEVED_SUCCESSFULLY) {
      /*if(!is_radius_enabled())
      {
              syslog(LOG_WARNING,"PAM-RADIUS: RADIUS is not enabled");
              return NSS_STATUS_UNAVAIL;
      }*/
    } else if (nss_res.ret == PAM_USER_NOT_FOUND) {
      /*Avoiding adding of user to PAM user list when RADIUS is disabled*/
      /*if(!is_radius_enabled())
      {
          syslog(LOG_WARNING,"PAM-RADIUS: RADIUS is not enabled");
          return NSS_STATUS_UNAVAIL;
      }*/
      /*Known Issue*/
      /* We need to add user to PAM user list If its not added during
       * Authentication/authorization or when getpwnaam call is invoked before
       * authentication/authorization(i.e in for ssh/telnet) Which leads in
       * adding invalid radius user to PAM user list*/
      /* There is no way to check validity of username without passowrd in
       * RADIUS*/
      PAMH_OPEN_Q(NSS_RADIUS_Q, radius_handle);
      ret = post_pam_userinfo(&nss_req, PAM_HELPER_Q);
      if (ret < 0) {
        syslog(LOG_WARNING, " %s : error openig queue %s \n", __FILE__,
               PAM_HELPER_Q);
        result = NSS_STATUS_UNAVAIL;
        pipe_close(radius_handle);
        return result;
      }
      ret =
          get_pam_userinfo(&nss_res, NSS_RADIUS_Q, radius_handle, WAIT_1000_MS);
      pipe_close(radius_handle);
      if (nss_res.action != PAM_RESPONSE &&
          nss_res.ret != PAM_USER_RETRIEVED_SUCCESSFULLY) {
        printf("PAM User: %s : not found\n", nss_req.usr.name);
        result = NSS_STATUS_UNAVAIL;
        return result;
      }
    } else {
      syslog(LOG_WARNING, "PAM user return code not valid: %d\n", nss_res.ret);
      result = NSS_STATUS_UNAVAIL;
      return result;
    }
  } else {
    syslog(LOG_WARNING, "Error: Not a PAM Respones\n");
    result = NSS_STATUS_UNAVAIL;
    return result;
  }
  init_buf = buffer;
  snprintf(pwd->pw_name, MAX_USER_NAME_LEN, "%s", nss_res.usr.name);
  pwd->pw_uid = nss_res.usr.uid;
  pwd->pw_gid = nss_res.usr.priv;

  *errnop = 0;
  return result;
}
/*
 * @ fn                 - _nss_radius_getpwuid_r
 * @ brief              - Get User Info using ssh uid.
 * @ uid                - user id, used to get the user info from pam_helper
 * @ pwd                - Passwd structure to fill
 */
enum nss_status _nss_radius_getpwuid_r(uid_t uid, struct passwd *pwd,
                                       char *buffer, size_t buflen,
                                       int *errnop) {
  enum nss_status result = NSS_STATUS_SUCCESS;
  int ret = 0;
  char *init_buf = NULL;
  pamusrpkt_t nss_req, nss_res;
  int radius_handle;
  char defshell[MAX_SHELL_NAME_LENGTH];

  memset(&nss_req, 0, sizeof(pamusrpkt_t));
  memset(&nss_res, 0, sizeof(pamusrpkt_t));

  nss_req.action = GET_USERINFO_BY_UID;
  nss_req.pt = PAM_RADIUS_TBL;
  nss_req.usr.uid = uid;

  strncpy(nss_req.srcq, NSS_RADIUS_Q, sizeof(nss_req.srcq));

  PAMH_CREATE_Q(NSS_RADIUS_Q);
  PAMH_OPEN_Q(NSS_RADIUS_Q, radius_handle);
  if (radius_handle == -1) {
    printf("error openig queue %s \n", NSS_RADIUS_Q);
    result = NSS_STATUS_UNAVAIL;
    return result;
  }
  ret = post_pam_userinfo(&nss_req, PAM_HELPER_Q);
  if (ret < 0) {
    printf("error openig queue %s \n", PAM_HELPER_Q);
    result = NSS_STATUS_UNAVAIL;
    pipe_close(radius_handle);
    return result;
  }
  ret = get_pam_userinfo(&nss_res, NSS_RADIUS_Q, radius_handle, WAIT_1000_MS);
  pipe_close(radius_handle);

  if (nss_res.action == PAM_RESPONSE) {
    if (nss_res.ret == PAM_USER_RETRIEVED_SUCCESSFULLY) {
      /*if(!is_radius_enabled())
      {
              syslog(LOG_WARNING,"PAM-RADIUS: RADIUS is not enabled");
              return NSS_STATUS_UNAVAIL;
      }*/
    } else if (nss_res.ret == PAM_USER_NOT_FOUND) {
      result = NSS_STATUS_UNAVAIL;
      return result;
    } else {
      printf("PAM user return code not valid: %d\n", nss_res.ret);
      return result;
    }
  } else {
    printf("Error: Not a PAM Respones\n");
    result = NSS_STATUS_UNAVAIL;
    return result;
  }

  init_buf = buffer;
  ADD_STRTOBUF_REF(pwd->pw_name, nss_res.usr.name, init_buf, buffer, buflen);
  pwd->pw_uid = nss_res.usr.uid;
  pwd->pw_gid = 10;
  *errnop = 0;
  return result;
}

/**
 * @fn get_pam_userinfo
 * @brief gets the pam user info.
 * @param pu     - pointer to pam user info
 * @param queue  - queue to fetch the message from.
 * @param handle - User Handle
 * @param num_ms - Waittime in ms.
 * @return   0 if success, -1 if failed.
 **/
int get_pam_userinfo(pamusrpkt_t *pu, char *queue, int handle,
                     unsigned int num_ms) {
  int err, ret = 0;
  unsigned int size;
  bool handle_open = TRUE;

  if (handle <= 0) {
    handle_open = FALSE;
    if (access(queue, F_OK) == -1) {
      printf(" %s : Queue %s not present : %s\n", __FILE__, queue,
             strerror(errno));
      return -1;
    }

    handle = pipe_open(queue, O_RDWR | O_NONBLOCK);
    if (handle < 0) {
      printf(" %s : Opening queue: %s failed : %s\n", __FILE__, queue,
             strerror(errno));
      return -1;
    }
  }

  if (WAIT_INFINITE_TIME != (signed int)num_ms) {
    struct timeval timeval;
    fd_set fdread;
    int n, sret;

    FD_ZERO(&fdread);
    FD_SET(handle, &fdread);
    n = handle + 1;

    timeval.tv_sec = 0;
    timeval.tv_usec = num_ms * 1000;
    sret = pipe_select(n, &fdread, NULL, NULL, &timeval);
    if (-1 == sret) {
      printf(" %s : Error waiting on queue %s : %s\n", __FILE__, queue,
             strerror(errno));
      ret = -1;
      goto end;
    } else if (0 == sret) {
      ret = 1;
      goto end;
    }
  }

  size = sizeof(pamusrpkt_t);
  PAMH_GET_FROM_Q(pu, size, handle, &err); // WAIT_INFINITE
  if ((err == -1) || (err != sizeof(pamusrpkt_t))){
    printf(" %s : Error in retrieving from queue %s : %s\n", __FILE__, queue,
           strerror(errno));
    ret = -1;
    goto end;
  }

end:
  if (handle_open == FALSE)
    pipe_close(handle);
  return ret;
}

/**
 * @fn post_pam_userinfo
 * @brief gets the pam user info posted to this task.
 * @param pu     - pointer to pam user info
 * @param queue  - queue to fetch the message from.
 * @return   0 if success, -1 if failed.
 **/
int post_pam_userinfo(pamusrpkt_t *pu, char *queue) {
  int err;
  int handle;

  if (access(queue, F_OK) == -1) {
    printf(" %s : Queue %s not present : %s\n", __FILE__, queue,
           strerror(errno));
    return -1;
  }

  handle = pipe_open(
      queue,
      O_WRONLY | O_NONBLOCK); /* Fortify [Path Manipulation]:: False Positive */
  if (handle < 0) {
    printf(" %s : Opening queue: %s failed : %s\n", __FILE__, queue,
           strerror(errno));
    return -1;
  }

  PAMH_ADD_TO_Q(pu, sizeof(pamusrpkt_t), handle, &err);

  if ((err == -1) || (err != sizeof(pamusrpkt_t))) {
    printf(" %s : post pam userinfo failed for queue %s : %s \n", __FILE__,
           queue, strerror(errno));
    pipe_close(handle);
    return -1;
  }

  pipe_close(handle);
  return 0;
}

/**
 * @fn remove_pam_user
 * @brief remove the pam user expect in present database.
 * @param uname  - user name to be removed
 * @param table  - expect this table, other table users with this name should be
 *removed.
 **/

void remove_pam_user(char *uname, int table) {
  pamusrpkt_t del_req, del_res;
  int ret, del_handle, curtbl;

  /* Delete user by name */
  memset(&del_req, 0, sizeof(pamusrpkt_t));
  memset(&del_res, 0, sizeof(pamusrpkt_t));

  for (curtbl = 0; curtbl < NUM_OF_TBLTYPES; curtbl++) {
    if (curtbl != table) {
      del_req.action = DEL_PAM_USER;
      del_req.pt = curtbl; // table which the user gonna be searched and
                           // deleted.
      strncpy(del_req.usr.name, uname, sizeof(del_req.usr.name) - 1);
      del_req.usr.name[sizeof(del_req.usr.name) - 1] = '\0';
      strncpy(del_req.srcq, DEL_USER_Q, sizeof(del_req.srcq) - 1);
      del_req.srcq[sizeof(del_req.srcq) - 1] = '\0';

      PAMH_CREATE_Q(DEL_USER_Q);
      PAMH_OPEN_Q(DEL_USER_Q, del_handle);
      if (del_handle == -1) {
        return;
      }
      ret = post_pam_userinfo(&del_req, PAM_HELPER_Q);
      if (ret < 0) {
        printf(" %s : error opening queue %s \n", __FILE__, PAM_HELPER_Q);
        pipe_close(del_handle);
        return;
      }
      ret = get_pam_userinfo(&del_res, DEL_USER_Q, del_handle, 1000);
      if (ret != 0) {
        printf(" %s : error getting from queue :%s \n", __FILE__, DEL_USER_Q);
        pipe_close(del_handle);
        return;
      }
      pipe_close(del_handle);
      if (del_res.action == PAM_RESPONSE) {
        if (del_res.ret == PAM_USER_DELETED_SUCCESSFULLY) {
          printf("User found in other database and deleted \n");
          return;
        } else if (del_res.ret == PAM_USER_NOT_FOUND) {
          printf("PAM User: %s : not found\n", del_req.usr.name);
          return;
        } else {
          printf("PAM user return code not valid: %d\n", del_res.ret);
          return;
        }
      } else {
        printf("Error: Not a PAM Respones\n");
      }
    }
  }
}

/** @fn Open a file specified by pathname with the given flags
 *  @param[in] pathname - File name with path
 *  @param[in] flags - Flags used to specify the task on the file
 *  @param[return] File descriptor [hFile] - If open fails, it checks the errno
 * . If errno is not EINTR (which indicates the call was interrupted by a
 * signal), it returns the file descriptor (which will be -1 in this case,
 * indicating an error).If errno is EINTR, the loop continues, retrying the open
 * call.
 */
int pipe_open(const char *pathname, int flags) {
  while (1) {
    int hFile = open(pathname, flags);

    if (hFile != -1)
      return hFile;

    if (errno != EINTR)
      return hFile;
  }
}

/** @fn designed to writing data to a file descriptor with special attention to
 * interruptions by signals
 *  @param[in] fd - File descriptor.
 *  @param[in] buf  - Content to write in file
 *  @param[in] count  - Number of bytes count of buf
 *  @param[return] File descriptor [hFile] - If errno is not EINTR
 *  (which means the error was not due to an interrupt signal), it returns the
 * result (-1), indicating an error.. If errno is EINTR, the loop continues,
 * retrying the write call.
 */
ssize_t pipe_write(int fd, const void *buf, size_t count) {
  while (1) {
    ssize_t Result = write(fd, buf, count);

    if (Result != -1)
      return (Result);

    if (errno != EINTR)
      return (Result);
  }
}

/** @fn designed to Close the File
 *  @param[in] hFile - File descriptor.
 *  @param[return] - Failure return -1 and success return 0
 */
int pipe_close(int hFile) {
  while (close(hFile) == -1) {
    if (errno != EINTR)
      return -1;
  }

  return 0;
}

/** @fn monitors multiple file descriptors to see if any of them are ready for
 * I/O operations, with special handling for interruptions by signals
 *  @param[in] nfds - highest-numbered file descriptor.
 *  @param[in] readfds - Set of file descriptors to be checked for readability.
 *  @param[in] writefds - Set of file descriptors to be checked for writability.
 *  @param[in] exceptfds - Set of file descriptors to be checked for exceptional
 * conditions.
 *  @param[in] timeout - Maximum interval to wait for any file descriptor to
 * become ready.
 *  @param[return] - If errno is not EINTR (which means the error was not due to
 * an interrupt signal), it returns the result (-1), indicating an error.If
 * errno is EINTR, the loop continues, retrying the select call.
 */
int pipe_select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds,
                struct timeval *timeout) {
  while (1) {
    int Result = select(nfds, readfds, writefds, exceptfds, timeout);

    if (Result != -1)
      return Result;

    if (errno != EINTR)
      return Result;
  }
}

/** @fn Function designed to read data from file descriptor with special
 * attention to interruptions by signals
 *  @param[in] fd - File descriptor.
 *  @param[in] buf  - Content to read from a file
 *  @param[in] count  - Number of bytes count of buf
 *  @param[return] File descriptor [hFile] - If errno is not EINTR
 *  (which means the error was not due to an interrupt signal), it returns the
 * result (-1), indicating an error.. If errno is EINTR, the loop continues,
 * retrying the write call.
 */
ssize_t pipe_read(int fd, void *buf, size_t count) {
  while (1) {
    ssize_t Result = read(fd, buf, count);

    if (Result != -1)
      return (Result);

    if (errno != EINTR)
      return (Result);
  }
}
