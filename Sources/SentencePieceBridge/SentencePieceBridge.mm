#import "SentencePieceBridge.h"
#import "sentencepiece_processor.h" // XCFramework의 헤더
#include <vector>
#include <string>

@implementation SentencePieceBridge {
    sentencepiece::SentencePieceProcessor *_processor;
}

- (instancetype)initWithModelPath:(NSString *)modelPath error:(NSError **)error {
    self = [super init];
    if (self) {
        _processor = new sentencepiece::SentencePieceProcessor();
        std::string path = [modelPath UTF8String];
        const auto status = _processor->Load(path);
        if (!status.ok()) {
            if (error) {
                NSString *errorMessage = [NSString stringWithUTF8String:status.ToString().c_str()];
                *error = [NSError errorWithDomain:@"com.google.sentencepiece"
                                             code:(NSInteger)status.code()
                                         userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            }
            delete _processor;
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    if (_processor) {
        delete _processor;
    }
}

- (NSArray<NSNumber *> *)encode:(NSString *)text {
    if (!_processor) return @[];
    
    std::string input = [text UTF8String];
    std::vector<int> ids;
    _processor->Encode(input, &ids);
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:ids.size()];
    for (int i : ids) {
        [result addObject:@(i)];
    }
    return result;
}

- (NSString *)decode:(NSArray<NSNumber *> *)ids {
    if (!_processor) return @"";
    
    std::vector<int> inputIds;
    inputIds.reserve(ids.count);
    for (NSNumber *n in ids) {
        inputIds.push_back(n.intValue);
    }
    
    std::string output;
    _processor->Decode(inputIds, &output);
    
    return [NSString stringWithUTF8String:output.c_str()];
}

- (int)bosId { return _processor ? _processor->bos_id() : -1; }
- (int)eosId { return _processor ? _processor->eos_id() : -1; }
- (int)unkId { return _processor ? _processor->unk_id() : -1; }
- (int)padId { return _processor ? _processor->pad_id() : -1; }

@end
