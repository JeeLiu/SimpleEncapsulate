//
//  Database.h
//  SimpleEncapsulate
//
//  Created by yhtian on 13-9-27.
//  Copyright (c) 2013年 SimpleEncapsulate. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase, FMDatabaseQueue;

@interface SEDatabase : NSObject {
    BOOL _override;
    FMDatabaseQueue *_dbQueue;
    NSOperationQueue *_operationQueue;
    FMDatabase *_db;
    dispatch_queue_t _updateQueue;
}
@property(atomic, strong, readonly) FMDatabaseQueue *dbQueue;

@property (nonatomic, copy) NSString *dbName;

+ (instancetype)sharedDatabase;

/**
 * @param override 是否覆盖原来的版本
 */
- (void)setDbName:(NSString *)dbName override:(BOOL)override;

/**
 * 合并升级版本
 */
- (void)setMigrateDataBlock:(void (^)(FMDatabase *db))block;

/**
 * @abstract      直接获取数据库内容。
 * @param query   SQL语句。
 * @param cls     返回数据类型，当数据返回时，会自动解析数据，并根据此类型创建对象。
 * @discussion    无。
 */
- (NSArray *)fetchWithQuery:(NSString *)query regClass:(Class)cls;

/**
 * @abstract      异步获取数据库内容。
 * @param query   SQL语句。
 * @param cls     返回数据类型，当数据返回时，会自动解析数据，并根据此类型创建对象。
 * @param handler 数据返回时处理的回调函数，|data|为生成的cls类型的数据。
 * @discussion    无。
 */
- (void)fetchAsyncWithQuery:(NSString *)query
                   regClass:(Class)cls
          completionHandler:(void (^)(NSArray *data))handler;

- (void)fetchAsyncWithQuery:(NSString *)query
                        tag:(NSInteger)tag
                   regClass:(Class)cls
          completionHandler:(void (^)(NSArray *data))handler;

/**
 * @abstract      只获取一列的数据。
 * @param query   SQL语句。
 * @discussion    此时返回的数组中没有对应的列名。
 */
- (NSArray *)fetchOneColumnWithQuery:(NSString *)query;

/**
 * @abstract      异步获取一列的数据。
 * @param query   SQL语句。
 * @param handler 数据返回时处理的回调函数。
 * @discussion    此时返回的数组中没有对应的列名。
 */
- (void)fetchOneColumnAsyncWithQuery:(NSString *)query
                   completionHandler:(void (^)(NSArray *data))handler;
- (void)fetchOneColumnAsyncWithQuery:(NSString *)query
                                 tag:(NSInteger)tag
                   completionHandler:(void (^)(NSArray *data))handler;

/**
 * @abstract      更新或插入数据。
 * @param query   SQL。
 * @param error   若有错误则给出错误提示。
 * @discussion    单次执行更新时使用，数据很多时不要直接使用，而是考虑使用事务或者updateBatches。
 * @see           - (void)indDeferredTransaction:
 */
- (BOOL)updateWithQuery:(NSString *)query error:(NSError **)error;

/**
 * @abstract      批量更新或插入数据。
 * @param queries 一组SQL语句。
 * @param handler 数据返回时处理的回调函数，若出错则|error|不为nil，此函数会用事务冲突，造成死锁。
 */
- (void)updateBatchWithQueries:(NSArray *)queries
             completionHandler:(void (^)(NSError *error))handler;
- (void)updateBatchWithQueries:(NSArray *)queries
                           tag:(NSInteger)tag
             completionHandler:(void (^)(NSError *error))handler;
/**
 * @abstract      使用延迟事务处理。
 */
- (void)inDeferredTransaction:(void (^)(BOOL *rollback))block;
- (void)inDeferredTransaction:(void (^)(BOOL *rollback))block
                          tag:(NSInteger)tag;

- (BOOL)isQueryExcuting:(NSString *)query;
- (void)cancelQuery:(NSString *)query;

- (BOOL)isQueryExcutingWithTag:(NSInteger)tag;
- (void)cancelQueryWithTag:(NSInteger)tag;

@end
