import Foundation
import sentencepiece // C++ 모듈 임포트

public class SPProcessor {
    // 내부적으로 C++ 포인터나 객체를 가질 수 있음
    
    public init() {
        print("SentencePieceKit initialized!")
    }
    
    // 테스트용 함수: C++ 모듈이 잘 연결되었는지 확인
    public func testConnection() {
        print("Successfully imported C++ sentencepiece module.")
    }
}
