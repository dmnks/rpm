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
	    RUNTIME_OUTPUT_DIRECTORY destdir/${CMAKE_INSTALL_PREFIX}/bin)
endforeach()

execute_process(COMMAND lsb_release -is
		OUTPUT_VARIABLE LSB_NAME
		OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND lsb_release -rs
		OUTPUT_VARIABLE LSB_RELEASE
		OUTPUT_STRIP_TRAILING_WHITESPACE)
string(TOLOWER ${LSB_NAME} LSB_NAME)

find_program(BWRAP bwrap REQUIRED)
find_program(UNSHARE unshare REQUIRED)
set(UNSHARE unshare -rm --map-auto)

set(TREEDIR ${CMAKE_CURRENT_BINARY_DIR}/tree)
string(REPLACE ";" " " UNSHARE_CMD "${UNSHARE}")
configure_file(mktree.${LSB_NAME} mktree @ONLY)

if (ENABLE_SANDBOX)
    set(UNSHARE ${UNSHARE} ${BWRAP}
	--cap-add ALL
	--ro-bind ${TREEDIR} /
	--bind ${CMAKE_CURRENT_BINARY_DIR} /srv
	--dev /dev --proc /proc
	--chdir /srv)
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
	DEPENDS rpmtests
)

add_custom_target(rpmtests
	COMMAND ${AUTOTEST} -I ${CMAKE_CURRENT_SOURCE_DIR}
		    -o rpmtests rpmtests.at &&
		cp ${CMAKE_CURRENT_SOURCE_DIR}/data/macros.debug . &&
		cp -r ${CMAKE_CURRENT_SOURCE_DIR}/data destdir/
	DEPENDS ${TESTSUITE_AT}
	DEPENDS ${TESTPROGS}
	DEPENDS tree
)

add_custom_target(tree
	COMMAND rm -rf destdir/ &&
		${CMAKE_MAKE_PROGRAM} -C ${CMAKE_BINARY_DIR}
		    DESTDIR=${CMAKE_CURRENT_BINARY_DIR}/destdir install &&
		mkdir -p destdir/etc &&
		ldconfig -r destdir ${CMAKE_INSTALL_PREFIX}/lib64
	DEPENDS ${TREEDIR}
)

add_custom_command(OUTPUT ${TREEDIR}
	COMMAND ./mktree
)
