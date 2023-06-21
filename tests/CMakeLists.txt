set(TREE_DIR mktree.output)
set(BASE_DIR ${TREE_DIR}/base)
set(INST_DIR ${TREE_DIR}/inst)
set(UTIL_DIR ${TREE_DIR}/util)
set(SANDBOX_DIR sandbox.default)

set(MACRO_DIR ${RPMCONFIGDIR}/macros.d)
set(LD_CONF_DIR ${INST_DIR}/${CMAKE_INSTALL_SYSCONFDIR}/ld.so.conf.d)
set(PROFILE_DIR ${INST_DIR}/${CMAKE_INSTALL_SYSCONFDIR}/profile.d)

set(PYTHON ${Python3_EXECUTABLE})
if (${WITH_INTERNAL_OPENPGP})
	if (${WITH_OPENSSL})
		set(CRYPTO openssl)
	else()
		set(CRYPTO libgcrypt)
	endif()
else()
	set(CRYPTO sequoia)
endif()

execute_process(COMMAND sh -c "grep ^ID /etc/os-release | cut -d= -f2"
		OUTPUT_VARIABLE OS_NAME
		OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND sh -c "grep ^VERSION_ID /etc/os-release | cut -d= -f2"
		OUTPUT_VARIABLE OS_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE)
string(TOLOWER ${OS_NAME} OS_NAME)

execute_process(COMMAND ${ID} -u OUTPUT_VARIABLE UID)
if (${UID} EQUAL 0)
	set(UNSHARE "")
elseif(EXISTS /run/.toolboxenv)
	set(UNSHARE sudo -E)
else()
	find_program(UNSHARE unshare REQUIRED)
	set(UNSHARE ${UNSHARE} -rm --map-auto)
endif()
string(REPLACE ";" " " UNSHARE_CMD "${UNSHARE}")

configure_file(atlocal.in atlocal @ONLY)
configure_file(atconfig.in atconfig @ONLY)
configure_file(package.m4.in package.m4 @ONLY)

get_property(TOP_TARGETS DIRECTORY .. PROPERTY BUILDSYSTEM_TARGETS)

set(TESTSUITE_AT
	rpmtests.at
	rpmgeneral.at
	rpmquery.at
	rpmverify.at
	rpmdb.at
	rpmbuild.at
	rpmbuildid.at
	rpmi.at
	rpme.at
	rpmvercmp.at
	rpmdeps.at
	rpmconflict.at
	rpmconfig.at
	rpmconfig2.at
	rpmconfig3.at
	rpmreplace.at
	rpmmacro.at
	rpmpython.at
	rpmdepmatch.at
	rpmscript.at
	rpmsigdig.at
	rpmspec.at
	rpmio.at
	rpmorder.at
	rpmvfylevel.at
	rpmpgp.at
)

set(AUTOTEST ${AUTOM4TE} --language=autotest)

set(TESTPROGS rpmpgpcheck rpmpgppubkeyfingerprint)
foreach(prg ${TESTPROGS})
	add_executable(${prg} EXCLUDE_FROM_ALL ${prg}.c)
	target_link_libraries(${prg} PRIVATE librpmio)
endforeach()
string(REPLACE ";" " " TESTPROGS_STR "${TESTPROGS}")

configure_file(sandbox.in sandbox @ONLY)
configure_file(mktree.in mktree @ONLY)
configure_file(mktree.${OS_NAME} mktree.${OS_NAME} @ONLY)

include(ProcessorCount)
ProcessorCount(nproc)
if (nproc GREATER 1)
	set(JOBS -j${nproc})
endif()

add_custom_target(check
	COMMAND ./sandbox shell --read-only ./rpmtests ${JOBS} $(TESTOPTS)
	DEPENDS tests
)

add_custom_target(shell
	COMMAND ./sandbox shell
	DEPENDS tree
)

add_custom_target(reset
	COMMAND ${UNSHARE} rm -rf ${SANDBOX_DIR}
)

add_custom_target(env
	COMMAND ./sandbox
	DEPENDS tests
)

add_custom_target(tests
	DEPENDS rpmtests
	DEPENDS ${UTIL_DIR}
	DEPENDS tree
)

add_custom_target(tree
	DEPENDS ${BASE_DIR}
	DEPENDS ${INST_DIR}
)

add_custom_command(OUTPUT rpmtests
	COMMAND ${AUTOTEST} -I ${CMAKE_CURRENT_SOURCE_DIR}
		-o rpmtests rpmtests.at
	DEPENDS ${TESTSUITE_AT}
	DEPENDS local.at
)

add_custom_command(OUTPUT ${BASE_DIR}
	COMMAND ./mktree base
	DEPENDS mktree.${OS_NAME}
	DEPENDS mktree.in
)

add_custom_command(OUTPUT ${INST_DIR}
	COMMAND ./mktree inst
	DEPENDS ${TOP_TARGETS}
	DEPENDS mktree.in
)

add_custom_command(OUTPUT ${UTIL_DIR}
	COMMAND ./mktree util
	DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/data
	DEPENDS ${TESTPROGS}
	DEPENDS mktree.in
)
