
github_repo(
    name = "cereal",
    repo = "USCiLab/cereal",
    bazel_compat = False,
    revision = "v1.3.2",
)

cc_binary(
    name = "ahi_bs_encoder",
    srcs = glob(["*.cpp"]),
    hdrs = glob(["*.hpp"]),
    includes = ["cereal/include"],
    deps = ["//:cereal"],
    compiler_flags = ["--std=c++11"],
)
