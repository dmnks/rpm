set(DOCKERFILE ${CMAKE_CURRENT_SOURCE_DIR}/Dockerfile.${OS_NAME})

find_program(PODMAN podman)
find_program(DOCKER docker)
mark_as_advanced(PODMAN DOCKER)

if (MKTREE_CONTAINER)
	set(MKTREE_MODE isolated)
	set(PODMAN podman)
	configure_file(mktree.rootfs mktree.rootfs)
elseif (PODMAN AND EXISTS ${DOCKERFILE})
	set(MKTREE_MODE native)
	configure_file(${DOCKERFILE} Dockerfile COPYONLY)
	add_custom_target(ci
		COMMAND ./mktree.oci build
		COMMAND ./mktree.oci shell --volatile
			rpmtests --log ${JOBS} $(TESTOPTS)
		WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	)
else()
	set(MKTREE_MODE standalone)
	configure_file(Dockerfile Dockerfile COPYONLY)
	find_program(PODMAN NAMES podman docker REQUIRED)
endif()
