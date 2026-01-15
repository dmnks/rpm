#include "system.h"

#include <unordered_map>
#include <string>

#include <pwd.h>
#include <grp.h>
#include <errno.h>
#include <rpm/argv.h>
#include <rpm/rpmlog.h>
#include <rpm/rpmstring.h>
#include <rpm/rpmmacro.h>

#include "misc.hh"
#include "rpmchroot.hh"
#include "rpmug.hh"
#include "debug.h"

using std::unordered_map;
using std::string;

struct rpmug_s {
    char *path;
    unordered_map<id_t,string> idMap;
    unordered_map<string,id_t> nameMap;
};

static __thread struct rpmug_s *rpmug_pw = NULL;
static __thread struct rpmug_s *rpmug_grp = NULL;

static const char *getpath(const char *bn, const char *dfl, struct rpmug_s *rs)
{
    char **dest = &rs->path;
    if (*dest == NULL) {
	char *s = rpmExpand("%{_", bn, "_path}", NULL);
	if (*s == '%' || *s == '\0') {
	    free(s);
	    // Use system lookup unless chrooted
	    s = rpmChrootDone() ? xstrdup(dfl) : NULL;
	}
	*dest = s;
    }
    return rs->path;
}

static const char *pwfile(void)
{
    return getpath("passwd", "/etc/passwd", rpmug_pw);
}

static const char *grpfile(void)
{
    return getpath("group", "/etc/group", rpmug_grp);
}

/*
 * Lookup an arbitrary field based on contents of another in a ':' delimited
 * file, such as /etc/passwd or /etc/group.
 */
static int lookup_field_in_file(const char *path, const char *val, int vcol, int rcol,
			char **ret)
{
    int rc = -1; /* assume not found */
    char *str, buf[BUFSIZ];
    FILE *f = fopen(path, "r");
    if (f == NULL) {
	rpmlog(RPMLOG_ERR, _("failed to open %s for id/name lookup: %s\n"),
		path, strerror(errno));
	return rc;
    }

    while ((str = fgets(buf, sizeof(buf), f)) != NULL) {
	int nf = vcol > rcol ? vcol : rcol;
	const char *fields[nf + 1];
	int col = -1;

	ARGV_t tokens = argvSplitString(str, ":", ARGV_NONE);
	for (ARGV_const_t tok = tokens; tok && *tok; tok++) {
	    fields[++col] = *tok;
	    if (col >= nf)
		break;
	}

	if (col >= nf) {
	    if (rstreq(val, fields[vcol])) {
		*ret = xstrdup(fields[rcol]);
		rc = 0;
	    }
	}
	argvFree(tokens);
    }

    fclose(f);

    return rc;
}

/*
 * Lookup an arbitrary field based on contents of another in a ':' delimited
 * file, such as /etc/passwd or /etc/group. Look at multiple files listed in
 * path separated by colons
 */
static int lookup_field(const char *path, const char *val, int vcol, int rcol,
			char **ret)
{
    ARGV_t paths = argvSplitString(path, ":", ARGV_SKIPEMPTY);
    int rc = -1;
    for (ARGV_t p = paths; *p; p++) {
	rc = lookup_field_in_file(*p, val, vcol, rcol, ret);
	if (!rc)
	    break;
    }
    argvFree(paths);
    return rc;
}

/* atol() with error handling, return 0/-1 on success/failure */
static int stol(const char *s, long *ret)
{
    int rc = 0;
    char *end = NULL;
    long val = strtol(s, &end, 10);

    /* only accept fully numeric data */
    if (*s == '\0' || *end != '\0')
	rc = -1;

    if ((val == LONG_MIN || val == LONG_MAX) && errno == ERANGE)
	rc = -1;

    if (rc == 0)
	*ret = val;

    return rc;
}

static int lookup_num(const char *path, const char *val, int vcol, int rcol,
			long *ret)
{
    char *buf = NULL;
    int rc = lookup_field(path, val, vcol, rcol, &buf);
    if (rc == 0) {
	rc = stol(buf, ret);
	free(buf);
    }
    return rc;
}

