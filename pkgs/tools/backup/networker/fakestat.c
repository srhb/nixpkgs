#define _GNU_SOURCE

#include <stdio.h>
#include <dlfcn.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

typedef int (*xstat_func_t)(int vers, const char *pathname, struct stat *buf);
typedef int (*xstat64_func_t)(int vers, const char *pathname, struct stat64 *buf);

int prefix(const char* start, const char *whole)
{
  while(*start)
  {
    if(*start++ != *whole++)
      return 0;
  }
  return 1;
}

int __xstat(int ver, const char *path, struct stat *buf)
{
	xstat_func_t orig_xstat;
  orig_xstat = dlsym(RTLD_NEXT, "__xstat");

  int retval;
  retval = orig_xstat(ver, path, buf);

  if (prefix(STOREPATH,path))
  {
    buf->st_nlink = 0;
  }

  return retval;
} 

int __xstat64(int ver, const char *path, struct stat64 *buf)
{
	xstat64_func_t orig_xstat64;
  orig_xstat64 = dlsym(RTLD_NEXT, "__xstat64");

  int retval;
  retval = orig_xstat64(ver, path, buf);

  if (prefix(STOREPATH,path))
  {
    buf->st_nlink = 0;
  }

  return retval;
}
