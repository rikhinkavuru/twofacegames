import SwiftUI

struct HomeScreen: View {
    @ObservedObject var viewModel: GameViewModel

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
            // Modern White Background
            Color.white
                .ignoresSafeArea()
            
            // Content View
            if mode == .menu {
                menuContentView
                    .transition(AnyTransition.asymmetric(
                        insertion: AnyTransition.opacity.combined(with: .move(edge: .bottom)),
                        removal: AnyTransition.opacity.combined(with: .move(edge: .top))
                    ))
            } else if mode == .create {
                createContentView
                    .transition(AnyTransition.asymmetric(
                        insertion: AnyTransition.opacity.combined(with: .move(edge: .trailing)),
                        removal: AnyTransition.opacity.combined(with: .move(edge: .leading))
                    ))
            } else if mode == .join {
                joinContentView
                    .transition(AnyTransition.asymmetric(
                        insertion: AnyTransition.opacity.combined(with: .move(edge: .trailing)),
                        removal: AnyTransition.opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
        .onAppear {
            withAnimation {
                animate = true
            }
        }
    }

    // MARK: - Menu Content View
    private var menuContentView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // MARK: - Top Spacer
                Spacer()
                    .frame(height: ScreenScale.height(80))
                
                // MARK: - Logo Section
                VStack(spacing: ScreenScale.height(32)) {
                    // "twoface" Wordmark
                    HStack(spacing: 0) {
                        Text("two")
                            .font(.system(size: ScreenScale.font(80), weight: .semibold, design: .default))
                            .foregroundColor(.appDeepBlack)
                            .tracking(-3)
                        
                        Text("face")
                            .font(.system(size: ScreenScale.font(80), weight: .semibold, design: .default))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.appAccentRed,
                                        Color(red: 0.5, green: 0.0, blue: 0.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .tracking(-3)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : -20)
                    .animation(Animation.easeOut(duration: 0.7), value: animate)
                    
                    // Studio Branding
                    HStack(spacing: ScreenScale.width(12)) {
                        Rectangle()
                            .fill(Color.appMutedGray.opacity(0.2))
                            .frame(height: 1)
                        
                        Text("HERD STUDIOS")
                            .font(.system(size: ScreenScale.font(12), weight: .semibold, design: .default))
                            .foregroundColor(.appMutedGray.opacity(0.6))
                            .tracking(4)
                            .fixedSize()
                        
                        Rectangle()
                            .fill(Color.appMutedGray.opacity(0.2))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, ScreenScale.width(16))
                    .frame(maxWidth: .infinity)
                    .opacity(animate ? 1 : 0)
                    .animation(Animation.easeOut(duration: 0.7).delay(0.1), value: animate)
                    
                    // Tagline
                    Text("Trust no one. Not even yourself.")
                        .font(.system(size: ScreenScale.font(15), weight: .light, design: .default))
                        .foregroundColor(.appMutedGray)
                        .tracking(0.3)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .opacity(animate ? 1 : 0)
                        .animation(Animation.easeOut(duration: 0.7).delay(0.15), value: animate)
                }
                .padding(.horizontal, ScreenScale.width(32))
                
                // MARK: - Middle Spacer
                Spacer()
                    .frame(height: ScreenScale.height(90))
                
                    // MARK: - Central Mask Icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: ScreenScale.width(140), height: ScreenScale.width(140))
                        .shadow(color: Color.black.opacity(0.25), radius: 35, x: 8, y: 20)
                    
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.appDeepBlack)
                        
                        Rectangle()
                            .fill(Color.white)
                    }
                    .frame(width: ScreenScale.width(140), height: ScreenScale.width(140))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 30, x: 6, y: 18)
                    
                    HStack(spacing: ScreenScale.width(32)) {
                        // Left Eye (Angled - outside edges upward)
                        Capsule()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: ScreenScale.width(28), height: ScreenScale.width(14))
                            .rotationEffect(.degrees(15))
                        
                        // Right Eye (Angled - outside edges upward)
                        Capsule()
                            .fill(Color.appDeepBlack.opacity(0.5))
                            .frame(width: ScreenScale.width(28), height: ScreenScale.width(14))
                            .rotationEffect(.degrees(-15))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(animate ? 1 : 0)
                .offset(y: animate ? 0 : 20)
                .animation(Animation.easeOut(duration: 0.8).delay(0.2), value: animate)
                
