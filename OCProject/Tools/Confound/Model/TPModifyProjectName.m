//
//  TPModifyProjectName.m
//  OCProject
//
//  Created by 王祥伟 on 2024/3/27.
//

#import "TPModifyProjectName.h"

@implementation TPModifyProjectName

+ (void)modifyProjectName:(NSString *)projectPath oldName:(NSString *)oldName newName:(NSString *)newName{
    [self modifyFilesClassName:projectPath oldName:[oldName stringByAppendingString:@"-Swift.h"] newName:[newName stringByAppendingString:@"-Swift.h"]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDirectory;
    NSString *podfilePath = [projectPath stringByAppendingPathComponent:@"Podfile"];
    if ([fm fileExistsAtPath:podfilePath isDirectory:&isDirectory] && !isDirectory) {
        [self replacePodfileContent:podfilePath oldString:oldName newString:newName];
    }
    
    NSString *projectPathPath = [projectPath stringByAppendingPathComponent:oldName];
    NSString *xcodeprojFilePath = [projectPathPath stringByAppendingPathExtension:@"xcodeproj"];
    NSString *xcworkspaceFilePath = [projectPathPath stringByAppendingPathExtension:@"xcworkspace"];
    
    if ([fm fileExistsAtPath:xcodeprojFilePath isDirectory:&isDirectory] && isDirectory) {
        NSString *projectPbxprojFilePath = [xcodeprojFilePath stringByAppendingPathComponent:@"project.pbxproj"];
        if ([fm fileExistsAtPath:projectPbxprojFilePath]) {
            [self resetBridgingHeaderFileName:projectPbxprojFilePath oldName:[oldName stringByAppendingString:@"-Bridging-Header"] newName:[newName stringByAppendingString:@"-Bridging-Header"]];
            [self resetEntitlementsFileName:projectPbxprojFilePath oldName:oldName newName:newName];
            [self replaceProjectFileContent:projectPbxprojFilePath oldName:oldName newName:newName];
        }
        NSString *contentsXcworkspacedataFilePath = [xcodeprojFilePath stringByAppendingPathComponent:@"project.xcworkspace/contents.xcworkspacedata"];
        if ([fm fileExistsAtPath:contentsXcworkspacedataFilePath]) {
            [self replaceProjectFileContent:contentsXcworkspacedataFilePath oldName:oldName newName:newName];
        }
        NSString *xcuserdataFilePath = [xcodeprojFilePath stringByAppendingPathComponent:@"xcuserdata"];
        if ([fm fileExistsAtPath:xcuserdataFilePath]) {
            [fm removeItemAtPath:xcuserdataFilePath error:nil];
        }
        [self renameFile:xcodeprojFilePath newPath:[[projectPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:@"xcodeproj"]];
    }
    
    if ([fm fileExistsAtPath:xcworkspaceFilePath isDirectory:&isDirectory] && isDirectory) {
        NSString *contentsXcworkspacedataFilePath = [xcworkspaceFilePath stringByAppendingPathComponent:@"contents.xcworkspacedata"];
        if ([fm fileExistsAtPath:contentsXcworkspacedataFilePath]) {
            [self replaceProjectFileContent:contentsXcworkspacedataFilePath oldName:oldName newName:newName];
        }
        NSString *xcuserdataFilePath = [xcworkspaceFilePath stringByAppendingPathComponent:@"xcuserdata"];
        if ([fm fileExistsAtPath:xcuserdataFilePath]) {
            [fm removeItemAtPath:xcuserdataFilePath error:nil];
        }
        [self renameFile:xcworkspaceFilePath newPath:[[projectPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:@"xcworkspace"]];
    }
    
    if ([fm fileExistsAtPath:projectPathPath isDirectory:&isDirectory] && isDirectory) {
        [self renameFile:projectPathPath newPath:[projectPath stringByAppendingPathComponent:newName]];
    }
}

static NSMutableDictionary *_fileNameDict;
static NSMutableSet *_filePathSet;
+ (void)modifyFilePrefix:(NSString *)projectPath oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix{
    [self modifyFilePrefix:projectPath otherPrefix:NO oldPrefix:oldPrefix newPrefix:newPrefix];
}

+ (void)modifyFilePrefix:(NSString *)projectPath otherPrefix:(BOOL)otherPrefix oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix{
    _fileNameDict = [NSMutableDictionary dictionary];
    _filePathSet = [NSMutableSet set];
    [self modifyClassDict:projectPath otherPrefix:otherPrefix oldPrefix:oldPrefix newPrefix:newPrefix];
    [self modifyClassNamePrefix:projectPath classReplaceDict:_fileNameDict];
    
    for (NSString *filePath in _filePathSet.allObjects) {
        NSString *fileName = filePath.lastPathComponent;
        NSString *fileString = filePath.stringByDeletingLastPathComponent;
        [self renameFile:filePath newPath:[fileString stringByAppendingPathComponent:[fileName stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix]]];
    }
}

+ (void)modifyClassDict:(NSString *)projectPath otherPrefix:(BOOL)otherPrefix oldPrefix:(NSString *)oldPrefix newPrefix:(NSString *)newPrefix{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        if ([filePath isEqualToString:@"Pods"]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self modifyClassDict:path otherPrefix:otherPrefix oldPrefix:oldPrefix newPrefix:newPrefix];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".pch"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"] || [fileName hasSuffix:@".xcodeproj"]) {
            NSArray *classNames = [fileName.stringByDeletingPathExtension componentsSeparatedByString:@"+"];
            for (NSString *className in classNames) {
                if ([className hasPrefix:oldPrefix]){
                    NSString *newClassName = [className stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
                    [_fileNameDict setValue:newClassName forKey:className];
                    [_filePathSet addObject:path];
                }
            }
            
            if ([fileName hasSuffix:@".h"]){
                NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
                
                ///其他类
                NSArray *fileNames = [fileContent subStartStr:@"@interface" endStr:@":"];
                for (NSString *string in fileNames) {
                    NSString *className = string.whitespace;
                    if ([className hasPrefix:oldPrefix]){
                        NSString *newClassName = [className stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
                        [_fileNameDict setValue:newClassName forKey:className];
                    }
                }
                
                ///其他类别
                NSArray *categoryFileNames = [fileContent subStartStr:@"@interface" endStr:@"("];
                for (NSString *string in categoryFileNames) {
                    NSString *className = string.whitespace;
                    if ([className hasPrefix:oldPrefix]){
                        NSString *newClassName = [className stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
                        [_fileNameDict setValue:newClassName forKey:className];
                    }
                }
            }
            
            if (!otherPrefix) return;
            if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".pch"]) {
                NSError *error = nil;
                NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
                if ([fileName hasSuffix:@".pch"]){
                    NSLog(@"%@",fileContent);
                    NSLog(@"%@",fileContent);
                }
                NSArray *words = [fileContent filterString];
                for (NSString *word in words) {
                    if ([word hasPrefix:oldPrefix]) {
                        NSMutableString *matchString = word.mutableCopy;
                        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^a-zA-Z]"
                                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                                 error:nil];
                        [regex replaceMatchesInString:matchString options:0 range:NSMakeRange(0, matchString.length) withTemplate:@""];
                        NSString *newClassName = [matchString stringByReplacingOccurrencesOfString:oldPrefix withString:newPrefix];
                        [_fileNameDict setValue:newClassName forKey:matchString];
                    }
                }
            }
        }
    }
}

