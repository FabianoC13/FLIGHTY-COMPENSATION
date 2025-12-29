import SwiftUI

struct FlightTimelineView: View {
    let events: [DelayEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timeline")
                .font(.system(size: 18, weight: .semibold))

            if events.isEmpty {
                Text("No events available")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                ForEach(events) { event in
                    HStack(alignment: .top, spacing: 12) {
                        // Timeline dot
                        VStack {
                            Circle()
                                .fill(event.type == .cancellation ? Color.red : Color.accentColor)
                                .frame(width: 10, height: 10)
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 2, height: 40)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(event.type == .cancellation ? "Cancelled" : "Delayed")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                                if let actual = event.actualTime {
                                    Text(actual, style: .time)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }

                            if let reason = event.reason {
                                Text(reason)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Text("Duration: \(event.formattedDuration)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(AppConstants.cardPadding)
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct FlightTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        FlightTimelineView(events: [
            DelayEvent(type: .delay, duration: 4*3600, actualTime: Date(), reason: "Operational delay"),
            DelayEvent(type: .cancellation, duration: 0, actualTime: nil, reason: "Cancelled by airline")
        ])
            .padding()
            .previewLayout(.sizeThatFits)
    }
}