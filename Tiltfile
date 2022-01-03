if k8s_context() not in ['minikube', 'kind-kind', 'k3d-k3d', 'docker-desktop']:
  fail("Tiltfile can be run on local k8s cluster only. Got: %s" % k8s_context())

k8s_yaml("./local-k8s/core-dns.yaml")

k8s_yaml("./k8s/namespace.yaml")

def bazel_k8s(target):
  return local("bazel run %s" % target)

def bazel_build(image, target, tag):
  custom_build(
    image,
    'bazel run %s -- --norun' % target,
    [],
    tag=tag,
    skips_local_docker=True,
  )

bazel_build('bazel/greeter', '//greeter:greeter_service_image', 'greeter_service_image')

k8s_yaml(bazel_k8s("//greeter:greeter-server"))
k8s_resource('greeter', port_forwards=5000)

