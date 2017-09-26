using Plots
gr()
include("RRT.jl")


plot([1,2],[2,3])

cost, isPathFound, nlist = rrtPathPlanner(30)
@show isPathFound
@show cost
@show length(nlist)
#@show nlist



iterList = [40 80 100 120 150 180 200 150 300]
nTrials = 30
cost = 0
listCosts = Vector{Float32}()

print("\n\n")
for testIter in iterList 
    totalcost =0
    idx = 0
    @show testIter
    nSuccess = 0
    cost = 0
    while idx < nTrials
        cost, isPathFound, nlist = rrtPathPlanner(testIter)
        if isPathFound
            nSuccess += 1
        end
        totalcost += cost 
        idx += 1
    end
    avgCost = totalcost /  nSuccess
    @show avgCost
    @show listCosts
    print("\n\n")
    #@printf("For the iter of %d the avg cost was %d across %d trials", maxIter, avgCost, nTrials)
    push!(listCosts, avgCost)
end

@show listCosts
@show iterList
@show listCosts'



plot(iterList, listCosts', show=true, seriestype=:scatter, legend=false, yaxis=((0,100), 0:20:100), xaxis=((0,320), 0:50:300))
title!("RRT nIter vs pathcost")
xlabel!("iterations requested of RRT alg")
ylabel!("euclidean path cost")
#
    # roomx = [0,0,dim,dim];
    # roomy = [0,dim,dim,0];
# 
    # @printf("%s", "plotted\n")
    # plot!(h, show=true, legend=false, size=(600,600),xaxis=((-5,25), 0:1:20 ), yaxis=((-5,25), 0:1:20), foreground_color_grid=:lightcyan)
# 
    # nIter = -1#fix hardcoding
    # title!("RRT nIter = $(nIter), Path Found $(isPathFound)")
# 
# 