// android/app/src/main/cpp/toolbox_opencv.cpp
// OpenCV 透视矫正 C++ 实现
#include <jni.h>
#include <opencv2/opencv.hpp>
#include <vector>

extern "C" JNIEXPORT jint JNICALL
Java_com_toolbox_scanner_NativePlugin_warpPerspective(
    JNIEnv* env,
    jobject /* this */,
    jbyteArray srcBytes,
    jint srcW,
    jint srcH,
    jdoubleArray corners,
    jbyteArray outBytes,
    jint outW,
    jint outH
) {
    // 1. 解码源图像
    jbyte* srcData = env->GetByteArrayElements(srcBytes, nullptr);
    cv::Mat src(srcH, srcW, CV_8UC3, (unsigned char*)srcData);

    // 2. 读取角点
    jdouble* cornerData = env->GetDoubleArrayElements(corners, nullptr);
    std::vector<cv::Point2f> srcCorners = {
        cv::Point2f((float)cornerData[0], (float)cornerData[1]),
        cv::Point2f((float)cornerData[2], (float)cornerData[3]),
        cv::Point2f((float)cornerData[4], (float)cornerData[5]),
        cv::Point2f((float)cornerData[6], (float)cornerData[7])
    };
    std::vector<cv::Point2f> dstCorners = {
        cv::Point2f(0, 0),
        cv::Point2f((float)outW, 0),
        cv::Point2f((float)outW, (float)outH),
        cv::Point2f(0, (float)outH)
    };

    // 3. 计算单应矩阵
    cv::Mat H = cv::getPerspectiveTransform(srcCorners, dstCorners);

    // 4. 应用透视变换
    cv::Mat dst;
    cv::warpPerspective(src, dst, H, cv::Size(outW, outH),
                        cv::INTER_LINEAR, cv::BORDER_CONSTANT,
                        cv::Scalar(255, 255, 255));

    // 5. 写回字节
    jbyte* outData = env->GetByteArrayElements(outBytes, nullptr);
    memcpy(outData, dst.data, outW * outH * 3);

    // 6. 释放
    env->ReleaseByteArrayElements(srcBytes, srcData, JNI_ABORT);
    env->ReleaseDoubleArrayElements(corners, cornerData, JNI_ABORT);
    env->ReleaseByteArrayElements(outBytes, outData, 0);

    return 0;
}

// Dart FFI 入口
extern "C" __attribute__((visibility("default"))) int
toolbox_warp_perspective(
    unsigned char* src, int srcW, int srcH,
    double* corners,
    unsigned char* dst, int outW, int outH
) {
    cv::Mat srcMat(srcH, srcW, CV_8UC3, src);
    std::vector<cv::Point2f> srcCorners = {
        cv::Point2f((float)corners[0], (float)corners[1]),
        cv::Point2f((float)corners[2], (float)corners[3]),
        cv::Point2f((float)corners[4], (float)corners[5]),
        cv::Point2f((float)corners[6], (float)corners[7])
    };
    std::vector<cv::Point2f> dstCorners = {
        cv::Point2f(0, 0),
        cv::Point2f((float)outW, 0),
        cv::Point2f((float)outW, (float)outH),
        cv::Point2f(0, (float)outH)
    };
    cv::Mat H = cv::getPerspectiveTransform(srcCorners, dstCorners);
    cv::Mat dstMat;
    cv::warpPerspective(srcMat, dstMat, H, cv::Size(outW, outH),
                        cv::INTER_LINEAR, cv::BORDER_CONSTANT,
                        cv::Scalar(255, 255, 255));
    memcpy(dst, dstMat.data, outW * outH * 3);
    return 0;
}
