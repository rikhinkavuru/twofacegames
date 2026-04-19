import SwiftUI

struct HomeScreen: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.theme) private var theme

    enum Mode {
        case menu
        case create
        case join
    }

    @State private var mode: Mode = .menu
    @State private var playerName = ""
    @State private var gameCode = ""
    @State private var createButtonPressed = false
    @State private var joinButtonPressed = false
    @State private var animate = false

    var body: some View {
        ZStack {
            HomeAmbientBackground()

            Group {
                switch mode {
                case .menu:
                    menuContentView
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            )
                        )
                case .create:
                    createContentView
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            )
                        )
                case .join:
                    joinContentView
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            )
                        )
                }
            }
            .padding(.horizontal, ScreenScale.width(20))
            .padding(.vertical, ScreenScale.height(18))

            overlayContent
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animate = true
            }
        }
        .animation(.smoothSpring, value: mode)
    }

    private var menuContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ScreenScale.height(22)) {
                Spacer(minLength: ScreenScale.height(22))

                heroPanel
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : -24)
                    .animation(.easeOut(duration: 0.75), value: animate)

                VStack(spacing: ScreenScale.height(16)) {
                    actionButton(
                        title: "Create Game",
                        subtitle: "Spin up a fresh neon lobby for your crew.",
                        icon: "plus",
                        accent: theme.accent,
                        isPressed: createButtonPressed,
                        action: {
                            withAnimation(.smoothSpring) {
                                mode = .create
                            }
                        }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in createButtonPressed = true }
                            .onEnded { _ in createButtonPressed = false }
                    )

                    actionButton(
                        title: "Join With Code",
                        subtitle: "Jump into a live lobby with your access code.",
                        icon: "link",
                        accent: theme.accentSecondary,
                        isPressed: joinButtonPressed,
                        action: {
                            withAnimation(.smoothSpring) {
                                mode = .join
                            }
                        }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in joinButtonPressed = true }
                            .onEnded { _ in joinButtonPressed = false }
                    )
                }
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 28)
                .animation(.easeOut(duration: 0.75).delay(0.15), value: animate)

                footerPill
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.75).delay(0.25), value: animate)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var createContentView: some View {
        formShell(
            eyebrow: "Host Lobby",
            title: "Create a room that feels alive.",
            subtitle: "Enter your name and launch a fresh code for everyone to join."
        ) {
            VStack(spacing: ScreenScale.height(16)) {
                technoField(
                    title: "Your Name",
                    prompt: "e.g. Alex",
                    text: $playerName,
                    icon: "person.crop.circle"
                )

                primaryButton(
                    title: viewModel.loading ? "Creating..." : "Create Lobby",
                    icon: viewModel.loading ? "hourglass" : "sparkles",
                    disabled: playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.loading,
                    action: {
                        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        Task {
                            await viewModel.createGame(hostName: trimmedName)
                        }
                    }
                )
            }
        }
    }

    private var joinContentView: some View {
        formShell(
            eyebrow: "Join Lobby",
            title: "Drop into the signal.",
            subtitle: "Enter your handle and a live room code to connect instantly."
        ) {
            VStack(spacing: ScreenScale.height(16)) {
                technoField(
                    title: "Your Name",
                    prompt: "e.g. Sam",
                    text: $playerName,
                    icon: "person.crop.circle"
                )

                technoField(
                    title: "Game Code",
                    prompt: "ABCDE",
                    text: $gameCode,
                    icon: "number.square",
                    isCodeField: true
                )

                primaryButton(
                    title: viewModel.loading ? "Joining..." : "Join Lobby",
                    icon: viewModel.loading ? "hourglass" : "arrow.right.circle.fill",
                    disabled: playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || gameCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.loading,
                    action: {
                        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedCode = gameCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        guard !trimmedName.isEmpty, !trimmedCode.isEmpty else { return }
                        Task {
                            await viewModel.joinGame(code: trimmedCode, playerName: trimmedName)
                        }
                    }
                )
            }
            .onChange(of: gameCode) { _, newValue in
                gameCode = newValue.uppercased()
            }
        }
    }

    private var heroPanel: some View {
        VStack(spacing: ScreenScale.height(22)) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [theme.accent.opacity(0.45), .clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: ScreenScale.width(110)
                        )
                    )
                    .scaledFrame(width: 180, height: 180)
                    .blur(radius: 2)

                Circle()
                    .strokeBorder(theme.border.opacity(0.55), lineWidth: 1)
                    .background(
                        Circle()
                            .fill(theme.surface.opacity(0.72))
                    )
                    .scaledFrame(width: 134, height: 134)
                    .overlay(maskGlyph)
                    .glassEffect()
                    .neonGlow(color: theme.accent)
            }

            VStack(spacing: ScreenScale.height(10)) {
                Text("TWOFACE")
                    .font(.system(size: ScreenScale.font(48), weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.textPrimary, theme.accent, theme.accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .tracking(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.75)

                Text("Trust no one. Not even yourself.")
                    .font(.system(size: ScreenScale.font(15), weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: ScreenScale.width(10)) {
                    capsuleTag("Techno party game", color: theme.success)
                    capsuleTag("Live room codes", color: theme.accentSecondary)
                }
            }
        }
        .padding(.horizontal, ScreenScale.width(24))
        .padding(.vertical, ScreenScale.height(28))
        .frame(maxWidth: .infinity)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(theme.border.opacity(0.65), lineWidth: 1)
        )
        .premiumShadow()
    }

    private var heroBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(theme.surface.opacity(0.72))
            .background(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.accent.opacity(0.16), theme.accentSecondary.opacity(0.12), theme.surface.opacity(0.88)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }

    private var maskGlyph: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.textPrimary, theme.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(ScreenScale.width(20))

            Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(theme.surface, style: StrokeStyle(lineWidth: ScreenScale.width(34), lineCap: .round))
                .rotationEffect(.degrees(90))
                .padding(ScreenScale.width(20))

            HStack(spacing: ScreenScale.width(22)) {
                Capsule()
                    .fill(theme.surface)
                    .scaledFrame(width: 24, height: 10)
                    .rotationEffect(.degrees(18))
                Capsule()
                    .fill(theme.textPrimary.opacity(0.35))
                    .scaledFrame(width: 24, height: 10)
                    .rotationEffect(.degrees(-18))
            }
        }
    }

    private var footerPill: some View {
        Text("v1.0 • herd studios")
            .font(.system(size: ScreenScale.font(11), weight: .semibold, design: .rounded))
            .foregroundColor(theme.textSecondary.opacity(0.9))
            .tracking(1.6)
            .padding(.horizontal, ScreenScale.width(18))
            .padding(.vertical, ScreenScale.height(10))
            .background(theme.surface.opacity(0.6))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(theme.border.opacity(0.55), lineWidth: 1)
            )
    }

    private var overlayContent: some View {
        VStack(spacing: ScreenScale.height(14)) {
            if let error = viewModel.error, !error.isEmpty {
                HStack(spacing: ScreenScale.width(12)) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(theme.warning)
                        .neonGlow(color: theme.warning)

                    Text(error)
                        .font(.system(size: ScreenScale.font(13), weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        viewModel.error = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: ScreenScale.font(12), weight: .bold))
                            .foregroundColor(theme.textSecondary)
                            .padding(10)
                            .background(theme.surfaceElevated.opacity(0.9))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, ScreenScale.width(16))
                .padding(.vertical, ScreenScale.height(14))
                .frame(maxWidth: .infinity)
                .background(theme.surface.opacity(0.82))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(theme.warning.opacity(0.45), lineWidth: 1)
                )
                .padding(.horizontal, ScreenScale.width(20))
                .padding(.top, ScreenScale.height(18))
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()

            if viewModel.loading {
                VStack(spacing: ScreenScale.height(14)) {
                    ProgressView()
                        .tint(theme.accent)
                        .scaleEffect(1.15)
                    Text(mode == .join ? "Joining lobby..." : "Creating lobby...")
                        .font(.system(size: ScreenScale.font(14), weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, ScreenScale.width(26))
                .padding(.vertical, ScreenScale.height(22))
                .background(theme.surface.opacity(0.84))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(theme.border.opacity(0.65), lineWidth: 1)
                )
                .neonGlow(color: theme.accent)
                .transition(.opacity)
            }

            Spacer()
        }
        .animation(.smoothSpring, value: viewModel.loading)
        .animation(.smoothSpring, value: viewModel.error)
        .allowsHitTesting(viewModel.loading || viewModel.error != nil)
    }

    private func formShell<Content: View>(
        eyebrow: String,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ScreenScale.height(18)) {
                HStack {
                    Button {
                        withAnimation(.smoothSpring) {
                            mode = .menu
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.system(size: ScreenScale.font(14), weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                            .padding(.horizontal, ScreenScale.width(16))
                            .padding(.vertical, ScreenScale.height(12))
                            .background(theme.surface.opacity(0.72))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(theme.border.opacity(0.6), lineWidth: 1)
                            )
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: ScreenScale.height(10)) {
                    Text(eyebrow.uppercased())
                        .font(.system(size: ScreenScale.font(11), weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentSecondary)
                        .tracking(2.8)

                    Text(title)
                        .font(.system(size: ScreenScale.font(33), weight: .black, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.system(size: ScreenScale.font(15), weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ScreenScale.width(4))

                VStack(spacing: ScreenScale.height(18)) {
                    content()
                }
                .padding(.horizontal, ScreenScale.width(18))
                .padding(.vertical, ScreenScale.height(22))
                .frame(maxWidth: .infinity)
                .background(theme.surface.opacity(0.76))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(theme.border.opacity(0.65), lineWidth: 1)
                )
                .premiumShadow()

                footerPill
                    .padding(.top, ScreenScale.height(4))
            }
            .padding(.top, ScreenScale.height(6))
            .frame(maxWidth: .infinity)
        }
    }

    private func technoField(
        title: String,
        prompt: String,
        text: Binding<String>,
        icon: String,
        isCodeField: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: ScreenScale.height(10)) {
            Text(title.uppercased())
                .font(.system(size: ScreenScale.font(11), weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary.opacity(0.88))
                .tracking(2.2)

            HStack(spacing: ScreenScale.width(12)) {
                Image(systemName: icon)
                    .font(.system(size: ScreenScale.font(16), weight: .bold))
                    .foregroundColor(isCodeField ? theme.accentSecondary : theme.accent)
                    .frame(width: ScreenScale.width(20))

                TextField(prompt, text: text)
                    .font(
                        .system(
                            size: ScreenScale.font(18),
                            weight: .semibold,
                            design: isCodeField ? .monospaced : .rounded
                        )
                    )
                    .foregroundColor(theme.textPrimary)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(isCodeField ? .characters : .words)
            }
            .padding(.horizontal, ScreenScale.width(16))
            .frame(height: ScreenScale.height(58))
            .background(theme.surfaceElevated.opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke((isCodeField ? theme.accentSecondary : theme.border).opacity(0.6), lineWidth: 1)
            )
            .if(isCodeField) { view in
                view.neonGlow(color: theme.accentSecondary)
            }
        }
    }

    private func primaryButton(title: String, icon: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: ScreenScale.width(10)) {
                Text(title.uppercased())
                    .font(.system(size: ScreenScale.font(15), weight: .black, design: .rounded))
                    .tracking(1.3)
                Image(systemName: icon)
                    .font(.system(size: ScreenScale.font(15), weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: ScreenScale.height(56))
            .background(
                LinearGradient(
                    colors: disabled
                        ? [theme.surfaceElevated, theme.surfaceElevated]
                        : [theme.accent, theme.accentSecondary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(disabled ? theme.textSecondary : theme.textOnAccent)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(disabled ? theme.border.opacity(0.6) : Color.white.opacity(0.18), lineWidth: 1)
            )
        }
        .disabled(disabled)
        .buttonStyle(ScaleButtonStyle())
        .if(!disabled) { view in
            view.neonGlow(color: theme.accent)
        }
    }

    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        accent: Color,
        isPressed: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: ScreenScale.width(16)) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.14))
                        .scaledFrame(width: 54, height: 54)
                    Image(systemName: icon)
                        .font(.system(size: ScreenScale.font(18), weight: .bold))
                        .foregroundColor(accent)
                        .neonGlow(color: accent)
                }

                VStack(alignment: .leading, spacing: ScreenScale.height(5)) {
                    Text(title.uppercased())
                        .font(.system(size: ScreenScale.font(16), weight: .black, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .tracking(1.1)
                    Text(subtitle)
                        .font(.system(size: ScreenScale.font(13), weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: ScreenScale.font(16), weight: .bold))
                    .foregroundColor(accent)
            }
            .padding(.horizontal, ScreenScale.width(18))
            .padding(.vertical, ScreenScale.height(18))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.surface.opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(accent.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: accent.opacity(0.12), radius: 16, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.easeOut(duration: 0.14), value: isPressed)
    }

    private func capsuleTag(_ title: String, color: Color) -> some View {
        HStack(spacing: ScreenScale.width(8)) {
            Circle()
                .fill(color)
                .scaledFrame(width: 8, height: 8)
                .neonGlow(color: color)
            Text(title)
                .font(.system(size: ScreenScale.font(11), weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, ScreenScale.width(12))
        .padding(.vertical, ScreenScale.height(8))
        .background(theme.surface.opacity(0.68))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(theme.border.opacity(0.4), lineWidth: 1)
        )
    }
}

private struct HomeAmbientBackground: View {
    @Environment(\.theme) private var theme
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    theme.background,
                    theme.surfaceElevated.opacity(0.95),
                    theme.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                Circle()
                    .fill(orbGradient(primary: theme.accent, secondary: theme.accentSecondary))
                    .frame(width: width * 0.72, height: width * 0.72)
                    .blur(radius: 18)
                    .offset(x: animate ? width * 0.28 : -width * 0.18, y: animate ? -height * 0.16 : -height * 0.28)

                Circle()
                    .fill(orbGradient(primary: theme.accentSecondary, secondary: theme.success))
                    .frame(width: width * 0.84, height: width * 0.84)
                    .blur(radius: 30)
                    .offset(x: animate ? -width * 0.2 : width * 0.18, y: animate ? height * 0.32 : height * 0.12)

                Circle()
                    .fill(orbGradient(primary: theme.success, secondary: theme.accent))
                    .frame(width: width * 0.46, height: width * 0.46)
                    .blur(radius: 12)
                    .offset(x: animate ? width * 0.16 : -width * 0.08, y: animate ? height * 0.05 : height * 0.18)
            }
            .ignoresSafeArea()

            Rectangle()
                .fill(.black.opacity(0.08))
                .blendMode(.overlay)
                .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }

    private func orbGradient(primary: Color, secondary: Color) -> RadialGradient {
        RadialGradient(
            colors: [primary.opacity(0.42), secondary.opacity(0.18), .clear],
            center: .center,
            startRadius: 24,
            endRadius: 180
        )
    }
}
