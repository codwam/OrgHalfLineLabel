//
//  TruncationLabel.m
//  OrgHalfLineLabel
//
//  Created by lihui02 on 2022/8/13.
//  Copyright © 2022 66-admin. All rights reserved.
//

#import "TruncationLabel.h"
#import <CoreText/CoreText.h>

#ifdef DEBUG
#   define XLog(...) NSLog(__VA_ARGS__)
//#   define XLog(fmt, ...) NSLog((@"[TruncationLabel] " fmt), ##__VA_ARGS__);
//#   define XLog(fmt, ...) NSLog((@"%s [Line %d] [TruncationLabel] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
    #define XLog(...) (void)0
#endif

@interface TruncationLabel ()
{
    BOOL _isDirty;
    NSAttributedString *_renderFirstText;
    NSAttributedString *_renderLastText;
}

@end

@implementation TruncationLabel

- (void)setNumberOfLines:(NSInteger)numberOfLines {
    if (_numberOfLines == numberOfLines) return;;
    _numberOfLines = numberOfLines;
    [self _markDirty];
}

- (void)setFirstText:(id)firstText {
    NSAssert(!firstText || [firstText isKindOfClass:[NSString class]] || [firstText isKindOfClass:[NSAttributedString class]], @"firstText error type \(%@)", NSStringFromClass([firstText class]));
    if ([firstText isEqual:self.firstText]) return;
    _firstText = firstText;
    
    if ([firstText isKindOfClass:[NSString class]]) {
        _renderFirstText = [[NSAttributedString alloc] initWithString:firstText attributes:@{
            NSForegroundColorAttributeName: [UIColor.whiteColor colorWithAlphaComponent:0.5],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSParagraphStyleAttributeName: self.defaultStyle,
        }];
    } else if ([firstText isKindOfClass:[NSAttributedString class]]) {
        _renderFirstText = firstText;
    }
    [self _markDirty];
}

- (void)setLastText:(id)lastText {
    NSAssert(!lastText || [lastText isKindOfClass:[NSString class]] || [lastText isKindOfClass:[NSAttributedString class]], @"lastText error type \(%@)", NSStringFromClass([lastText class]));
    if ([lastText isEqual:self.lastText]) return;
    _lastText = lastText;
    
    if ([lastText isKindOfClass:[NSString class]]) {
        NSMutableParagraphStyle *style = self.defaultStyle;
//        style.alignment = NSTextAlignmentRight; // alignment不会改变计算的width，只会改变origin
        _renderLastText = [[NSAttributedString alloc] initWithString:lastText attributes:@{
            NSForegroundColorAttributeName: [UIColor.whiteColor colorWithAlphaComponent:0.7],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSParagraphStyleAttributeName: style,
        }];
    } else if ([lastText isKindOfClass:[NSAttributedString class]]) {
        _renderLastText = lastText;
    }
    [self _markDirty];
}

- (NSMutableParagraphStyle *)defaultStyle {
    NSMutableParagraphStyle *style = NSParagraphStyle.defaultParagraphStyle.mutableCopy;
    style.minimumLineHeight = 20;
    return style;
}

- (void)_markDirty {
    _isDirty = YES;
    
    [self setNeedsLayout];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    if (!_isDirty) return;
    _isDirty = NO;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, - 1.0);
    
    CTFramesetterRef firstFramesetter, lastFramesetter;
    CTFrameRef firstFrame, lastFrame;
    NSInteger firstMaxLinesCount = 0, lastMaxLinesCount = 0;
    CFArrayRef firstLines, lastLines;
    CFIndex firstLinesCount = 0, lastLinesCount = 0;
    CGPoint *firstOrigins = NULL, *lastOrigins = NULL;
    CGPoint lastOrigin = CGPointZero;
    NSInteger truncationLineIndex = -1;
    double truncationLineWidth = 0;
    BOOL needTruncate = false;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    
    // first text
    firstFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) _renderFirstText);
    if (firstFramesetter) {
        firstFrame = CTFramesetterCreateFrame(firstFramesetter, CFRangeMake(0, 0), path, NULL);
        firstLines = CTFrameGetLines(firstFrame);
        firstLinesCount = CFArrayGetCount(firstLines );
        firstOrigins = malloc(firstLinesCount * sizeof(CGPoint));
        CTFrameGetLineOrigins(firstFrame, CFRangeMake(0, 0), firstOrigins);
    }
    // last text
    lastFramesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) _renderLastText);
    if (lastFramesetter) {
        lastFrame = CTFramesetterCreateFrame(lastFramesetter, CFRangeMake(0, 0), path, NULL);
        lastLines = CTFrameGetLines(lastFrame);
        lastLinesCount = CFArrayGetCount(lastLines );
        lastOrigins = malloc(lastLinesCount * sizeof(CGPoint));
        CTFrameGetLineOrigins(lastFrame, CFRangeMake(0, 0), lastOrigins);
    }
    if (self.numberOfLines == 0) {
        firstMaxLinesCount = firstLinesCount;
        lastMaxLinesCount = lastLinesCount;
    } else {
        // 优先绘制last text
        lastMaxLinesCount = lastLinesCount;
        firstMaxLinesCount = MIN(self.numberOfLines - lastLinesCount + 1, firstLinesCount);
    }
    // 判断是否需要截取
    if (self.numberOfLines != 0) {
        NSMutableAttributedString *tmp = [[NSMutableAttributedString alloc] init];
        [tmp appendAttributedString:_renderFirstText];
        [tmp appendAttributedString:_renderLastText];
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) tmp);
        // TODO: 方法1
//        CGSize suggestSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(rect.size.width, CGFLOAT_MAX), nil);
//        needTruncate = suggestSize > self.frame.size.height;
        CGMutablePathRef path = CGPathCreateMutable();
        // TODO: 方法2
