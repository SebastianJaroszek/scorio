//
//  ContentView.swift
//  PadelCounter Watch App
//
//  Created by Sebastian Jaroszek on 25/08/2025.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @State private var team1Sets = 0
    @State private var team2Sets = 0
    @State private var team1Games = 0
    @State private var team2Games = 0
    @State private var team1Points = 0
    @State private var team2Points = 0
    @State private var gameHistory: [GameAction] = []
    
    enum GameAction {
        case team1Point(sets: Int, games: Int, points: Int, oppSets: Int, oppGames: Int, oppPoints: Int)
        case team2Point(sets: Int, games: Int, points: Int, oppSets: Int, oppGames: Int, oppPoints: Int)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main scoring area
                HStack(spacing: 0) {
                    // Team 1 side
                    Button(action: {
                        addPointToTeam1()
                    }) {
                        VStack(spacing: 2) {
                            // Sets (small)
                            Text("\(team1Sets)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            // Games (medium)
                            Text("\(team1Games)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.95))
                            
                            // Current game points (large)
                            Text(formatPoints(team1Points))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                            
                            Text("MY TEAM")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: geometry.size.width / 2, height: geometry.size.height * 0.75)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Team 2 side
                    Button(action: {
                        addPointToTeam2()
                    }) {
                        VStack(spacing: 2) {
                            // Sets (small)
                            Text("\(team2Sets)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            // Games (medium)
                            Text("\(team2Games)")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white.opacity(0.95))
                            
                            // Current game points (large)
                            Text(formatPoints(team2Points))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                            
                            Text("RIVALS")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: geometry.size.width / 2, height: geometry.size.height * 0.75)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.orange.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Undo button
                Button(action: {
                    undoLastAction()
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .semibold))
                        Text("UNDO")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(height: geometry.size.height * 0.25)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(gameHistory.isEmpty)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Score Management
    
    private func addPointToTeam1() {
        // Save COMPLETE current state before adding point (both teams)
        gameHistory.append(.team1Point(sets: team1Sets, games: team1Games, points: team1Points,
                                      oppSets: team2Sets, oppGames: team2Games, oppPoints: team2Points))
        
        team1Points += 1
        checkGameWin()
        WKInterfaceDevice.current().play(.start)
    }
    
    private func addPointToTeam2() {
        // Save COMPLETE current state before adding point (both teams)
        gameHistory.append(.team2Point(sets: team2Sets, games: team2Games, points: team2Points,
                                      oppSets: team1Sets, oppGames: team1Games, oppPoints: team1Points))
        
        team2Points += 1
        checkGameWin()
        WKInterfaceDevice.current().play(.success)
    }
    
    private func checkGameWin() {
        // Check if someone won the game
        if team1Points >= 4 || team2Points >= 4 {
            // Check for game win conditions
            if team1Points >= 4 && team1Points - team2Points >= 2 {
                // Team 1 wins the game
                team1Games += 1
                team1Points = 0
                team2Points = 0
                checkSetWin()
            } else if team2Points >= 4 && team2Points - team1Points >= 2 {
                // Team 2 wins the game
                team2Games += 1
                team1Points = 0
                team2Points = 0
                checkSetWin()
            }
        }
    }
    
    private func checkSetWin() {
        // Check if someone won the set (6 games with 2+ game advantage)
        if team1Games >= 6 && team1Games - team2Games >= 2 {
            // Team 1 wins the set
            team1Sets += 1
            team1Games = 0
            team2Games = 0
        } else if team2Games >= 6 && team2Games - team1Games >= 2 {
            // Team 2 wins the set
            team2Sets += 1
            team1Games = 0
            team2Games = 0
        }
        // Handle tiebreak at 6-6 (simplified - just continue to 7)
        else if team1Games == 6 && team2Games == 6 {
            // Continue playing until someone gets 2 game advantage
        }
    }
    
    private func undoLastAction() {
        guard !gameHistory.isEmpty else {
            WKInterfaceDevice.current().play(.failure)
            return
        }
        
        let lastAction = gameHistory.removeLast()
        
        // Simply restore the exact state that was saved before the last action
        switch lastAction {
        case .team1Point(let prevSets, let prevGames, let prevPoints, let oppSets, let oppGames, let oppPoints):
            // Restore Team 1's state
            team1Sets = prevSets
            team1Games = prevGames
            team1Points = prevPoints
            // Restore Team 2's state
            team2Sets = oppSets
            team2Games = oppGames
            team2Points = oppPoints
            
        case .team2Point(let prevSets, let prevGames, let prevPoints, let oppSets, let oppGames, let oppPoints):
            // Restore Team 2's state
            team2Sets = prevSets
            team2Games = prevGames
            team2Points = prevPoints
            // Restore Team 1's state
            team1Sets = oppSets
            team1Games = oppGames
            team1Points = oppPoints
        }
        
        // Play appropriate sound
        if team1Sets == 0 && team2Sets == 0 && team1Games == 0 && team2Games == 0 && team1Points == 0 && team2Points == 0 {
            WKInterfaceDevice.current().play(.retry) // Back to 0-0
        } else {
            WKInterfaceDevice.current().play(.notification) // Regular undo
        }
    }
    
    // MARK: - Score Formatting
    
    private func formatPoints(_ points: Int) -> String {
        switch points {
        case 0: return "0"
        case 1: return "15"
        case 2: return "30"
        case 3: return "40"
        default:
            // Handle deuce and advantage
            let otherPoints = points == team1Points ? team2Points : team1Points
            if points == otherPoints && points >= 3 {
                return "40" // Deuce
            } else if points > otherPoints && points >= 4 {
                return "AD" // Advantage
            } else if otherPoints > points && otherPoints >= 4 {
                return "40" // Other team has advantage
            } else {
                return "40"
            }
        }
    }
}

// MARK: - Watch App Structure

@main
struct PaddleScoreTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("Apple Watch Ultra 2 (49mm)")
                .previewDisplayName("Ultra 2")
            
            ContentView()
                .previewDevice("Apple Watch Series 9 (45mm)")
                .previewDisplayName("Series 9")
            
            ContentView()
                .previewDevice("Apple Watch SE (40mm)")
                .previewDisplayName("SE 40mm")
        }
    }
}
