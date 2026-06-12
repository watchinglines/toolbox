// android/app/src/main/cpp/CMakeLists.txt
# OpenCV 桥接原生代码(Android)
cmake_minimum_required(VERSION 3.18.1)
project(toolbox_opencv)

set(CMAKE_CXX_STANDARD 17)

# 加载 OpenCV SDK
set(OpenCV_DIR ${CMAKE_SOURCE_DIR}/opencv/sdk/native/jni)
find_package(OpenCV REQUIRED)

add_library(toolbox_opencv SHARED toolbox_opencv.cpp)

# 链接 OpenCV 核心库
target_link_libraries(toolbox_opencv ${OpenCV_LIBS} log)
