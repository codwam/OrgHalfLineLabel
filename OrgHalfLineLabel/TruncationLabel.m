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
        _renderLastText = [[NSAttributedString alloc] initWithString:lastText attributes:@{
            NSForegroundColorAttributeName: [UIColor.whiteColor colorWithAlphaComponent:0.7],
            NSFontAttributeName: [UIFont systemFontOfSize:14],
            NSParagraphStyleAttributeName: self.defaultStyle,
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
    // 判断是否需要截取
    {
        NSMutableAttributedString *tmp = [[NSMutableAttributedString alloc] init];
        [tmp appendAttributedString:_renderFirstText];
        [tmp appendAttributedString:_renderLastText];
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) tmp);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, CGFLOAT_MAX)); // 如果是固定的rect，并不会计算出多余的行数
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        CFIndex linesCount = CFArrayGetCount(lines);
        XLog(@"%@: lines: %ld", tmp.string, (long)linesCount);
    }
    if (self.numberOfLines == 0) {
        firstMaxLinesCount = firstLinesCount;
        lastMaxLinesCount = lastLinesCount;
    } else {
        // 优先绘制last text
        lastMaxLinesCount = lastLinesCount;
        firstMaxLinesCount = MIN(self.numberOfLines - lastLinesCount + 1, firstLinesCount);
    }
    
    // 获取last text的line
    __auto_type lastTextLine = CTLineCreateWithAttributedString((CFAttributedStringRef) _renderLastText);
    CGFloat ascent = 0, descent = 0, leading = 0;
    double lastTextLineWidth = CTLineGetTypographicBounds(lastTextLine, &ascent, &descent, &leading);
    
    // 绘制 first text
    for (int i = 0; i < firstMaxLinesCount; i++) {
        __auto_type lineOrigin = firstOrigins[i];
        CTLineRef line = CFArrayGetValueAtIndex(firstLines, i);
        XLog(@"lineOrigin: %@", NSStringFromCGPoint(lineOrigin));
        // last line hanle
        CTLineRef lastLine = nil;
        if (i == firstMaxLinesCount - 1 && _renderLastText) {
            CFRange range = CTLineGetStringRange(line);
            XLog(@"range: {%ld, %ld}}", range.location, range.length);
            NSRange endLineRange = NSMakeRange(range.location, 0);
            endLineRange.length  = [_renderFirstText length] - endLineRange.location;
            
            NSAttributedString *endString = [_renderFirstText attributedSubstringFromRange:endLineRange];
            NSMutableAttributedString *tmpString = [[NSMutableAttributedString alloc] init];
            [tmpString appendAttributedString:endString];
            [tmpString appendAttributedString:_renderLastText];
            CTLineRef endLine = CTLineCreateWithAttributedString((CFAttributedStringRef) tmpString);
            // truncation
            NSDictionary *attributes  = [_renderFirstText attributesAtIndex:range.location + range.length - 1 effectiveRange:NULL];
            NSAttributedString *token = [[NSAttributedString alloc] initWithString:@"\u2026" attributes:attributes];
            CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef) token);
            lastLine = CTLineCreateTruncatedLine(endLine, rect.size.width, kCTLineTruncationEnd, truncationToken);
            // 如果截取了，恢复原来的字符串
            if (lastLine) {
                endLine = CTLineCreateWithAttributedString((CFAttributedStringRef) endString);
                lastLine = CTLineCreateTruncatedLine(endLine, rect.size.width - lastTextLineWidth, kCTLineTruncationEnd, truncationToken);
            }
            
            CFRelease(endLine);
            CFRelease(truncationToken);
        }
        if (lastLine) {
            double width = CTLineGetTypographicBounds(lastLine, NULL, NULL, NULL);
            XLog(@"lastLine width: %f", width);
            lastOrigin = CGPointMake(lineOrigin.x + width, lineOrigin.y);
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
    double remainingLength = rect.size.width - lastOrigin.x;
    
    // TODO: lihui02 这个不知道为什有时截断不了，必须继续增加length才可以
//        CTLineRef lastLine = NULL;
//        while (remainingLength < width && lastLine == NULL) {
//            lastLine = CTLineCreateTruncatedLine(renderLastLine, remainingLength, kCTLineTruncationEnd, NULL);
//            remainingLength += 1;
//        }
//        if (lastLine) {
//            CGFloat ascent = 0, descent = 0, leading = 0;
//            double width = CTLineGetTypographicBounds(lastLine, &ascent, &descent, &leading);
//            CFIndex index = CTLineGetStringIndexForPosition(renderLastLine, CGPointMake(width, 0));
//            CTLineDraw(lastLine, context);
//            // draw remaining words
//            __auto_type remainingWords = CTLineCreateWithAttributedString((CFAttributedStringRef) [_renderLastText attributedSubstringFromRange:NSMakeRange(index, _renderLastText.length - index)]);
//            CGContextSetTextPosition(context, 0, lastOrigin.y - (ascent + descent + leading));
//            CTLineDraw(remainingWords, context);
//            CFRelease(remainingWords);
//        } else {
//            CTLineDraw(renderLastLine, context);
//        }
    
    __auto_type typesetter = CTTypesetterCreateWithAttributedString((CFAttributedStringRef) _renderLastText);
    if (typesetter) {
        CFIndex breakIndex = CTTypesetterSuggestLineBreak(typesetter, 0, remainingLength);
        if (breakIndex < _renderLastText.length) {
            // draw last line 1
            __auto_type lastLine1 = CTLineCreateWithAttributedString((CFAttributedStringRef) [_renderLastText attributedSubstringFromRange:NSMakeRange(0, breakIndex)]);
            CTLineDraw(lastLine1, context);
            CFRelease(lastLine1);
//            CTLineDraw(renderLastLine, context); // 这个也可以，绘制多出来的也不会有问题
            // draw last line 2
            __auto_type lastLine2 = CTLineCreateWithAttributedString((CFAttributedStringRef) [_renderLastText attributedSubstringFromRange:NSMakeRange(breakIndex, _renderLastText.length - breakIndex)]);
            CGContextSetTextPosition(context, 0, lastOrigin.y - (ascent + descent + leading));
            CTLineDraw(lastLine2, context);
            CFRelease(lastLine2);
        } else {
            CTLineDraw(lastTextLine, context);
        }
        CFRelease(typesetter);
    }
    
//    CFRelease(frame);
//    CFRelease(path);
    
    if (firstFramesetter) CFRelease(firstFramesetter);
    if (lastFramesetter) CFRelease(lastFramesetter);
    if (lastTextLine) CFRelease(lastTextLine);
}

@end
