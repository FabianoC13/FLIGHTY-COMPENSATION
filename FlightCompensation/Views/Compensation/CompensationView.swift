import SwiftUI

struct CompensationView: View {
    @StateObject private var viewModel: CompensationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: CompensationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppConstants.largeSpacing) {
                    if viewModel.eligibility.isEligible {
                        VStack(spacing: AppConstants.spacing) {
                            Text("You may be entitled to")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                            
                            Text(viewModel.eligibility.formattedAmount)
                                .font(.system(size: 56, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, AppConstants.largeSpacing * 2)
                        
                        VStack(alignment: .leading, spacing: AppConstants.spacing) {
                            Text(viewModel.eligibility.reason)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppConstants.spacing)
                        }
                        
                        VStack(spacing: AppConstants.spacing) {
                            Button(action: {
                                viewModel.startClaim()
                            }) {
                                HStack {
                                    if viewModel.isStartingClaim {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    Text(viewModel.isStartingClaim ? "Starting..." : "Start claim")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(Color.accentColor)
                                .cornerRadius(AppConstants.cardCornerRadius)
                            }
                            .disabled(viewModel.isStartingClaim)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("Save for later")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, AppConstants.spacing)
                        .padding(.top, AppConstants.largeSpacing)
                    } else {
                        VStack(spacing: AppConstants.spacing) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                                .padding(.top, AppConstants.largeSpacing * 2)
                            
                            Text(viewModel.eligibility.reason)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppConstants.spacing)
                            
                            Button(action: {
                                dismiss()
                            }) {
                                Text("OK")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.accentColor)
                                    .cornerRadius(AppConstants.cardCornerRadius)
                            }
                            .padding(.horizontal, AppConstants.spacing)
                            .padding(.top, AppConstants.largeSpacing)
                        }
                    }
                }
            }
            .navigationTitle("Compensation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


