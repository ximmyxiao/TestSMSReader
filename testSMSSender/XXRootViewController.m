#import "XXRootViewController.h"
#import "fmdb.h"
#import "MsgCell.h"
#import "GCDAsyncSocket.h"

@interface XXRootViewController()<GCDAsyncSocketDelegate>
@property(nonatomic,strong) NSMutableArray* allMsgs;
@property(nonatomic,strong) UITextField* iptf;
@property(nonatomic,strong) UITextField* porttf;
@property(nonatomic,strong) GCDAsyncSocket* socket;
@property(nonatomic,strong) NSString* selectContent;
@property(nonatomic,strong) NSString* dbPath;
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
        NSLog(@"Could not open db.");
        [self showAlertMessage:@"Could not open db."];
    }
    
    NSInteger count = [db intForQuery:@"SELECT count(*) FROM message"];
    NSLog(@"total db count:%ld",(long)count);
//    NSString* countString = [NSString stringWithFormat:@"total msg count:%ld",(long)count];
//    [self showAlertMessage:countString];
    NSDateFormatter* dateFormat = [NSDateFormatter new];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    FMResultSet *rs = [db executeQuery:@"SELECT guid,text,date FROM message"];
    while ([rs next]) {
        ;
        
        NSString* guid = [rs stringForColumn:@"guid"];
        NSString* text = [rs stringForColumn:@"text"];
        NSInteger interval = [rs intForColumn:@"date"];
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

- (void)checkAndSend
{
    [self loadSMSData];
    
    [self connectSocket];

    for (MsgModel* model in self.allMsgs)
    {
        NSString *requestStrFrmt = @"%@\r\n\r\n";
        
        NSString *requestStr = [NSString stringWithFormat:requestStrFrmt,model.msgContent];
        
        //    NSString *requestStr = @"abcd";
        //    requestStr = [requestStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
        
        [self.socket writeData:requestData withTimeout:-1.0 tag:0];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[MsgCell class] forCellReuseIdentifier:@"MsgCell"];
    
    UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
    headerView.backgroundColor = [UIColor lightGrayColor];
    
    self.iptf = [[UITextField alloc] initWithFrame:CGRectMake(40, 12, 140, 20)];
    self.iptf.backgroundColor = [UIColor whiteColor];
    self.iptf.text = @"192.168.0.110";
    [headerView addSubview:self.iptf];

    self.porttf = [[UITextField alloc] initWithFrame:CGRectMake(200,12,100, 20)];
    self.porttf.backgroundColor = [UIColor whiteColor];
    self.porttf.text = @"8892";
    [headerView addSubview:self.porttf];
    
    self.tableView.tableHeaderView = headerView;

    [self loadSMSData];
    
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(checkAndSend) userInfo:nil repeats:YES];
}
- (void)loadView {
	[super loadView];

	_objects = [[NSMutableArray alloc] init];

	self.title = @"Root View Controller";
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)];
    
    
#ifdef DEBUG
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
    if ([self.allMsgs count] == 0)
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
    return [self.allMsgs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MsgCell* cell = [tableView dequeueReusableCellWithIdentifier:@"MsgCell" forIndexPath:indexPath];
    cell.model = self.allMsgs[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    MsgModel* model = self.allMsgs[indexPath.row];
    self.selectContent = model.msgContent;
    [self connectSocket];
}


#pragma mark - socket utility
- (void)connectSocket
{
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    self.socket.autoDisconnectOnClosedReadStream = NO;
    if (![self.socket connectToHost:self.iptf.text onPort: [self.porttf.text integerValue]  error:nil])
    {

    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{

    
    NSString *requestStrFrmt = @"%@\r\n\r\n";
    
    NSString *requestStr = [NSString stringWithFormat:requestStrFrmt,self.selectContent];

//    NSString *requestStr = @"abcd";
//    requestStr = [requestStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.socket writeData:requestData withTimeout:-1.0 tag:0];
}
@end
