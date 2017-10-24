//
//  MsgCell.h
//  SMSCell
//
//  Created by Piao Piao on 2017/3/6.
//  Copyright © 2017年 Piao Piao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MsgModel : NSObject
@property(nonatomic,strong) NSString* msgsender;
@property(nonatomic,strong) NSString* msgTime;
@property(nonatomic,strong) NSString* msgContent;
@property(nonatomic,assign) BOOL isSend;

@end

@interface MsgCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *authorLabel;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *contentLabel;
@property(nonatomic,strong) MsgModel* model;
@property(nonatomic,strong) NSString* msgContent;
@end
