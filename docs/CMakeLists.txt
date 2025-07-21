set(site_dir ${CMAKE_BINARY_DIR}/site)
file(MAKE_DIRECTORY ${site_dir})

if (WITH_DOXYGEN)
    find_package(Doxygen REQUIRED)
endif()
if (DOXYGEN_FOUND)
	# XXX API docs should be pre-built in tarballs
	file(GLOB headers ${CMAKE_SOURCE_DIR}/include/rpm/*.h)
	set(DOXYGEN_WARN_IF_UNDOCUMENTED NO)
	set(DOXYGEN_OPTIMIZE_OUTPUT_FOR_C YES)
	set(DOXYGEN_HTML_OUTPUT ${site_dir}/api)
	if (ENABLE_WERROR)
		set(DOXYGEN_WARN_AS_ERROR YES)
	endif()
	doxygen_add_docs(apidoc librpm/Doxyheader.h ${headers}
			ALL USE_STAMP_FILE)
	install(DIRECTORY ${DOXYGEN_HTML_OUTPUT}/ DESTINATION ${CMAKE_INSTALL_DOCDIR}/API)
endif()

set(manuals
  	manual/about.md
	manual/arch_dependencies.md
	manual/autosetup.md
	manual/boolean_dependencies.md
	manual/buildprocess.md
	manual/buildsystem.md
	manual/conditionalbuilds.md
	manual/dependencies.md
	manual/dependency_generators.md
	manual/devel_documentation.md
	manual/dynamic_specs.md
	manual/file_triggers.md
	manual/format_header.md
	manual/format_lead.md
	manual/format_v3.md
	manual/format_v4.md
	manual/format_v6.md
	manual/index.md
	manual/large_files.md
	manual/lua.md
	manual/macros.md
	manual/more_dependencies.md
	manual/philosophy.md
	manual/plugins.md
	manual/queryformat.md
	manual/relocatable.md
	manual/scriptlet_expansion.md
	manual/signatures_digests.md
	manual/spec.md
	manual/tags.md
	manual/triggers.md
	manual/tsort.md
	manual/users_and_groups.md
)
install(FILES ${manuals} TYPE DOC)

add_subdirectory(man)

if (ENABLE_JEKYLL)
	# Generates Jekyll source pages
	add_custom_target(pages)
	if (TARGET apidoc)
		add_dependencies(pages apidoc)
	endif()
	if (TARGET clidoc)
		add_dependencies(pages clidoc)
	endif()

	# Configure the Jekyll site to build
	set(site_files
		_layouts/favicon.ico
		_config.yml
		man/manpage.css
		man/index.md
		${manuals}
	)
	configure_file(index.md.in ${site_dir}/index.md @ONLY)
	foreach(file ${site_files})
		configure_file(${file} ${site_dir}/${file} COPYONLY)
	endforeach()

	# Pull common files from the root website repo
	set(root_git "https://github.com/rpm-software-management/rpm-web.git")
	set(root_dir ${site_dir}/root)
	set(root_files
		_layouts/default.html
		_layouts/redirected.html
		_plugins/jekyll-relative-links.rb
		_plugins/jekyll-relative-links/context.rb
		_plugins/jekyll-relative-links/generator.rb
	)
	if (NOT EXISTS ${root_dir})
		execute_process(COMMAND git clone ${root_git} ${root_dir})
	endif()
	foreach(file ${root_files})
		configure_file(${root_dir}/${file} ${site_dir}/${file} COPYONLY)
	endforeach()

	# TODO
	find_program(JEKYLL jekyll)
	mark_as_advanced(JEKYLL)

	set(JEKYLL ${JEKYLL} serve --host 0.0.0.0)

	add_custom_target(site
		COMMAND ${JEKYLL}
		DEPENDS pages
		WORKING_DIRECTORY ${site_dir})
endif()
