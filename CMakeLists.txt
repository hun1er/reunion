cmake_minimum_required(VERSION 3.1)
project(reunion CXX)

if (WIN32)
	message(FATAL_ERROR "CMakeLists.txt Windows platform isn't supported yet. Use msvc/Reunion.sln instead it!")
endif()

add_custom_target(appversion DEPENDS
	COMMAND "${PROJECT_SOURCE_DIR}/reunion/version/appversion.sh" "${PROJECT_SOURCE_DIR}"
)

add_subdirectory(reunion)
