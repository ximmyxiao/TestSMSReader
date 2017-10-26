//
//  MsgCell.m
//  SMSCell
//
//  Created by Piao Piao on 2017/3/6.
//  Copyright © 2017年 Piao Piao. All rights reserved.
//

#import "MsgCell.h"
@implementation MsgModel
@end

@implementation MsgCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {
        self.authorLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, 20)];
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 10 - 100, 10, 100, 20)];
        self.timeLabel.textAlignment = NSTextAlignmentRight;
        self.contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, [UIScreen mainScreen].bounds.size.width - 20, 80)];
        self.contentLabel.numberOfLines = 0;

        [self.contentView addSubview:self.authorLabel];
        [self.contentView addSubview:self.timeLabel];
        [self.contentView addSubview:self.contentLabel];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

    }
    return self;
}

- (void)prepareForReuse
{
    
}
- (void)setMsgContent:(NSString*)msgContent
{
    _msgContent = msgContent;
    self.contentLabel.text = msgContent;
    [self.contentLabel sizeToFit];
    self.contentLabel.frame = CGRectMake(10, 4, [UIScreen mainScreen].bounds.size.width - 20, self.contentLabel.bounds.size.height);
}

- (void)setModel:(MsgModel *)model
{
    _model = model;
    self.authorLabel.text = model.msgsender;
    self.timeLabel.text = model.msgTime;
    self.contentLabel.text = model.msgContent;
    [self.contentLabel sizeToFit];
    self.contentLabel.frame = CGRectMake(10, 4, [UIScreen mainScreen].bounds.size.width - 20, self.contentLabel.bounds.size.height);
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
