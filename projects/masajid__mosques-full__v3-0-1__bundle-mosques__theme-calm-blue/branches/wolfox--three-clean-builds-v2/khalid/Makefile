ARCHS = arm64
TARGET = iphone:clang:latest:14.0
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = WolFoxKhalid
WolFoxKhalid_FILES = KSA.mm c.mm fishhook/fishhook.c
WolFoxKhalid_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)/fishhook
WolFoxKhalid_FRAMEWORKS = UIKit Foundation CoreLocation CoreBluetooth MapKit Security AVFoundation
include $(THEOS_MAKE_PATH)/tweak.mk
