cmake_minimum_required(VERSION 3.16)
project(kolibri_db LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(PkgConfig REQUIRED)
pkg_check_modules(PQXX REQUIRED libpqxx)

add_executable(kolibri
  src/main.cpp
  src/db.cpp
  src/kolibri_repo.cpp
)

target_include_directories(kolibri PRIVATE ${PQXX_INCLUDE_DIRS} src)
target_link_libraries(kolibri PRIVATE ${PQXX_LIBRARIES})
