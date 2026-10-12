# Matrix — nativer Matrix-Client für iPod touch 4 (iOS 6.1, ARMv7), Theos.
TARGET = iphone:clang:7.1:5.0
ARCHS  = armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Matrix

Matrix_FILES  = $(wildcard src/*.m)
Matrix_FRAMEWORKS = UIKit CoreGraphics QuartzCore Foundation
Matrix_CFLAGS  = -fobjc-arc -O2 -Wall -Ivendor/mbedtls/include
Matrix_LDFLAGS = -Lvendor/mbedtls/lib
Matrix_LIBRARIES = mbedtls mbedx509 mbedcrypto

include $(THEOS_MAKE_PATH)/application.mk
