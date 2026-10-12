import SwiftUI

/// "What happened" step: the facts EU261 depends on that flight data can't give us,
/// with the eligibility result updating live as the passenger answers.
struct DisruptionDetailsView: View {
    @ObservedObject var viewModel: ClaimViewModel

    private var report: Binding<DisruptionReport> { $viewModel.claimRequest.disruption }

    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isCancellation {
                FormSection(title: "When did the airline tell you about the cancellation?") {
                    ChoiceList(options: DisruptionReport.Notice.allCases, selection: report.notice)
                }

                FormSection(title: "Did the airline offer you another flight?") {
                    ChoiceList(options: [true, false], selection: report.alternativeOffered, label: { $0 ? "Yes" : "No" })
                    if viewModel.claimRequest.disruption.alternativeOffered == true {
                        Text("Compared with your original flight, the alternative left…")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        ChoiceList(options: DisruptionReport.AlternativeDeparture.allCases, selection: optional(report.alternativeDeparture))
                        Text("…and got you to your destination")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                        ChoiceList(options: DisruptionReport.AlternativeArrival.allCases, selection: optional(report.alternativeArrival))
                    }
                }
            } else if viewModel.needsArrivalDelayAnswer {
                FormSection(title: "How late did you reach your final destination?") {
                    ChoiceList(options: DisruptionReport.ArrivalDelay.allCases, selection: report.arrivalDelay)
                    Text("What counts is the time the aircraft doors opened at your final destination.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            } else if let event = viewModel.flight.latestDelayEvent {
                FormSection(title: "Arrival delay") {
                    Text("Flight data shows you arrived \(event.formattedDuration) late.")
                        .foregroundStyle(.white)
                }
            }

            FormSection(title: "Reason the airline gave (optional)") {
                PremiumTextField(placeholder: "e.g. technical problem, crew shortage, weather", text: report.airlineReason)
                Toggle(isOn: report.alreadyCompensated) {
                    Text("The airline already paid me compensation for this flight")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .tint(PremiumTheme.electricBlue)
            }

            EligibilitySummaryCard(viewModel: viewModel)
        }
    }

    private func optional<T>(_ binding: Binding<T>) -> Binding<T?> {
        Binding<T?>(get: { binding.wrappedValue }, set: { if let value = $0 { binding.wrappedValue = value } })
    }
}

/// Live result of the EU261 check, with the fee and net payout shown up front
/// (European Commission notice on claim agencies, 2017).
struct EligibilitySummaryCard: View {
    @ObservedObject var viewModel: ClaimViewModel

    var body: some View {
        let eligibility = viewModel.eligibility
        VStack(alignment: .leading, spacing: 10) {
            if !eligibility.isEligible {
                Label("Not eligible", systemImage: "xmark.octagon.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
            } else if eligibility.needsMoreInformation == true {
                Label("Up to \(viewModel.amountText)", systemImage: "questionmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(PremiumTheme.goldStart)
            } else {
                Label("You can claim \(viewModel.amountText)", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.green)
                Text("You receive \(viewModel.netPayoutText) after our \(Config.successFeePercent)% fee (VAT included). No win, no fee.")
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

            Text(eligibility.reason)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            ForEach(eligibility.warnings ?? [], id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(PremiumTheme.goldStart)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 16)
    }
}

/// Vertical list of tappable options with a checkmark on the selected one.
struct ChoiceList<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option?
    let label: (Option) -> String

    init(options: [Option], selection: Binding<Option?>, label: @escaping (Option) -> String) {
        self.options = options
        self._selection = selection
        self.label = label
    }

    var body: some View {
        VStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                    HapticsManager.shared.impact(style: .light)
                } label: {
                    HStack {
                        Text(label(option))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: selection == option ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selection == option ? PremiumTheme.goldStart : .white.opacity(0.4))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selection == option ? PremiumTheme.electricBlue.opacity(0.2) : Color.white.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension ChoiceList where Option: RawRepresentable, Option.RawValue == String {
    init(options: [Option], selection: Binding<Option?>) {
        self.init(options: options, selection: selection, label: { $0.rawValue })
    }
}
