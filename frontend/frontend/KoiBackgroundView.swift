//
//  KoiBackgroundView.swift
//  frontend
//
//  Created by Jayden Zhang on 7/31/25.
//

import SwiftUI

struct KoiBackgroundView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Dynamic gradient background
            KoiGradientBackground()
            
            // Animated koi fish
            AnimatedKoiFish()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
}

// MARK: - Gradient Background Component
struct KoiGradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.15),
                Color.blue.opacity(0.08),
                Color.white.opacity(0.9),
                Color.purple.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Animated Koi Fish Component
struct AnimatedKoiFish: View {
    @State private var koiFish: [KoiFish] = []
    @State private var groupTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ForEach(koiFish.indices, id: \.self) { index in
                KoiFishView(fish: koiFish[index])
                    .position(koiFish[index].currentPosition)
                    .opacity(koiFish[index].opacity)
            }
        }
        .onAppear {
            startGroupSpawning(screenSize: CGSize(width: 400, height: 800))
        }
        .onDisappear {
            groupTimer?.invalidate()
        }
    }
    
    private func startGroupSpawning(screenSize: CGSize) {
        // Spawn first group immediately
        spawnKoiGroup(screenSize: screenSize)
        
        // Set up timer to spawn groups every 15 seconds
        groupTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { _ in
            spawnKoiGroup(screenSize: screenSize)
        }
    }
    
    private func spawnKoiGroup(screenSize: CGSize) {
        let groupSize = Int.random(in: 3...5)
        let isHorizontal = Bool.random()
        
        let newFish = (0..<groupSize).map { i in
            createKoiFish(
                id: Int.random(in: 1000...9999), // Random ID to avoid conflicts
                index: i,
                groupSize: groupSize,
                isHorizontal: isHorizontal,
                screenSize: screenSize
            )
        }
        
        // Add new fish to existing array
        koiFish.append(contentsOf: newFish)
        
        // Start swimming animation for new fish
        for fish in newFish {
            animateKoi(fish: fish, screenSize: screenSize)
        }
        
        // Remove old fish that have completed their journey
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
            koiFish.removeAll { fish in
                newFish.contains { $0.id == fish.id }
            }
        }
    }
    
    private func createKoiFish(id: Int, index: Int, groupSize: Int, isHorizontal: Bool, screenSize: CGSize) -> KoiFish {
        let spacing: CGFloat = 40
        let groupOffset = CGFloat(groupSize - 1) * spacing / 2
        
        let startPos: CGPoint
        let direction: KoiFish.Direction
        
        if isHorizontal {
            // Left to right movement
            direction = .leftToRight
            startPos = CGPoint(
                x: -50,
                y: CGFloat.random(in: 200...600) + CGFloat(index) * spacing - groupOffset
            )
        } else {
            // Top to bottom movement
            direction = .topToBottom
            startPos = CGPoint(
                x: CGFloat.random(in: 100...300) + CGFloat(index) * spacing - groupOffset,
                y: -50
            )
        }
        
        return KoiFish(
            id: id,
            startPosition: startPos,
            currentPosition: startPos,
            size: CGFloat.random(in: 18...25),
            swimDuration: Double.random(in: 8...12),
            delay: Double(index) * 0.3,
            color: [
                Color.orange.opacity(0.15),
                Color.orange.opacity(0.2),
                Color(red: 1.0, green: 0.8, blue: 0.6).opacity(0.18),
                Color(red: 1.0, green: 0.7, blue: 0.5).opacity(0.22)
            ].randomElement() ?? Color.orange.opacity(0.15),
            direction: direction,
            opacity: 0.0
        )
    }
    
    private func animateKoi(fish: KoiFish, screenSize: CGSize) {
        guard let index = koiFish.firstIndex(where: { $0.id == fish.id }) else { return }
        
        let endPos: CGPoint
        switch fish.direction {
        case .leftToRight:
            endPos = CGPoint(x: screenSize.width + 50, y: fish.currentPosition.y)
        case .topToBottom:
            endPos = CGPoint(x: fish.currentPosition.x, y: screenSize.height + 50)
        }
        
        // Fade in
        withAnimation(.easeIn(duration: 1.0).delay(fish.delay)) {
            koiFish[index].opacity = 1.0
        }
        
        // Move across screen
        withAnimation(.linear(duration: fish.swimDuration).delay(fish.delay)) {
            koiFish[index].currentPosition = endPos
        }
        
        // Fade out near the end
        withAnimation(.easeOut(duration: 2.0).delay(fish.delay + fish.swimDuration - 2.0)) {
            if index < koiFish.count {
                koiFish[index].opacity = 0.0
            }
        }
    }
}

// MARK: - Koi Fish Model
struct KoiFish: Identifiable {
    let id: Int
    let startPosition: CGPoint
    let size: CGFloat
    let swimDuration: Double
    let delay: Double
    let color: Color
    let direction: Direction
    
    var currentPosition: CGPoint
    var opacity: Double = 0.0
    
    enum Direction {
        case leftToRight
        case topToBottom
    }
    
    init(id: Int, startPosition: CGPoint, currentPosition: CGPoint, size: CGFloat, swimDuration: Double, delay: Double, color: Color, direction: Direction, opacity: Double = 0.0) {
        self.id = id
        self.startPosition = startPosition
        self.currentPosition = currentPosition
        self.size = size
        self.swimDuration = swimDuration
        self.delay = delay
        self.color = color
        self.direction = direction
        self.opacity = opacity
    }
}

// MARK: - Individual Koi Fish View
struct KoiFishView: View {
    let fish: KoiFish
    
    var body: some View {
        Image(systemName: "fish.fill")
            .foregroundColor(fish.color)
            .font(.system(size: fish.size))
            .rotationEffect(.degrees(fish.direction == .topToBottom ? 90 : 0)) // Only rotate for vertical movement
    }
}

#Preview {
    KoiBackgroundView()
}
