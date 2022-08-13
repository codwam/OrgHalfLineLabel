//
//  TruncationLabel.h
//  OrgHalfLineLabel
//
//  Created by lihui02 on 2022/8/13.
//  Copyright © 2022 66-admin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TruncationLabel : UIView

/// maximun lines
@property(nonatomic, assign) NSInteger numberOfLines;

/// first render text (NSString or NSAttributedString)
@property(nonatomic, copy, nullable) id firstText;

/// first render text (NSString or NSAttributedString)
@property(nonatomic, copy, nullable) id lastText;

@end

NS_ASSUME_NONNULL_END
