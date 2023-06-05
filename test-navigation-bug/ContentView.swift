//
//  ContentView.swift
//  test-navigation-bug
//
//  Created by David Arvelo on 6/5/23.
//

import SwiftUI
import SwiftUINavigation

struct ContentView: View {
    @StateObject var viewModel: ViewModel = ViewModel()
    @State var presentSheet: Bool = false

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            presentSheet = true
            viewModel.onAppear()
        }
        .handleAlertEvent(viewModel: viewModel)
        .sheet(isPresented: $presentSheet) {
            Text("Modal Sheet")
                .handleAlertEvent(viewModel: viewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


@MainActor
class ViewModel: ObservableObject {

    @Published var state: State

    struct State {
        var alert: Alerts? = nil
    }

    init() {
        state = State()
    }

    func onAppear() {
        Task(priority: .background) {
            try? await Task.sleep(for: .seconds(1))
            await showAlert()
        }
    }

    func showAlert() async {
        state.alert = .okAlert(
            AlertState(
                title: {
                    TextState("Title")
                },
                actions: {
                    ButtonState(action: .send(.ok)) {
                        TextState("OK")
                    }
                },
                message: {
                    TextState("Message")
                }
            )
        )
    }

    func onAlertOkTapped() {
        state.alert = nil
    }
}


private struct HandleAlertModifier: ViewModifier {
    @ObservedObject var viewModel: ViewModel
    func body(content: Content) -> some View {
        content
            .alert(unwrapping: $viewModel.state.alert, case: /Alerts.okAlert) { action in
                switch action {
                case nil, .ok:
                    viewModel.onAlertOkTapped()
                }
            }
    }
}

private extension View {
    func handleAlertEvent(viewModel: ViewModel) -> some View {
        modifier(HandleAlertModifier(viewModel: viewModel))
    }
}


enum Alerts {
    case okAlert(AlertState<Actions.Ok>)
}

struct Actions {
    enum Ok {
        case ok
    }
}
