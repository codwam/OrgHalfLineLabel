//
//  ViewController.m
//  OrgHalfLineLabel
//
//  Created by 66-admin on 2018/5/3.
//  Copyright © 2018年 66-admin. All rights reserved.
//

#import "ViewController.h"
#import "OrgHalfLineLabel.h"
#import "TruncationLabel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSString * halfStr = @"我志愿加入中国共产党，拥护党的纲领，遵守党的章程，履行党员义务，执行党的决定，严守党的纪律，保守党的秘密，对党忠诚，积极工作，为共产主义奋斗终身，随时准备为党和人民牺牲一切，永不叛党。";
    
    //NSString * halfStr = @"I volunteered to join the Communist Party of China, adhered to the party's programme, adhered to the party's statute, fulfilled the party's obligations, carried out the party's decisions, strictly adhered to the party's discipline, conserved the secret of the party, worked hard for the party, worked hard for the Communist Party, and was ready to sacrifice the party and the people at any time and never rebel.";
    
    OrgHalfLineLabel * label1 = [[OrgHalfLineLabel alloc] initWithFrame:CGRectMake(10.f, 40.f, self.view.frame.size.width - 20.f, 100.f)];
    label1.backgroundColor = [UIColor lightGrayColor];
    label1.numberOfLines   = 0;
    label1.orgLineSpacing  = 5.f;
    label1.orgCharSpacing  = 0.5;
    label1.orgLastLineRightIndent = 150.f;
    label1.orgTruncationEndAttributedString = [self orgSetAttributedStringStyle:@" 更多"];
    label1.text = halfStr;
    [self.view addSubview:label1];
    
//    OrgHalfLineLabel * label4 = [[OrgHalfLineLabel alloc] initWithFrame:CGRectMake(10.f, CGRectGetMaxY(label1.frame) + 10.f, label1.frame.size.width, label1.frame.size.height)];
//    label4.backgroundColor = [UIColor lightGrayColor];
//    label4.numberOfLines   = 0;
//    label4.lineBreakMode   = NSLineBreakByCharWrapping;
//    label4.orgLineSpacing  = 5.f;
//    label4.orgCharSpacing  = 0.5;
//    label4.orgTruncationEndAttributedString = [self orgSetAttributedStringStyle:@" 更多"];
//    label4.text = halfStr;
//    [self.view addSubview:label4];
    
//    OrgHalfLineLabel * label2 = [[OrgHalfLineLabel alloc] initWithFrame:CGRectMake(10.f, CGRectGetMaxY(label4.frame) + 10.f, label1.frame.size.width, 180.f)];
//    label2.backgroundColor = [UIColor lightGrayColor];
//    label2.numberOfLines   = 0;
//    label2.orgLineSpacing  = 5.f;
//    label2.orgCharSpacing  = 0.5;
//    label2.text = halfStr;
//    [self.view addSubview:label2];
    
//    OrgHalfLineLabel * label3 = [[OrgHalfLineLabel alloc] initWithFrame:CGRectMake(10.f, CGRectGetMaxY(label2.frame) + 10.f, label1.frame.size.width, label2.frame.size.height)];
//    label3.backgroundColor = [UIColor lightGrayColor];
//    label3.numberOfLines   = 0;
//    label3.orgLineSpacing  = 5.f;
//    label3.orgCharSpacing  = 0.5;
//    label3.orgVerticalTextAlignment = OrgHLVerticalTextAlignmentBottom;
//    label3.text = halfStr;
//    [self.view addSubview:label3];
    
    {
        CGFloat height = 40.0;
        NSArray *ranges = @[
            [NSValue valueWithRange:NSMakeRange(0, 0)],
            [NSValue valueWithRange:NSMakeRange(0, 1)],
            
            [NSValue valueWithRange:NSMakeRange(0, 26)],
            [NSValue valueWithRange:NSMakeRange(0, 27)],
            [NSValue valueWithRange:NSMakeRange(0, 28)], // 刚好一行
            [NSValue valueWithRange:NSMakeRange(0, 29)],

            [NSValue valueWithRange:NSMakeRange(0, halfStr.length)],
        ];
        TruncationLabel *lastLabel;
        for (int i = 0; i < ranges.count; i++) {
            NSRange range = [ranges[i] rangeValue];
            NSString *str1 = [halfStr substringWithRange:range];
            TruncationLabel *_label1 = [[TruncationLabel alloc] initWithFrame:CGRectMake(10.f, CGRectGetMaxY(label1.frame) + 10.f * (i + 1) + height * i, self.view.frame.size.width - 20.f, height)];
            _label1.backgroundColor = UIColor.darkGrayColor;
            _label1.numberOfLines = 2;
            _label1.firstText = str1;
            _label1.lastText = @"#我是一个标签";
            [self.view addSubview:_label1];
            lastLabel = _label1;
        }
        // Special Case
//#define NilOrEmpty (@"")
#define NilOrEmpty (@"nil")
        NSArray *texts =@[
            @[@"我", NilOrEmpty],
            @[NilOrEmpty, @"#我是一个标签"],
            @[NilOrEmpty, NilOrEmpty],
            
            @[[halfStr substringWithRange:NSMakeRange(0, 30)], @"#我是一个长标签我是一个长标签我是一个长标签我是一个长标签我是一个长标签"],
        ];
        for (int i = 0; i < texts.count; i++) {
            TruncationLabel *_label1 = [[TruncationLabel alloc] initWithFrame:CGRectMake(10.f, CGRectGetMaxY(lastLabel.frame) + 10.f * (i + 1) + height * i, self.view.frame.size.width - 20.f, height)];
            _label1.backgroundColor = UIColor.darkGrayColor;
            _label1.numberOfLines = 2;
            _label1.firstText = [[texts[i] firstObject]  isEqual: @"nil"] ? nil : [texts[i] firstObject];
            _label1.lastText = [[texts[i] lastObject]  isEqual: @"nil"] ? nil : [texts[i] lastObject];
            [self.view addSubview:_label1];
        }
    }
}

- (NSMutableAttributedString *)orgSetAttributedStringStyle:(NSString *)string {
    
    if (!string) {
        return nil;
    }
    
    NSMutableParagraphStyle * style = [[NSMutableParagraphStyle alloc] init];
    style.paragraphSpacing = 0;
    
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    NSDictionary * attributes = @{NSForegroundColorAttributeName : [UIColor redColor],
                                  NSFontAttributeName : [UIFont systemFontOfSize:16],
                                  NSKernAttributeName : @(0.5)};
    [attributedString addAttributes:attributes range:NSMakeRange(0, [attributedString length])];
    
    return attributedString;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)injected {
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self viewDidLoad];
}

@end
