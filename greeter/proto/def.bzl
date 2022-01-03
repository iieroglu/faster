load("@io_bazel_rules_go//proto:def.bzl", "go_proto_library")
load("@rules_proto//proto:defs.bzl", "ProtoInfo", "proto_library")
load("@bazel_skylib//lib:shell.bzl", "shell")

"""

Lints Proto files with Buf and defines rules for creating Proto descriptor files.
"""

BUF_ARRAY = select({
    "@bazel_tools//src/conditions:darwin": ["@buf_darwin//file"],
    "//conditions:default": ["@buf_linux//file"],
})

BUF = select({
    "@bazel_tools//src/conditions:darwin": "@buf_darwin//file",
    "//conditions:default": "@buf_linux//file",
})

CombinedDescriptorInfo = provider(
    "Set of Proto descriptors derived from input ProtoInfo.transitive_descriptor_sets and " +
    "CombinedDescriptorInfo.descriptors",
    fields = {
        "descriptors": "Depset of FileDescriptorSet files of all transitively dependent proto_library rules",
        "descriptor_providers": "Depset of direct proto_library and combined descriptor dependency targets",
    },
)

def paths(files):
    return [f.path for f in files]

def _combined_proto_descriptor_impl(ctx):
    if not (ctx.attr.proto_library or ctx.attr.descriptor_providers):
        fail("The proto_library and descriptor_providers attributes cannot both be empty.")

    descriptor_sets = [
#        ctx.attr._required_proto_library[ProtoInfo].transitive_descriptor_sets,
    ]
    if ctx.attr.proto_library:
        descriptor_sets.append(ctx.attr.proto_library[ProtoInfo].transitive_descriptor_sets)

    for provider in ctx.attr.descriptor_providers:
        if ProtoInfo in provider:
            descriptor_sets.append(provider[ProtoInfo].transitive_descriptor_sets)
        if CombinedDescriptorInfo in provider:
            descriptor_sets.append(provider[CombinedDescriptorInfo].descriptors)

    descriptors = depset(
        transitive = descriptor_sets,
    )

    descriptor_providers = depset(
#        [ctx.attr._required_proto_library] +
        ([ctx.attr.proto_library] if ctx.attr.proto_library else []) +
        ctx.attr.descriptor_providers,
    )

    descriptor_name = ctx.attr.descriptor_name
    if not descriptor_name:
        # The file is based on 'ctx.label.name' to avoid conflicts.
        descriptor_name = ctx.label.package.replace("/", "_") + "_" + ctx.label.name + "_combined.pb"
    combined_file = ctx.actions.declare_file(descriptor_name)
    ctx.actions.run_shell(
        inputs = descriptors,
        outputs = [combined_file],
        command = "cat %s > %s" % (
            " ".join(paths(descriptors.to_list())),
            combined_file.path,
        ),
    )

    return [
        DefaultInfo(
            files = depset([combined_file]),
        ),
        CombinedDescriptorInfo(
            descriptors = descriptors,
            descriptor_providers = descriptor_providers,
        ),
    ]

combined_proto_descriptor = rule(
    implementation = _combined_proto_descriptor_impl,
    attrs = {
        "descriptor_name": attr.string(
            mandatory = False,
        ),
        "proto_library": attr.label(
            mandatory = False,
            providers = [ProtoInfo],
        ),
        "descriptor_providers": attr.label_list(
            allow_empty = True,
            providers = [[CombinedDescriptorInfo], [ProtoInfo]],
        ),
    },
)

def fast_proto_library(name, srcs, deps = [], visibility = None, skip_linter = False, descriptor_name = None, descriptor_visibility = []):
    """Bazel fast_proto_library rule.

    Builds proto with validators, and runs them thru linter

    Args:
      **attrs: Rule attributes
    """
    deps = depset(deps + [
#        "@com_github_grpc_ecosystem_grpc_gateway_v2//protoc-gen-openapiv2/options:options_proto",
#        "@com_github_mwitkow_go_proto_validators//:validator_proto",
        "@go_googleapis//google/api:annotations_proto",
    ])

    proto_library(
        name = name,
        srcs = srcs,
        deps = deps,
        visibility = visibility,
    )

    if descriptor_name == None:
        descriptor_name = name + "_pb"

    has_external_descriptor_visibility = False
    for v in descriptor_visibility:
        if v != Label("//visibility:private"):
            has_external_descriptor_visibility = True

    if not skip_linter or has_external_descriptor_visibility:
        combined_proto_descriptor(
            name = descriptor_name,
            proto_library = name,
            visibility = descriptor_visibility,
        )

