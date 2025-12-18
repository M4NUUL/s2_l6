cmake_minimum_required(VERSION 3.20)
project(techshop)

set(CMAKE_CXX_STANDARD 17)

add_executable(techshop main.cpp)

find_package(PkgConfig REQUIRED)
pkg_check_modules(PQXX REQUIRED libpqxx)

target_include_directories(techshop PRIVATE ${PQXX_INCLUDE_DIRS})
target_link_libraries(techshop PRIVATE ${PQXX_LIBRARIES})
