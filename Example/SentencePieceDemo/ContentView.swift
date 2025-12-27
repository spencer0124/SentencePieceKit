import SwiftUI
import SentencePieceKit

public struct ContentView: View {
    @State private var inputText = "Hello, World!"
    @State private var tokenIds: [Int] = []
    @State private var decodedText = ""
    @State private var modelLoaded = false
    @State private var errorMessage: String?
    
    // Tokenizer instance
    @State private var tokenizer: SentencepieceTokenizer?
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            Text("SentencePieceKit Demo")
                .font(.title)
                .bold()
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            // Model Loading Section
            HStack {
                Text("Model Status:")
                if modelLoaded {
                    Text("Loaded ✅")
                        .foregroundColor(.green)
                } else {
                    Text("Not Loaded ❌")
                        .foregroundColor(.red)
                }
            }
            
            Button("Load Model (example.model)") {
                loadModel()
            }
            .buttonStyle(.borderedProminent)
            .disabled(modelLoaded)
            
            Divider()
            
            // Input Section
            TextField("Enter text...", text: $inputText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            Button("Encode & Decode") {
                processText()
            }
            .disabled(!modelLoaded)
            
            Divider()
            
            // Output Section
            VStack(alignment: .leading, spacing: 10) {
                Text("Tokens IDs:")
                    .font(.headline)
                Text("\(tokenIds.map { String($0) }.joined(separator: ", "))")
                    .font(.system(.body, design: .monospaced))
                    .padding(5)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(5)
                
                Text("Decoded:")
                    .font(.headline)
                Text(decodedText)
                    .padding(5)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private func loadModel() {
        // 1. Locate the .model file in the Main Bundle
        // Note: User must add 'example.model' (or any .model file) to the app target
        guard let modelPath = Bundle.main.path(forResource: "sentencepiece.bpe", ofType: "model") else {
            errorMessage = "Model file not found in Bundle! Please add 'sentencepiece.bpe.model' to the project resources."
            return
        }
        
        do {
            // 2. Initialize Tokenizer
            tokenizer = try SentencepieceTokenizer(modelPath: modelPath)
            modelLoaded = true
            errorMessage = nil
            print("Model loaded successfully from: \(modelPath)")
        } catch {
            errorMessage = "Failed to load model: \(error.localizedDescription)"
        }
    }
    
    private func processText() {
        guard let tokenizer = tokenizer else { return }
        
        // 3. Encode
        let ids = tokenizer.encode(inputText)
        self.tokenIds = ids
        
        // 4. Decode
        let decoded = tokenizer.decode(ids)
        self.decodedText = decoded
    }
}

#Preview {
    ContentView()
}
