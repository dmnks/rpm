# Use our top-level targets as an ordering clue to cmake: the project
# needs to be built before we can populate anything...
get_property(TOP_TARGETS DIRECTORY .. PROPERTY BUILDSYSTEM_TARGETS)

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

find_program(FAKECHROOT fakechroot REQUIRED)
find_program(UNSHARE unshare REQUIRED)
find_program(AUTOM4TE autom4te REQUIRED)
set(AUTOTEST ${AUTOM4TE} --language=autotest)

set(TESTPROGS rpmpgpcheck rpmpgppubkeyfingerprint)
foreach(prg ${TESTPROGS})
	add_executable(${prg} EXCLUDE_FROM_ALL ${prg}.c)
	target_link_libraries(${prg} PRIVATE librpmio)
endforeach()

# Detect suitable OS-specific script
if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/mktree.${OS_NAME})
	message(WARNING
		"Your OS is not supported by the test suite, disabling.")
	return()
endif()

configure_file(atlocal.in atlocal @ONLY)
configure_file(package.m4.in package.m4 @ONLY)
configure_file(mktree.in mktree @ONLY)
configure_file(mktree.${OS_NAME} mktree.${OS_NAME} @ONLY)

include(ProcessorCount)
ProcessorCount(nproc)
if (nproc GREATER 1)
	set(JOBS -j${nproc})
endif()

add_custom_target(check
	COMMAND ./mktree check ${JOBS} $(TESTOPTS)
	DEPENDS tree
)

add_custom_target(reset
	COMMAND ./mktree reset
)

add_custom_command(OUTPUT rpmtests
	COMMAND ${AUTOTEST} -I ${CMAKE_CURRENT_SOURCE_DIR}
		-o rpmtests rpmtests.at
	DEPENDS ${TESTSUITE_AT}
	DEPENDS local.at
)

add_custom_target(tree
	COMMAND ./mktree build
	BYPRODUCTS mktree.output
	DEPENDS rpmtests
	DEPENDS ${TESTPROGS}
	DEPENDS ${TOP_TARGETS}
)
