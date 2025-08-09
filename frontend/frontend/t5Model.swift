//
//  t5Model.swift
//  frontend
//
//  Created by Jayden Zhang on 8/2/25.
//

import SwiftUI

// MARK: - Main Chat View
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Loading indicator
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("AI is thinking...")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .onChange(of: viewModel.messages.count) {
                        // Auto-scroll to bottom when new message is added
                        if let lastMessage = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Input area
                HStack {
                    TextField("Type your message...", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disabled(viewModel.isLoading)
                        .onSubmit {
                            Task {
                                await viewModel.sendMessage()
                            }
                        }
                    
                    Button(action: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(20)
                    }
                    .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("AI Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Chat") {
                        Task {
                            await viewModel.startNewChat()
                        }
                    }
                }
            }
            .task {
                // Start initial chat session
                await viewModel.startNewChat()
            }
        }
    }
}

class ChatService: ObservableObject {
    private let networkService: NetworkService
    
    init(authToken: String? = nil) {
        self.networkService = NetworkService(authToken: authToken)
    }
    
    func startChat() async throws -> UUID {
        let response: StartChatResponse? = try await networkService.requestEndpoint(
            endpoint: "/user/chat/start",
            method: "POST"
        )
        
        guard let response = response else {
            throw RequestError.emptyResponse
        }
        
        return UUID(uuidString: response.session_id) ?? UUID()
    }
    
    func sendMessage(_ message: String, sessionId: UUID) async throws -> String {
        let requestBody = ChatMessageRequest(message: message)
        
        let response: ChatMessageResponse? = try await networkService.requestEndpoint(
            endpoint: "/user/chat/message/\(sessionId.uuidString)",
            method: "POST",
            body: requestBody
        )
        
        guard let response = response else {
            throw RequestError.emptyResponse
        }
        
        return response.response
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var sessionId: UUID?
    private let chatService: ChatService
    
    init() {
        // Get auth token from keychain if you need it
        let authToken = KeychainManager.instance.getToken(forKey: "authToken")
        self.chatService = ChatService(authToken: authToken)
    }
    
    func startNewChat() async {
        do {
            sessionId = try await chatService.startChat()
            messages = []
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start chat: \(error.localizedDescription)"
        }
    }
    
    func sendMessage() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let sessionId = sessionId else {
            await startNewChat()
            guard sessionId != nil else { return }
            await sendMessage()
            return
        }
        
        let userMessage = inputText
        inputText = ""
        
        // Add user message
        messages.append(ChatMessage(text: userMessage, isFromUser: true))
        isLoading = true
        errorMessage = nil
        
        do {
            // Get AI response
            let aiResponse = try await chatService.sendMessage(userMessage, sessionId: sessionId)
            messages.append(ChatMessage(text: aiResponse, isFromUser: false))
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
