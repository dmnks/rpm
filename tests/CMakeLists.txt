set(RPM_TARGETS librpm librpmio librpmbuild librpmsign)

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

find_program(AUTOM4TE autom4te REQUIRED)
set(AUTOTEST ${AUTOM4TE} --language=autotest)

set(TESTPROGS rpmpgpcheck rpmpgppubkeyfingerprint)
foreach(prg ${TESTPROGS})
	add_executable(${prg} EXCLUDE_FROM_ALL ${prg}.c)
	target_link_libraries(${prg} PRIVATE librpmio)
endforeach()
string(REPLACE ";" " " TESTPROG_NAMES "${TESTPROGS}")

include(ProcessorCount)
ProcessorCount(nproc)
if (nproc GREATER 1)
	set(JOBS -j${nproc})
endif()

set(OS_NAME opensuse)
# Set up mktree
find_program(BWRAP bwrap REQUIRED)
if ("${MKTREE_BACKEND}" STREQUAL "")
	set(MKTREE_BACKEND podman)
endif()
message(STATUS "Using mktree backend: ${MKTREE_BACKEND}")
if ("${MKTREE_BACKEND}" STREQUAL "podman")
	find_program(PODMAN podman REQUIRED)
	if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Dockerfile.${OS_NAME})
		# Native build mode
		set(MKTREE_NATIVE 1)
		configure_file(Dockerfile.${OS_NAME} Dockerfile COPYONLY)
	else()
		# Containerized build mode
		set(MKTREE_NATIVE 0)
		configure_file(Dockerfile Dockerfile COPYONLY)
		message(WARNING
			"Native build integration with test-suite is not "
			"available on this platform, falling back to "
			"containerized building.")
	endif()
	configure_file(mktree.native mktree.native @ONLY)
	set(MKTREE_BUILD_DEPS Dockerfile)
endif()
configure_file(mktree.${MKTREE_BACKEND} mktree @ONLY)

configure_file(atlocal.in atlocal @ONLY)
configure_file(package.m4.in package.m4 @ONLY)
configure_file(snapshot snapshot COPYONLY)

add_custom_target(check
	COMMAND ./mktree check ${JOBS} $(TESTOPTS)
	DEPENDS mktree.dir/full
)

# add_custom_target(ci
# 	COMMAND ./mktree.podman build
# 	COMMAND ./mktree.podman check ${JOBS} $(TESTOPTS)
# 	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
# )

add_custom_target(shell
	COMMAND ./mktree shell ||:
	DEPENDS mktree.dir/base
)

add_custom_target(atshell
	COMMAND ./mktree atshell ||:
	DEPENDS mktree.dir/base
)

add_custom_target(reset
	COMMAND ./mktree reset
)

add_custom_target(tree
	DEPENDS mktree.dir/full
)

add_custom_command(OUTPUT rpmtests
	COMMAND ${AUTOTEST} -I ${CMAKE_CURRENT_SOURCE_DIR}
		-o rpmtests rpmtests.at
	DEPENDS ${TESTSUITE_AT}
	DEPENDS local.at
)

add_custom_command(OUTPUT mktree.dir/base
	COMMAND ./mktree build --base
	DEPENDS ${MKTREE_BUILD_DEPS}
)

add_custom_command(OUTPUT mktree.dir/full
	COMMAND ./mktree build
	DEPENDS ${MKTREE_BUILD_DEPS}
	DEPENDS rpmtests
	DEPENDS ${TESTPROGS}
	DEPENDS ${RPM_TARGETS}
)
