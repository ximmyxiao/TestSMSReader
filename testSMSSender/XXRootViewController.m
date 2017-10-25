#import "XXRootViewController.h"
#import "FMDB.h"
#import "MsgCell.h"
#import "GCDAsyncSocket.h"
#import <CoreTelephony/CoreTelephonyDefines.h>

@interface CTMessageCenter : NSObject
+ (id)sharedMessageCenter;
- (void)acknowledgeIncomingMessageWithId:(unsigned int)arg1;
- (void)acknowledgeOutgoingMessageWithId:(unsigned int)arg1;
- (void)addMessageOfType:(int)arg1 toArray:(id)arg2 withIdsFromArray:(id)arg3;
- (id)allIncomingMessages;
- (void)dealloc;
- (id)decodeMessage:(id)arg1;
- (id)deferredMessageWithId:(unsigned int)arg1;
- (id)encodeMessage:(id)arg1;
- (bool)getCharacterCount:(long long*)arg1 andMessageSplitThreshold:(long long*)arg2 forSmsText:(id)arg3;
- (int)incomingMessageCount;
- (id)incomingMessageWithId:(unsigned int)arg1;
- (id)incomingMessageWithId:(unsigned int)arg1 isDeferred:(bool)arg2;
- (id)init;
- (struct { int x1; int x2; })isDeliveryReportsEnabled:(bool*)arg1;
- (bool)isMmsConfigured;
- (bool)isMmsEnabled;
- (struct { int x1; int x2; })send:(id)arg1;
- (struct { int x1; int x2; })send:(id)arg1 withMoreToFollow:(bool)arg2;
- (struct { int x1; int x2; })sendMMS:(id)arg1;
- (struct { int x1; int x2; })sendMMSFromData:(id)arg1 messageId:(unsigned int)arg2;
- (void)sendMessageAsSmsToShortCodeRecipients:(id)arg1 andReplaceData:(id*)arg2;
- (struct { int x1; int x2; })sendSMS:(id)arg1 withMoreToFollow:(bool)arg2;
- (bool)sendSMSWithText:(id)arg1 serviceCenter:(id)arg2 toAddress:(id)arg3;
- (bool)sendSMSWithText:(id)arg1 serviceCenter:(id)arg2 toAddress:(id)arg3 withID:(unsigned int)arg4;
- (bool)sendSMSWithText:(id)arg1 serviceCenter:(id)arg2 toAddress:(id)arg3 withMoreToFollow:(bool)arg4;
- (bool)sendSMSWithText:(id)arg1 serviceCenter:(id)arg2 toAddress:(id)arg3 withMoreToFollow:(bool)arg4 withID:(unsigned int)arg5;
- (void)setDeliveryReportsEnabled:(bool)arg1;
- (bool)simulateDeferredMessage;
- (bool)simulateSmsReceived:(id)arg1;
- (id)statusOfOutgoingMessages;
@end

#define TOTAL_HEADER_HEIGHT (260)

#define SERVER_RETURN_STEP_0_OK @"0|0|ok|"
#define SERVER_RETURN_STEP_1_OK @"1|0"

typedef NS_ENUM(NSInteger,SOCKET_STATE) {
    SOCKET_NOT_CONNECT = 0,
    SOCKET_IN_CONNECT,
};

@interface XXRootViewController()<GCDAsyncSocketDelegate,UITextFieldDelegate,UITableViewDelegate,UITableViewDataSource>
@property(nonatomic,strong) NSMutableArray* allMsgs;
@property(nonatomic,strong) UITextField* ipTF;
@property(nonatomic,strong) UITextField* accountTF;
@property(nonatomic,strong) UITextField* sendToTF;
@property(nonatomic,strong) UILabel* cellStringLabel;
@property(nonatomic,strong) UILabel* codeLabel;
@property(nonatomic,strong) GCDAsyncSocket* socket;
@property(nonatomic,strong) NSString* selectContent;
@property(nonatomic,strong) NSString* dbPath;
@property(nonatomic, assign)SOCKET_STATE socketState;
@property(nonatomic,assign) NSInteger lastHeartBeatInterval;
@property(nonatomic,strong) NSMutableArray* allLogs;
@property(nonatomic,strong) UITableView* tableView;
@end

@implementation XXRootViewController {
	NSMutableArray *_objects;
}

- (void)showAlertMessage:(NSString*) msg
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:msg message:nil delegate:nil cancelButtonTitle:nil  otherButtonTitles:@"OK", nil];
    [alertView show];
}

