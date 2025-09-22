import SwiftUI

struct SocialView: View {
    @EnvironmentObject var socialManager: SocialManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var progressManager: ProgressManager
    
    @State private var selectedTab: SocialTab = .friends
    @State private var showingAddFriend = false
    @State private var showingCreateChallenge = false
    @State private var showingProfile = false
    @State private var searchText = ""
    @State private var animateElements = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Social Tabs
                socialTabsSection
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedTab {
                        case .friends:
                            friendsSection
                        case .challenges:
                            challengesSection
                        case .leaderboard:
                            leaderboardSection
                        case .feed:
                            feedSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                .background(themeManager.currentTheme.backgroundColor.ignoresSafeArea())
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Friend") {
                            showingAddFriend = true
                        }
                        
                        Button("Create Challenge") {
                            showingCreateChallenge = true
                        }
                        
                        Button("My Profile") {
                            showingProfile = true
                        }
                        
                        Divider()
                        
                        Button("Settings") {
                            // Navigate to social settings
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                animateElements = true
            }
        }
        .sheet(isPresented: $showingAddFriend) {
            AddFriendView()
        }
        .sheet(isPresented: $showingCreateChallenge) {
            CreateChallengeView()
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
    
    // MARK: - Social Tabs Section
    private var socialTabsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(SocialTab.allCases, id: \.self) { tab in
                    SocialTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        count: getTabCount(for: tab)
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(themeManager.currentTheme.cardBackgroundColor)
    }
    
    // MARK: - Friends Section
    private var friendsSection: some View {
        VStack(spacing: 20) {
            // Friend Requests
            if !socialManager.friendRequests.isEmpty {
                friendRequestsCard
            }
            
            // Online Friends
            if !onlineFriends.isEmpty {
                onlineFriendsSection
            }
            
            // All Friends
            allFriendsSection
            
            // Quick Actions
            friendsQuickActions
        }
    }
    
    private var friendRequestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("👋 Friend Requests")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Text("\(socialManager.friendRequests.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.currentTheme.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(socialManager.friendRequests.prefix(3)) { request in
                    FriendRequestCard(request: request)
                }
                
                if socialManager.friendRequests.count > 3 {
                    Button("View All Requests") {
                        // Navigate to full requests view
                    }
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var onlineFriendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🟢 Online Now")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Text("\(onlineFriends.count) online")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(onlineFriends) { friend in
                        OnlineFriendCard(friend: friend)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var allFriendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("👥 All Friends")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Text("\(socialManager.friends.count) friends")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            // Search Bar
            SearchBar(text: $searchText, placeholder: "Search friends...")
            
            LazyVStack(spacing: 8) {
                ForEach(filteredFriends) { friend in
                    FriendCard(friend: friend)
                        .scaleEffect(animateElements ? 1.0 : 0.9)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.6).delay(Double(filteredFriends.firstIndex(of: friend) ?? 0) * 0.1), value: animateElements)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var friendsQuickActions: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            QuickActionCard(
                title: "Find Friends",
                subtitle: "Discover new workout buddies",
                icon: "person.badge.plus",
                color: .blue
            ) {
                showingAddFriend = true
            }
            
            QuickActionCard(
                title: "Invite via Link",
                subtitle: "Share your friend code",
                icon: "link",
                color: .green
            ) {
                shareInviteLink()
            }
        }
    }
    
    // MARK: - Challenges Section
    private var challengesSection: some View {
        VStack(spacing: 20) {
            // Active Challenges
            activeChallengesSection
            
            // Available Challenges
            availableChallengesSection
            
            // Challenge History
            challengeHistorySection
        }
    }
    
    private var activeChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔥 Active Challenges")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Button("Create New") {
                    showingCreateChallenge = true
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            if socialManager.activeChallenges.isEmpty {
                EmptyChallengesView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(socialManager.activeChallenges) { challenge in
                        ActiveChallengeCard(challenge: challenge)
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var availableChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💪 Join Challenges")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(socialManager.availableChallenges.prefix(5)) { challenge in
                        AvailableChallengeCard(challenge: challenge)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var challengeHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🏆 Recent Completions")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                NavigationLink("View All", destination: ChallengeHistoryView())
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.accentColor)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(socialManager.completedChallenges.prefix(3)) { challenge in
                    CompletedChallengeCard(challenge: challenge)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Leaderboard Section
    private var leaderboardSection: some View {
        VStack(spacing: 20) {
            // Leaderboard Type Selector
            leaderboardTypeSelector
            
            // Current User Rank
            currentUserRankCard
            
            // Top Rankings
            topRankingsSection
        }
    }
    
    private var leaderboardTypeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LeaderboardType.allCases, id: \.self) { type in
                    LeaderboardTypeButton(
                        type: type,
                        isSelected: socialManager.selectedLeaderboardType == type
                    ) {
                        socialManager.selectedLeaderboardType = type
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var currentUserRankCard: some View {
        if let userEntry = socialManager.currentUserLeaderboardEntry {
            CurrentUserRankCard(entry: userEntry)
        }
    }
    
    private var topRankingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏆 Top Performers")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            LazyVStack(spacing: 8) {
                ForEach(socialManager.currentLeaderboard.enumerated().map({ $0 }), id: \.element.id) { index, entry in
                    LeaderboardEntryCard(
                        entry: entry,
                        rank: index + 1,
                        isCurrentUser: entry.userId == authManager.currentUser?.id
                    )
                    .scaleEffect(animateElements ? 1.0 : 0.9)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.1), value: animateElements)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Feed Section
    private var feedSection: some View {
        VStack(spacing: 20) {
            // Post Input
            createPostSection
            
            // Activity Feed
            activityFeedSection
        }
    }
    
    private var createPostSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: authManager.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.3))
                        .overlay(
                            Text(authManager.currentUser?.username.prefix(1).uppercased() ?? "U")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                Button("Share your workout...") {
                    // Open post creation view
                }
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }
            
            HStack {
                Spacer()
                
                Button("📸 Photo") {
                    // Add photo post
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)
                
                Button("💪 Workout") {
                    // Share workout post
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)
                
                Button("🏆 Achievement") {
                    // Share achievement post
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📰 Activity Feed")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            LazyVStack(spacing: 12) {
                ForEach(socialManager.activityFeed) { activity in
                    ActivityFeedCard(activity: activity)
                        .scaleEffect(animateElements ? 1.0 : 0.95)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.6).delay(Double(socialManager.activityFeed.firstIndex(of: activity) ?? 0) * 0.1), value: animateElements)
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Computed Properties
    private var onlineFriends: [Friend] {
        socialManager.friends.filter { $0.isOnline }
    }
    
    private var filteredFriends: [Friend] {
        if searchText.isEmpty {
            return socialManager.friends
        } else {
            return socialManager.friends.filter { friend in
                friend.username.localizedCaseInsensitiveContains(searchText) ||
                friend.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getTabCount(for tab: SocialTab) -> Int {
        switch tab {
        case .friends:
            return socialManager.friends.count
        case .challenges:
            return socialManager.activeChallenges.count
        case .leaderboard:
            return socialManager.currentLeaderboard.count
        case .feed:
            return socialManager.activityFeed.count
        }
    }
    
    private func shareInviteLink() {
        let inviteCode = authManager.currentUser?.friendCode ?? "GORILLA123"
        let inviteLink = "https://gorillamadnezz.app/invite/\(inviteCode)"
        
        let activityController = UIActivityViewController(
            activityItems: [inviteLink],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}

// MARK: - Enums

enum SocialTab: String, CaseIterable {
    case friends = "Friends"
    case challenges = "Challenges"
    case leaderboard = "Leaderboard"
    case feed = "Feed"
    
    var icon: String {
        switch self {
        case .friends: return "person.2.fill"
        case .challenges: return "trophy.fill"
        case .leaderboard: return "chart.bar.fill"
        case .feed: return "newspaper.fill"
        }
    }
}

// MARK: - Supporting Views

struct SocialTabButton: View {
    let tab: SocialTab
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: tab.icon)
                        .font(.caption)
                    
                    Text(tab.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isSelected ? Color.white : themeManager.currentTheme.accentColor)
                            .foregroundColor(isSelected ? themeManager.currentTheme.accentColor : .white)
                            .cornerRadius(8)
                    }
                }
                
                if isSelected {
                    Rectangle()
                        .fill(themeManager.currentTheme.accentColor)
                        .frame(height: 2)
                        .cornerRadius(1)
                }
            }
        }
        .foregroundColor(isSelected ? themeManager.currentTheme.accentColor : themeManager.currentTheme.secondaryTextColor)
        .padding(.horizontal, 16)
        .buttonStyle(PlainButtonStyle())
    }
}