+ (void)modifyClassNamePrefix:(NSString *)projectPath classReplaceDict:(NSDictionary *)classReplaceDict{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        if ([filePath isEqualToString:@"Pods"]) continue;
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self modifyClassNamePrefix:path classReplaceDict:classReplaceDict];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".pch"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"] || [fileName isEqualToString:@"project.pbxproj"]) {
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            NSArray *allClassNames = classReplaceDict.allKeys;
            for (NSString *className in allClassNames) {
                if ([fileContent containsString:className]) fileContent = [fileContent stringByReplacingOccurrencesOfString:className withString:classReplaceDict[className]].mutableCopy;
            }
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

+ (void)modifyFilesClassName:(NSString *)projectPath oldName:(NSString *)oldName newName:(NSString *)newName{
    // 文件内容 Const > DDConst (h,m,swift,xib,storyboard)
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:projectPath error:nil];
    BOOL isDirectory;
    for (NSString *filePath in files) {
        NSString *path = [projectPath stringByAppendingPathComponent:filePath];
        if ([fm fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
            [self modifyFilesClassName:path oldName:oldName newName:newName];
            continue;
        }
        
        NSString *fileName = filePath.lastPathComponent;
        if ([fileName hasSuffix:@".h"] || [fileName hasSuffix:@".m"] || [fileName hasSuffix:@".pch"] || [fileName hasSuffix:@".swift"] || [fileName hasSuffix:@".xib"] || [fileName hasSuffix:@".storyboard"]) {
            
            NSError *error = nil;
            NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("打开文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                abort();
            }
            
            NSString *regularExpression = [NSString stringWithFormat:@"\\b%@\\b", oldName];
            BOOL isChanged = [self regularReplacement:regularExpression oldString:fileContent newString:newName];
            if (!isChanged) continue;
            error = nil;
            [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                printf("保存文件 %s 失败：%s\n", path.UTF8String, error.localizedDescription.UTF8String);
                abort();
            }
        }
    }
}

