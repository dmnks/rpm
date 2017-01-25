#ifndef H_RPMCHECKSIG
#define H_RPMCHECKSIG

#include <rpm/rpmtypes.h>
#include <rpm/rpmsw.h>
#include <rpm/rpmkeyring.h>
#include <rpm/rpmcli.h>

#ifdef __cplusplus
extern "C" {
#endif

int rpmpkgVerifySigs(rpmKeyring keyring, rpmQueryFlags flags,
			   FD_t fd, const char *fn);

#endif	/* H_RPMDB */