static int lookup_str(const char *path, long val, int vcol, int rcol,
			char **ret)
{
    char *vbuf = NULL;
    rasprintf(&vbuf, "%ld", val);
    int rc = lookup_field(path, vbuf, vcol, rcol, ret);
    free(vbuf);
    return rc;
}

static void rpmugInit(void)
{
    if (rpmug_pw == NULL)
	rpmug_pw = new rpmug_s {};
    if (rpmug_grp == NULL)
	rpmug_grp = new rpmug_s {};
}

int rpmugUid(const char * thisUname, uid_t * uid)
{
    if (rstreq(thisUname, UID_0_USER)) {
	*uid = 0;
	return 0;
    }

    rpmugInit();

    auto it = rpmug_pw->nameMap.find(thisUname);
    if (it == rpmug_pw->nameMap.end()) {
	const char *path = pwfile();
	long id;
	if (path) {
	    if (lookup_num(path, thisUname, 0, 2, &id))
		return -1;
	} else {
	    struct passwd *pwent = getpwnam(thisUname);
	    if (pwent == NULL)
		return -1;
	    id = pwent->pw_uid;
	}
	rpmug_pw->nameMap.insert({thisUname, id});
	*uid = id;
    } else {
	*uid = it->second;
    }

    return 0;
}

int rpmugGid(const char * thisGname, gid_t * gid)
{
    if (rstreq(thisGname, GID_0_GROUP)) {
	*gid = 0;
	return 0;
    }

    rpmugInit();

    auto it = rpmug_grp->nameMap.find(thisGname);
    if (it == rpmug_grp->nameMap.end()) {
	const char *path = grpfile();
	long id;
	if (path) {
	    if (lookup_num(path, thisGname, 0, 2, &id))
		return -1;
	} else {
	    struct group *grent = getgrnam(thisGname);
	    if (grent == NULL)
		return -1;
	    id = grent->gr_gid;
	}
	rpmug_grp->nameMap.insert({thisGname, id});
	*gid = id;
    } else {
	*gid = it->second;
    }

    return 0;
}

const char * rpmugUname(uid_t uid)
{
    if (uid == (uid_t) 0)
	return UID_0_USER;

    rpmugInit();

    const char *retname = NULL;
    auto it = rpmug_pw->idMap.find(uid);
    if (it == rpmug_pw->idMap.end()) {
	const char *path = pwfile();
	char *uname = NULL;

	if (path) {
	    if (lookup_str(path, uid, 2, 0, &uname))
		return NULL;
	} else {
	    struct passwd *pwent = getpwuid(uid);
	    if (pwent == NULL)
		return NULL;
	    uname = pwent->pw_name;
	}

	auto res = rpmug_pw->idMap.insert({uid, uname}).first;
	retname = res->second.c_str();
    } else {
	retname = it->second.c_str();
    }
    return retname;
}

const char * rpmugGname(gid_t gid)
{
    if (gid == (gid_t) 0)
	return GID_0_GROUP;

    rpmugInit();

    const char *retname = NULL;
    auto it = rpmug_grp->idMap.find(gid);
    if (it == rpmug_grp->idMap.end()) {
	const char *path = grpfile();
	char *gname = NULL;

	if (path) {
	    if (lookup_str(path, gid, 2, 0, &gname))
		return NULL;
	} else {
	    struct group *grent = getgrgid(gid);
	    if (grent == NULL)
		return NULL;
	    gname = grent->gr_name;
	}

	auto res = rpmug_grp->idMap.insert({gid, gname}).first;
	retname = res->second.c_str();
    } else {
	retname = it->second.c_str();
    }
    return retname;
}

void rpmugFree(void)
{
    if (rpmug_pw) {
	free(rpmug_pw->path);
	delete rpmug_pw;
	rpmug_pw = NULL;
    }
    if (rpmug_grp) {
	free(rpmug_grp->path);
	delete rpmug_grp;
	rpmug_grp = NULL;
    }
}
