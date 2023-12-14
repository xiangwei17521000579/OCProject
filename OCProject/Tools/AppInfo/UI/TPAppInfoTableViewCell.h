//
//  TPAppInfoTableViewCell.h
//  OCProject
//
//  Created by 王祥伟 on 2023/12/12.
//

#import "TPBaseTableViewCell.h"
#import "TPAppInfoModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface TPAppInfoTableViewCell : TPBaseTableViewCell

+ (instancetype)initWithTableView:(UITableView *)tableView withModel:(TPAppInfoListModel *)model;

@end

NS_ASSUME_NONNULL_END