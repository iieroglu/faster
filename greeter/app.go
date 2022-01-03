package main

import (
	"fmt"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"log"
	"net"
	pb "github.com/iieroglu/faster/greeter/proto/v1"
	"github.com/iieroglu/faster/greeter/srv"
)

var (
	s *grpc.Server
)

const (
	port = ":5000"
)

func main() {
	fmt.Println("Hello, world.")

	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s = grpc.NewServer()
	pb.RegisterGreeterServer(s, &server.Server{})
	// Register reflection service on gRPC server.
	reflection.Register(s)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}


