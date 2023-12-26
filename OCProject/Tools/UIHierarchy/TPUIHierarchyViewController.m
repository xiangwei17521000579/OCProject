//
//  TPUIHierarchyViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/25.
//

#import "TPUIHierarchyViewController.h"
#import "TPUIHierarchyManager.h"
@interface TPUIHierarchyViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL isOpen;
@property (nonatomic, strong) NSMutableArray <TPUIHierarchyModel *>*data;//展示数据
@end

@implementation TPUIHierarchyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = [NSString stringWithFormat:@"UI图层(%@)",[TPUIHierarchyManager isOn] ? @"开" : @"关"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"一键展开" style:(UIBarButtonItemStyleDone) target:self action:@selector(oneKeyExpansion)];
    [self setUpSubViews];
}

- (void)setUpSubViews{
    self.data  = [NSMutableArray array];
    if (self.model) [self.data addObject:self.model];
    [self.tableView reloadData];
    
    UIButton *customView = [[UIButton alloc] init];
    customView.backgroundColor = UIColor.redColor;
    customView.layer.cornerRadius = 20;
    [customView setTitle:[TPUIHierarchyManager isOn] ? @"关" : @"开" forState:UIControlStateNormal];
    [customView setTitleColor:UIColor.cFFFFFF forState:UIControlStateNormal];
    [customView addTarget:self action:@selector(clickOn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:customView];
    [customView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-30);
        make.width.height.mas_equalTo(40);
        make.bottom.mas_equalTo(-50);
    }];
}

- (void)oneKeyExpansion{
    self.isOpen = YES;
    [self updateUIHierarchy];
}

- (void)clickOn:(UIButton *)sender{
    [TPUIHierarchyManager isOn] ? [TPUIHierarchyManager stop] : [TPUIHierarchyManager start];
    [sender setTitle:[TPUIHierarchyManager isOn] ? @"关" : @"开" forState:UIControlStateNormal];
    self.title = [NSString stringWithFormat:@"UI图层(%@)",[TPUIHierarchyManager isOn] ? @"开" : @"关"];
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [TPMediator performTarget:@"TPUIHierarchyTableViewCell_Class" action:@"initWithTableView:withModel:" object:tableView object:self.data[indexPath.row]] ?: [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    TPUIHierarchyModel *model = self.data[indexPath.row];
    model.isOpen = !model.isOpen;
    self.isOpen = NO;
    [self updateUIHierarchy];
}

- (void)updateUIHierarchy{
    [self.data removeAllObjects];
    [self.data addObject:self.model];
    [self getUIHierarchy:self.model];
    [self.tableView reloadData];
}

- (void)getUIHierarchy:(TPUIHierarchyModel *)model{
    if (self.isOpen) model.isOpen = YES;
    if (!model.isOpen) return;
    for (TPUIHierarchyModel *item in model.subviews) {
        [self.data addObject:item];
        [self getUIHierarchy:item];
    }
}

#pragma mark -- setter
- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0.01)];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 0.01)];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = UITableViewAutomaticDimension;
        [self.view addSubview:_tableView];
        [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(0);
        }];
    }
    return _tableView;
}

- (BOOL)controllerOverlap{
    return YES;
}

@end