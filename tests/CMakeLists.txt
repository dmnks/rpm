set(TREE_DIR mktree.output)
set(BASE_DIR ${TREE_DIR}/base)
set(INST_DIR ${TREE_DIR}/inst)
set(UTIL_DIR ${TREE_DIR}/util)

set(SANDBOX_DIR mktree.sandbox)

set(MACRO_DIR ${RPMCONFIGDIR}/macros.d)
set(LD_CONF_DIR ${INST_DIR}/${CMAKE_INSTALL_SYSCONFDIR}/ld.so.conf.d)
set(PROFILE_DIR ${INST_DIR}/${CMAKE_INSTALL_SYSCONFDIR}/profile.d)

function(os_release var key)
	execute_process(
		COMMAND sh -c "grep ^${key} /etc/os-release | cut -d= -f2"
		OUTPUT_STRIP_TRAILING_WHITESPACE
		OUTPUT_VARIABLE value
	)
	string(TOLOWER ${value} value)
	set(${var} ${value} PARENT_SCOPE)
endfunction()

os_release(OS_NAME ID)
os_release(OS_VERSION VERSION_ID)

execute_process(COMMAND ${ID} -u OUTPUT_VARIABLE UID)
if (${UID} EQUAL 0)
	set(UNSHARE "")
elseif(EXISTS /run/.toolboxenv)
	set(UNSHARE "sudo -E")
else()
	find_program(UNSHARE unshare REQUIRED)
	set(UNSHARE "${UNSHARE} -rm --map-auto")
endif()

get_property(TOP_TARGETS DIRECTORY .. PROPERTY BUILDSYSTEM_TARGETS)

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

configure_file(atlocal.in atlocal @ONLY)
configure_file(package.m4.in package.m4 @ONLY)

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

configure_file(mktree.common mktree.common @ONLY)
configure_file(mktree.bwrap mktree.bwrap COPYONLY)
if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/mktree.${OS_NAME})
	message(FATAL_ERROR
	"Native test suite support (mktree.${OS_NAME} file) not available "
	"for your OS. Please re-run CMake with ENABLE_TESTSUITE=OFF "
	"and consider ENABLE_CI=ON.")
endif()
configure_file(mktree.${OS_NAME} mktree.${OS_NAME} @ONLY)

include(ProcessorCount)
ProcessorCount(nproc)
if (nproc GREATER 1)
	set(JOBS -j${nproc})
endif()

add_custom_target(check
	COMMAND buildah unshare ./mktree shell ./rpmtests ${JOBS} $(TESTOPTS)
	# COMMAND ./mktree shell --read-only ./rpmtests ${JOBS} $(TESTOPTS)
	DEPENDS tests
)

add_custom_target(shell
	COMMAND buildah unshare ./mktree shell
	DEPENDS tree
)

add_custom_target(env
	COMMAND buildah unshare ./mktree env
	DEPENDS tests
)

add_custom_target(tests
	DEPENDS rpmtests
	DEPENDS tree
)

add_custom_command(OUTPUT rpmtests
	COMMAND ${AUTOTEST} -I ${CMAKE_CURRENT_SOURCE_DIR}
		-o rpmtests rpmtests.at
	DEPENDS ${TESTSUITE_AT}
	DEPENDS local.at
)

add_custom_target(tree
	COMMAND buildah unshare ./mktree build
	COMMAND buildah unshare ./mktree install
	DEPENDS ${TOP_TARGETS}
	DEPENDS ${TESTPROGS}
)
