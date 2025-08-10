//
//  followingView.swift
//  frontend
//
//  Created by Jayden Zhang on 8/2/25.
//

import SwiftUI

struct followingView: View {
    let initialTab: Int
    @State private var followers: [UserFameInfo] = []
    @State private var following: [UserFameInfo] = []
    @State private var totalFollowers = 0
    @State private var totalFollowing = 0
    @State private var selectedTab = 0
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            // Tab selection with beautiful styling
            HStack(spacing: 0) {
                ForEach(0..<2) { index in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 6) {
                            Text(index == 0 ? "Followers" : "Following")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("\(index == 0 ? totalFollowers : totalFollowing)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == index ? .purple.opacity(0.9) : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTab == index ? Color.purple.opacity(0.1) : Color.clear)
                        )
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.4))
                    .blur(radius: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(selectedTab == 0 ? followers : following, id: \.uuid) { user in
                        UserRowView(user: user)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.08),
                    Color.blue.opacity(0.05),
                    Color.white.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            selectedTab = initialTab
        }
        .task {
            await loadInitialData()
        }
        .onChange(of: selectedTab) {
            Task {
                await loadTabData()
            }
        }
    }
    
    // Include all the same functions from your original followingView
    private func loadInitialData() async {
        isLoading = true
        
        async let followersData = try? getFollowers(limit: 20, offset: 0)
        async let followingData = try? getFollowing(limit: 20, offset: 0)
        
        let results = await (followersData, followingData)
        
        await MainActor.run {
            if let followersResult = results.0 {
                self.followers = followersResult.followers
                self.totalFollowers = followersResult.total
            }
            
            if let followingResult = results.1 {
                self.following = followingResult.following
                self.totalFollowing = followingResult.total
            }
            
            isLoading = false
        }
    }
    
    private func loadTabData() async {
        isLoading = true
        
        do {
            if selectedTab == 0 && followers.isEmpty {
                let result = try await getFollowers(limit: 20, offset: 0)
                await MainActor.run {
                    self.followers = result.followers
                    self.totalFollowers = result.total
                }
            } else if selectedTab == 1 && following.isEmpty {
                let result = try await getFollowing(limit: 20, offset: 0)
                await MainActor.run {
                    self.following = result.following
                    self.totalFollowing = result.total
                }
            }
        } catch {
            print("Failed to load tab data:", error)
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    func getFollowers(limit: Int = 20, offset: Int = 0) async throws -> (total: Int, followers: [UserFameInfo]) {
        let network = NetworkService()
        
        do {
            let response: FameResponse? = try await network.requestEndpoint(
                endpoint: "/user/get-fame",
                method: "POST",
                body: [
                    "type": 0,
                    "limit": limit,
                    "offset": offset
                ]
            )
            
            guard let response = response else {
                // Return empty instead of throwing for no data
                return (total: 0, followers: [])
            }
            
            return (total: response.total, followers: response.users)
            
        } catch {
            print("Failed to get followers (user might have none): \(error)")
            // Return empty result instead of throwing for any error
            return (total: 0, followers: [])
        }
    }

    func getFollowing(limit: Int = 20, offset: Int = 0) async throws -> (total: Int, following: [UserFameInfo]) {
        let network = NetworkService()
        
        do {
            let response: FameResponse? = try await network.requestEndpoint(
                endpoint: "/user/get-fame",
                method: "POST",
                body: [
                    "type": 1,
                    "limit": limit,
                    "offset": offset
                ]
            )
            
            guard let response = response else {
                // Return empty instead of throwing for no data
                return (total: 0, following: [])
            }
            
            return (total: response.total, following: response.users)
            
        } catch {
            print("Failed to get following (user might not be following anyone): \(error)")
            // Return empty result instead of throwing for any error
            return (total: 0, following: [])
        }
    }}

struct UserRowView: View {
    let user: UserFameInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture placeholder
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.name.prefix(1)).uppercased())
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if user.isSubscribed {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 16) {
                    Text("\(user.followers) followers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(user.following) following")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Follow/Unfollow button (you can implement this)
            Button("Follow") {
                // Implement follow functionality
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.purple.opacity(0.9))
            .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    followingView(initialTab: 1)
}
