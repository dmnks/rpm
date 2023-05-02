set(PYTHON ${Python3_EXECUTABLE})
set(prefix ${CMAKE_INSTALL_PREFIX})
set(pyexecdir ${Python3_SITEARCH})
set(usrbindir ${CMAKE_INSTALL_FULL_BINDIR})
set(usrlibdir ${CMAKE_INSTALL_FULL_LIBDIR})
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

set(BASE_DIR ${CMAKE_CURRENT_BINARY_DIR}/base)
set(TREE_DIR ${BASE_DIR}/tree)
set(INST_DIR ${BASE_DIR}/inst)
set(UTIL_DIR ${BASE_DIR}/util)
set(DATA_DIR ${UTIL_DIR}/data)

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
	set(UNSHARE "")
elseif(EXISTS /run/.toolboxenv)
	set(UNSHARE sudo)
else()
	find_program(UNSHARE unshare REQUIRED)
	set(UNSHARE ${UNSHARE} -rm --map-auto)
endif()

string(REPLACE ";" " " UNSHARE_CMD "${UNSHARE}")
configure_file(mktree.${LSB_NAME} mktree @ONLY)

if (ENABLE_SANDBOX)
	set(UNSHARE ${UNSHARE} ${BWRAP}
	    --ro-bind ${TREE_DIR} /
	    --bind ${CMAKE_CURRENT_BINARY_DIR} /srv --chdir /srv
	    --dev /dev --proc /proc)
else()
	foreach (util cpio diff file gzip mount readelf tar)
		find_program(__${UTIL} ${util} REQUIRED)
	endforeach()
endif()

include(ProcessorCount)
ProcessorCount(nproc)
if (nproc GREATER 1)
	set(JOBS -j${nproc})
endif()

add_custom_target(check
	COMMAND ${UNSHARE} ./rpmtests ${JOBS} $(TESTOPTS)
	DEPENDS testsuite
	DEPENDS testimage
)

add_custom_target(testenv
	COMMAND ${UNSHARE} env "PS1='(testenv)#" "'" sh || true
)

add_custom_target(testsuite
	DEPENDS rpmtests
	DEPENDS ${TESTPROGS}
	DEPENDS ${DATA_DIR}
)

add_custom_target(testimage
	DEPENDS ${INST_DIR}
	DEPENDS ${TREE_DIR}
)

add_custom_command(OUTPUT rpmtests
	COMMAND ${AUTOTEST} -I ${CMAKE_CURRENT_SOURCE_DIR}
		-o rpmtests rpmtests.at
	DEPENDS ${TESTSUITE_AT}
)

add_custom_command(OUTPUT ${DATA_DIR}
	COMMAND rm -rf ${DATA_DIR} &&
		mkdir -p ${DATA_DIR} &&
		cp -r ${CMAKE_CURRENT_SOURCE_DIR}/data ${UTIL_DIR}/
	DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/data
)

add_custom_command(OUTPUT ${INST_DIR}
	COMMAND rm -rf ${INST_DIR} &&
		${CMAKE_MAKE_PROGRAM} -C ${CMAKE_BINARY_DIR}
		DESTDIR=${INST_DIR} install &&
		mkdir -p ${INST_DIR}/etc &&
		ldconfig -r ${INST_DIR} ${CMAKE_INSTALL_PREFIX}/lib64
	DEPENDS ${TOP_TARGETS}
)

add_custom_command(OUTPUT ${TREE_DIR}
	COMMAND rm -rf ${TREE_DIR} && ./mktree
	DEPENDS mktree
)
