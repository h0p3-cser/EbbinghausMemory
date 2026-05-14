import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var selectedItemID: MemoryItem.ID?
    @State private var showingCreateSheet = false
    @State private var showingCreateGroupSheet = false
    @State private var showingSettingsSheet = false

    var body: some View {
        Group {
            if #available(macOS 13.0, *) {
                NavigationSplitView {
                    SidebarView(
                        viewModel: viewModel,
                        selectedItemID: $selectedItemID,
                        showingCreateSheet: $showingCreateSheet,
                        showingCreateGroupSheet: $showingCreateGroupSheet
                    )
                } detail: {
                    detailContent
                }
            } else {
                NavigationView {
                    SidebarView(
                        viewModel: viewModel,
                        selectedItemID: $selectedItemID,
                        showingCreateSheet: $showingCreateSheet,
                        showingCreateGroupSheet: $showingCreateGroupSheet
                    )
                    detailContent
                }
            }
        }
        .frame(minWidth: 860, minHeight: 560)
        .toolbar {
            ToolbarItem {
                Button {
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("设置")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateMemoryItemView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingCreateGroupSheet) {
            CreateGroupView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        if let item = viewModel.item(with: selectedItemID) {
            DetailView(item: item, viewModel: viewModel)
        } else {
            PlaceholderDetailView()
        }
    }
}

private struct SidebarView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var selectedItemID: MemoryItem.ID?
    @Binding var showingCreateSheet: Bool
    @Binding var showingCreateGroupSheet: Bool

    @State private var pendingDeleteItem: MemoryItem?
    @State private var showingDeleteConfirmation = false
    @State private var pendingDeleteGroup: MemoryGroup?
    @State private var showingFirstGroupDeleteConfirmation = false
    @State private var showingFinalGroupDeleteConfirmation = false

    // Batch operation state
    @State private var isBatchMode = false
    @State private var selectedIDs: Set<MemoryItem.ID> = []
    @State private var showingFirstBatchDeleteConfirmation = false
    @State private var showingFinalBatchDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("记忆项目")
                    .font(.title3.weight(.semibold))

                Spacer()

                // Batch toggle button
                Button {
                    isBatchMode.toggle()
                    if !isBatchMode { selectedIDs.removeAll() }
                } label: {
                    Image(systemName: isBatchMode ? "checkmark.circle.fill" : "checklist")
                        .foregroundStyle(isBatchMode ? .blue : .secondary)
                }
                .buttonStyle(.borderless)
                .contentShape(Rectangle())
                .frame(width: 28, height: 28)
                .help(isBatchMode ? "退出批量模式" : "批量操作")

                Button {
                    showingCreateGroupSheet = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                }
                .buttonStyle(.borderless)
                .contentShape(Rectangle())
                .frame(width: 28, height: 28)
                .help("新建分组")

                Button {
                    showingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .contentShape(Rectangle())
                .frame(width: 28, height: 28)
                .help("新建列表")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if viewModel.shouldShowNotificationWarning {
                Label("通知权限未开启，将无法接收提醒", systemImage: "bell.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }

            List(selection: $selectedItemID) {
                // Ungrouped items shown directly
                ForEach(viewModel.items(in: nil)) { item in
                    itemRow(item)
                }

                ForEach(viewModel.groups) { group in
                    Section {
                        ForEach(viewModel.items(in: group.id)) { item in
                            itemRow(item)
                        }
                    } header: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(group.colorName.color)

                            Text(group.name)
                                .lineLimit(1)

                            Spacer()

                            Text("\(viewModel.items(in: group.id).count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            requestDeleteGroup(group)
                        } label: {
                            Label("删除分组", systemImage: "trash")
                        }
                    }
                    .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                        dropItem(providers, to: group.id)
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(minWidth: 260)
        .safeAreaInset(edge: .bottom) {
            if isBatchMode && !selectedIDs.isEmpty {
                VStack(spacing: 8) {
                    Text("已选中 \(selectedIDs.count) 个项目")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button(role: .destructive) {
                        showingFirstBatchDeleteConfirmation = true
                    } label: {
                        Label("批量删除", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .controlSize(.small)
                }
                .padding(10)
                .background(.regularMaterial)
            }
        }
        .onDrop(of: [UTType.text], isTargeted: nil) { providers in
            dropItem(providers, to: nil)
        }
        .confirmationDialog(
            "确定删除这个记忆项目吗？",
            isPresented: $showingDeleteConfirmation,
            presenting: pendingDeleteItem
        ) { item in
            Button("删除「\(item.listName)」", role: .destructive) {
                viewModel.deleteItem(id: item.id)
                selectedIDs.remove(item.id)
                if selectedItemID == item.id {
                    selectedItemID = nil
                }
            }
            Button("取消", role: .cancel) {}
        } message: { item in
            Text("删除后会同步移除「\(item.listName)」的所有复习提醒。")
        }
        .confirmationDialog(
            "删除这个分组文件夹？",
            isPresented: $showingFirstGroupDeleteConfirmation,
            presenting: pendingDeleteGroup
        ) { group in
            Button("继续删除「\(group.name)」", role: .destructive) {
                showingFinalGroupDeleteConfirmation = true
            }
            Button("取消", role: .cancel) {}
        } message: { group in
            Text("这个操作会让「\(group.name)」里的 \(viewModel.items(in: group.id).count) 个记忆项目从主页面消失。")
        }
        .confirmationDialog(
            "最后确认删除？",
            isPresented: $showingFinalGroupDeleteConfirmation,
            presenting: pendingDeleteGroup
        ) { group in
            Button("确认删除分组和其中项目", role: .destructive) {
                if let selectedItemID,
                   viewModel.item(with: selectedItemID)?.groupID == group.id {
                    self.selectedItemID = nil
                }
                selectedIDs = selectedIDs.filter { id in
                    viewModel.item(with: id)?.groupID != group.id
                }
                viewModel.deleteGroupAndItems(id: group.id)
                pendingDeleteGroup = nil
            }
            Button("取消", role: .cancel) {}
        } message: { group in
            Text("删除后会同步移除「\(group.name)」内所有项目及其复习提醒。此操作不会写入已完成记录。")
        }
        .confirmationDialog(
            "确定要批量删除 \(selectedIDs.count) 个项目吗？",
            isPresented: $showingFirstBatchDeleteConfirmation
        ) {
            Button("继续", role: .destructive) {
                showingFinalBatchDeleteConfirmation = true
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作将删除选中的所有项目及其复习提醒，且不可撤销。")
        }
        .confirmationDialog(
            "最后确认批量删除？",
            isPresented: $showingFinalBatchDeleteConfirmation
        ) {
            Button("确认删除 \(selectedIDs.count) 个项目", role: .destructive) {
                for id in selectedIDs {
                    viewModel.deleteItem(id: id)
                }
                selectedIDs.removeAll()
                if let selectedItemID, selectedIDs.contains(selectedItemID) {
                    self.selectedItemID = nil
                }
                isBatchMode = false
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后所有选中的项目及其复习提醒将永久移除。此操作不可撤销。")
        }
    }

    private func requestDelete(_ item: MemoryItem) {
        pendingDeleteItem = item
        showingDeleteConfirmation = true
    }

    private func requestDeleteGroup(_ group: MemoryGroup) {
        pendingDeleteGroup = group
        showingFirstGroupDeleteConfirmation = true
    }

    private func itemRow(_ item: MemoryItem) -> some View {
        MemoryItemRow(item: item, isBatchMode: isBatchMode, isSelected: selectedIDs.contains(item.id))
            .tag(item.id)
            .onDrag {
                NSItemProvider(object: item.id.uuidString as NSString)
            }
            .onTapGesture {
                if isBatchMode {
                    if selectedIDs.contains(item.id) {
                        selectedIDs.remove(item.id)
                    } else {
                        selectedIDs.insert(item.id)
                    }
                }
            }
            .contextMenu {
                Button(role: .destructive) {
                    requestDelete(item)
                } label: {
                    Label("删除", systemImage: "trash")
                }
            }
    }

    private func dropItem(_ providers: [NSItemProvider], to groupID: MemoryGroup.ID?) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            let idString: String?

            if let data = item as? Data {
                idString = String(data: data, encoding: .utf8)
            } else if let string = item as? String {
                idString = string
            } else if let string = item as? NSString {
                idString = String(string)
            } else {
                idString = nil
            }

            guard let idString, let itemID = UUID(uuidString: idString) else { return }

            Task { @MainActor in
                viewModel.moveItem(itemID, to: groupID)
            }
        }

        return true
    }
}

private struct PlaceholderDetailView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("选择或新建一个记忆项目")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
