#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CaptainHook.h>

#define iOS7() (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0)
#define iconSize() ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 45 : 54)
#define iconMargin() ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ? 3 : 6)

// TODO: Support for Nested Folders in iOS 7.

@interface SBIcon : NSObject
- (void)launch; // iOS 6
- (void)launchFromLocation:(NSInteger)location; //iOS 7
- (BOOL)isFolderIcon;
@end

@interface SBFolder : NSObject
- (SBIcon *)iconAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface SBFolderIcon : SBIcon
- (SBFolder *)folder;
@end

@interface SBIconView : UIView
@property(assign) SBIcon *icon;
@property(assign, getter = isHighlighted) BOOL highlighted;
@end

@interface SBFolderIconView : SBIconView
@property(readonly, assign) SBFolderIcon *folderIcon;
@end

@interface SBIconController : NSObject
- (void)iconTapped:(SBIconView *)iconView;
- (BOOL)hasOpenFolder;
@end

static SBIconView *tappedIcon;
static NSDate *lastTappedTime;
static BOOL doubleTapRecognized;

static BOOL reversedBehavior;
static BOOL keepFolderPreview;
static float doubleTapTimeout;

static void preferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.qusic.taptapfolder.plist"];
    reversedBehavior = [preferences[@"ReversedBehavior"]boolValue];
    keepFolderPreview = [preferences[@"KeepFolderPreview"]boolValue];
    doubleTapTimeout = [preferences[@"DoubleTapTimeout"]floatValue] ? : 0.25;
}

CHDeclareClass(SBIconController);
CHOptimizedMethod(1, self, void, SBIconController, iconTapped, SBIconView *, iconView)
{
    if (!self.hasOpenFolder && iconView.icon.isFolderIcon) {
        NSDate *nowTime = [NSDate date];
        if (iconView == tappedIcon) {
            if ([nowTime timeIntervalSinceDate:lastTappedTime] < doubleTapTimeout) {
                doubleTapRecognized = YES;
                if (reversedBehavior) {
                    SBIcon *firstIcon = [((SBFolderIconView *)iconView).folderIcon.folder iconAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                    if (iOS7()) {
                        if([firstIcon respondsToSelector:@selector(launchFromLocation:context:)])
                            [firstIcon launchFromLocation:0 context:nil];
                        else
                            [firstIcon launchFromLocation:0];
                        iconView.highlighted = NO;
                    } else {
                        [firstIcon launch];
                    }
                } else {
                    CHSuper(1, SBIconController, iconTapped, iconView);
                }
                return;
            }
        } else {
            if (iOS7() && tappedIcon != nil) {
                tappedIcon.highlighted = NO;
            }
        }
        tappedIcon = iconView;
        lastTappedTime = nowTime;
        doubleTapRecognized = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(doubleTapTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
            if (!doubleTapRecognized && iconView == tappedIcon) {
                if (reversedBehavior) {
                    CHSuper(1, SBIconController, iconTapped, iconView);
                } else {
                    SBIcon *firstIcon = [((SBFolderIconView *)iconView).folderIcon.folder iconAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                    if (iOS7()) {
                        if([firstIcon respondsToSelector:@selector(launchFromLocation:context:)])
                            [firstIcon launchFromLocation:0 context:nil];
                        else
                            [firstIcon launchFromLocation:0];
                        iconView.highlighted = NO;
                    } else {
                        [firstIcon launch];
                    }
                }
            }
        });
    } else {
        CHSuper(1, SBIconController, iconTapped, iconView);
    }
}

CHDeclareClass(SBIconGridImage)
CHOptimizedClassMethod(2, self, CGRect, SBIconGridImage, rectAtIndex, NSUInteger, index, maxCount, NSUInteger, count)
{
    if (keepFolderPreview) {
        return CHSuper(2, SBIconGridImage, rectAtIndex, index, maxCount, count);
    } else {
        if (index == 0) {
            return CGRectMake(0, 0, iconSize(), iconSize());
        } else {
            return CGRectMake(iconSize() / 2, iconSize() + iconMargin(), 0, 0);
        }
    }
}
CHOptimizedClassMethod(3, self, CGRect, SBIconGridImage, rectAtIndex, NSUInteger, index, forImage, id, image, maxCount, NSUInteger, count)
{
    if (keepFolderPreview) {
        return CHSuper(3, SBIconGridImage, rectAtIndex, index, forImage, image, maxCount, count);
    } else {
        if (index == 0) {
            return CGRectMake(0, 0, iconSize(), iconSize());
        } else {
            return CGRectMake(iconSize() / 2, iconSize() + iconMargin(), 0, 0);
        }
    }
}

CHConstructor
{
	@autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, preferencesChangedCallback, CFSTR("me.qusic.taptapfolder.preferencesChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        preferencesChangedCallback(NULL, NULL, NULL, NULL, NULL);
        CHLoadLateClass(SBIconController);
        CHHook(1, SBIconController, iconTapped);
        CHLoadLateClass(SBIconGridImage);
        if (iOS7()) {
            CHHook(2, SBIconGridImage, rectAtIndex, maxCount);
        } else {
            CHHook(3, SBIconGridImage, rectAtIndex, forImage, maxCount);
        }
	}
}
