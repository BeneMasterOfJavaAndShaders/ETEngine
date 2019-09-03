

##############################
# general for cmake list files
##############################


# custom configuration types
############################
macro(setupConfigurations)

	# set our configuration types
	set(CMAKE_CONFIGURATION_TYPES "Debug;DebugEditor;Develop;DevelopEditor;Shipping" 
		CACHE STRING "Available build-types: Debug, DebugEditor, Develop, DevelopEditor and Shipping" FORCE)
		
	# copy settings from existing build types
	set(CMAKE_CXX_FLAGS_DEBUGEDITOR "${CMAKE_CXX_FLAGS_DEBUG}" )
	set(CMAKE_C_FLAGS_DEBUGEDITOR "${CMAKE_C_FLAGS_DEBUG}")
	set(CMAKE_EXE_LINKER_FLAGS_DEBUGEDITOR "${CMAKE_EXE_LINKER_FLAGS_DEBUG}")

	set(CMAKE_CXX_FLAGS_DEVELOP "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
	set(CMAKE_C_FLAGS_DEVELOP "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
	set(CMAKE_EXE_LINKER_FLAGS_DEVELOP "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO}")

	set(CMAKE_CXX_FLAGS_DEVELOPEDITOR "${CMAKE_CXX_FLAGS_DEVELOP}")
	set(CMAKE_C_FLAGS_DEVELOPEDITOR "${CMAKE_C_FLAGS_DEVELOP}")
	set(CMAKE_EXE_LINKER_FLAGS_DEVELOPEDITOR "${CMAKE_EXE_LINKER_FLAGS_DEVELOP}")

	set(CMAKE_CXX_FLAGS_SHIPPING "${CMAKE_CXX_FLAGS_RELEASE}")
	set(CMAKE_C_FLAGS_SHIPPING "${CMAKE_C_FLAGS_RELEASE}" )
	set(CMAKE_EXE_LINKER_FLAGS_SHIPPING "${CMAKE_EXE_LINKER_FLAGS_RELEASE}")

endmacro(setupConfigurations)


# output dir for executables
############################
function(outputDirectories TARGET)

	if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8") # 64 bit
		set(_p "x64")	
	else() # 32 bit
		set(_p "x32")	
	endif()

	foreach(_c ${CMAKE_CONFIGURATION_TYPES})
		string(TOUPPER ${_c} _C)

		set_target_properties(${TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_${_C} ${PROJECT_BINARY_DIR}/../bin/${_c}_${_p}/${TARGET})
	endforeach()

endfunction(outputDirectories)


# output dir for libraries
############################
function(libOutputDirectories TARGET)

	if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8") # 64 bit
		set(_p "x64")	
	else() # 32 bit
		set(_p "x32")	
	endif()

	foreach(_c ${CMAKE_CONFIGURATION_TYPES})
		string(TOUPPER ${_c} _C)

		set_target_properties(${TARGET} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY_${_C} ${PROJECT_BINARY_DIR}/../lib/${_c}_${_p}/${TARGET})
		set_target_properties(${TARGET} PROPERTIES LIBRARY_OUTPUT_DIRECTORY_${_C} ${PROJECT_BINARY_DIR}/../lib/${_c}_${_p}/${TARGET})
	endforeach()

endfunction(libOutputDirectories)


# make project filters mimic directory structure
################################################
function(assign_source_group)
    foreach(_source IN ITEMS ${ARGN})
        if (IS_ABSOLUTE "${_source}")
            file(RELATIVE_PATH _source_rel "${CMAKE_CURRENT_SOURCE_DIR}" "${_source}")
        else()
            set(_source_rel "${_source}")
        endif()
        get_filename_component(_source_path "${_source_rel}" PATH)
        string(REPLACE "/" "\\" _source_path_msvc "${_source_path}")
        source_group("${_source_path_msvc}" FILES "${_source}")
    endforeach()
endfunction(assign_source_group)


# PCH
#########
function(precompiled_headers SOURCELIST)
	# only windows
	if (MSVC)
		# run this first to set all files to use pch
		foreach( src_file ${SOURCELIST} )
			set_source_files_properties( ${src_file} PROPERTIES COMPILE_FLAGS "/Yustdafx.h" )
		endforeach( src_file ${SOURCELIST} )
		# run this second to overwrite the pch setting for the stdafx.cpp file
		set_source_files_properties(stdafx.cpp PROPERTIES COMPILE_FLAGS "/Ycstdafx.h" )
	endif(MSVC)
endfunction(precompiled_headers)


# Parallel build
#################
function(targetCompileOptions _target)
	# only windows
	if(MSVC)
		target_compile_options(${_target} PRIVATE "/MP")
	endif()

	target_compile_options(
		${_target} PRIVATE 
		"$<$<CONFIG:Debug>:/D_DEBUG /DET_DEBUG>"
		"$<$<CONFIG:DebugEditor>:/D_DEBUG /DET_DEBUG /DEDITOR>"
		"$<$<CONFIG:Develop>:/DET_DEVELOP>"
		"$<$<CONFIG:DevelopEditor>:/DET_DEVELOP /DEDITOR>"
		"$<$<CONFIG:Shipping>:/DET_SHIPPING>"
	)
endfunction(targetCompileOptions)


# Config defines
#################
function(target_definitions)
	# os
	if (MSVC)
		add_definitions(-DPLATFORM_Win)
	endif(MSVC)
	
	# architecture
	if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
		add_definitions(-DPLATFORM_x64)
	 else() 
		add_definitions(-DPLATFORM_x32)
	endif()
endfunction(target_definitions)


# get vcpkg install directory
####################################################
function(getVcpkgTarget vcpkg_target)

	if("${CMAKE_GENERATOR}" MATCHES "(Win64|IA64)") # 64 bit
		if(MSVC)
			set(${vcpkg_target} "x64-windows" PARENT_SCOPE)
		else()
			set(${vcpkg_target} "x64-linux" PARENT_SCOPE)
		endif()
	else() # 32 bit
		set(${vcpkg_target} "x86-windows" PARENT_SCOPE)
	endif()

endfunction(getVcpkgTarget)


# get vcpkg toolset triplet
####################################################
function(getToolsetTriplet out_triplet)

	set(_vcpkgTarget )
	getVcpkgTarget(_vcpkgTarget)

	if(DEFINED MSVC_TOOLSET_VERSION)
		set(_toolset "v${MSVC_TOOLSET_VERSION}")
	elseif(DEFINED CMAKE_VS_PLATFORM_TOOLSET)
		set(_toolset "${CMAKE_VS_PLATFORM_TOOLSET}")
	else()
		message(FATAL_ERROR "Visual studio toolset couldn't be deduced from cmake")
	endif()

	set(${out_triplet} "${_vcpkgTarget}-${_toolset}" PARENT_SCOPE)
endfunction(getToolsetTriplet)


# get vcpkg install directory
####################################################
function(getVcpkgInstallDir vcpkg_install)
	set(_vcpkgTargetToolset )
	getToolsetTriplet(_vcpkgTargetToolset)

	set(${vcpkg_install} "${PROJECT_BINARY_DIR}/../dependancies/submodules/vcpkg/vcpkg/installed/${_vcpkgTargetToolset}" PARENT_SCOPE)
endfunction(getVcpkgInstallDir)


# link to all dependancies
###########################
function(dependancyLinks TARGET _useSdlMain)

	set(dep_dir "${PROJECT_BINARY_DIR}/../dependancies")
	
	set(_vcpkgInstall )
	getVcpkgInstallDir(_vcpkgInstall)

	if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
		set(dep_pf "${dep_dir}/x64")
	 else() 
		set(dep_pf "${dep_dir}/x32")
	endif()

	# separate debug and release libs
	target_link_libraries (${TARGET} 		
		debug ${dep_pf}/rttr/Debug/rttr_core_d.lib				optimized ${dep_pf}/rttr/Release/rttr_core.lib
	
		debug ${dep_pf}/bullet/Debug/BulletDynamics_Debug.lib	optimized ${dep_pf}/bullet/Release/BulletDynamics.lib
		debug ${dep_pf}/bullet/Debug/BulletCollision_Debug.lib	optimized ${dep_pf}/bullet/Release/BulletCollision.lib
		debug ${dep_pf}/bullet/Debug/LinearMath_Debug.lib		optimized ${dep_pf}/bullet/Release/LinearMath.lib 

		debug ${_vcpkgInstall}/debug/lib/freetyped.lib			optimized ${_vcpkgInstall}/lib/freetype.lib	)

	target_link_libraries (${TARGET} 
		${dep_pf}/sdl2/SDL2.lib
		${dep_pf}/assimp/assimp.lib
		${dep_pf}/openAL/openAL.lib )

	if (MSVC)
		target_link_libraries(${TARGET} opengl32.lib)

		if (_useSdlMain)
			target_link_libraries(${TARGET} ${dep_pf}/sdl2/SDL2main.lib)
		endif(_useSdlMain)

	endif(MSVC)

endfunction(dependancyLinks)


# place a list of all libraries built by vcpkg
####################################################
function(getVcpkgLibs out_list)
	set (${out_list} "freetype" "bz2" "libpng16" "zlib" PARENT_SCOPE)
endfunction(getVcpkgLibs)


# place a list of unified libraries in the out list
####################################################
function(getUniLibs out_list)
	set (${out_list} "sdl2" "assimp" "openAL" PARENT_SCOPE)
endfunction(getUniLibs)


# place a list of separated libraries in the out list
######################################################
function(getSepLibs out_list)
	set (${out_list} "bullet" "rttr" PARENT_SCOPE)
endfunction(getSepLibs)


# link to all dependancies
###########################
function(libIncludeDirs)

	set(_vcpkgInstall )
	getVcpkgInstallDir(_vcpkgInstall)
	include_directories("${_vcpkgInstall}/include/")	
	
	include_directories("${PROJECT_BINARY_DIR}/../dependancies/submodules/stb")

	set(libs )
	getUniLibs(libs)
	set(sep_libs )
	getSepLibs(sep_libs)
	list (APPEND libs ${sep_libs})

	foreach(_lib ${libs})
		include_directories("${PROJECT_BINARY_DIR}/../dependancies/include/${_lib}/")	
	endforeach(_lib)

endfunction(libIncludeDirs)


# check if filenames loosely match
###################################
function(getMatchingFiles _searchList _fileList out_list)

	foreach(_searchFile ${_searchList})

		set(_index -1)
		set(_currentIndex -1)
		foreach(_filePath ${_fileList})
			MATH(EXPR _currentIndex "${_currentIndex}+1")
			get_filename_component(_fileName ${_filePath} NAME_WE)
			if ("${_searchFile}" MATCHES "${_fileName}*")
				set(_index ${_currentIndex})
			endif()
		endforeach()

		if(${_index} GREATER -1)
			list(GET _fileList ${_index} _filePath)
			list(APPEND ret_list ${_filePath})
		endif()

	endforeach()
	
	set (${out_list} "${ret_list}" PARENT_SCOPE)

endfunction(getMatchingFiles)


# copy dll (and pdb) files in the appropriate directory according to configuration - post build command version
################################################################################################################
function(copyDllCommand _target)

	# paths for our libraries depend on the architecture we compile for
	if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
		set(_p "x64")
	 else() 
		set(_p "x32")
	endif()

	set(uni_libs )
	getUniLibs(uni_libs)
	set(sep_libs )
	getSepLibs(sep_libs)
	
	set(_vcpkgInstall )
	getVcpkgInstallDir(_vcpkgInstall)
	set(vcpkg_libs )
	getVcpkgLibs(vcpkg_libs)

	# where the lib files live
	set(_cfg "Release") 
	set(_vcCfg "")
	if(("$<CONFIG>" STREQUAL "Debug") OR ("$<CONFIG>" STREQUAL "DebugEditor"))
		set(_cfg "Debug")
		set(_vcCfg "/debug")
	
		# for debug applications we also copy pdbs	
		foreach(_lib ${uni_libs})
			file(GLOB pdbs ${PROJECT_SOURCE_DIR}/dependancies/${_p}/${_lib}/*.pdb)
			foreach(_pdb ${pdbs})
				add_custom_command(TARGET ${_target} 
					POST_BUILD
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_pdb}" $<TARGET_FILE_DIR:${_target}>
					COMMAND ${CMAKE_COMMAND} -E echo "Copying ${_pdb}" 
				)
			endforeach()
		endforeach()
		foreach(_lib ${sep_libs})
			file(GLOB pdbs ${PROJECT_SOURCE_DIR}/dependancies/${_p}/${_lib}/${_cfg}/*.pdb)
			foreach(_pdb ${pdbs})
				add_custom_command(TARGET ${_target} 
					POST_BUILD
					COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_pdb}" $<TARGET_FILE_DIR:${_target}>
					COMMAND ${CMAKE_COMMAND} -E echo "Copying ${_pdb}" 
				)
			endforeach()
		endforeach()

		file(GLOB pdbs ${_vcpkgInstall}${_vcCfg}/bin/*.pdb)
		getMatchingFiles("${vcpkg_libs}" "${pdbs}" pdbs)
		foreach(_pdb ${pdbs})
			add_custom_command(TARGET ${_target} 
				POST_BUILD
				COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_pdb}" $<TARGET_FILE_DIR:${_target}>
				COMMAND ${CMAKE_COMMAND} -E echo "Copying ${_pdb}" 
			)
		endforeach()
	endif()

	foreach(_lib ${uni_libs})
		file(GLOB dlls ${PROJECT_SOURCE_DIR}/dependancies/${_p}/${_lib}/*.dll)
		foreach(_dll ${dlls})
			add_custom_command(TARGET ${_target} 
				POST_BUILD
				COMMAND ${CMAKE_COMMAND} -E copy_if_different "${_dll}" $<TARGET_FILE_DIR:${_target}> 
				COMMAND ${CMAKE_COMMAND} -E echo "Copying ${_dll}" 
			)
		endforeach()
	endforeach()
	foreach(_lib ${sep_libs})
		file(GLOB debugDlls ${PROJECT_SOURCE_DIR}/dependancies/${_p}/${_lib}/Debug/*.dll)
		foreach(_dll ${debugDlls})
			add_custom_command(TARGET ${_target} 
				POST_BUILD
				COMMAND ${CMAKE_COMMAND} -E $<IF:$<OR:$<CONFIG:Debug>,$<CONFIG:DebugEditor>>,copy_if_different\ "${_dll}"\ $<TARGET_FILE_DIR:${_target}>,echo\ "">
				COMMAND ${CMAKE_COMMAND} -E $<IF:$<OR:$<CONFIG:Debug>,$<CONFIG:DebugEditor>>,echo\ "Copying ${_dll}",echo\ "">
			)
		endforeach()

		file(GLOB releaseDlls ${PROJECT_SOURCE_DIR}/dependancies/${_p}/${_lib}/Release/*.dll)
		foreach(_dll ${releaseDlls})
			add_custom_command(TARGET ${_target} 
				POST_BUILD
				COMMAND ${CMAKE_COMMAND} -E $<IF:$<OR:$<CONFIG:Debug>,$<CONFIG:DebugEditor>>,echo\ "",copy_if_different\ "${_dll}"\ $<TARGET_FILE_DIR:${_target}>>
				COMMAND ${CMAKE_COMMAND} -E $<IF:$<OR:$<CONFIG:Debug>,$<CONFIG:DebugEditor>>,echo\ "",echo\ "Copying ${_dll}">
			)
		endforeach()
	endforeach()
	
	file(GLOB debugDlls ${_vcpkgInstall}/debug/bin/*.dll)
	getMatchingFiles("${vcpkg_libs}" "${debugDlls}" debugDlls)
	foreach(_dll ${debugDlls})
		add_custom_command(TARGET ${_target} 
			POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E $<IF:$<OR:$<CONFIG:Debug>,$<CONFIG:DebugEditor>>,copy_if_different\ "${_dll}"\ $<TARGET_FILE_DIR:${_target}>,echo\ "">
			COMMAND ${CMAKE_COMMAND} -E $<IF:$<OR:$<CONFIG:Debug>,$<CONFIG:DebugEditor>>,echo\ "Copying ${_dll}",echo\ "">
		)
	endforeach()
	file(GLOB releaseDlls ${_vcpkgInstall}/bin/*.dll)
	getMatchingFiles("${vcpkg_libs}" "${releaseDlls}" releaseDlls)
	foreach(_dll ${releaseDlls})
		add_custom_command(TARGET ${_target} 
			POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E $<IF:$<OR:$<CONFIG:Debug>,$<CONFIG:DebugEditor>>,echo\ "",copy_if_different\ "${_dll}"\ $<TARGET_FILE_DIR:${_target}>>
			COMMAND ${CMAKE_COMMAND} -E $<IF:$<OR:$<CONFIG:Debug>,$<CONFIG:DebugEditor>>,echo\ "",echo\ "Copying ${_dll}">
		)
	endforeach()

endfunction(copyDllCommand)


# install dll (and pdb) files in the appropriate directory according to configuration
######################################################################################
function(installDlls TARGET)

	set(projectBase "${PROJECT_BINARY_DIR}/..")
	set(baseBinDir "${projectBase}/bin")

	# paths for our libraries depend on the architecture we compile for
	if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
		set(platform "x64")
	 else() 
		set(platform "x32")
	endif()

	set(uni_libs )
	getUniLibs(uni_libs)
	set(sep_libs )
	getSepLibs(sep_libs)
	
	set(_vcpkgInstall )
	getVcpkgInstallDir(_vcpkgInstall)
	set(vcpkg_libs )
	getVcpkgLibs(vcpkg_libs)

	foreach(configType ${CMAKE_CONFIGURATION_TYPES})

		set(binDir "${baseBinDir}/${configType}_${platform}/${TARGET}")

		# where the lib files live
		set(libcfg "Release") 
		set(_vcCfg "")
		if(("${configType}" STREQUAL "Debug") OR ("${configType}" STREQUAL "DebugEditor"))
			set(libcfg "Debug")
			set(_vcCfg "/debug")

			# for debug applications we also copy pdbs
			foreach(_lib ${uni_libs})
				install(DIRECTORY ${projectBase}/dependancies/${platform}/${_lib}/
					CONFIGURATIONS ${configType}
					DESTINATION ${binDir}/
					FILES_MATCHING PATTERN "*.pdb")
			endforeach()
			foreach(_lib ${sep_libs})
				install(DIRECTORY ${projectBase}/dependancies/${platform}/${_lib}/${libcfg}/
					CONFIGURATIONS ${configType}
					DESTINATION ${binDir}/
					FILES_MATCHING PATTERN "*.pdb")
			endforeach()

			file(GLOB pdbs ${_vcpkgInstall}${_vcCfg}/bin/*.pdb)
			getMatchingFiles("${vcpkg_libs}" "${pdbs}" pdbs)
			foreach(_pdb ${pdbs})
				install(FILES ${_pdb} CONFIGURATIONS ${configType} DESTINATION ${binDir}/)
			endforeach()
		endif()

		# copy dlls for all libraries
		foreach(_lib ${uni_libs})
			install(DIRECTORY ${projectBase}/dependancies/${platform}/${_lib}/
				CONFIGURATIONS ${configType}
				DESTINATION ${binDir}/
				FILES_MATCHING PATTERN "*.dll")
		endforeach()
		foreach(_lib ${sep_libs})
			install(DIRECTORY ${projectBase}/dependancies/${platform}/${_lib}/${libcfg}/
				CONFIGURATIONS ${configType}
				DESTINATION ${binDir}/
				FILES_MATCHING PATTERN "*.dll")
		endforeach()

		file(GLOB dlls ${_vcpkgInstall}${_vcCfg}/bin/*.dll)
		getMatchingFiles("${vcpkg_libs}" "${dlls}" dlls)
		foreach(_dll ${dlls})
			install(FILES ${_dll} CONFIGURATIONS ${configType} DESTINATION ${binDir}/)
		endforeach()

	endforeach()

endfunction(installDlls)


# install everything in the appropriate directory according to configuration
#############################################################################
function(installResources TARGET)

	set(projectBase "${PROJECT_BINARY_DIR}/..")
	set(baseBinDir "${projectBase}/bin")

	# paths for our libraries depend on the architecture we compile for
	if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
		set(platform "x64")
	 else() 
		set(platform "x32")
	endif()

	foreach(configType ${CMAKE_CONFIGURATION_TYPES})

		set(binDir "${baseBinDir}/${configType}_${platform}/${TARGET}")

		# copy config files
		install(DIRECTORY ${projectBase}/source/Demo/Config/
			CONFIGURATIONS ${configType}
			DESTINATION ${binDir}/)

	endforeach()

endfunction(installResources)


# cook package files and install them in the binary output directory
#####################################################################
function(installCookResources TARGET)

	set(projectBase "${PROJECT_BINARY_DIR}/..")
	set(cmp_dir "${projectBase}/resources/")

	# figure out the directory the cooker binary lives in
	#-----------------------------------------------------------
	if("${CMAKE_SIZEOF_VOID_P}" EQUAL "8")
		set(_p "x64")
	 else() 
		set(_p "x32")
	endif()
	set(bin_base_dir "${projectBase}/bin/$<CONFIG>_${_p}/")
	set(cooker_dir "${bin_base_dir}EtCooker/")
	set(pak_file_dir "${bin_base_dir}${TARGET}/")

	set(resource_name "compiledPackage")
	set(res_file "${cmp_dir}asset_database.json")

	# any files that can trigger the resources to be rebuilt
	file(GLOB_RECURSE deps ${cmp_dir}/assets/*.*)
	list (APPEND deps ${cmp_dir}/asset_database.json)

	set(target_name "cook-installed-resources-${TARGET}")

	# the command list that will run - for installing resources
	#-----------------------------------------------------------
	add_custom_target(${target_name} 
		DEPENDS ${deps} EtCooker 
		
		COMMAND ${CMAKE_COMMAND} -E echo "Cooking resource packages - Source ${res_file} ; Out directory Directory: ${pak_file_dir}"
		COMMAND ${CMAKE_COMMAND} -E echo ""
		COMMAND ${cooker_dir}EtCooker.exe ${res_file} ${pak_file_dir} n
		COMMAND ${CMAKE_COMMAND} -E echo ""
		COMMAND ${CMAKE_COMMAND} -E echo ""
		
		COMMENT "Cooking installed resource files"

		VERBATIM
	)

endfunction(installCookResources)
