TWEAK_NAME = TapTapFolder
TapTapFolder_FILES = Tweak.m
TapTapFolder_FRAMEWORKS = UIKit

export TARGET = iphone:clang
export ARCHS = armv7 armv7s arm64
export TARGET_IPHONEOS_DEPLOYMENT_VERSION = 4.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_armv7s = 6.0
export TARGET_IPHONEOS_DEPLOYMENT_VERSION_arm64 = 7.0
export ADDITIONAL_OBJCFLAGS = -fobjc-arc -fvisibility=hidden
export INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk

internal-stage::
	$(ECHO_NOTHING)pref="$(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences"; mkdir -p "$$pref"; cp "Preferences.plist" "$$pref/$(TWEAK_NAME).plist"; cp "Icon.png" "$$pref/$(TWEAK_NAME).png"; cp "Icon@2x.png" "$$pref/$(TWEAK_NAME)@2x.png"$(ECHO_END)
