#import <UIKit/UIKit.h>

@interface SBIconImageView : UIView
@end
@interface SBFolderIconImageView : SBIconImageView
@end
@interface _SBIconGridWrapperView :UIImageView
@end

@interface SBIconBlurryBackgroundView : UIView
@end
@interface SBFolderIconBackgroundView : SBIconBlurryBackgroundView
@end

#define FRAME (CGRectMake(0,0,60,60))

%hook SBFolderIconImageView
- (id)init {

	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.qusic.taptapfolder.plist"];
	BOOL removeBlur = [preferences[@"blurBeGone"]boolValue];

	if (removeBlur == YES) {
		self.frame = FRAME;
		for (UIView *view in self.subviews) {

			if ([view isMemberOfClass:[UIView class]]) {
					view.frame = FRAME;
					for (UIView *subView in view.subviews) {
						if ([subView isMemberOfClass:[%c(_SBIconGridWrapperView) class]]) {
							subView.frame = FRAME;
						}
					}
			} else if ([view isMemberOfClass:[%c(SBFolderIconBackgroundView) class]]) {
					view.frame = CGRectMake(0,0,0,0);
			}
		}
	}

	return %orig;
}
- (void)layoutSubviews {
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/me.qusic.taptapfolder.plist"];
	BOOL removeBlur = [preferences[@"blurBeGone"]boolValue];

	%orig;

	if (removeBlur == YES) {
		self.frame = FRAME;
		for (UIView *view in self.subviews) {

			if ([view isMemberOfClass:[UIView class]]) {
					view.frame = FRAME;
					for (UIView *subView in view.subviews) {
						if ([subView isMemberOfClass:[%c(_SBIconGridWrapperView) class]]) {
							subView.frame = FRAME;
						}
					}
			} else if ([view isMemberOfClass:[%c(SBFolderIconBackgroundView) class]]) {
					view.frame = CGRectMake(0,0,0,0);
			}
		}
	}
}
%end
