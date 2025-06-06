#ifndef _RPMFILEUTIL_H
#define _RPMFILEUTIL_H

/** \ingroup rpmfileutil rpmio
 * \file rpmfileutil.h
 * File and path manipulation helper functions.
 */

#include <rpm/rpmutil.h>
#include <rpm/rpmio.h>
#include <rpm/argv.h>

#ifdef __cplusplus
extern "C" {
#endif

/** \ingroup rpmfileutil
 * Compression types detected by rpm (subject to build configuration).
 */
typedef enum rpmCompressedMagic_e {
    COMPRESSED_NOT		= 0,	/*!< not compressed */
    COMPRESSED_OTHER		= 1,	/*!< gzip can handle */
    COMPRESSED_BZIP2		= 2,	/*!< bzip2 can handle */
    COMPRESSED_ZIP		= 3,	/*!< unzip can handle */
    COMPRESSED_LZMA		= 4,	/*!< lzma can handle */
    COMPRESSED_XZ		= 5,	/*!< xz can handle */
    COMPRESSED_LZIP		= 6,	/*!< lzip can handle */
    COMPRESSED_LRZIP		= 7,	/*!< lrzip can handle */
    COMPRESSED_7ZIP		= 8,	/*!< 7zip can handle */
    COMPRESSED_GEM		= 9,	/*!< gem can handle */
    COMPRESSED_ZSTD		= 10	/*!< zstd can handle */
} rpmCompressedMagic;

/** \ingroup rpmfileutil
 * RPM glob flags, largely modelled after glob(3) flags.
 */
enum rpmglobFlags_e {
    RPMGLOB_NONE		= 0,
    RPMGLOB_NOCHECK		= (1 << 0), /*!< same as GLOB_NOCHECK */
};

typedef rpmFlags rpmglobFlags;

/** \ingroup rpmfileutil
 * Calculate a file digest and size.
 * @param algo		digest algorithm
 * @param fn		file name
 * @param asAscii	return digest as ascii string?
 * @param[out] digest	address of calculated digest
 * @return		0 on success, 1 on error
 */
int rpmDoDigest(int algo, const char * fn,int asAscii, unsigned char * digest);

/** \ingroup rpmfileutil
 * Thin wrapper for mkstemp(3). 
 * @param templ			template for temporary filename
 * @return 			file handle or NULL on error
 */
FD_t rpmMkTemp(char *templ);

/** \ingroup rpmfileutil
 * Return file handle for a temporaray file.
 * A unique temporaray file path will be created in
 * [prefix/]%{_tmppath} directory.
 * The file name and the open file handle are returned.
 *
 * @param prefix	leading part of temp file path
 * @param[out] fn		temp file name (or NULL)
 * @return fdptr	open file handle or NULL on error
 */
FD_t rpmMkTempFile(const char * prefix, char **fn);

/** \ingroup rpmfileutil
 * Insure that directories in path exist, creating as needed.
 * @param path		directory path
 * @param mode		directory mode (if created)
 * @param uid		directory uid (if created), or -1 to skip
 * @param gid		directory uid (if created), or -1 to skip
 * @return		0 on success, errno (or -1) on error
 */
int rpmioMkpath(const char * path, mode_t mode, uid_t uid, gid_t gid);

/** \ingroup rpmfileutil
 * Create several directories (including parents if needed) in one go.
 * Macros in pathstr will be expanded in the process.
 * @param root		leading root directory (or NULL for none)
 * @param pathstr	list of directories separated with :
 * @return		0 if all directories were successfully created
 * 			(or already existed), non-zero otherwise
 */
int rpmMkdirs(const char *root, const char *pathstr);

/** \ingroup rpmfileutil
 * Canonicalize file path.
 * @param path		path to canonicalize (in-place)
 * @return		pointer to path
 */
char * rpmCleanPath	(char * path);

/** \ingroup rpmfileutil
 * Merge 3 args into path.
 * Contrary to what the argument names and older API docs claim,
 * THIS DOES NOT HANDLE URL's.
 * @param urlroot	root URL (often path to chroot, or NULL)
 * @param urlmdir	directory URL (often a directory, or NULL)
 * @param urlfile	file URL (often a file, or NULL)
 * @return		expanded, merged, canonicalized path (malloc'ed)
 */
char * rpmGenPath	(const char * urlroot,
			const char * urlmdir,
			const char * urlfile);

/** \ingroup rpmfileutil
 * Return (malloc'ed) expanded, canonicalized, file path.
 * @param path		macro(s) to expand (NULL terminates list)
 * @return		canonicalized path (malloc'ed)
 */
char * rpmGetPath (const char * path, ...) RPM_GNUC_NULL_TERMINATED;

/** \ingroup rpmfileutil
 * Expand a glob pattern into matching paths.
 * When RPMGLOB_NOCHECK is specified, non-matching and non-glob patterns
 * are returned as is.
 * @param pattern	glob pattern
 * @param flags		bit(s) to control glob operation
 * @param[out] *argcPtr	no. of paths
 * @param[out] *argvPtr	ARGV_t array of paths
 * @return		0 on success
 */
int rpmGlobPath(const char * pattern, rpmglobFlags flags,
		int * argcPtr, ARGV_t * argvPtr);

/** \ingroup rpmfileutil
 * Expand a glob pattern into matching paths, fail if nothing matches.
 * @param pattern	glob pattern
 * @param[out] *argcPtr	no. of paths
 * @param[out] *argvPtr	ARGV_t array of paths
 * @return		0 on success
 */
int rpmGlob(const char * pattern, int * argcPtr, ARGV_t * argvPtr);

/** \ingroup rpmfileutil
 * Escape isspace(3) characters in string.
 * @param s             string
 * @return              escaped string
 */
char * rpmEscapeSpaces(const char * s);

/** \ingroup rpmfileutil
 * Escape given characters in string.
 * @param s             string
 * @param accept        chars to escape
 * @return              escaped string
 */
char * rpmEscape(const char *s, const char *accept);

/** \ingroup rpmfileutil
 * Unescape each char listed in accept by removing a backslash preceding it.
 * @param s		string
 * @param accept	chars to unescape (NULL for all)
 */
void rpmUnescape(char *s, const char *accept);

/** \ingroup rpmfileutil
 * Return type of compression used in file.
 * @param file		name of file
 * @param[out] compressed	address of compression type
 * @return		0 on success, 1 on I/O error
 */
int rpmFileIsCompressed (const char * file, rpmCompressedMagic * compressed);

/** \ingroup rpmfileutil
 * Check if path (string) ends with given suffix
 * @param path		(path) string
 * @param suffix	suffix string to check for
 * @return		1 if true, 0 otherwise
 */
int rpmFileHasSuffix(const char *path, const char *suffix);

/** \ingroup rpmfileutil
 * Like getcwd() but the result is malloced.
 * @return              current working directory (malloc'ed)
 */
char * rpmGetCwd(void);

#ifdef __cplusplus
}
#endif
#endif /* _RPMFILEUTIL_H */
