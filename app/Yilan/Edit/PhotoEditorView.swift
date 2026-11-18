import SwiftUI

struct PhotoEditorView: View {
    let item: MediaItem
    let initialTurns: Int
    let onSaved: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var preview: PhotoEdit.Preview?
    @State private var edit = PhotoEdit()
    @State private var format: PhotoEdit.Format = .png
    @State private var saving = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("轻编辑").font(.title2.weight(.semibold))
            Text(item.name).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)

            Group {
                if let preview { canvas(preview) }
                else if error == nil { ProgressView() }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))

            if let preview {
                HStack(spacing: 12) {
                    Button("向右旋转") { edit.rotateRight() }
                    Button("重置裁切") { edit.crop = PhotoEdit.full }.disabled(edit.crop == PhotoEdit.full)
                    Spacer()
                    LabeledContent("缩放比例") {
                        TextField("缩放比例", value: $edit.percent, format: .number)
                            .labelsHidden()
                            .frame(width: 52)
                        Text("%")
                    }
                    .fixedSize()
                    Picker("格式", selection: $format) {
                        ForEach(PhotoEdit.Format.allCases) { Text($0.label).tag($0) }
                    }
                    .fixedSize()
                }
                .disabled(saving)
                HStack {
                    Text("拖出矩形可裁切，支持 1–200% 尺寸。")
                    Spacer()
                    let size = edit.outputSize(preview.size)
                    Text("\(Int(size.width)) × \(Int(size.height))").monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let error { Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true) }

            HStack {
                Text("副本保存在原文件旁，不含原图的 EXIF 信息。").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("取消") { dismiss() }.keyboardShortcut(.cancelAction).disabled(saving)
                Button(saving ? "正在保存…" : "另存副本") { save() }
                    .buttonStyle(.borderedProminent)
                    .disabled(saving || (preview.map { !edit.allowsOutput($0.size) } ?? true))
            }
        }
        .padding(20)
        .frame(width: 600)
        .interactiveDismissDisabled(saving)
        .task {
            edit.turns = initialTurns
            let url = item.url
            let result = await Task.detached(priority: .userInitiated) { Result { try PhotoEdit.preview(url) } }.value
            guard !Task.isCancelled else { return }
            switch result {
            case .success(let image): preview = image
            case .failure(let failure): error = failure.localizedDescription
            }
        }
    }

    private func canvas(_ preview: PhotoEdit.Preview) -> some View {
        GeometryReader { geo in
            let rotated = edit.rotatedSize(preview.size)
            let scale = min(geo.size.width / rotated.width, geo.size.height / rotated.height)
            let width = rotated.width * scale
            let height = rotated.height * scale
            Color.clear.frame(width: width, height: height).overlay {
                Image(decorative: preview.image, scale: 1)
                    .resizable()
                    .frame(width: preview.size.width * scale, height: preview.size.height * scale)
                    .rotationEffect(.degrees(Double(edit.normalizedTurns * 90)))
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .topLeading) {
                if edit.crop != PhotoEdit.full {
                    let rect = CGRect(x: edit.crop.minX * width, y: edit.crop.minY * height,
                                      width: edit.crop.width * width, height: edit.crop.height * height)
                    Path { path in
                        path.addRect(CGRect(x: 0, y: 0, width: width, height: height))
                        path.addRect(rect)
                    }
                    .fill(.black.opacity(0.55), style: FillStyle(eoFill: true))
                    Rectangle().strokeBorder(.white, lineWidth: 1.5)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 5).onChanged { value in
                guard !saving else { return }
                let a = CGPoint(x: min(max(value.startLocation.x / width, 0), 1), y: min(max(value.startLocation.y / height, 0), 1))
                let b = CGPoint(x: min(max(value.location.x / width, 0), 1), y: min(max(value.location.y / height, 0), 1))
                guard abs(a.x - b.x) * width >= 2, abs(a.y - b.y) * height >= 2 else { return }
                edit.crop = CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
            })
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    private func save() {
        guard !saving, let preview, edit.allowsOutput(preview.size) else { return }
        saving = true
        error = nil
        let source = item, settings = edit, outputFormat = format
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                Result {
                    let url = URL(filePath: source.url.path, directoryHint: .notDirectory)
                    let fresh = FolderScanner.item(at: url)
                    guard let fresh, fresh.fileID == source.fileID, fresh.fileSize == source.fileSize,
                          fresh.modificationDate == source.modificationDate else { throw PhotoEdit.Failure.sourceChanged }
                    return try settings.export(url, format: outputFormat)
                }
            }.value
            saving = false
            switch result {
            case .success(let saved):
                dismiss()
                onSaved(saved)
            case .failure(let failure):
                error = failure.localizedDescription
            }
        }
    }
}
