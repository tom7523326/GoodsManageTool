import SwiftUI
import VisionKit

struct BarcodeScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onScan: (String) -> Void

    @State private var isSupported = DataScannerViewController.isSupported
    @State private var isAvailable = DataScannerViewController.isAvailable
    @State private var startErrorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if let startErrorMessage {
                    ContentUnavailableView(
                        "无法启动扫码",
                        systemImage: "barcode.viewfinder",
                        description: Text(startErrorMessage)
                    )
                } else if isSupported && isAvailable {
                    DataScannerRepresentable(
                        onScan: { value in
                            onScan(value)
                            dismiss()
                        },
                        onStartFailed: { message in
                            startErrorMessage = message
                        }
                    )
                } else {
                    ContentUnavailableView(
                        "无法使用扫码",
                        systemImage: "barcode.viewfinder",
                        description: Text("请检查相机权限，或在真机上重试")
                    )
                }
            }
            .navigationTitle("扫描条码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

private struct DataScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onStartFailed: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        guard !uiViewController.isScanning else { return }
        do {
            try uiViewController.startScanning()
        } catch {
            onStartFailed("相机启动失败，请检查权限后重试")
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = addedItems.first else { return }
            if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue {
                dataScanner.stopScanning()
                onScan(payload)
            }
        }
    }
}
