//
//  ViewController.m
//  Example
//
//  Created by zhuruhong on 2022/11/21.
//

#import "ViewController.h"
#import <Masonry/Masonry.h>
//logger
#import <CCDBucket/CCDLogger.h>
#import <CCDBucket/CCDDamServer.h>
//websocket server
#import <GCDWebSocket/GCDWebSocketServer.h>
#import <GCDWebSocket/GCDWebSocketServerConnection.h>
//websocket client
#import <SocketRocket/SocketRocket.h>

@interface ViewController ()
<
GCDWebServerDelegate,
GCDWebSocketServerTransport,
SRWebSocketDelegate
>

@property (nonatomic, strong) GCDWebSocketServer *wsServer;
@property (nonatomic, strong) SRWebSocket *websocketClient;
@property (nonatomic, strong) NSTimer *heartbeatTimer;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) UISwitch *webLogSwitch;
@property (nonatomic, strong) UILabel *webLogLabel;

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *statusButton;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4]; // 10.4+ style
    [_dateFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
    [_dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [_dateFormatter setDateFormat:@"yyyy/MM/dd HH:mm:ss:SSS"];
    
    self.webLogSwitch = [[UISwitch alloc] init];
    [self.webLogSwitch addTarget:self action:@selector(doSwitchAction) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.webLogSwitch];
    [self.webLogSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(20);
        make.top.equalTo(self.view).offset(80);
    }];
    
    self.webLogLabel = [[UILabel alloc] init];
    self.webLogLabel.textColor = [UIColor blueColor];
    self.webLogLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:self.webLogLabel];
    [self.webLogLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.top.equalTo(self.webLogSwitch.mas_bottom).offset(6);
        make.height.equalTo(@40);
    }];
    
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.textColor = [UIColor blueColor];
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    [self.view addSubview:self.statusLabel];
    [self.statusLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.top.equalTo(self.webLogLabel.mas_bottom).offset(6);
        make.height.equalTo(@60);
    }];
    
    self.statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.statusButton.frame = CGRectMake(20, 160, 180, 40);
    [self.statusButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.statusButton setTitle:@"start websocket" forState:UIControlStateNormal];
    [self.statusButton addTarget:self action:@selector(startOrStopClient) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.statusButton];
    [self.statusButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(20);
        make.top.equalTo(self.statusLabel.mas_bottom).offset(6);
        make.size.mas_equalTo(CGSizeMake(180, 40));
    }];
    
    self.textView = [[UITextView alloc] init];
    self.textView.layer.borderColor = [UIColor blueColor].CGColor;
    self.textView.layer.borderWidth = 1.0f;
    self.textView.font = [UIFont systemFontOfSize:14.0f];
    [self.view addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.top.equalTo(self.statusButton.mas_bottom).offset(6);
        make.bottom.equalTo(self.view).offset(-100);
    }];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self startEchoServer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.webLogSwitch setOn:[CCDDamServer sharedInstance].isRunning animated:YES];
    self.webLogLabel.text = [NSString stringWithFormat:@"web log address is %@log", [CCDDamServer sharedInstance].serverURL];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stopHeartbeatTimer];
}

- (void)doSwitchAction
{
    if ([CCDDamServer sharedInstance].isRunning) {
        [[CCDDamServer sharedInstance] stop];
    } else {
        [[CCDDamServer sharedInstance] start];
        self.webLogLabel.text = [NSString stringWithFormat:@"web log address is %@/log", [CCDDamServer sharedInstance].serverURL];
    }
}

- (void)startOrStopClient
{
    if (nil == self.websocketClient) {
        NSString *wsUrl = @"ws://localhost:2022";
        [self openWebSocketClient:wsUrl];
        [self.statusButton setTitle:@"stop websocket" forState:UIControlStateNormal];
    } else {
        [self closeWebSocketClient];
        [self.statusButton setTitle:@"start websocket" forState:UIControlStateNormal];
    }
}

#pragma mark - date formate

- (NSString *)getCurrentTime
{
    NSDate *nowDate = [NSDate date];
    return [self.dateFormatter stringFromDate:nowDate];
}

#pragma mark - heartbeat

- (void)stopHeartbeatTimer
{
    if (self.heartbeatTimer) {
        [self.heartbeatTimer invalidate];
        self.heartbeatTimer = nil;
    }
}