//        CGPathAddRect(path, NULL, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, CGFLOAT_MAX)); // 如果是固定的rect，并不会计算出多余的行数
        CGPathAddRect(path, NULL, rect); // 如果是固定的rect，并不会计算出多余的行数
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        CFIndex linesCount = CFArrayGetCount(lines);
        XLog(@"%@: lines: %ld", tmp.string, (long)linesCount);
        needTruncate = linesCount > self.numberOfLines;
        
        if (needTruncate) { // 需要截断
            // 计算出截断的第几行
            truncationLineIndex = self.numberOfLines - lastLinesCount;
            CTLineRef lastLine = CFArrayGetValueAtIndex(lastLines, lastLinesCount - 1);
            truncationLineWidth = CTLineGetTypographicBounds(lastLine, NULL, NULL, NULL);
            XLog(@"truncationLineWidth: %f", truncationLineWidth);
        } else {
            CTFrameDraw(frame, context);
        }
    }
    
    return;
    
    // 获取last text的line
//    __auto_type lastTextLine = CTLineCreateWithAttributedString((CFAttributedStringRef) _renderLastText);
//    CGFloat ascent = 0, descent = 0, leading = 0;
//    double lastTextLineWidth = CTLineGetTypographicBounds(lastTextLine, &ascent, &descent, &leading);
    
    // 绘制 first text
    int i = 0;
    for (; i < firstMaxLinesCount; i++) {
        __auto_type lineOrigin = firstOrigins[i];
        CTLineRef line = CFArrayGetValueAtIndex(firstLines, i);
        XLog(@"line origin: %@", NSStringFromCGPoint(lineOrigin));
        // last line hanle
        CTLineRef lastLine = nil;
        if (i == truncationLineIndex && _renderLastText) {
            CFRange range = CTLineGetStringRange(line);
            XLog(@"range: {%ld, %ld}}", range.location, range.length);
            NSRange endLineRange = NSMakeRange(range.location, 0);
            endLineRange.length  = [_renderFirstText length] - endLineRange.location;
            NSAttributedString *endString = [_renderFirstText attributedSubstringFromRange:endLineRange];
            CTLineRef endLine = CTLineCreateWithAttributedString((CFAttributedStringRef) endString);
            // truncation
            NSDictionary *attributes  = [_renderFirstText attributesAtIndex:range.location + range.length - 1 effectiveRange:NULL];
            NSAttributedString *token = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:attributes];
            CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) token);
            lastLine = CTLineCreateTruncatedLine(endLine, rect.size.width - truncationLineWidth, kCTLineTruncationEnd, truncationToken);
            
            CFRelease(truncationToken);
            CFRelease(endLine);
        }
        if (lastLine) {
            lastOrigin = CGPointMake(lineOrigin.x + rect.size.width - truncationLineWidth, lineOrigin.y);
            CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
            CTLineDraw(lastLine, context);
            CFRelease(lastLine);
        } else {
            double width = CTLineGetTypographicBounds(line, NULL, NULL, NULL);
            XLog(@"line width: %f", width);
            lastOrigin = CGPointMake(lineOrigin.x + width, lineOrigin.y);
            CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
            CTLineDraw(line, context);
        }
    }
    // draw last text
    if (_renderFirstText.length == 0) { // 没有 first text
        // TODO: lihui02 为什么是25？？？
        lastOrigin = CGPointMake(0, 25);
        CGContextSetTextPosition(context, lastOrigin.x, lastOrigin.y);
    }
//    double remainingLength = rect.size.width - lastOrigin.x;
//    __auto_type typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef) _renderLastText);
//    if (typesetter) {
//        CFIndex breakIndex = CTTypesetterSuggestLineBreak(typesetter, 0, remainingLength);
//        if (breakIndex < _renderLastText.length) {
//            // draw last line 1
//            __auto_type lastLine1 = CTLineCreateWithAttributedString((CFAttributedStringRef) [_renderLastText attributedSubstringFromRange:NSMakeRange(0, breakIndex)]);
//            CTLineDraw(lastLine1, context);
//            CFRelease(lastLine1);
////            CTLineDraw(renderLastLine, context); // 这个也可以，绘制多出来的也不会有问题
//            // draw last line 2
//            __auto_type lastLine2 = CTLineCreateWithAttributedString((CFAttributedStringRef) [_renderLastText attributedSubstringFromRange:NSMakeRange(breakIndex, _renderLastText.length - breakIndex)]);
//            CGContextSetTextPosition(context, 0, lastOrigin.y - (ascent + descent + leading));
//            CTLineDraw(lastLine2, context);
//            CFRelease(lastLine2);
//        } else {
//            CTLineDraw(lastTextLine, context);
//        }
//        CFRelease(typesetter);
//    }
    
    // 绘制 last text
    for (int i = 0; i < lastMaxLinesCount; i++) {
        __auto_type lineOrigin = lastOrigins[i];
        CTLineRef line = CFArrayGetValueAtIndex(lastLines, i);
        XLog(@"line origin: %@", NSStringFromCGPoint(lineOrigin));
        // last line hanle
        if (i == truncationLineIndex) {
            CGContextSetTextPosition(context, lineOrigin.x + lastOrigin.x, lineOrigin.y);
            CTLineDraw(line, context);
        } else {
            CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
            CTLineDraw(line, context);
        }
    }
    
//    CTLineDraw(CFArrayGetValueAtIndex(lastLines, 0), context);
    
    
//    CFRelease(frame);
//    CFRelease(path);
    
    if (firstFramesetter) CFRelease(firstFramesetter);
    if (lastFramesetter) CFRelease(lastFramesetter);
//    if (lastTextLine) CFRelease(lastTextLine);
}

@end
