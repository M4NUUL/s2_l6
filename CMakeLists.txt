cmake_minimum_required(VERSION 3.16)
project(s2_l6_kolibri LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(kolibri
  src/main.cpp
  src/db.cpp
  src/kolibri_repo.cpp
)

find_package(PkgConfig REQUIRED)
pkg_check_modules(PQXX REQUIRED libpqxx)

target_include_directories(kolibri PRIVATE ${PQXX_INCLUDE_DIRS})
target_link_directories(kolibri PRIVATE ${PQXX_LIBRARY_DIRS})
target_link_libraries(kolibri PRIVATE ${PQXX_LIBRARIES})
