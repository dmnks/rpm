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
set(TESTUTILS bwrap cpio diff dnf file readelf)
set(TESTPROGS rpmpgpcheck rpmpgppubkeyfingerprint)
foreach(prg ${TESTPROGS})
	add_executable(${prg} EXCLUDE_FROM_ALL ${prg}.c)
	target_link_libraries(${prg} PRIVATE librpmio)
	set_target_properties(${prg} PROPERTIES
	    RUNTIME_OUTPUT_DIRECTORY image/inst/${CMAKE_INSTALL_PREFIX}/bin)
endforeach()

execute_process(COMMAND lsb_release -is
		OUTPUT_VARIABLE LSB_NAME
		OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND lsb_release -rs
		OUTPUT_VARIABLE LSB_RELEASE
		OUTPUT_STRIP_TRAILING_WHITESPACE)
string(TOLOWER ${LSB_NAME} LSB_NAME)

if (ENABLE_ISOLATION)
    find_program(PODMAN podman docker REQUIRED)
    execute_process(COMMAND ${PODMAN} build -t rpm
		    -f ${CMAKE_SOURCE_DIR}/Dockerfile
		    ${CMAKE_SOURCE_DIR})
    set(PODMAN_RUN ${PODMAN} run -it --rm --privileged
	--volume ${CMAKE_CURRENT_BINARY_DIR}:${CMAKE_CURRENT_BINARY_DIR}:z
	--workdir ${CMAKE_CURRENT_BINARY_DIR} rpm)
else()
    find_program(PODMAN podman)
    execute_process(COMMAND id -u OUTPUT_VARIABLE UID)
    foreach (util ${TESTUTILS})
	find_program(__${UTIL} ${util} REQUIRED)
    endforeach()
    if (${UID} EQUAL 0)
	set(PODMAN_RUN "")
    elseif (PODMAN)
	set(PODMAN_RUN ${PODMAN} unshare)
    else()
	message(FATAL_ERROR "Must be root or ENABLE_ISOLATION")
    endif()
endif()

include(ProcessorCount)
ProcessorCount(nproc)
if (nproc GREATER 1)
	set(JOBS -j${nproc})
endif()

add_custom_target(check
	COMMAND ${PODMAN_RUN} ./rpmtests ${JOBS} $(TESTOPTS)
	DEPENDS rpmtests
)

add_custom_target(rpmtests
	COMMAND ${AUTOTEST} -I ${CMAKE_CURRENT_SOURCE_DIR}
		    -o rpmtests rpmtests.at &&
		cp ${CMAKE_CURRENT_SOURCE_DIR}/data/macros.debug .
	DEPENDS ${TESTSUITE_AT}
	DEPENDS ${TESTPROGS}
	DEPENDS image
)

add_custom_target(image
	COMMAND rm -rf image/inst &&
		${CMAKE_MAKE_PROGRAM} -C ${CMAKE_BINARY_DIR}
		    DESTDIR=${CMAKE_CURRENT_BINARY_DIR}/image/inst install &&
		mkdir -p image/inst/etc/ld.so.conf.d/ &&
		ldconfig -r image/inst ${CMAKE_INSTALL_PREFIX}/lib64 &&
		sed -i 's,^%_dbpath\t.*$$,%_dbpath /usr/lib/sysimage/rpm,'
		    image/inst/${CMAKE_INSTALL_PREFIX}/lib/rpm/macros &&
		cp -r ${CMAKE_CURRENT_SOURCE_DIR}/data image/inst/
	DEPENDS image/base
)

add_custom_command(OUTPUT image/base
	COMMAND ${PODMAN_RUN} ${CMAKE_SOURCE_DIR}/ci/${LSB_NAME}/mktree
		${CMAKE_CURRENT_BINARY_DIR}/image/base ${LSB_RELEASE}
)
