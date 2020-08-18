# benchmark file to compare two commits of NLPModelsIpopt

using Pkg
bmark_dir = @__DIR__
Pkg.activate(bmark_dir)
Pkg.instantiate()
using Git
if isdir(joinpath(bmark_dir, "..", ".git"))
  Pkg.develop(PackageSpec(url=joinpath(bmark_dir, "..")))
  bmarkname = Git.head()  # sha of HEAD
else
  Pkg.add("NLPModelsIpopt")
  bmarkname = "nlpmodelsipopt"
end

# set environment variables to point to local install of IPOPT if necessary
# ENV["JULIA_IPOPT_EXECUTABLE_PATH"] = "/home/dorban/local/bin"
# ENV["JULIA_IPOPT_LIBRARY_PATH"] = "/home/dorban/local/lib"

using BenchmarkTools
using CUTEst

using NLPModelsIpopt

set_mastsif()  # path to CUTEst collection is in ENV["MASTSIF"]

const SUITE = BenchmarkGroup()

all_sif_problems = CUTEst.select()
for prob ∈ all_sif_problems
  SUITE[prob] = @benchmarkable ipopt(model) setup=(model = CUTEstModel($prob)) teardown=(finalize(model))
end

