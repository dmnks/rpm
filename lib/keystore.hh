#ifndef _KEYSTORE_H
#define _KEYSTORE_H

#include <string>

#include <rpm/rpmtypes.h>
#include <rpm/rpmutil.h>

namespace rpm {

class keystore {
public:
    virtual rpmRC load_keys(rpmtxn txn, rpmKeyring keyring) = 0;
    virtual rpmRC import_key(rpmtxn txn, rpmPubkey key, int replace = 1, rpmFlags flags = 0) = 0;
    virtual rpmRC delete_key(rpmtxn txn, rpmPubkey key) = 0;
    virtual rpmRC delete_store(rpmtxn txn) = 0;

    virtual ~keystore() = default;
};

class keystore_fs : public keystore {
public:
    virtual rpmRC load_keys(rpmtxn txn, rpmKeyring keyring);
    virtual rpmRC import_key(rpmtxn txn, rpmPubkey key, int replace = 1, rpmFlags flags = 0);
    virtual rpmRC delete_key(rpmtxn txn, rpmPubkey key);
    virtual rpmRC delete_store(rpmtxn txn);
private:
    rpmRC delete_key(rpmtxn txn, const std::string & keyid, const std::string & newname = "");
};

class keystore_rpmdb : public keystore {
public:
    virtual rpmRC load_keys(rpmtxn txn, rpmKeyring keyring);
    virtual rpmRC import_key(rpmtxn txn, rpmPubkey key, int replace = 1, rpmFlags flags = 0);
    virtual rpmRC delete_key(rpmtxn txn, rpmPubkey key);
    virtual rpmRC delete_store(rpmtxn txn);
private:
    rpmRC delete_key(rpmtxn txn, const std::string & keyid, unsigned int newinstance = 0);
};

class keystore_openpgp_cert_d : public keystore {
public:
    virtual rpmRC load_keys(rpmtxn txn, rpmKeyring keyring);
    virtual rpmRC import_key(rpmtxn txn, rpmPubkey key, int replace = 1, rpmFlags flags = 0);
    virtual rpmRC delete_key(rpmtxn txn, rpmPubkey key);
    virtual rpmRC delete_store(rpmtxn txn);
};

RPM_GNUC_INTERNAL
keystore *getKeystore(const char * krtype);

}; /* namespace */

#endif /* _KEYSTORE_H */