- (void)loadSMSData
{
    NSMutableArray* thisTimeFetch = [NSMutableArray array];

    
    NSString * path = self.dbPath;
    
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    
    if (![db open]) {
        [self showAlertMessage:@"Could not open db."];
    }
    
    NSInteger count = [db intForQuery:@"SELECT count(*) FROM message"];
//    NSString* countString = [NSString stringWithFormat:@"total msg count:%ld",(long)count];
//    [self showAlertMessage:countString];
    [self DLog:[NSString stringWithFormat:@"msg count:%ld",(long)count]];

    NSDateFormatter* dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    FMResultSet *rs = [db executeQuery:@"SELECT guid,text,date FROM message"];
    while ([rs next]) {
        ;
        
        NSString* guid = [rs stringForColumn:@"guid"];
        NSString* text = [rs stringForColumn:@"text"];
        NSInteger interval = [rs intForColumn:@"date"];
        if ([[NSDate date] timeIntervalSince1970] - interval > 24*3600)
        {
            continue;
        }
        NSDate* sendDate = [NSDate dateWithTimeIntervalSince1970:interval];
        MsgModel* model = [MsgModel new];
        model.msgsender = guid;
        model.msgContent = text;
        model.msgTime = [dateFormat stringFromDate:sendDate];
        [thisTimeFetch addObject:model];
        
        
        
    }
    // close the result set.
    // it'll also close when it's dealloc'd, but we're closing the database before
    // the autorelease pool closes, so sqlite will complain about it.
    [rs close];
    
    [db close];
    
//    MsgModel* model = [MsgModel new];
//    model.msgsender = @"1312424242";
//    model.msgContent = @"sfdjaslfdjlaksfjkasjfdkasjfa";
//    model.msgTime = @"2017-03-17 19:00:00";
//    [thisTimeFetch addObject:model];
    self.allMsgs = thisTimeFetch;
    
}

- (void)setAllMsgs:(NSMutableArray *)allMsgs
{
    _allMsgs = allMsgs;
    [self.tableView reloadData];
}

- (NSString*)isAnyNewMsgComing
{
    NSString* newMsg;
    NSMutableArray* thisTimeFetch = [NSMutableArray array];
    
    
    NSString * path = self.dbPath;
    
    FMDatabase *db = [FMDatabase databaseWithPath:path];
    
    if (![db open]) {
        [self showAlertMessage:@"Could not open db."];
    }
    
    NSInteger count = [db intForQuery:@"SELECT count(*) FROM message"];
    //    NSString* countString = [NSString stringWithFormat:@"total msg count:%ld",(long)count];
    //    [self showAlertMessage:countString];
    [self DLog:[NSString stringWithFormat:@"msg count:%ld",(long)count]];
    
    NSDateFormatter* dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    FMResultSet *rs = [db executeQuery:@"SELECT guid,text,date FROM message"];
    while ([rs next]) {
        ;
        
        NSString* guid = [rs stringForColumn:@"guid"];
        NSString* text = [rs stringForColumn:@"text"];
        NSInteger interval = [rs intForColumn:@"date"];
        if ([[NSDate date] timeIntervalSince1970] - interval > 24*3600)
        {
            continue;
        }
        NSDate* sendDate = [NSDate dateWithTimeIntervalSince1970:interval];
        MsgModel* model = [MsgModel new];
        model.msgsender = guid;
        model.msgContent = text;
        model.msgTime = [dateFormat stringFromDate:sendDate];
        newMsg = text;
        [thisTimeFetch addObject:model];
        
        
        
    }
    // close the result set.
    // it'll also close when it's dealloc'd, but we're closing the database before
    // the autorelease pool closes, so sqlite will complain about it.
    [rs close];
    
    [db close];
    
    return newMsg;
    
}

- (void)checkAndSend
{
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        for (;;)
        {
            NSString* newMsg = [self isAnyNewMsgComing];
            if ([newMsg length] > 0)
            {
                break;
            }
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSString* newMsg = [self isAnyNewMsgComing];
        //2|0|收到的验证码\t手机号|帐号标识
        NSString* codeMsg = [NSString stringWithFormat:@"2|0|%@\t15920087392|%@",newMsg,self.accountTF.text];
        [self sendContent:codeMsg];
    });
}

