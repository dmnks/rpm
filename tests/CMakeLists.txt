set(SANDBOX_DIR sandbox.dir)
set(CONTAINER_DIR ${SANDBOX_DIR}/container)
set(IMAGE_DIR ${SANDBOX_DIR}/image)
set(TREE_DIR ${IMAGE_DIR}/tree)
set(INST_DIR ${IMAGE_DIR}/inst)
set(UTIL_DIR ${IMAGE_DIR}/util)
set(DATA_DIR ${UTIL_DIR}/data)

set(MACRO_DIR ${RPMCONFIGDIR}/macros.d)
set(LD_CONF_DIR ${INST_DIR}/${CMAKE_INSTALL_SYSCONFDIR}/ld.so.conf.d)

set(pyexecdir ${Python3_SITEARCH})
set(usrbindir ${CMAKE_INSTALL_FULL_BINDIR})
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
endforeach()

find_program(LSB lsb_release REQUIRED)
execute_process(COMMAND ${LSB} -is
		OUTPUT_VARIABLE LSB_NAME
		OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND ${LSB} -rs
		OUTPUT_VARIABLE LSB_RELEASE
		OUTPUT_STRIP_TRAILING_WHITESPACE)
string(TOLOWER ${LSB_NAME} LSB_NAME)

find_program(BWRAP bwrap REQUIRED)
execute_process(COMMAND id -u OUTPUT_VARIABLE UID)
if (${UID} EQUAL 0)
	set(UNSHARE_CMD "")
elseif(EXISTS /run/.toolboxenv)
	set(UNSHARE_CMD "sudo")
else()
	find_program(UNSHARE unshare REQUIRED)
	set(UNSHARE_CMD "${UNSHARE} -rm --map-auto")
endif()

configure_file(sandbox.in sandbox @ONLY)
configure_file(mktree.${LSB_NAME} mktree @ONLY)

include(ProcessorCount)
ProcessorCount(nproc)
if (nproc GREATER 1)
	set(JOBS -j${nproc})
endif()

add_custom_target(check
	COMMAND MOUNTARGS=-r ./sandbox ./rpmtests ${JOBS} $(TESTOPTS)
	DEPENDS tests
)

add_custom_target(shell
	COMMAND ./sandbox env "PS1=(shell) \\W# " sh
	VERBATIM
	DEPENDS tests
)

add_custom_target(env
	COMMAND ./sandbox
	DEPENDS tests
)

add_custom_target(tests
	DEPENDS suite
	DEPENDS image
)

add_custom_target(suite
	DEPENDS rpmtests
	DEPENDS ${TESTPROGS}
	DEPENDS ${DATA_DIR}
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
	COMMAND rm -rf ${DATA_DIR} &&
		cp -r ${CMAKE_CURRENT_SOURCE_DIR}/data ${UTIL_DIR}/ &&
		mkdir -p ${UTIL_DIR}/{build,${MACRO_DIR}} &&
		ln -sf /data/SOURCES ${UTIL_DIR}/build/ &&
		ln -sf /data/macros.test ${UTIL_DIR}/${MACRO_DIR}/
	DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/data
)

add_custom_command(OUTPUT ${INST_DIR}
	COMMAND rm -rf ${INST_DIR} &&
		${CMAKE_MAKE_PROGRAM} -C ${CMAKE_BINARY_DIR}
		DESTDIR=${CMAKE_CURRENT_BINARY_DIR}/${INST_DIR} install &&
		mkdir -p ${LD_CONF_DIR} &&
		echo ${CMAKE_INSTALL_FULL_LIBDIR} > ${LD_CONF_DIR}/rpm.conf &&
		ldconfig -r ${INST_DIR} ${CMAKE_INSTALL_FULL_LIBDIR}
	DEPENDS ${TOP_TARGETS}
)

add_custom_command(OUTPUT ${TREE_DIR}
	COMMAND rm -rf ${TREE_DIR} &&
		./mktree
	DEPENDS mktree
)
