import SwiftUI

struct CreateMemoryItemView: View {
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var listName = ""
    @State private var creationDate = Date()
    @State private var selectedGroupID: MemoryGroup.ID?

    private var trimmedName: String {
        listName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("新建记忆项目")
                .font(.title2.weight(.semibold))

            Form {
                TextField("列表名称", text: $listName)

                DatePicker(
                    "创建日期",
                    selection: $creationDate,
                    displayedComponents: [.date]
                )

                Picker("所属分组", selection: $selectedGroupID) {
                    Text("不归入分组").tag(MemoryGroup.ID?.none)

                    ForEach(viewModel.groups) { group in
                        Text(group.name).tag(MemoryGroup.ID?.some(group.id))
                    }
                }
            }

            HStack {
                Spacer()

                Button("取消") {
                    dismiss()
                }

                Button {
                    viewModel.addItem(
                        listName: trimmedName,
                        creationDate: creationDate,
                        groupID: selectedGroupID
                    )
                    dismiss()
                } label: {
                    Label("创建", systemImage: "plus.circle.fill")
                }
                .keyboardShortcut(.defaultAction)
                .disabled(trimmedName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