- (void)testFunc
{
    NSString*readContent = @"0|0|ok|";
    if ([readContent compare:SERVER_RETURN_STEP_0_OK options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        [self startHeartBeatCheck];
        [self sendHeartBeat];
    }
    else if ([readContent hasPrefix:SERVER_RETURN_STEP_1_OK])
    {
        //1|0|发送的短信内容||
        NSArray* array = [readContent componentsSeparatedByString:@"|"];
        if ([array count] >= 3)
        {
            NSString* code = array[2];
            [self needSendMsgWithCode:code];
            
        }
        else
        {
            [self DLog:@"step 1 ok return error"];
        }
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.allLogs = [NSMutableArray array];
    self.edgesForExtendedLayout = UIRectEdgeTop;
    
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, TOTAL_HEADER_HEIGHT)];
    headerView.backgroundColor = [UIColor colorWithRed:0xec/255.0 green:0xec/255.0 blue:0xec/255.0 alpha:1];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [self.view addSubview:headerView];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, headerView.frame.size.height, [UIScreen mainScreen].bounds.size.width, self.view.bounds.size.height - headerView.frame.size.height) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[MsgCell class] forCellReuseIdentifier:@"MsgCell"];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];

    CGFloat topPad = 10;
    CGFloat bottomPad = 10;
    
    CGFloat yOrigin = topPad;
    
    UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, yOrigin, 100, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.text = @"电脑端地址";
    label.textAlignment = NSTextAlignmentRight;
    [headerView addSubview:label];

    NSString* lastIP = [[NSUserDefaults standardUserDefaults] objectForKey:@"LastIP"];
    if ([lastIP length] == 0)
    {
        lastIP = @"139.224.24.162:8732";
    }
    
