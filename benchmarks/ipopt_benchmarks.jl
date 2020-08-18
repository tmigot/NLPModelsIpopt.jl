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

using LinearAlgebra
using Logging

using DataFrames
using JLD2

using CUTEst
using NLPModelsIpopt
using SolverBenchmark

probnames = ["ROSENBR", "WOODS", "PENALTY1"]
#= probnames = CUTEst.select()  # all CUTEst problems =#
#= probnames = filter(x -> endswith(x, ".SIF"), readdir(ENV["MASTSIF"])) =#
problems = (CUTEstModel(probname) for probname ∈ probnames)

solvers = Dict{Symbol,Function}(:ipopt => model -> ipopt(model, max_cpu_time=3600.0, linear_solver="ma57"))
stats = bmark_solvers(solvers, problems)

save_stats(stats, joinpath(bmark_dir, "$(bmarkname).jld2"), force=true)

statuses, avgs = quick_summary(stats)
for solver ∈ keys(stats)
  @info "statistics for" solver statuses[solver] avgs[solver]
end

cols = [:name, :nvar, :ncon, :objective, :dual_feas, :primal_feas, :elapsed_time, :iter,
        :neval_obj, :neval_grad, :neval_cons, :neval_jac, :neval_hess, :status]
col_formatters = Dict{Symbol, String}(:objective => "%10.3e",
                                      :elapsed_time => "%.2f")
hdr_override = Dict{Symbol, String}(:objective => "f",
                                    :dual_feas => "‖∇L‖₂",
                                    :primal_feas => "‖c‖₂",
                                    :elapsed_time => "t")
open(joinpath(bmark_dir, "$(bmarkname).md"), "w") do io
  pretty_stats(io, stats[:ipopt][!, cols], col_formatters=col_formatters, hdr_override=hdr_override)
end

open(joinpath(bmark_dir, "$(bmarkname)_main.tex"), "w") do io
  println(io, "\\documentclass[varwidth=20cm,crop=true]{standalone}")
  println(io, "\\usepackage{longtable}")
  println(io, "\\begin{document}")
  println(io, "\\include{$(bmarkname)}")
  println(io, "\\end{document}")
end

hdr_override = Dict{Symbol, String}(:objective => "\\(f\\)",
                                    :dual_feas => "\\(\\|\\nabla L\\|_2\\)",
                                    :primal_feas => "\\(\\|c\\|_2\\)",
                                    :elapsed_time => "\\(t\\)")
open(joinpath(bmark_dir, "$(bmarkname).tex"), "w") do io
  pretty_latex_stats(io, stats[:ipopt][!, cols], hdr_override=hdr_override)
end

# performance measures
#= first_order(df) = df.status .== :first_order =#
#= unbounded(df) = df.status .== :unbounded =#
#= solved(df) = first_order(df) .| unbounded(df) =#
#= costnames = ["time", =#
#=              "objective evals", =#
#=              "gradient evals", =#
#=              "Hessian evals", =#
#=              "obj + grad + hess"] =#
#= costs = [df -> .!solved(df) .* Inf .+ df.elapsed_time, =#
#=          df -> .!solved(df) .* Inf .+ df.neval_obj, =#
#=          df -> .!solved(df) .* Inf .+ df.neval_grad, =#
#=          df -> .!solved(df) .* Inf .+ df.neval_hess, =#
#=          df -> .!solved(df) .* Inf .+ df.neval_obj .+ df.neval_grad .+ df.neval_hess] =#

#= # plot and save performance profiles =#
#= ENV["GKSwstype"] = "100"  # plot headless =#
#= using Plots =#
#= p = profile_solvers(stats, costs, costnames) =#
#= Plots.pdf(p, "$(bmarkname).pdf") =#
