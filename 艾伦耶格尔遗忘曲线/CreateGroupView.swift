import SwiftUI

struct CreateGroupView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var groupName = ""
    @State private var colorName: GroupColorName = .blue

    private var trimmedName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("新建分组")
                .font(.title2.weight(.semibold))

            Form {
                TextField("分组名称", text: $groupName)

                VStack(alignment: .leading, spacing: 10) {
                    Text("文件夹颜色")

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(44), spacing: 10), count: 4), spacing: 10) {
                        ForEach(GroupColorName.allCases) { option in
                            Button {
                                colorName = option
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 28, height: 28)

                                    if option == colorName {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .help(option.rawValue)
                        }
                    }
                }
            }

            HStack {
                Spacer()

                Button("取消") {
                    dismiss()
                }

                Button {
                    viewModel.addGroup(name: trimmedName, colorName: colorName)
                    dismiss()
                } label: {
                    Label("创建", systemImage: "folder.badge.plus")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