//    lastIP = @"127.0.0.1:5000";
    self.ipTF = [[UITextField alloc] initWithFrame:CGRectMake(120, yOrigin, 200, 20)];
    self.ipTF.backgroundColor = [UIColor whiteColor];
    self.ipTF.text = lastIP;
    self.ipTF.delegate = self;
    self.ipTF.placeholder = @"请输入电脑端的手机连接地址";
    self.ipTF.font = [UIFont systemFontOfSize:14];
    [headerView addSubview:self.ipTF];
    
    yOrigin += 20;
    yOrigin += bottomPad;
    
    UIView* lineView = [[UIView alloc] initWithFrame:CGRectMake(0, yOrigin, [UIScreen mainScreen].bounds.size.width, 1)];
    lineView.backgroundColor = [UIColor lightGrayColor];
    [headerView addSubview:lineView];

    yOrigin += topPad;

    UILabel* labelAccount = [[UILabel alloc] initWithFrame:CGRectMake(0, yOrigin, 100, 20)];
    labelAccount.backgroundColor = [UIColor clearColor];
    labelAccount.text = @"账号标识";
    labelAccount.textAlignment = NSTextAlignmentRight;
    [headerView addSubview:labelAccount];

    self.accountTF = [[UITextField alloc] initWithFrame:CGRectMake(120,yOrigin,200, 20)];
    self.accountTF.backgroundColor = [UIColor whiteColor];
    self.accountTF.text = @"39432.1";
    self.accountTF.placeholder = @"请输入电脑端显示的账号标识";
    self.accountTF.font = [UIFont systemFontOfSize:14];

    [headerView addSubview:self.accountTF];
    
    yOrigin += 20;
    yOrigin += 10;
    
    UIView* lineView2 = [[UIView alloc] initWithFrame:CGRectMake(0, yOrigin, [UIScreen mainScreen].bounds.size.width, 1)];
    lineView2.backgroundColor = [UIColor lightGrayColor];
    [headerView addSubview:lineView2];
    yOrigin += topPad;

    UILabel* labelSendTo = [[UILabel alloc] initWithFrame:CGRectMake(0, yOrigin, 100, 20)];
    labelSendTo.backgroundColor = [UIColor clearColor];
    labelSendTo.text = @"发送短信到";
    labelSendTo.textAlignment = NSTextAlignmentRight;
    [headerView addSubview:labelSendTo];
    
    self.sendToTF = [[UITextField alloc] initWithFrame:CGRectMake(120,yOrigin,200, 20)];
    self.sendToTF.backgroundColor = [UIColor whiteColor];
    self.sendToTF.text = @"";
    self.sendToTF.placeholder = @"";
    [headerView addSubview:self.sendToTF];
    
    yOrigin += 20;
    yOrigin += 10;
    
    UIView* lineView3 = [[UIView alloc] initWithFrame:CGRectMake(0, yOrigin, [UIScreen mainScreen].bounds.size.width, 1)];
    lineView3.backgroundColor = [UIColor lightGrayColor];
    [headerView addSubview:lineView3];
    yOrigin += topPad;

    UILabel* labelCellString = [[UILabel alloc] initWithFrame:CGRectMake(0, yOrigin, 100, 20)];
    labelCellString.backgroundColor = [UIColor clearColor];
    labelCellString.text = @"手机字符串";
    labelCellString.textAlignment = NSTextAlignmentRight;
    [headerView addSubview:labelCellString];
    
    
    self.cellStringLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, yOrigin, 200, 20)];
    self.cellStringLabel.backgroundColor = [UIColor clearColor];
    self.cellStringLabel.text = @"";
    self.cellStringLabel.textAlignment = NSTextAlignmentLeft;
    [headerView addSubview:self.cellStringLabel];
    
    yOrigin += 20;
    yOrigin += 10;
    
    UIView* lineView4 = [[UIView alloc] initWithFrame:CGRectMake(0, yOrigin, [UIScreen mainScreen].bounds.size.width, 1)];
    lineView4.backgroundColor = [UIColor lightGrayColor];
    [headerView addSubview:lineView4];
    yOrigin += topPad;

    UILabel* labelCode = [[UILabel alloc] initWithFrame:CGRectMake(0, yOrigin, 100, 20)];
    labelCode.backgroundColor = [UIColor clearColor];
    labelCode.text = @"预定代码";
    labelCode.textAlignment = NSTextAlignmentRight;
    [headerView addSubview:labelCode];
    
    
    self.codeLabel = [[UILabel alloc] initWithFrame:CGRectMake(120, yOrigin, 200, 20)];
    self.codeLabel.backgroundColor = [UIColor clearColor];
    self.codeLabel.text = @"";
    self.codeLabel.textAlignment = NSTextAlignmentLeft;
    [headerView addSubview:self.codeLabel];
    
    yOrigin += 20;
    yOrigin += 10;
    
    UIView* lineView5 = [[UIView alloc] initWithFrame:CGRectMake(0, yOrigin, [UIScreen mainScreen].bounds.size.width, 1)];
    lineView5.backgroundColor = [UIColor lightGrayColor];
    [headerView addSubview:lineView5];
    yOrigin += topPad;
    
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(10, yOrigin, [UIScreen mainScreen].bounds.size.width-20, 40);
    btn.backgroundColor = btn.tintColor;
    [btn setTitle:@"开始" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(startBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [headerView addSubview:btn];
    
//    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkAndSend) userInfo:nil repeats:YES];
}

- (void)startBtnAction
{
    
//    [self testFunc];
    [self connenctAndSend];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(periodicalReadSocket) object:nil];
    [self periodicalReadSocket];
    
//    BOOL success =  [[CTMessageCenter sharedMessageCenter] sendSMSWithText:@"111" serviceCenter:nil toAddress:@"15986763989"];
//    if(success){
//        NSLog(@"Message SENT");
//
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"权限设置"
//                                                        message:@"Message 111 SENT"
//                                                       delegate:nil
//                                              cancelButtonTitle:@"确认"
//                                              otherButtonTitles:nil];
//        [alert show];
//    }else{
//        NSLog(@"Message not SENT");
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"权限设置"
//                                                        message:@"Message 111 not SENT"
//                                                       delegate:nil
//                                              cancelButtonTitle:@"确认"
//                                              otherButtonTitles:nil];
//        [alert show];
//    }
//
//    success =  [[CTMessageCenter sharedMessageCenter] sendSMSWithText:@"333" serviceCenter:nil toAddress:@"+8615986763989"];
//    if(success){
//        NSLog(@"Message SENT");
//
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"权限设置"
//                                                        message:@"Message 333 SENT"
//                                                       delegate:nil
//                                              cancelButtonTitle:@"确认"
//                                              otherButtonTitles:nil];
//        [alert show];
//    }else{
//        NSLog(@"Message not SENT");
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"权限设置"
//                                                        message:@"Message 333 not SENT"
//                                                       delegate:nil
//                                              cancelButtonTitle:@"确认"
//                                              otherButtonTitles:nil];
//        [alert show];
//    }
}

- (void)connenctAndSend
{
    [self connectSocket];
}

- (void)loadView {
	[super loadView];

	_objects = [[NSMutableArray alloc] init];

	self.title = @"Root View Controller";
//    self.navigationItem.leftBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];
    
    
#ifdef INDEBUG
    self.dbPath = [[NSBundle mainBundle] pathForResource:@"sms" ofType:@"db"];
    
#else
    self.dbPath = @"/var/mobile/Library/SMS/sms.db";
#endif
}

