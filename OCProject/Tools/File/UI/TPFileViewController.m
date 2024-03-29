//
//  TPFileViewController.m
//  OCProject
//
//  Created by 王祥伟 on 2023/12/15.
//

#import "TPFileViewController.h"
#import "TPFileManager.h"

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface TPFileViewController ()<UIDocumentInteractionControllerDelegate>
@property (nonatomic, strong) UIDocumentInteractionController *doc;
@end

@implementation TPFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.name ?: @"文件";
    
    self.data = self.path ? [TPFileManager dataForFilePath:self.path] : [TPFileManager defaultFile];
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    self.doc = nil;
}

- (NSString *)cellClass{
    return TPString.tc_file;
}

#pragma mark -- UITableViewDelegate,UITableViewDataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    TPFileModel *model = self.data[indexPath.row];
    if (model.isDirectory){
        [TPRouter jumpUrl:[NSString stringWithFormat:@"%@?name=%@&path=%@",TPString.vc_file,model.fileName,model.filePath]];
    }else{
        
        if (model.fileType == TPFileTypeJson){
            NSString *jsonString = [NSString stringWithContentsOfFile:model.filePath encoding:NSUTF8StringEncoding error:nil];
            NSData *jaonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:jaonData options:NSJSONReadingMutableContainers error:nil];
            if (dic) [TPRouter jumpUrl:[NSString stringWithFormat:@"%@?fileName=%@",TPString.vc_file_data,model.fileName] params:@{@"dic":dic}];
        }else if (model.fileType == TPFileTypeVideo){
            AVPlayerViewController *player = [[AVPlayerViewController alloc] init];
            player.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:model.filePath]];
            [self presentViewController:player animated:YES completion:nil];
        }else{
            NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithContentsOfFile:model.filePath];
            if (dic) {
                [TPRouter jumpUrl:[NSString stringWithFormat:@"%@?fileName=%@",TPString.vc_file_data,model.fileName] params:@{@"dic":dic}];
            }else{
                UIDocumentInteractionController *doc = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:model.filePath]];
                doc.delegate = self;
                self.doc = doc;
                BOOL canOpen = [doc presentPreviewAnimated:YES];
                if (!canOpen) {
                    [TPToastManager showText:@"该文件还没有添加预览模式"];
                }
            }
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (self.path) return [UIView new];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.width, 300)];
    UILabel *label = [[UILabel alloc] init];
    [view addSubview:label];
    
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.mas_equalTo(15);
        make.right.mas_equalTo(-15);
    }];
    TPFileModel *model = self.data[section];
    label.text = [NSString stringWithFormat:@"沙盒路径：\n%@",model.filePath];
    label.numberOfLines = 0;
    label.textColor = UIColor.c000000;
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return self.path ? 0 : 300;
}

#pragma mark - UIDocumentInteractionControllerDelegate
- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller{
    return self;
}

- (nullable UIView *)documentInteractionControllerViewForPreview:(UIDocumentInteractionController *)controller{
    return self.view;
}

@end
