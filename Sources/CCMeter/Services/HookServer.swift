import Foundation
import Network

/// Lightweight HTTP server that listens for Claude Code hook events.
/// When a request arrives, it notifies the aggregator to fetch usage.
final class HookServer {
    private var listener: NWListener?
    private let onEvent: () -> Void

    init(onEvent: @escaping () -> Void) {
        self.onEvent = onEvent
    }

    func start() {
        do {
            let params = NWParameters.tcp
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: Constants.hookServerPort)!)
        } catch {
            print("HookServer: failed to create listener: \(error)")
            return
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }

        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("HookServer: listening on port \(Constants.hookServerPort)")
            case .failed(let error):
                print("HookServer: failed: \(error)")
            default:
                break
            }
        }

        listener?.start(queue: .global(qos: .utility))
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .utility))

        // Read the incoming request (we don't need to parse it)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] _, _, _, _ in
            // Send 200 OK response
            let response = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            let responseData = response.data(using: .utf8)!
            connection.send(content: responseData, completion: .contentProcessed { _ in
                connection.cancel()
            })

            // Notify aggregator
            self?.onEvent()
        }
    }
}