+ (BOOL)regularReplacement:(NSString *)regular oldString:(NSMutableString *)oldString newString:(NSString *)newString{
    __block BOOL isChanged = NO;
    BOOL isGroupNo = [newString isEqualToString:@"\\1"];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regular options:NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnixLineSeparators error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:oldString options:0 range:NSMakeRange(0, oldString.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!isChanged) {
            isChanged = YES;
        }
        if (isGroupNo) {
            NSString *withString = [oldString substringWithRange:[obj rangeAtIndex:1]];
            [oldString replaceCharactersInRange:obj.range withString:withString];
        } else {
            [oldString replaceCharactersInRange:obj.range withString:newString];
        }
    }];
    return isChanged;
}

+ (void)replacePodfileContent:(NSString *)filePath oldString:(NSString *)oldString newString:(NSString *)newString{
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *regularExpression = [NSString stringWithFormat:@"target +'%@", oldString];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [fileContent replaceCharactersInRange:obj.range withString:[NSString stringWithFormat:@"target '%@", newString]];
    }];
    
    regularExpression = [NSString stringWithFormat:@"project +'%@.", oldString];
    expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [fileContent replaceCharactersInRange:obj.range withString:[NSString stringWithFormat:@"project '%@.", newString]];
    }];
    
    [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

+ (void)resetBridgingHeaderFileName:(NSString *)projectPbxprojFilePath oldName:(NSString *)oldName newName:(NSString *)newName{
    NSString *rootPath = projectPbxprojFilePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:projectPbxprojFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *regularExpression = @"SWIFT_OBJC_BRIDGING_HEADER = \"?([^\";]+)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *entitlementsPath = [fileContent substringWithRange:[obj rangeAtIndex:1]];
        NSString *entitlementsName = entitlementsPath.lastPathComponent.stringByDeletingPathExtension;
        if (![entitlementsName isEqualToString:oldName]) return;
        entitlementsPath = [rootPath stringByAppendingPathComponent:entitlementsPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:entitlementsPath]) return;
        NSString *newPath = [entitlementsPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:[newName stringByAppendingPathExtension:@"h"]];
        [self renameFile:entitlementsPath newPath:newPath];
    }];
}

+ (void)renameFile:(NSString *)oldPath newPath:(NSString *)newPath{
    NSError *error;
    [[NSFileManager defaultManager] moveItemAtPath:oldPath toPath:newPath error:&error];
    if (error) {
        printf("修改文件名称失败。\n  oldPath=%s\n  newPath=%s\n  ERROR:%s\n", oldPath.UTF8String, newPath.UTF8String, error.localizedDescription.UTF8String);
        if (error.code != 516) abort();
    }
}

+ (void)resetEntitlementsFileName:(NSString *)projectPbxprojFilePath oldName:(NSString *)oldName newName:(NSString *)newName{
    NSString *rootPath = projectPbxprojFilePath.stringByDeletingLastPathComponent.stringByDeletingLastPathComponent;
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:projectPbxprojFilePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *regularExpression = @"CODE_SIGN_ENTITLEMENTS = \"?([^\";]+)";
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *entitlementsPath = [fileContent substringWithRange:[obj rangeAtIndex:1]];
        NSString *entitlementsName = entitlementsPath.lastPathComponent.stringByDeletingPathExtension;
        if (![entitlementsName isEqualToString:oldName]) return;
        entitlementsPath = [rootPath stringByAppendingPathComponent:entitlementsPath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:entitlementsPath]) return;
        NSString *newPath = [entitlementsPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:[newName stringByAppendingPathExtension:@"entitlements"]];
        [self renameFile:entitlementsPath newPath:newPath];
    }];
}

+ (void)replaceProjectFileContent:(NSString *)filePath oldName:(NSString *)oldName newName:(NSString *)newName{
    NSMutableString *fileContent = [NSMutableString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *regularExpression = [NSString stringWithFormat:@"\\b%@\\b", oldName];
    NSRegularExpression *expression = [NSRegularExpression regularExpressionWithPattern:regularExpression options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [expression matchesInString:fileContent options:0 range:NSMakeRange(0, fileContent.length)];
    [matches enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSTextCheckingResult * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *string = [fileContent substringWithRange:NSMakeRange(obj.range.location+obj.range.length, 2)];
        if ([string containsString:@".h"] || [string containsString:@".m"] || [string containsString:@".swift"]){
            return;
        }
        [fileContent replaceCharactersInRange:obj.range withString:newName];
    }];
    
    [fileContent writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

@end
