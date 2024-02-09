set(DOCKERFILE ${CMAKE_CURRENT_SOURCE_DIR}/Dockerfile.${OS_NAME})

find_program(PODMAN podman)
find_program(DOCKER docker)
mark_as_advanced(PODMAN DOCKER)

if (PODMAN AND EXISTS ${DOCKERFILE})
        set(MKTREE_NATIVE yes)
        configure_file(${DOCKERFILE} Dockerfile COPYONLY)
        add_custom_target(ci
                COMMAND ./mktree.oci build
                COMMAND ./mktree.oci check ${JOBS} $(TESTOPTS)
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
else()
        set(MKTREE_NATIVE no)
        configure_file(Dockerfile Dockerfile COPYONLY)
endif()

find_program(PODMAN NAMES podman docker REQUIRED)
