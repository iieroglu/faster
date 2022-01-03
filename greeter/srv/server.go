package server

import (
	"golang.org/x/net/context"
	pb "github.com/iieroglu/faster/greeter/proto/v1"
)

// server is used to implement helloworld.GreeterServer.
type Server struct{}

// SayHello implements helloworld.GreeterServer
func (s *Server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	return &pb.HelloReply{Message: "Helloo " + in.Name}, nil
}

// SayHelloAgain implements helloworld.GreeterServer
func (s *Server) SayHelloAgain(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	return &pb.HelloReply{Message: "Helloo " + in.Name}, nil
}

