import SwiftUI

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.current.appBackgroundStart,
                    AppTheme.current.appBackgroundEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .scaleEffect(animate ? 1.0 : 0.82)
                .opacity(animate ? 1.0 : 0.35)
                .shadow(color: AppTheme.current.brandPrimary.opacity(0.35), radius: 16)
                .animation(.easeOut(duration: 0.9), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}

