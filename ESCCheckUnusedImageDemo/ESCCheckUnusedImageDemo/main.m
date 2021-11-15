//
//  main.m
//  ESCCheckUnusedImageDemo
//
//  Created by feifan5号 on 2021/11/15.
//

#import <Foundation/Foundation.h>
#import "FFArchiveFIleCopyTool.h"

int main(int argc, const char * argv[]) {
    
    
    dispatch_queue_t cQueue = dispatch_queue_create("cququ", 0);
    
    @autoreleasepool {
        
        NSLog(@"程序开始运行");
        
        NSString *dirPath = @"/Users/feifan5hao/Desktop/code/jun_ios_1";
        
        NSMutableArray *fileArray = [NSMutableArray array];
        
        [FFArchiveFIleCopyTool scanDirWithDirPath:dirPath resultFileArray:fileArray];
        
        
        NSMutableArray *imageNameArray = [NSMutableArray array];
        
        NSMutableDictionary *imagePathDict = [NSMutableDictionary dictionary];
        //检测图片文件
        NSLog(@"检测文件夹下图片文件名字");
        for (int i = 0; i < fileArray.count; i++) {
            NSString *filePath = fileArray[i];
            BOOL isDir = NO;
            BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
            if (isExists && isDir) {
                NSString *last = filePath.lastPathComponent;
                NSString *lastType = [[last componentsSeparatedByString:@"."] lastObject];
                if ([lastType isEqualToString:@"imageset"]) {
                    //                            NSLog(@"%@",last);
                    NSString *imageName = [[last componentsSeparatedByString:@"."] firstObject];
                    [imageNameArray addObject:imageName];
                    
                    [imagePathDict setObject:filePath forKey:imageName];
                }
            }
        }
        NSLog(@"%lu",(unsigned long)imageNameArray.count);
        //收集文件字符串内容
        NSLog(@"手机文件夹下文件字符串内容");
        NSMutableArray *stringArray = [NSMutableArray array];
        for (int i = 0; i < fileArray.count; i++) {
            NSString *filePath = fileArray[i];
            BOOL isDir = NO;
            BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir];
            if (isExists && isDir == NO) {
                NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
                if (content.length > 0) {
                    [stringArray addObject:content];
                    
                }
            }
        }
        NSLog(@"%lu",(unsigned long)stringArray.count);
        NSLog(@"开始检测图片名称是否存在于文件字符串中");
        __block double totalFileSize = 0;
        dispatch_semaphore_t semaphore_t = dispatch_semaphore_create(0);
        
        dispatch_group_t groutp_t = dispatch_group_create();
        
        for (NSString *imageName in imageNameArray) {
            
            dispatch_group_enter(groutp_t);
            
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                BOOL isUsed = NO;
                for (NSString *content in stringArray) {
                    NSString *image = [NSString stringWithFormat:@"\"%@",imageName];
                    
                    if ([content containsString:image]) {
                        isUsed = YES;
                        dispatch_group_leave(groutp_t);
                        break;
                    }
                }
                
                if (isUsed == NO) {
                    NSString *filePath = [imagePathDict objectForKey:imageName];
                    NSError *error;
                    NSDictionary *attributesDict = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
                    
                    float fileSize = [[attributesDict objectForKey:NSFileSize] floatValue] / 1024;
                    
                    NSLog(@"=====未检测到使用：%@=%.2lf",imageName,fileSize);
                    dispatch_sync(cQueue, ^{
                        totalFileSize = totalFileSize + fileSize;
                    });
                    dispatch_group_leave(groutp_t);
                }
            });
        }
        dispatch_group_notify(groutp_t, dispatch_get_global_queue(0, 0), ^{
            NSLog(@"转主线程");
            NSLog(@"%d",(int)totalFileSize);
            dispatch_semaphore_signal(semaphore_t);
        });
        dispatch_semaphore_wait(semaphore_t, DISPATCH_TIME_FOREVER);
    }
    
    NSLog(@"程序结束");
    
    return 0;
}
