//
//  View38.swift
//  Mock_designs
//
//  Created by Abdullah on 9/13/26.
//
//  A minimal, redesigned take on View37's Wordle-helper concept.
//

import SwiftUI

/// The four Wordle-style states a tile can cycle through on tap.
enum TileState: CaseIterable {
    case empty, absent, present, correct

    /// Full cycle used by the keyboard (lets the user mark a letter absent/gray).
    var next: TileState {
        switch self {
        case .empty:   return .absent
        case .absent:  return .present
        case .present: return .correct
        case .correct: return .empty
        }
    }

    var background: Color {
        switch self {
        case .empty:   return Color(.systemGray6)
        case .absent:  return Color(red: 0.47, green: 0.49, blue: 0.49) // Wordle gray
        case .present: return Color(red: 0.79, green: 0.71, blue: 0.34) // Wordle yellow
        case .correct: return Color(red: 0.42, green: 0.67, blue: 0.39) // Wordle green
        }
    }

    var foreground: Color {
        self == .empty ? .primary : .white
    }
}

/// Shared source of truth: each letter has a single state used by both the
/// guess tiles and the keyboard, so changes in one place reflect in the other.
@Observable
final class WordleState {
    var letterStates: [String: TileState] = [:]

    func state(for letter: String) -> TileState {
        letterStates[letter] ?? .empty
    }

    func setState(_ state: TileState, for letter: String) {
        letterStates[letter] = state
    }

    /// Letters still in play — anything not marked absent (gray) on the keyboard.
    var availableLetters: [String] {
        alphabet.filter { state(for: $0) != .absent }
    }
}

struct View38: View {

    @State private var model = WordleState()

    /// Standard QWERTY layout for the state-tracking keyboard.
    private let keyboardRows: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Wordle Helper")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .padding(.top, 24)

                Spacer()

                // The guess row: five scrollable letter pickers.
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { _ in
                        LetterPicker()
                    }
                }

                Spacer()

                // Keyboard for tracking each letter's state.
                VStack(spacing: 8) {
                    ForEach(keyboardRows.indices, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(keyboardRows[row], id: \.self) { key in
                                KeyTile(letter: key)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal)
        }
        .environment(model)
    }
}

/// A single tappable keyboard key that cycles through all four Wordle states.
struct KeyTile: View {
    let letter: String
    @Environment(WordleState.self) private var model

    var body: some View {
        let state = model.state(for: letter)
        Text(letter)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(state.foreground)
            .frame(width: 30, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(state.background)
            )
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    model.setState(state.next, for: letter)
                }
            }
    }
}

/// A vertical letter spinner with chevrons; supports press-and-hold to repeat.
/// Cycles only through letters still in play and shares its color with the keyboard.
struct LetterPicker: View {
    @Environment(WordleState.self) private var model

    @State private var currentLetter = "A"
    @State private var repeatTimer: Timer?

    /// The letter this tile has marked as correct (green). Position-specific:
    /// green never comes from the shared model, so it won't highlight other tiles.
    @State private var correctLetter: String?

    /// The letter to show — falls back to the first available letter if the
    /// current one was just marked absent (gray) on the keyboard.
    private var displayedLetter: String {
        let available = model.availableLetters
        if available.contains(currentLetter) { return currentLetter }
        return available.first ?? currentLetter
    }

    /// Green is local to this tile; yellow (present) is read from the shared model.
    private func displayState(for letter: String) -> TileState {
        if correctLetter == letter { return .correct }
        return model.state(for: letter) == .present ? .present : .empty
    }

    var body: some View {
        let letter = displayedLetter
        let state = displayState(for: letter)

        VStack(spacing: 8) {
            chevron("chevron.up", step: increment)

            Text(letter)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(state.foreground)
                .frame(width: 52, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(state.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color(.systemGray4),
                                              lineWidth: state == .empty ? 1.5 : 0)
                        )
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        cycleGuess(for: letter, from: state)
                    }
                }

            chevron("chevron.down", step: decrement)
        }
    }

    private func chevron(_ symbol: String, step: @escaping () -> Void) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.secondary)
            .frame(width: 52, height: 22)
            .contentShape(Rectangle()) // full frame is tappable
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in startRepeating(step: step) }
                    .onEnded { _ in stopRepeating() }
            )
    }

    /// Cycle empty → yellow → green → empty. Yellow writes to the shared model
    /// (letter-wide); green is stored locally and also greens the keyboard key.
    private func cycleGuess(for letter: String, from current: TileState) {
        switch current {
        case .empty:
            correctLetter = nil
            model.setState(.present, for: letter)
        case .present:
            correctLetter = letter
            model.setState(.correct, for: letter)
        case .correct:
            correctLetter = nil
            model.setState(.empty, for: letter)
        case .absent:
            break
        }
    }

    private func increment() {
        step(by: 1)
    }

    private func decrement() {
        step(by: -1)
    }

    /// Move to the next/previous available letter, wrapping around.
    private func step(by delta: Int) {
        let available = model.availableLetters
        guard !available.isEmpty else { return }
        let start = available.firstIndex(of: displayedLetter) ?? 0
        let next = (start + delta + available.count) % available.count
        currentLetter = available[next]
    }

    private func startRepeating(step: @escaping () -> Void) {
        // onChanged fires repeatedly; only start the timer once per press.
        guard repeatTimer == nil else { return }
        step() // step once immediately on press
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            step()
        }
    }

    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}

