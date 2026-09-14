//
//  View37.swift
//  Mock_designs
//
//  Created by Abdullah on 9/12/26.
//

import SwiftUI

let alphabet = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
                "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

struct View37: View {
    
    var body: some View {
        VStack {
            
            Spacer()
            

            
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { i in
                    HollowSquareTypingView()
//                    HollowSquareView(letter: "A")
                }
            }
            .frame(width: 282)
            
            Spacer()
            
            ForEach(0..<Int(ceil(Double(alphabet.count ) / 5)), id: \.self) { i in
                HStack(spacing: 8) {
                    let numColumns = Int(floor(Double(alphabet.count ) / 5))
                    ForEach(0..<numColumns, id: \.self) { j in
                        let index = (i * numColumns) + j
                        
                        if index < alphabet.count {
                            HollowSquareView(letter: alphabet[index])
                        }
                        else {
                            Spacer()
                        }
                    }
                }
                .frame(width: 282)
            }
        }
    }
}

/*
 
 0 0 1 2 3 4
 1 0 1 2 3 4
 2 0 1 2 3 4
 3 0 1 2 3 4
 4 0 1 2 3 4
 5 0 1 2 3 4
 
 
 
 0 1 2 3 4
 5 6 7 8 9
 10 11 12 13 14
 
 */

struct HollowSquareView: View {
    var letter: String?

    
    
    @State private var currColorIndex = 0
    let currSquareColors: [Color] = [.orange, .gray, .green]
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.5)) {
                if currColorIndex < currSquareColors.count - 1 {
                    currColorIndex += 1
                }
                else {
                    currColorIndex = 0
                }
            }
        } label: {
            ZStack {
                Rectangle()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(currSquareColors[currColorIndex])
                Text(letter ?? "")
                    .foregroundStyle(.white)
                    .font(.system(size: 24, weight: .bold))
            }
        }
    }
}


struct HollowSquareTypingView: View {
    
    
    @State private var currLetterIndex = 0
    
    @State private var currColorIndex = 0
    let currSquareColors: [Color] = [.orange, .green]
    
    

    @State private var repeatTimer: Timer?

    
    var body: some View {
        
        VStack(spacing: 6) {
            
            TiangleNext()
                .frame(width: 50, height: 25)
                .rotationEffect(.degrees(180))
                .foregroundStyle(currSquareColors[currColorIndex])
                .opacity(0.5)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in startRepeating(step: incrementLetter) }
                        .onEnded { _ in stopRepeating() }
                )
            
            
            ZStack {
                Rectangle()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(currSquareColors[currColorIndex])
                
                
                Text(alphabet[currLetterIndex])
                    .foregroundStyle(.white)
                    .font(.system(size: 24, weight: .bold))
                

            }
            .onTapGesture(count: 1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    if currColorIndex < currSquareColors.count - 1 {
                        currColorIndex += 1
                    }
                    else {
                        currColorIndex = 0
                    }
                }
            }
            
            TiangleNext()
                .frame(width: 50, height: 25)
                .foregroundStyle(currSquareColors[currColorIndex])
                .opacity(0.5)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in startRepeating(step: decrementLetter) }
                        .onEnded { _ in stopRepeating() }
                )
        }

    }

    private func incrementLetter() {
        if currLetterIndex < alphabet.count - 1 {
            currLetterIndex += 1
        }
        else {
            currLetterIndex = 0
        }
    }

    private func decrementLetter() {
        if currLetterIndex > 0 {
            currLetterIndex -= 1
        }
        else {
            currLetterIndex = alphabet.count - 1
        }
    }

    private func startRepeating(step: @escaping () -> Void) {
        
        guard repeatTimer == nil else { return }
        step()
        repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            step()
        }
    }

    private func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}

struct TiangleNext: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let point1 = CGPoint(x: rect.minX, y: rect.minY)
        let point2 = CGPoint(x: rect.maxX, y: rect.minY)
        let point3 = CGPoint(x: rect.midX, y: rect.maxY)
        
        path.move(to: point1)
        path.addLine(to: point2)
        path.addLine(to: point3)
        path.closeSubpath()
        return path
    }
}

