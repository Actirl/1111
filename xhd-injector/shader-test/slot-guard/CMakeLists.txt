cmake_minimum_required(VERSION 3.20)
project(XHDSlotGuard LANGUAGES CXX)
add_library(xhd_slot_guard STATIC ../xhd_srv_slot_guard.cpp)
target_compile_features(xhd_slot_guard PRIVATE cxx_std_17)
