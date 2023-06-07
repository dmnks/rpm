set(SANDBOX_DIR sandbox.dir)
set(CONTAINER_DIR ${SANDBOX_DIR}/container)
set(IMAGE_DIR ${SANDBOX_DIR}/image)
set(TREE_DIR ${IMAGE_DIR}/tree)
set(INST_DIR ${IMAGE_DIR}/inst)
set(UTIL_DIR ${IMAGE_DIR}/util)
set(DATA_DIR ${UTIL_DIR}/data)

set(MACRO_DIR ${RPMCONFIGDIR}/macros.d)
set(LD_CONF_DIR ${INST_DIR}/${CMAKE_INSTALL_SYSCONFDIR}/ld.so.conf.d)

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

find_program(AUTOM4TE autom4te REQUIRED)
set(AUTOTEST ${AUTOM4TE} --language=autotest)
set(TESTPROGS rpmpgpcheck rpmpgppubkeyfingerprint)
foreach(prg ${TESTPROGS})
	add_executable(${prg} EXCLUDE_FROM_ALL ${prg}.c)
	target_link_libraries(${prg} PRIVATE librpmio)
	set_target_properties(${prg} PROPERTIES
		RUNTIME_OUTPUT_DIRECTORY ${UTIL_DIR}/usr/bin)
	add_custom_command(TARGET ${prg} PRE_BUILD
		COMMAND mkdir -p ${UTIL_DIR}/usr/bin)
endforeach()

execute_process(COMMAND sh -c "grep ^ID /etc/os-release | cut -d= -f2"
		OUTPUT_VARIABLE OS_NAME
		OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND sh -c "grep ^VERSION_ID /etc/os-release | cut -d= -f2"
		OUTPUT_VARIABLE OS_VERSION
		OUTPUT_STRIP_TRAILING_WHITESPACE)
string(TOLOWER ${OS_NAME} OS_NAME)

find_program(BWRAP bwrap REQUIRED)
find_program(ID id REQUIRED)
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
configure_file(sandbox.in sandbox @ONLY)
configure_file(mktree.${OS_NAME} mktree @ONLY)

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
	DEPENDS image
)

add_custom_target(reset
	COMMAND ${UNSHARE} rm -rf ${CONTAINER_DIR}
)

add_custom_target(env
	COMMAND ./sandbox
	DEPENDS tests
)

add_custom_target(tests
	DEPENDS rpmtests
	DEPENDS ${TESTPROGS}
	DEPENDS ${DATA_DIR}
	DEPENDS image
)

add_custom_target(image
	DEPENDS ${INST_DIR}
	DEPENDS ${TREE_DIR}
)

add_custom_command(OUTPUT rpmtests
	COMMAND ${AUTOTEST} -I ${CMAKE_CURRENT_SOURCE_DIR}
		-o rpmtests rpmtests.at
	DEPENDS ${TESTSUITE_AT}
	DEPENDS local.at
)

add_custom_command(OUTPUT ${DATA_DIR}
	COMMAND rm -rf ${DATA_DIR}
	COMMAND cp -r ${CMAKE_CURRENT_SOURCE_DIR}/data ${UTIL_DIR}/
	COMMAND mkdir -p ${UTIL_DIR}/{build,${MACRO_DIR}}
	COMMAND ln -sf /data/SOURCES ${UTIL_DIR}/build/
	COMMAND ln -sf /data/macros.test ${UTIL_DIR}/${MACRO_DIR}/
	DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/data
)

add_custom_command(OUTPUT ${INST_DIR}
	COMMAND rm -rf ${INST_DIR}
	COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_BINARY_DIR}
		DESTDIR=${CMAKE_CURRENT_BINARY_DIR}/${INST_DIR} install
	COMMAND mkdir -p ${LD_CONF_DIR}
	COMMAND echo ${CMAKE_INSTALL_FULL_LIBDIR} > ${LD_CONF_DIR}/rpm.conf
	COMMAND ldconfig -r ${INST_DIR} ${CMAKE_INSTALL_FULL_LIBDIR}
	DEPENDS ${TOP_TARGETS}
)

add_custom_command(OUTPUT ${TREE_DIR}
	COMMAND ${UNSHARE} rm -rf ${TREE_DIR}
	COMMAND ./mktree
	DEPENDS mktree
)
