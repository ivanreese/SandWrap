import SwiftUI
import WebKit

let url = URL(string: ProcessInfo.processInfo.arguments.contains("--online") ? "https://rakebook.vercel.app" : "http://chonker.local:5173")!

@main
struct SandWrapApp: App {
  var body: some Scene {
    WindowGroup { AppView() }
    .windowResizability(.contentSize) // Allow resizing
#if os(macOS)
    .windowStyle(HiddenTitleBarWindowStyle()) // Remove title bar
    .commands { CommandGroup(replacing: .newItem) {} } // Remove default menu items
#endif
  }
}

struct AppView: View {
  @State private var error: Error?
  @State private var loading = true
  
  var body: some View {
    VStack {
      if let error = error {
        // In the event of an error, show the error message and a handy quit button (so you don't have to force-quit)
        Text(error.localizedDescription)
          .foregroundColor(.pink)
          .font(.headline)
        Button("Quit") { exit(EXIT_FAILURE) }
          .buttonStyle(.bordered)
          .foregroundColor(.primary)
      } else {
        // Load the WebView, and show a spinner while it's loading
        ZStack {
          Color.white // Background color
          PlatformWebView(error: $error, loading: $loading).opacity(loading ? 0 : 1)
        }
      }
    }
    .ignoresSafeArea() // Allow views to stretch right to the edges
    .persistentSystemOverlays(.hidden) // Hide the home indicator at the bottom
#if os(iOS)
    .statusBarHidden() // Hide the status bar at the top
    .defersSystemGestures(on:.all) // Block the first swipe from the top (todo: doesn't seem to block the bottom)
#else
    .frame(
      maxWidth: min(NSScreen.main?.visibleFrame.width ?? 1920, 1920),
      maxHeight: min(NSScreen.main?.visibleFrame.height ?? 1200, 1200)
    )
    .onAppear {
      NSApplication.shared.windows.first?.center() // Center the window
      DispatchQueue.main.async { // Hide the traffic lights
        if let window = NSApplication.shared.windows.first {
          window.standardWindowButton(.closeButton)?.isHidden = true
          window.standardWindowButton(.miniaturizeButton)?.isHidden = true
          window.standardWindowButton(.zoomButton)?.isHidden = true
        }
      }
    }
#endif
  }
}

#if os(macOS)
typealias ViewRepresentable = NSViewRepresentable
#else
typealias ViewRepresentable = UIViewRepresentable
#endif

struct PlatformWebView: ViewRepresentable {
  let webView = WKWebView()
  @Binding var error: Error?
  @Binding var loading: Bool
  
  func makeNSView(context: Context)-> WKWebView { return makeView(context:context) }
  func makeUIView(context: Context)-> WKWebView { return makeView(context:context) }
  
  func makeView(context: Context)->WKWebView {
    webView.isInspectable = true
    webView.navigationDelegate = context.coordinator
    webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
    return webView
  }
  
  func updateNSView(_ uiView: WKWebView, context: Context) {}
  func updateUIView(_ uiView: WKWebView, context: Context) {}
  func makeCoordinator() -> WebViewCoordinator { WebViewCoordinator(self) }

  class WebViewCoordinator: NSObject, WKNavigationDelegate {
    let parent: PlatformWebView
    init(_ webView: PlatformWebView) { self.parent = webView }
    func webView(_ wv: WKWebView, didFinish nav: WKNavigation) { parent.loading = false }
    func webView(_ wv: WKWebView, didFail nav: WKNavigation, withError error: Error) { parent.error = error }
    func webView(_ wv: WKWebView, didFailProvisionalNavigation nav: WKNavigation, withError error: Error) { parent.error = error }
    func webView(_ wv: WKWebView, respondTo challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) { (.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!)) }
  }
}
