
import SwiftUI
import CloudKit

@MainActor
private enum GroupsListCache {
    static var groups: [SharedGroup] = []
    static var hasLoaded = false
}

struct GroupsListView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var subscriptionManager =
    SubscriptionManager.shared
    
    // MARK: - State
    
    @State private var groups: [SharedGroup] = []
    @State private var isLoading = false
    @State private var needsRefresh = false
    @State private var hasLoadedGroups = false
    
    @State private var showCreateGroup = false
    @State private var showPaywall = false
    
    @State private var groupToRename: SharedGroup?
    @State private var groupToRemove: SharedGroup?
    
    @State private var errorMessage = ""
    @State private var showError = false
    
    // MARK: - Subscription Rules
    
    private var ownedGroupCount: Int {
        groups.filter(\.isOwnedByCurrentUser).count
    }
    
    private var canCreateAnotherGroup: Bool {
        subscriptionManager.isSubscribed || ownedGroupCount < 1
    }
    
    private var canUseCreateButton: Bool {
        subscriptionManager.isSubscribed || hasLoadedGroups
    }
    
    // MARK: - Body
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                AppColors.dashboardGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    groupsHeader
                    
                    groupsContent
                    
                }
                
            }
            .toolbar(.hidden, for: .navigationBar)
            
            // MARK: - Create Group Sheet
            
            .sheet(isPresented: $showCreateGroup) {
                
                CreateGroupView {
                    
                    Task {
                        await loadGroups()
                    }
                    
                }
                
            }
            
            // MARK: - Premium Paywall
            
            .sheet(isPresented: $showPaywall) {
                
                PaywallView(
                    reason: "Create unlimited groups with Premium."
                )
                
            }
            
            // MARK: - Rename Group
            
            .sheet(item: $groupToRename) { group in
                
                RenameGroupView(group: group) {
                    
                    Task {
                        await loadGroups()
                    }
                    
                }
                
            }
            
            // MARK: - Initial Loading
            
            .task {
                guard !Task.isCancelled else { return }
                await loadGroups()
            }
            
            // MARK: - Accepted Invitation
            
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .didAcceptGroupShare
                )
            ) { _ in
                
                Task {
                    await loadGroups()
                }
                
            }
            
            // MARK: - Error Alert
            
            .alert(
                "Error",
                isPresented: $showError
            ) {
                
                Button("OK", role: .cancel) { }
                
            } message: {
                
                Text(errorMessage)
                
            }
            
            // MARK: - Delete / Leave Confirmation
            
            .confirmationDialog(
                groupToRemove.map { group in
                    
                    group.isOwnedByCurrentUser
                    ? "Delete \"\(group.name)\"?"
                    : "Leave \"\(group.name)\"?"
                    
                } ?? "",
                isPresented: Binding(
                    get: {
                        groupToRemove != nil
                    },
                    set: { isPresented in
                        
                        if !isPresented {
                            groupToRemove = nil
                        }
                        
                    }
                ),
                titleVisibility: .visible
            ) {
                
                Button(
                    groupToRemove?.isOwnedByCurrentUser == true
                    ? "Delete"
                    : "Leave",
                    role: .destructive
                ) {
                    
                    if let group = groupToRemove {
                        
                        Task {
                            await remove(group)
                        }
                        
                    }
                    
                }
                
                Button("Cancel", role: .cancel) {
                    groupToRemove = nil
                }
                
            } message: {
                
                if groupToRemove?.isOwnedByCurrentUser == true {
                    
                    Text(
                        "This removes the group for everyone, including anyone you've shared it with. This can't be undone."
                    )
                    
                } else {
                    
                    Text(
                        "You'll be removed from this group and won't see its expenses any more. The group stays for everyone else."
                    )
                    
                }
                
            }
            
        }
        
    }
    
    // MARK: - Purple Header
    
    private var groupsHeader: some View {
        
        VStack(alignment: .leading, spacing: 22) {
            
            HStack(spacing: 12) {
                
                Button {
                    dismiss()
                } label: {
                    
                    HStack(spacing: 5) {
                        
                        Image(systemName: "chevron.left")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .semibold
                                )
                            )
                        
                        Text("Back")
                            .font(.system(size: 16))
                        
                    }
                    .foregroundStyle(.white)
                    
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                
                Text("Groups")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                
                Button {
                    createGroupTapped()
                } label: {
                    
                    Image(systemName: "plus")
                        .font(
                            .system(
                                size: 20,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            canUseCreateButton
                            ? Color.white
                            : Color.white.opacity(0.45)
                        )
                        .frame(
                            width: 44,
                            height: 44,
                            alignment: .trailing
                        )
                    
                }
                .disabled(!canUseCreateButton)
                .accessibilityLabel("Create Group")
                .frame(
                    maxWidth: .infinity,
                    alignment: .trailing
                )
                
            }
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text("Shared Expenses")
                    .font(
                        .system(
                            size: 27,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                
                Text("Manage expenses together")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        Color.white.opacity(0.85)
                    )
                
            }
            
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 28)
        
    }
    
    // MARK: - Main Content
    
    private var groupsContent: some View {
        
        ScrollView {
            
            VStack(spacing: 24) {
                
                if isLoading && !hasLoadedGroups {
                    
                    loadingState
                    
                } else if groups.isEmpty {
                    
                    if hasLoadedGroups {
                        
                        emptyState
                        
                    } else {
                        
                        unavailableState
                        
                    }
                    
                } else {
                    
                    groupsSection
                    
                }
                
                createGroupButton
                
            }
            .padding(
                .horizontal,
                AppColors.pageHorizontalPadding
            )
            .padding(.top, 24)
            .padding(.bottom, 40)
            
        }
        .refreshable {
            
            await loadGroups(showSpinner: false)
            
        }
        .background {
            
            UnevenRoundedRectangle(
                topLeadingRadius:
                    AppColors.dashboardContentCornerRadius,
                topTrailingRadius:
                    AppColors.dashboardContentCornerRadius
            )
            .fill(AppColors.dashboardSurface)
            .ignoresSafeArea(edges: .bottom)
            
        }
        
    }
    
    // MARK: - Groups Section
    
    private var groupsSection: some View {
        
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                
                Text("My Groups")
                    .font(
                        .system(
                            size: 21,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        AppColors.textPrimary
                    )
                
                Spacer()
                
                Text(
                    "\(groups.count) \(groups.count == 1 ? "group" : "groups")"
                )
                .font(.system(size: 13))
                .foregroundStyle(
                    AppColors.textSecondary
                )
                
            }
            
            ForEach(groups) { group in
                
                groupCard(group)
                
            }
            
        }
        
    }
    
    // MARK: - Group Card
    
    private func groupCard(
        _ group: SharedGroup
    ) -> some View {
        
        NavigationLink {
            GroupDetailView(group: group)
                .tint(.white)
        } label: {
            
            HStack(spacing: 14) {
                
                // Group Icon
                
                Image(
                    systemName: group.isOwnedByCurrentUser
                    ? "person.3.fill"
                    : "person.2.fill"
                )
                .font(.system(size: 21))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
                .frame(
                    width: 52,
                    height: 52
                )
                .background(
                    AppColors.dashboardPurple.opacity(0.10)
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 15
                    )
                )
                
                // Group Information
                
                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {
                    
                    Text(group.name)
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            AppColors.textPrimary
                        )
                        .lineLimit(1)
                    
                    Text(
                        group.createdAt,
                        format: .dateTime
                            .day()
                            .month(.abbreviated)
                            .year()
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(
                        AppColors.textSecondary
                    )
                    
                    Text(
                        group.isOwnedByCurrentUser
                        ? "Created by you"
                        : "Joined group"
                    )
                    .font(
                        .system(
                            size: 12,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        AppColors.dashboardPurple
                    )
                    
                }
                
                Spacer(minLength: 4)
                
                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        AppColors.textSecondary
                    )
                
            }
            .padding(16)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(AppColors.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        AppColors.cardCornerRadius
                )
            )
            .overlay {
                
                RoundedRectangle(
                    cornerRadius:
                        AppColors.cardCornerRadius
                )
                .stroke(
                    AppColors.border,
                    lineWidth: 1
                )
                
            }
            
        }
        .buttonStyle(.plain)
        
        // Long-press menu replaces the old List swipe actions.
        
        .contextMenu {
            
            if group.isOwnedByCurrentUser {
                
                Button {
                    
                    groupToRename = group
                    
                } label: {
                    
                    Label(
                        "Rename Group",
                        systemImage: "pencil"
                    )
                    
                }
                
                Button(role: .destructive) {
                    
                    groupToRemove = group
                    
                } label: {
                    
                    Label(
                        "Delete Group",
                        systemImage: "trash"
                    )
                    
                }
                
            } else {
                
                Button(role: .destructive) {
                    
                    groupToRemove = group
                    
                } label: {
                    
                    Label(
                        "Leave Group",
                        systemImage:
                            "rectangle.portrait.and.arrow.right"
                    )
                    
                }
                
            }
            
        }
        
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        
        VStack(spacing: 16) {
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    AppColors.dashboardPurple
                )
                .frame(
                    width: 96,
                    height: 96
                )
                .background(
                    AppColors.dashboardPurple.opacity(0.10)
                )
                .clipShape(Circle())
            
            Text("No Groups Yet")
                .font(
                    .system(
                        size: 22,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    AppColors.textPrimary
                )
            
            Text(
                "Create a group to share expenses with friends or family."
            )
            .font(.system(size: 14))
            .foregroundStyle(
                AppColors.textSecondary
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 65)
        .padding(.bottom, 40)
        
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        
        VStack(spacing: 14) {
            
            ProgressView()
                .tint(AppColors.dashboardPurple)
            
            Text("Loading your groups...")
                .font(.subheadline)
                .foregroundStyle(
                    AppColors.textSecondary
                )
            
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
        
    }
    
    // MARK: - Unavailable State
    
    private var unavailableState: some View {
        
        VStack(spacing: 14) {
            
            Image(
                systemName: "wifi.exclamationmark"
            )
            .font(.system(size: 36))
            .foregroundStyle(
                AppColors.dashboardPurple
            )
            
            Text("Unable to Load Groups")
                .font(.headline)
                .foregroundStyle(
                    AppColors.textPrimary
                )
            
            Text(
                "Check your connection and pull down to try again."
            )
            .font(.subheadline)
            .foregroundStyle(
                AppColors.textSecondary
            )
            .multilineTextAlignment(.center)
            
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
        
    }
    
    // MARK: - Create Group Button
    
    private var createGroupButton: some View {
        
        Button {
            
            createGroupTapped()
            
        } label: {
            
            HStack(spacing: 10) {
                
                Image(systemName: "plus")
                    .font(
                        .system(
                            size: 16,
                            weight: .bold
                        )
                    )
                
                Text("Create New Group")
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                canUseCreateButton
                ? AppColors.dashboardPurple
                : AppColors.dashboardPurple.opacity(0.45)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 16
                )
            )
            
        }
        .buttonStyle(.plain)
        .disabled(!canUseCreateButton)
        
    }
    
    // MARK: - Create Group Action
    
    private func createGroupTapped() {
        
        guard canUseCreateButton else {
            return
        }
        
        if canCreateAnotherGroup {
            
            showCreateGroup = true
            
        } else {
            
            showPaywall = true
            
        }
        
    }
    
    // MARK: - Remove Group
    
    private func remove(
        _ group: SharedGroup
    ) async {
        
        do {
            
            if group.isOwnedByCurrentUser {
                
                try await GroupSharingManager.shared
                    .deleteGroup(group)
                
            } else {
                
                try await GroupSharingManager.shared
                    .leaveGroup(group)
                
            }
            
            groupToRemove = nil
            
            await loadGroups()
            
        } catch {
            
            groupToRemove = nil
            errorMessage = error.localizedDescription
            showError = true
            
        }
        
    }
    
    // MARK: - Load Groups
    
    
    private func loadGroups(
        showSpinner: Bool = true
    ) async {
        
        // Prevent overlapping CloudKit requests.
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetchedGroups = try await GroupSharingManager.shared.fetchAllGroups()
            
            groups = fetchedGroups
            hasLoadedGroups = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
// MARK: - Preview

#Preview {
    GroupsListView()
}