- (void)startHeartbeatTimerWith:(NSTimeInterval)interval
{
    [self stopHeartbeatTimer];
    
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(doHeartbeatAction) userInfo:nil repeats:YES];
}

- (void)doHeartbeatAction
{
    if (self.websocketClient.readyState == SR_OPEN) {
        NSString *testData = @"[heartbeat] server will echo this string when received.";
        [self.websocketClient send:testData];
    }
}

#pragma mark - websocket client

- (void)closeWebSocketClient
{
    if (self.websocketClient) {
        [self.websocketClient close];
        self.websocketClient = nil;
    }
}

- (void)openWebSocketClient:(NSString *)urlString
{
    NSAssert(urlString, @"please set websocket url");
    NSURL *URL = [NSURL URLWithString:urlString];
    NSAssert(URL, @"url:(%@) error, please check !!!", urlString);
    
    [self closeWebSocketClient];
    
    self.websocketClient = [[SRWebSocket alloc] initWithURL:URL];
    self.websocketClient.delegate = self;
    [self.websocketClient open];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    DDLogDebug(@"receive echo message from server:  %@", message);
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSString *text = @"create the text for test, then send this string to server; server will echo this string when received.";
    [self.websocketClient send:text];
    DDLogDebug(@"%@", text);
    //start heartbeat loop
    [self startHeartbeatTimerWith:5];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    DDLogDebug(@"didFailWithError: %@", error);
}

#pragma mark - echo server

- (void)startEchoServer
{
    self.wsServer = [[GCDWebSocketServer alloc] init];
    self.wsServer.transport = self;
    self.wsServer.delegate = self;
    [self.wsServer startWithPort:2022 bonjourName:nil];
}

#pragma mark - GCDWebServerDelegate

/**
 *  This method is called after the server has successfully started.
 */
- (void)webServerDidStart:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] start: %@", server.serverURL);
    self.statusLabel.text = [NSString stringWithFormat:@"websocket server address is ws://%@:%@", server.serverURL.host, server.serverURL.port];
    NSString *text = [NSString stringWithFormat:@"[WebServer] start: %@\n\n", server.serverURL];
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
}

- (void)webServerDidCompleteBonjourRegistration:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] Bonjour: %@", server.bonjourServerURL);
    NSString *text = [NSString stringWithFormat:@"[WebServer] Bonjour: %@\n\n", server.bonjourServerURL];
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
}

- (void)webServerDidStop:(GCDWebServer*)server
{
    DDLogDebug(@"[WebServer] stop: %@", server);
}

#pragma mark - GCDWebSocketServerTransport

- (void)transportWillBegin:(GCDWebServerConnection *)transport
{
    //one connection will callback by this method when it open
    NSString *text = [NSString stringWithFormat:@"[%@] connection[%p] will begin\n\n", [self getCurrentTime], transport];
    DDLogDebug(@"%@", text);
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
}

- (void)transportWillEnd:(GCDWebServerConnection *)transport
{
    //one connection will callback by this method when it close
    NSString *text = [NSString stringWithFormat:@"[%@] connection[%@] will end\n\n", [self getCurrentTime], transport];
    DDLogDebug(@"%@", text);
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
}

- (void)transport:(GCDWebServerConnection *)transport received:(GCDWebSocketMessage)msg
{
    //server got the msg by this method
    NSString *content = [[NSString alloc] initWithData:msg.body.payload encoding:NSUTF8StringEncoding];
    NSString *text = [NSString stringWithFormat:@"[%@] connection[%p] received: opcode=%d, payload=%@\n\n", [self getCurrentTime], transport, msg.header.opcode, content];
    DDLogDebug(@"%@", text);
    [self.textView insertText:text];
    [self.textView scrollRangeToVisible:NSMakeRange(-1, 1)];
    
#ifdef DEBUG
    GCDWebSocketServerConnection *connection = nil;
    if ([transport isKindOfClass:[GCDWebSocketServerConnection class]]) {
        connection = (GCDWebSocketServerConnection *)transport;
    }
    
    //echo message
    GCDWebSocketMessage echoMessage;
    echoMessage.header.fin = YES;
    echoMessage.header.opcode = GCDWebSocketOpcodeTextFrame;
    echoMessage.body.payload = msg.body.payload;
    [connection sendMessage:echoMessage];
#endif
}

@end
