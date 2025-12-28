import SwiftUI

struct EliteSegmentedControl: View {
    var options: [String]
    @Binding var selectedIndex: Int
    
    // Aesthetic Tuning
    // Taller height as requested
    private let height: CGFloat = 44 
    private let activeColor = Color(uiColor: .white)
    private let inactiveColor = Color.clear
    private let backgroundColor = Color(uiColor: .tertiarySystemFill)
    private let textActiveColor = Color.black
    private let textInactiveColor = Color.primary
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background Container
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .frame(height: height)
            
            // Sliding Active Segment
            HStack(spacing: 0) {
                 ForEach(0..<options.count, id: \.self) { index in
                     GeometryReader { geo in
                         if selectedIndex == index {
                             RoundedRectangle(cornerRadius: 8)
                                 .fill(activeColor)
                                 .padding(3)
                                 .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                 .transition(.opacity) // Smoother transition
                         }
                     }
                     .frame(maxWidth: .infinity)
                 }
            }
            .frame(height: height)
            
            // Text Labels Overlay
            HStack(spacing: 0) {
                ForEach(0..<options.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIndex = index
                        }
                    }) {
                        Text(options[index])
                            .font(.system(size: 15, weight: .medium)) // Fixed, non-stretched font
                            .foregroundStyle(selectedIndex == index ? textActiveColor : textInactiveColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle()) // Make entire area tappable
                    }
                }
            }
            .frame(height: height)
        }
        .frame(height: height) // Hard constraint
    }
}