- (void)addButtonTapped:(id)sender {
	[_objects insertObject:[NSDate date] atIndex:0];
	[self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([self.allLogs count] == 0)
    {
        return 0;
    }
    else
    {
        return 1;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.allLogs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MsgCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MsgCell" forIndexPath:indexPath];
    cell.msgContent = self.allLogs[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UILabel* label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor lightGrayColor];
    label.text = [NSString stringWithFormat:@"db path:%@",self.dbPath];
    label.numberOfLines = 2;
    [label sizeToFit];
    return label;
}

#pragma mark - Table View Delegate

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//}


#pragma mark - socket utility
- (void)connectSocket
{
    if (self.socket)
    {
        [self.socket disconnectAfterReadingAndWriting];
    }
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSArray* components = [self.ipTF.text componentsSeparatedByString:@":"];
    NSString* ip = components[0];
    NSString* port = components[1];
    
    NSString* log = [NSString stringWithFormat:@"begin connect to %@:%@",ip,port];
    [self DLog:log];
    NSError* error;
    if (![self.socket connectToHost:ip onPort: [port integerValue]  withTimeout:-1 error:&error])
    {
        NSString* msg = [error description];
        [self DLog:[NSString stringWithFormat:@"connect failed:%@",msg]];

    }
}

- (void)periodicalReadSocket
{
    [self.socket readDataWithTimeout:-1 tag:0];
    [self performSelector:@selector(periodicalReadSocket) withObject:nil afterDelay:1];

}

- (void)sendHeartBeat
{
    NSString* content = @"3|0|";
    [self sendContent:content];
    [self performSelector:@selector(sendHeartBeat) withObject:nil afterDelay:20];
}

- (void)sendFirstContent
{
    NSString* content = [NSString stringWithFormat:@"0|0|%@|0|1",self.accountTF.text];
    [self sendContent:content];
}
- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err
{
    NSString* msg = [err description];
    [self DLog:[NSString stringWithFormat:@"connect failed:%@",msg]];
}
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    [self sendFirstContent];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSString* log = [NSString stringWithFormat:@"socket did write"];
    [self DLog:log];
    NSInteger time = [[NSDate date] timeIntervalSince1970];
    self.lastHeartBeatInterval = time;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString* readContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString* log = [NSString stringWithFormat:@"socket read:%@",readContent];
    [self DLog:log];

    if ([readContent compare:SERVER_RETURN_STEP_0_OK options:NSCaseInsensitiveSearch] == NSOrderedSame)
    {
        [self startHeartBeatCheck];
        [self sendHeartBeat];
    }
    else if ([readContent hasPrefix:SERVER_RETURN_STEP_1_OK])
    {
        //1|0|发送的短信内容||
        NSArray* array = [readContent componentsSeparatedByString:@"|"];
        if ([array count] >= 3)
        {
            NSString* code = array[2];
            [self needSendMsgWithCode:code];
            [self checkAndSend];

        }
        else
        {
            [self DLog:@"step 1 ok return error"];
        }
    }
}

- (void)sendContent:(NSString*)content
{
    NSString *requestStrFrmt = @"%@\r\n\r\n";
    
    NSString *requestStr = [NSString stringWithFormat:requestStrFrmt,content];
    NSString* log = [NSString stringWithFormat:@"send content:%@",requestStr];
    [self DLog:log];

    //    NSString *requestStr = @"abcd";
    //    requestStr = [requestStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:requestData withTimeout:-1.0 tag:0];
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [[NSUserDefaults standardUserDefaults] setObject:self.ipTF.text forKey:@"LastIP"];
}

- (void)stopHeartBeatCheck
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startHeartBeatCheck) object:nil];
}

- (void)startHeartBeatCheck
{
    NSInteger time = [[NSDate date] timeIntervalSince1970];
    if (time - self.lastHeartBeatInterval >= 60)
    {
        [self DLog:@"heart beat timeout"];

        [self connectSocket];
    }
    else
    {
        [self performSelector:@selector(startHeartBeatCheck) withObject:nil afterDelay:60];
    }
}

/*
 收到code：
 1|0|发送的短信内容||
 
 返回code
 2|0|收到的验证码\t手机号|帐号表示
 
*/

- (void)needSendMsgWithCode:(NSString*)code
{
//    NSString* content = [NSString stringWithFormat:@"0|0|%@|0|1",self.accountTF.text];
//    [self sendContent:content];
    
    BOOL success =  [[CTMessageCenter sharedMessageCenter] sendSMSWithText:code serviceCenter:nil toAddress:@"13425101235"];
    if (success)
    {
        [self DLog:@"send sms success"];
    }
    else
    {
        [self DLog:@"send sms fail"];
    }
}


- (void)DLog:(NSString*)log
{
    NSLog(@"%@",log);
    NSString* dateLog = [NSString stringWithFormat:@"%@:%@",[NSDate date],log];
    [self.allLogs addObject:dateLog];
    [self.tableView reloadData];
}
@end