struct FriendRequestCard: View {
    let request: FriendRequest
    @EnvironmentObject var socialManager: SocialManager
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: request.profileImageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(request.username.prefix(1).uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(request.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text("Wants to be friends")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Accept") {
                    socialManager.acceptFriendRequest(request.id)
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(themeManager.currentTheme.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16)
                
                Button("Decline") {
                    socialManager.declineFriendRequest(request.id)
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .cornerRadius(16)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(themeManager.currentTheme.backgroundColor.opacity(0.3))
        .cornerRadius(8)
    }
}

struct OnlineFriendCard: View {
    let friend: Friend
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: friend.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.3))
                        .overlay(
                            Text(friend.username.prefix(1).uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
            
            Text(friend.username)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
                .lineLimit(1)
            
            if let activity = friend.currentActivity {
                Text(activity)
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    .lineLimit(1)
            }
        }
        .frame(width: 70)
    }
}

struct FriendCard: View {
    let friend: Friend
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: friend.profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(themeManager.currentTheme.accentColor.opacity(0.3))
                        .overlay(
                            Text(friend.username.prefix(1).uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.currentTheme.accentColor)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                if friend.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                
                if let activity = friend.currentActivity {
                    Text(activity)
                        .font(.caption2)
                        .foregroundColor(Color.green)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Level \(friend.level)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(themeManager.currentTheme.accentColor.opacity(0.2))
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .cornerRadius(8)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text("\(friend.currentStreak)")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(themeManager.currentTheme.backgroundColor.opacity(0.3))
        .cornerRadius(8)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActiveChallengeCard: View {
    let challenge: Challenge
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(challenge.title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                
                Spacer()
                
                Text(challenge.type.emoji)
                    .font(.title2)
            }
            
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .lineLimit(2)
            
            // Progress Bar
            VStack(spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                    
                    Spacer()
                    
                    Text("\(Int(challenge.progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                }
                
                ProgressView(value: challenge.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.currentTheme.accentColor))
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(.caption)
                    Text("\(challenge.participantCount) participants")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
                
                Spacer()
                
                Text(challenge.timeRemaining)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(themeManager.currentTheme.cardBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct EmptyChallengesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text("🏆")
                .font(.system(size: 32))
            
            Text("No Active Challenges")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            
            Text("Create or join a challenge to start competing with friends!")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// Additional supporting views would continue here...
// (AvailableChallengeCard, CompletedChallengeCard, LeaderboardTypeButton, etc.)

#Preview {
    SocialView()
        .environmentObject(SocialManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
        .environmentObject(ProgressManager())
}
