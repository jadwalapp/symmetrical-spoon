// Code generated by protoc-gen-connect-swift. DO NOT EDIT.
//
// Source: whatsapp/v1/whatsapp.proto
//

import Connect
import Foundation
import SwiftProtobuf

public protocol Whatsapp_V1_ProfileServiceClientInterface: Sendable {

    @discardableResult
    func `initiateConnectWhatsappAccount`(request: Whatsapp_V1_InitiateConnectWhatsappAccountRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<Whatsapp_V1_InitiateConnectWhatsappAccountResponse>) -> Void) -> Connect.Cancelable

    @available(iOS 13, *)
    func `initiateConnectWhatsappAccount`(request: Whatsapp_V1_InitiateConnectWhatsappAccountRequest, headers: Connect.Headers) async -> ResponseMessage<Whatsapp_V1_InitiateConnectWhatsappAccountResponse>

    @discardableResult
    func `completeConnectWhatsappAccount`(request: Whatsapp_V1_CompleteConnectWhatsappAccountRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<Whatsapp_V1_CompleteConnectWhatsappAccountResponse>) -> Void) -> Connect.Cancelable

    @available(iOS 13, *)
    func `completeConnectWhatsappAccount`(request: Whatsapp_V1_CompleteConnectWhatsappAccountRequest, headers: Connect.Headers) async -> ResponseMessage<Whatsapp_V1_CompleteConnectWhatsappAccountResponse>

    /// possible errors:
    ///   - not found
    @discardableResult
    func `removeWhatsappAccountConnection`(request: Whatsapp_V1_RemoveWhatsappAccountConnectionRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<Whatsapp_V1_RemoveWhatsappAccountConnectionResponse>) -> Void) -> Connect.Cancelable

    /// possible errors:
    ///   - not found
    @available(iOS 13, *)
    func `removeWhatsappAccountConnection`(request: Whatsapp_V1_RemoveWhatsappAccountConnectionRequest, headers: Connect.Headers) async -> ResponseMessage<Whatsapp_V1_RemoveWhatsappAccountConnectionResponse>

    /// possible errors:
    ///   - not found
    @discardableResult
    func `getWhatsappAccount`(request: Whatsapp_V1_GetWhatsappAccountRequest, headers: Connect.Headers, completion: @escaping @Sendable (ResponseMessage<Whatsapp_V1_GetWhatsappAccountResponse>) -> Void) -> Connect.Cancelable

    /// possible errors:
    ///   - not found
    @available(iOS 13, *)
    func `getWhatsappAccount`(request: Whatsapp_V1_GetWhatsappAccountRequest, headers: Connect.Headers) async -> ResponseMessage<Whatsapp_V1_GetWhatsappAccountResponse>
}

/// Concrete implementation of `Whatsapp_V1_ProfileServiceClientInterface`.
public final class Whatsapp_V1_ProfileServiceClient: Whatsapp_V1_ProfileServiceClientInterface, Sendable {
    private let client: Connect.ProtocolClientInterface

    public init(client: Connect.ProtocolClientInterface) {
        self.client = client
    }

    @discardableResult
    public func `initiateConnectWhatsappAccount`(request: Whatsapp_V1_InitiateConnectWhatsappAccountRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<Whatsapp_V1_InitiateConnectWhatsappAccountResponse>) -> Void) -> Connect.Cancelable {
        return self.client.unary(path: "/whatsapp.v1.ProfileService/InitiateConnectWhatsappAccount", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
    }

    @available(iOS 13, *)
    public func `initiateConnectWhatsappAccount`(request: Whatsapp_V1_InitiateConnectWhatsappAccountRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<Whatsapp_V1_InitiateConnectWhatsappAccountResponse> {
        return await self.client.unary(path: "/whatsapp.v1.ProfileService/InitiateConnectWhatsappAccount", idempotencyLevel: .unknown, request: request, headers: headers)
    }

    @discardableResult
    public func `completeConnectWhatsappAccount`(request: Whatsapp_V1_CompleteConnectWhatsappAccountRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<Whatsapp_V1_CompleteConnectWhatsappAccountResponse>) -> Void) -> Connect.Cancelable {
        return self.client.unary(path: "/whatsapp.v1.ProfileService/CompleteConnectWhatsappAccount", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
    }

    @available(iOS 13, *)
    public func `completeConnectWhatsappAccount`(request: Whatsapp_V1_CompleteConnectWhatsappAccountRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<Whatsapp_V1_CompleteConnectWhatsappAccountResponse> {
        return await self.client.unary(path: "/whatsapp.v1.ProfileService/CompleteConnectWhatsappAccount", idempotencyLevel: .unknown, request: request, headers: headers)
    }

    @discardableResult
    public func `removeWhatsappAccountConnection`(request: Whatsapp_V1_RemoveWhatsappAccountConnectionRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<Whatsapp_V1_RemoveWhatsappAccountConnectionResponse>) -> Void) -> Connect.Cancelable {
        return self.client.unary(path: "/whatsapp.v1.ProfileService/RemoveWhatsappAccountConnection", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
    }

    @available(iOS 13, *)
    public func `removeWhatsappAccountConnection`(request: Whatsapp_V1_RemoveWhatsappAccountConnectionRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<Whatsapp_V1_RemoveWhatsappAccountConnectionResponse> {
        return await self.client.unary(path: "/whatsapp.v1.ProfileService/RemoveWhatsappAccountConnection", idempotencyLevel: .unknown, request: request, headers: headers)
    }

    @discardableResult
    public func `getWhatsappAccount`(request: Whatsapp_V1_GetWhatsappAccountRequest, headers: Connect.Headers = [:], completion: @escaping @Sendable (ResponseMessage<Whatsapp_V1_GetWhatsappAccountResponse>) -> Void) -> Connect.Cancelable {
        return self.client.unary(path: "/whatsapp.v1.ProfileService/GetWhatsappAccount", idempotencyLevel: .unknown, request: request, headers: headers, completion: completion)
    }

    @available(iOS 13, *)
    public func `getWhatsappAccount`(request: Whatsapp_V1_GetWhatsappAccountRequest, headers: Connect.Headers = [:]) async -> ResponseMessage<Whatsapp_V1_GetWhatsappAccountResponse> {
        return await self.client.unary(path: "/whatsapp.v1.ProfileService/GetWhatsappAccount", idempotencyLevel: .unknown, request: request, headers: headers)
    }

    public enum Metadata {
        public enum Methods {
            public static let initiateConnectWhatsappAccount = Connect.MethodSpec(name: "InitiateConnectWhatsappAccount", service: "whatsapp.v1.ProfileService", type: .unary)
            public static let completeConnectWhatsappAccount = Connect.MethodSpec(name: "CompleteConnectWhatsappAccount", service: "whatsapp.v1.ProfileService", type: .unary)
            public static let removeWhatsappAccountConnection = Connect.MethodSpec(name: "RemoveWhatsappAccountConnection", service: "whatsapp.v1.ProfileService", type: .unary)
            public static let getWhatsappAccount = Connect.MethodSpec(name: "GetWhatsappAccount", service: "whatsapp.v1.ProfileService", type: .unary)
        }
    }
}