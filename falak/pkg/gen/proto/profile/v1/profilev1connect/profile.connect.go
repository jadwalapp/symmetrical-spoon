// Code generated by protoc-gen-connect-go. DO NOT EDIT.
//
// Source: profile/v1/profile.proto

package profilev1connect

import (
	connect "connectrpc.com/connect"
	context "context"
	errors "errors"
	v1 "github.com/jadwalapp/symmetrical-spoon/falak/pkg/gen/proto/profile/v1"
	http "net/http"
	strings "strings"
)

// This is a compile-time assertion to ensure that this generated file and the connect package are
// compatible. If you get a compiler error that this constant is not defined, this code was
// generated with a version of connect newer than the one compiled into your binary. You can fix the
// problem by either regenerating this code with an older version of connect or updating the connect
// version compiled into your binary.
const _ = connect.IsAtLeastVersion1_13_0

const (
	// ProfileServiceName is the fully-qualified name of the ProfileService service.
	ProfileServiceName = "profile.v1.ProfileService"
)

// These constants are the fully-qualified names of the RPCs defined in this package. They're
// exposed at runtime as Spec.Procedure and as the final two segments of the HTTP route.
//
// Note that these are different from the fully-qualified method names used by
// google.golang.org/protobuf/reflect/protoreflect. To convert from these constants to
// reflection-formatted method names, remove the leading slash and convert the remaining slash to a
// period.
const (
	// ProfileServiceGetProfileProcedure is the fully-qualified name of the ProfileService's GetProfile
	// RPC.
	ProfileServiceGetProfileProcedure = "/profile.v1.ProfileService/GetProfile"
	// ProfileServiceAddDeviceProcedure is the fully-qualified name of the ProfileService's AddDevice
	// RPC.
	ProfileServiceAddDeviceProcedure = "/profile.v1.ProfileService/AddDevice"
)

// These variables are the protoreflect.Descriptor objects for the RPCs defined in this package.
var (
	profileServiceServiceDescriptor          = v1.File_profile_v1_profile_proto.Services().ByName("ProfileService")
	profileServiceGetProfileMethodDescriptor = profileServiceServiceDescriptor.Methods().ByName("GetProfile")
	profileServiceAddDeviceMethodDescriptor  = profileServiceServiceDescriptor.Methods().ByName("AddDevice")
)

// ProfileServiceClient is a client for the profile.v1.ProfileService service.
type ProfileServiceClient interface {
	GetProfile(context.Context, *connect.Request[v1.GetProfileRequest]) (*connect.Response[v1.GetProfileResponse], error)
	AddDevice(context.Context, *connect.Request[v1.AddDeviceRequest]) (*connect.Response[v1.AddDeviceResponse], error)
}

// NewProfileServiceClient constructs a client for the profile.v1.ProfileService service. By
// default, it uses the Connect protocol with the binary Protobuf Codec, asks for gzipped responses,
// and sends uncompressed requests. To use the gRPC or gRPC-Web protocols, supply the
// connect.WithGRPC() or connect.WithGRPCWeb() options.
//
// The URL supplied here should be the base URL for the Connect or gRPC server (for example,
// http://api.acme.com or https://acme.com/grpc).
func NewProfileServiceClient(httpClient connect.HTTPClient, baseURL string, opts ...connect.ClientOption) ProfileServiceClient {
	baseURL = strings.TrimRight(baseURL, "/")
	return &profileServiceClient{
		getProfile: connect.NewClient[v1.GetProfileRequest, v1.GetProfileResponse](
			httpClient,
			baseURL+ProfileServiceGetProfileProcedure,
			connect.WithSchema(profileServiceGetProfileMethodDescriptor),
			connect.WithClientOptions(opts...),
		),
		addDevice: connect.NewClient[v1.AddDeviceRequest, v1.AddDeviceResponse](
			httpClient,
			baseURL+ProfileServiceAddDeviceProcedure,
			connect.WithSchema(profileServiceAddDeviceMethodDescriptor),
			connect.WithClientOptions(opts...),
		),
	}
}

// profileServiceClient implements ProfileServiceClient.
type profileServiceClient struct {
	getProfile *connect.Client[v1.GetProfileRequest, v1.GetProfileResponse]
	addDevice  *connect.Client[v1.AddDeviceRequest, v1.AddDeviceResponse]
}

// GetProfile calls profile.v1.ProfileService.GetProfile.
func (c *profileServiceClient) GetProfile(ctx context.Context, req *connect.Request[v1.GetProfileRequest]) (*connect.Response[v1.GetProfileResponse], error) {
	return c.getProfile.CallUnary(ctx, req)
}

// AddDevice calls profile.v1.ProfileService.AddDevice.
func (c *profileServiceClient) AddDevice(ctx context.Context, req *connect.Request[v1.AddDeviceRequest]) (*connect.Response[v1.AddDeviceResponse], error) {
	return c.addDevice.CallUnary(ctx, req)
}

// ProfileServiceHandler is an implementation of the profile.v1.ProfileService service.
type ProfileServiceHandler interface {
	GetProfile(context.Context, *connect.Request[v1.GetProfileRequest]) (*connect.Response[v1.GetProfileResponse], error)
	AddDevice(context.Context, *connect.Request[v1.AddDeviceRequest]) (*connect.Response[v1.AddDeviceResponse], error)
}

// NewProfileServiceHandler builds an HTTP handler from the service implementation. It returns the
// path on which to mount the handler and the handler itself.
//
// By default, handlers support the Connect, gRPC, and gRPC-Web protocols with the binary Protobuf
// and JSON codecs. They also support gzip compression.
func NewProfileServiceHandler(svc ProfileServiceHandler, opts ...connect.HandlerOption) (string, http.Handler) {
	profileServiceGetProfileHandler := connect.NewUnaryHandler(
		ProfileServiceGetProfileProcedure,
		svc.GetProfile,
		connect.WithSchema(profileServiceGetProfileMethodDescriptor),
		connect.WithHandlerOptions(opts...),
	)
	profileServiceAddDeviceHandler := connect.NewUnaryHandler(
		ProfileServiceAddDeviceProcedure,
		svc.AddDevice,
		connect.WithSchema(profileServiceAddDeviceMethodDescriptor),
		connect.WithHandlerOptions(opts...),
	)
	return "/profile.v1.ProfileService/", http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case ProfileServiceGetProfileProcedure:
			profileServiceGetProfileHandler.ServeHTTP(w, r)
		case ProfileServiceAddDeviceProcedure:
			profileServiceAddDeviceHandler.ServeHTTP(w, r)
		default:
			http.NotFound(w, r)
		}
	})
}

// UnimplementedProfileServiceHandler returns CodeUnimplemented from all methods.
type UnimplementedProfileServiceHandler struct{}

func (UnimplementedProfileServiceHandler) GetProfile(context.Context, *connect.Request[v1.GetProfileRequest]) (*connect.Response[v1.GetProfileResponse], error) {
	return nil, connect.NewError(connect.CodeUnimplemented, errors.New("profile.v1.ProfileService.GetProfile is not implemented"))
}

func (UnimplementedProfileServiceHandler) AddDevice(context.Context, *connect.Request[v1.AddDeviceRequest]) (*connect.Response[v1.AddDeviceResponse], error) {
	return nil, connect.NewError(connect.CodeUnimplemented, errors.New("profile.v1.ProfileService.AddDevice is not implemented"))
}