                Spacer()
                    .frame(height: ScreenScale.height(90))
            }
            
            // MARK: - Menu Buttons
            VStack(spacing: ScreenScale.height(20)) {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        mode = .create
                    }
                }) {
                    HStack(spacing: ScreenScale.width(10)) {
                        Text("CREATE GAME")
                            .font(.system(size: ScreenScale.font(15), weight: .semibold, design: .default))
                            .tracking(1)
                        
                        Image(systemName: "plus")
                            .font(.system(size: ScreenScale.font(14), weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: ScreenScale.height(50))
                    .foregroundColor(.white)
                    .background(Color.appDeepBlack)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
                }
                .scaleEffect(createButtonPressed ? 0.97 : 1)
                .animation(Animation.easeOut(duration: 0.12), value: createButtonPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in createButtonPressed = true }
                        .onEnded { _ in createButtonPressed = false }
                )
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        mode = .join
                    }
                }) {
                    HStack(spacing: ScreenScale.width(10)) {
                        Text("JOIN WITH CODE")
                            .font(.system(size: ScreenScale.font(15), weight: .semibold, design: .default))
                            .tracking(1)
                        
                        Image(systemName: "link")
                            .font(.system(size: ScreenScale.font(13), weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: ScreenScale.height(50))
                    .foregroundColor(.appDeepBlack.opacity(0.7))
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.appMutedGray.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
                }
                .scaleEffect(joinButtonPressed ? 0.97 : 1)
                .animation(Animation.easeOut(duration: 0.12), value: joinButtonPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in joinButtonPressed = true }
                        .onEnded { _ in joinButtonPressed = false }
                )
            }
            .padding(.horizontal, ScreenScale.width(24))
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            .animation(Animation.easeOut(duration: 0.7).delay(0.4), value: animate)
            
            Spacer()
                .frame(height: ScreenScale.height(24))
            
            Text("v1.0 • herd studios")
                .font(.system(size: ScreenScale.font(11), weight: .regular, design: .default))
                .foregroundColor(.appMutedGray.opacity(0.5))
                .tracking(0.5)
            
            Spacer()
                .frame(height: ScreenScale.height(20))
        }
    }

    // MARK: - Create Content View
    private var createContentView: some View {
        ScrollView {
            VStack(spacing: ScreenScale.height(32)) {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            mode = .menu
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: ScreenScale.font(20), weight: .semibold))
                            .foregroundColor(.appDeepBlack)
                    }
                    Spacer()
                }
                .padding(.horizontal, ScreenScale.width(24))
                .padding(.top, ScreenScale.height(20))

                VStack(alignment: .leading, spacing: ScreenScale.height(12)) {
                    Text("CREATE GAME")
                        .font(.system(size: ScreenScale.font(32), weight: .bold))
                        .foregroundColor(.appDeepBlack)
                    
                    Text("Enter your name to start a new lobby.")
                        .font(.system(size: ScreenScale.font(16)))
                        .foregroundColor(.appMutedGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ScreenScale.width(24))

                VStack(alignment: .leading, spacing: ScreenScale.height(8)) {
                    Text("YOUR NAME")
                        .font(.system(size: ScreenScale.font(12), weight: .bold))
                        .foregroundColor(.appDeepBlack.opacity(0.5))
                        .tracking(1)
                    
                    TextField("e.g. Alex", text: $playerName)
                        .font(.system(size: ScreenScale.font(18), weight: .semibold))
                        .padding()
                        .frame(height: ScreenScale.height(56))
                        .background(Color.appCreamSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appMutedGray.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, ScreenScale.width(24))

                Spacer()
                    .frame(minHeight: 40)

                Button(action: {
                    if !playerName.isEmpty {
                        Task {
                            await viewModel.createGame(hostName: playerName)
                        }
                    }
                }) {
                    Text("CREATE LOBBY")
                        .font(.system(size: ScreenScale.font(16), weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ScreenScale.height(56))
                        .background(playerName.isEmpty ? Color.appMutedGray : Color.appDeepBlack)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(playerName.isEmpty)
                .padding(.horizontal, ScreenScale.width(24))
                .padding(.bottom, ScreenScale.height(40))
            }
        }
    }

    // MARK: - Join Content View
    private var joinContentView: some View {
        ScrollView {
            VStack(spacing: ScreenScale.height(32)) {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            mode = .menu
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: ScreenScale.font(20), weight: .semibold))
                            .foregroundColor(.appDeepBlack)
                    }
                    Spacer()
                }
                .padding(.horizontal, ScreenScale.width(24))
                .padding(.top, ScreenScale.height(20))

                VStack(alignment: .leading, spacing: ScreenScale.height(12)) {
                    Text("JOIN GAME")
                        .font(.system(size: ScreenScale.font(32), weight: .bold))
                        .foregroundColor(.appDeepBlack)
                    
                    Text("Enter your name and the game code.")
                        .font(.system(size: ScreenScale.font(16)))
                        .foregroundColor(.appMutedGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ScreenScale.width(24))

                VStack(spacing: ScreenScale.height(20)) {
                    VStack(alignment: .leading, spacing: ScreenScale.height(8)) {
                        Text("YOUR NAME")
                            .font(.system(size: ScreenScale.font(12), weight: .bold))
                            .foregroundColor(.appDeepBlack.opacity(0.5))
                            .tracking(1)
                        
                        TextField("e.g. Sam", text: $playerName)
                            .font(.system(size: ScreenScale.font(18), weight: .semibold))
                            .padding()
                            .frame(height: ScreenScale.height(56))
                            .background(Color.appCreamSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appMutedGray.opacity(0.2), lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: ScreenScale.height(8)) {
                        Text("GAME CODE")
                            .font(.system(size: ScreenScale.font(12), weight: .bold))
                            .foregroundColor(.appDeepBlack.opacity(0.5))
                            .tracking(1)
                        
                        TextField("ABCDE", text: $gameCode)
                            .font(.system(size: ScreenScale.font(18), weight: .bold, design: .monospaced))
                            .padding()
                            .frame(height: ScreenScale.height(56))
                            .background(Color.appCreamSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appMutedGray.opacity(0.2), lineWidth: 1)
                            )
                            .onChange(of: gameCode) { _, newValue in
                                gameCode = newValue.uppercased()
                            }
                    }
                }
                .padding(.horizontal, ScreenScale.width(24))

                Spacer()
                    .frame(minHeight: 40)

                Button(action: {
                    if !playerName.isEmpty && !gameCode.isEmpty {
                        Task {
                            await viewModel.joinGame(code: gameCode, playerName: playerName)
                        }
                    }
                }) {
                    Text("JOIN LOBBY")
                        .font(.system(size: ScreenScale.font(16), weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ScreenScale.height(56))
                        .background((playerName.isEmpty || gameCode.isEmpty) ? Color.appMutedGray : Color.appDeepBlack)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(playerName.isEmpty || gameCode.isEmpty)
                .padding(.horizontal, ScreenScale.width(24))
                .padding(.bottom, ScreenScale.height(40))
            }
        }
    }
}
