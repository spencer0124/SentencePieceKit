//
//  SentencePieceBridge.h
//  SentencePieceKit
//
//  Created by SeungYong on 12/27/25.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentencePieceBridge : NSObject

- (nullable instancetype)initWithModelPath:(NSString *)modelPath error:(NSError **)error;
- (NSArray<NSNumber *> *)encode:(NSString *)text;
- (NSString *)decode:(NSArray<NSNumber *> *)ids;

- (int)bosId;
- (int)eosId;
- (int)unkId;
- (int)padId;

@end

NS_ASSUME_NONNULL_END