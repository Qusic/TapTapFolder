#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CaptainHook.h>

@interface SBIcon : NSObject
- (void)launch; // iOS 6
- (void)launchFromLocation:(NSInteger)location; //iOS 7 & 8
- (void)launchFromLocation:(NSInteger)location context:(id)context; //iOS 8.3
- (BOOL)isFolderIcon;
- (BOOL)isNewsstandIcon;
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
- (BOOL)isEditing;
- (BOOL)hasOpenFolder;
@end

static NSString * const kIdentifier = @"me.qusic.taptapfolder";
static NSString * const kReversedBehaviorKey = @"ReversedBehavior";
static NSString * const kKeepFolderPreviewKey = @"KeepFolderPreview";
static NSString * const kDoubleTapTimeoutKey = @"DoubleTapTimeout";

static NSUserDefaults *preferences;
static SBIconView *tappedIcon;
static NSDate *lastTappedTime;
static BOOL doubleTapRecognized;

static BOOL iOS7(void) {
    return kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_0;
}

static CGRect iconFrameForGridIndex(NSUInteger index) {
    CGFloat iconSize = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 45 : 54;
    CGFloat iconMargin = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? 3 : 6;
    if (index == 0) {
        return CGRectMake(0, 0, iconSize, iconSize);
    } else {
        return CGRectMake(iconSize / 2, iconSize + iconMargin, 0, 0);
    }
}

CHDeclareClass(SBIconController);
CHDeclareClass(SBIconGridImage)

CHOptimizedMethod(1, self, void, SBIconController, iconTapped, SBIconView *, iconView) {
    void (^launchFirstApp)(void) = ^(void) {
        SBIcon *firstIcon = [((SBFolderIconView *)iconView).folderIcon.folder iconAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        if (iOS7()) {
            if([firstIcon respondsToSelector:@selector(launchFromLocation:context:)]) {
                [firstIcon launchFromLocation:0 context:nil];
            } else {
                [firstIcon launchFromLocation:0];
            }
            iconView.highlighted = NO;
        } else {
            [firstIcon launch];
        }
    };
    void (^openFolder)(void) = ^(void) {
        CHSuper(1, SBIconController, iconTapped, iconView);
    };
    void (^singleTapAction)(void) = ^(void) {
        if ([preferences boolForKey:kReversedBehaviorKey]) {
            openFolder();
        } else {
            launchFirstApp();
        }
    };
    void (^doubleTapAction)(void) = ^(void) {
        if ([preferences boolForKey:kReversedBehaviorKey]) {
            launchFirstApp();
        } else {
            openFolder();
        }
    };

    if (!self.isEditing && !self.hasOpenFolder && iconView.icon.isFolderIcon && !([iconView.icon respondsToSelector:@selector(isNewsstandIcon)] && iconView.icon.isNewsstandIcon)) {
        NSDate *nowTime = [NSDate date];
        if (iconView == tappedIcon) {
            if ([nowTime timeIntervalSinceDate:lastTappedTime] < [preferences floatForKey:kDoubleTapTimeoutKey]) {
                doubleTapRecognized = YES;
                doubleTapAction();
                return;
            }
        } else {
            if (iOS7()) {
                tappedIcon.highlighted = NO;
            }
        }
        tappedIcon = iconView;
        lastTappedTime = nowTime;
        doubleTapRecognized = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([preferences floatForKey:kDoubleTapTimeoutKey] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void) {
            if (!doubleTapRecognized && iconView == tappedIcon) {
                singleTapAction();
            }
        });
    } else {
        CHSuper(1, SBIconController, iconTapped, iconView);
    }
}

CHOptimizedClassMethod(2, self, CGRect, SBIconGridImage, rectAtIndex, NSUInteger, index, maxCount, NSUInteger, count) {
    return [preferences boolForKey:kKeepFolderPreviewKey]
    ? CHSuper(2, SBIconGridImage, rectAtIndex, index, maxCount, count)
    : iconFrameForGridIndex(index);
}

CHOptimizedClassMethod(3, self, CGRect, SBIconGridImage, rectAtIndex, NSUInteger, index, forImage, id, image, maxCount, NSUInteger, count) {
    return [preferences boolForKey:kKeepFolderPreviewKey]
    ? CHSuper(3, SBIconGridImage, rectAtIndex, index, forImage, image, maxCount, count)
    : iconFrameForGridIndex(index);
}

CHConstructor {
    @autoreleasepool {
        preferences = [[NSUserDefaults alloc]initWithSuiteName:kIdentifier];
        [preferences registerDefaults:@{
            kReversedBehaviorKey: @YES,
            kKeepFolderPreviewKey: @YES,
            kDoubleTapTimeoutKey: @0.2
        }];
        CHLoadLateClass(SBIconController);
        CHLoadLateClass(SBIconGridImage);
        CHHook(1, SBIconController, iconTapped);
        if (iOS7()) {
            CHHook(2, SBIconGridImage, rectAtIndex, maxCount);
        } else {
            CHHook(3, SBIconGridImage, rectAtIndex, forImage, maxCount);
        }
    }
}
