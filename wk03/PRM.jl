# Attempt to make a PRM.
#print("Hello World! ☺ ♫ ☕ \n\n")

using Plots
using DataStructures
#gr()

plot([1,2],[2,3])

module rrt 
    export Node, Edge, Obstacle, Room, Point

    struct Point
        x::Int
        y::Int
    end

    struct Node
        id::Int
        iPrev::Int #parent
        state::Point
    end


    struct Vertex
        id::Int
        state::Point
    end


    struct Edge
        startID::Int
        endID::Int
    end

    struct Obstacle
        SW::Point
        NE::Point
    end

    ### Some types?
    struct Room #corners of the room
        x1::Int
        y1::Int #bottom left corner?
        x2::Int
        y2::Int
        obstacleList::Array{Obstacle}
    end

    struct tempQueueType
        v::rrt.Vertex
        statesList::Vector{rrt.Vertex}
        cost::Int64
    end

    Base.show(io::IO, v::Vertex) = print(io, "V($(v.id), ($(v.state.x),$(v.state.y)))")
    Base.show(io::IO, p::Point) = print(io, "P($(p.x),$(p.y))")
    Base.show(io::IO, q::tempQueueType) = print(io, "Q($(q.v),$(q.statesList) $(q.cost))")
    Base.isless(q1::tempQueueType, q2::tempQueueType) = q1.cost < q2.cost
    Base.isless(p1::Point, p2::Point) = q1.x< q2.x
end

function isCollidingRects(rect1, rect2)
    topEdge1 = rect1.NE.y
    rightEdge1 = rect1.NE.x
    leftEdge1 = rect1.SW.x
    bottomEdge1 = rect1.SW.y

    topEdge2 = rect2.NE.y
    rightEdge2 = rect2.NE.x
    leftEdge2 = rect2.SW.x
    bottomEdge2 = rect2.SW.y

    if ( leftEdge1 < rightEdge2 && rightEdge1 > leftEdge2 && bottomEdge1 < topEdge2 && topEdge1 > bottomEdge2)
         return true
	end
    return false
end

# https://www.gamedevelopment.blog/collision-detection-circles-rectangles-and-polygons/
# public boolean isRectanglesColliding(Rectangle rec1, Rectangle rec2){
    # int topEdge1 = rec1.position.y + rec1.height;
    # int rightEdge1 = rec1.position.x + rec1.width; 
    # int leftEdge1 = rec1.position.x;
    # int bottomEdge1 = rec1.position.y;
    # int topEdge2 = rec2.position.y + rec2.height;
    # int rightEdge2 = rec2.position.x + rec2.width; 
    # int leftEdge2 = rec2.position.x;
    # int bottomEdge2 = rec2.position.y;   
    # 
    # if( leftEdge1 < rightEdge2 && rightEdge1 > leftEdge2 && bottomEdge1 < topEdge2 && topEdge1 > bottomEdge2){
        # return true; 
   # }
   # return false;
# }

function isCollidingNode(pt,obs)
    # this does not work.
    px,py = pt.x, pt.y
    x1,y1 = obs.SW.x, obs.SW.y
    x2,y2 = obs.NE.x, obs.NE.y 

    # obs1 = rrt.Obstacle(P(8,3), P(10,18))
    # isCollidingNode(rrt.Point(1,10))

    #print("Checking collision. $(px) vs obs $(obs) \n")
    if (px >= x1 && px <= x2 && py >= y1 && py <= y2)
        return true
    else
        return false
    end
end
function isCollidingNodeMultipleObs(pt, obstacleList)
    coll = false 
    for obs in obstacleList
        if isCollidingNode(pt, obs)
            coll = true
        end
    end
    return coll
end


function isCollidingEdgeMultipleObs(r, nn, obstacleList)
    coll = false 
    for obs in obstacleList
        if isCollidingEdge(r, nn, obs)
            coll = true
        end
    end
    return coll

end
function isCollidingEdge(r, nn, obs)
    # to detect collision, let's just check whether any of the four
    # lines of the rectangular obstacle intersect with our edge
    # ignore collinearity for now

    # Tofix: To make it look prettier in the graph, I am just going to add a 1 grid pt
    # spacer for now, until I figure out how to check for coincidence of point
    # in line. Or really, I should use GeometryShapes library

    x1,y1 = obs.SW.x, obs.SW.y
    x2,y2 = obs.NE.x, obs.NE.y 

    # pad it out a bit?
    # x1 -= 1
    # y1 -= 1
    # x2 += 1
    # y2 += 1

    pt1 = rrt.Point(x1, y1)
    pt2 = rrt.Point(x1, y2)
    pt3 = rrt.Point(x2, y2)
    pt4 = rrt.Point(x2, y1)
    
    # let A, B be r, nn
    coll1 = intersectLineSeg(r.state, nn.state, pt1, pt2)
    coll2 = intersectLineSeg(r.state, nn.state, pt2, pt3)
    coll3 = intersectLineSeg(r.state, nn.state, pt3, pt4)
    coll4 = intersectLineSeg(r.state, nn.state, pt4, pt1)
    if (!coll1 && !coll2 && !coll3 && !coll4)
    #    print("Not collliding, the edge between pt $(r) and pt $(nn)\n")
        return false
    else
    #    print("COLLIDING, the edge between pt $(r) and pt $(nn)\n")
        return true
    end
end

function ccw(A,B,C)
    # determines direction of lines formed by three points
	return (C.y-A.y) * (B.x-A.x) > (B.y-A.y) * (C.x-A.x)
end

function intersectLineSeg(A,B,C,D) #no ":" at the end!
 	return ( (ccw(A, C, D) != ccw(B, C, D)) && ccw(A, B, C) != ccw(A, B, D))
end


function nearV(r, nodeslist, maxDist)
    # r is point
    # given maxDist, return all nodes within that distance of node
    nearVs = Vector{rrt.Vertex}()
    for n in nodeslist
        dist = distPt(r.state, n.state)
        if dist < maxDist 
            push!(nearVs, n)
        end
    end
    return nearVs
end


function distPt(pt1, pt2)
    x2,y2 = pt2.x, pt2.y
    x1,y1 = pt1.x, pt1.y
    dist = sqrt( (x1-x2)^2 + (y1-y2)^2 )
    return dist
end


# function findNodeFromState(nodestate, nodeslist)
    # for n in nodeslist
        # if n.state == nodestate
            # return n
        # end
    # return Void
# end

function fuzzyState(nodestate, maxDist)
    dist = maxDist
    listFuzzyStates = Vector{rrt.Point}()
    x, y = nodestate.x, nodestate.y
    l = rrt.Point(x-dist , y)
    r = rrt.Point(x+dist , y)
    u = rrt.Point(x, y+dist ) 
    d = rrt.Point(x, y-dist )
    NW = rrt.Point(x-dist , y+dist )
    SW = rrt.Point(x-dist , y-dist )
    NE = rrt.Point(x+dist , y+dist )
    SE = rrt.Point(x+dist , y-dist )
    push!(listFuzzyStates, l, r, u, d, NW, SW, NE, SE)
    return listFuzzyStates 
end

function fuzzyFindNodeFromState(nodestate, nodeslist)
    res = Void #result
    for n in nodeslist
        if n.state == nodestate
            res = n
            return res 
        end
    end

    fuzzyDist = 1
    while res == Void
        for n in nodeslist
            nFuzzyState = fuzzyState(n.state, fuzzyDist)
            if nodestate in nFuzzyState
                #print("\nFuzzy search required to find node, using distance $(fuzzyDist)\n")
                res = n
            end
        end
        fuzzyDist += 1
    end
    return res
end



function preprocessPRM(numPts, maxDist, obstacleList)
    #numPts = 100
    #maxDist = 10
    #room = Room(0,0,21,21);


    vlist = Vector{rrt.Vertex}()

    nodeslist = Vector{rrt.Vertex}()
    edgeslist = Vector{rrt.Edge}()

    startV = rrt.Vertex(0, rrt.Point(0,0)) #vertex: we just remove the prevID from node type
    push!(nodeslist, startV)
    #@printf("string %s",nodeslist)

    maxID = 1

    # Sample points, create list of nodes 
    for i in 1:numPts
        v = rrt.Point(rand(1:20),rand(1:20)) #new point
            if !isCollidingNodeMultipleObs(v, obstacleList) #todo
                newVertex = rrt.Vertex(maxID, v)
                maxID += 1
                push!(nodeslist, newVertex)
            end
    end

    # Connect each node to its neighboring nodes within a ball or radius r
    for vStart in nodeslist 
        nearlist = nearV(vStart, nodeslist, maxDist) # parent point #TODO
        for vEnd in nearlist
                if !isCollidingEdgeMultipleObs(vStart, vEnd, obstacleList) #todo
                    newEdge = rrt.Edge(vStart.id, vEnd.id) #by ID, or just store node? #wait no, i'd have multiple copies of same node for no real reason, mulitple edges per node
                    push!(edgeslist, newEdge)
                end
        end
    end

    #@show edgeslist 
    #@printf("\nPath found? %s Length of nodeslist: %d\n", isPathFound, length(nodeslist))
    return nodeslist, edgeslist
end


function getSuccessors(curVertex, edgeslist, nodeslist) #assuming bidirectional for now
    #curVertex = findNode(nodeID)
    nodeID = curVertex.id
    successorIDs = Vector{Int}()
    successors = Vector{rrt.Vertex}()

    for e in edgeslist
        if e.startID == nodeID
            push!(successorIDs, e.endID)
        end
        if e.endID == nodeID #should I include endID? it is bidirectional after all. 
            push!(successorIDs, e.startID) #yes, because local planner connects in bidirectional way
        end
    end

    for id in successorIDs
        vertex = findNode(id, nodeslist)
        push!(successors, vertex)
    end

    return successors
end
function queryPRM(beginState, endState, nlist, edgeslist)

    beginVertex = fuzzyFindNodeFromState(beginState, nlist) #TODO: There is no reason to do this, I should use nearV instead, and add a new edge to the graph
    endVertex = fuzzyFindNodeFromState(endState, nlist)

#    print("This is the beginState $(beginState) and the endState $(endState)\n")
#    print("This is the beginVertex--> $(beginVertex) >>> and the endVertex--> $(endVertex)\n")

    pathNodes = Vector{rrt.Vertex}()
    visited = Vector{rrt.Vertex}() #nodes we've searched through
    
    foo = rrt.tempQueueType(beginVertex, pathNodes, 1) 
    #frontier = binary_maxheap(rrt.tempQueueType)
    frontier = PriorityQueue() #rrt.tempQueueType, Int
    # Ah! I'm to use heaps instead (specific implementation of priorityqueues)
    enqueue!(frontier, foo, 1) #root node has cost 0  
	zcost = 99999

    while length(frontier) != 0
        #print("\n\n=========== NEW ITERATION\n")
        tmp = DataStructures.dequeue!(frontier)
        pathVertices = []
        curVertex, pathVertices, totaledgecost = tmp.v, tmp.statesList, tmp.cost

        if curVertex == endVertex 
            #print("Hurrah! endState reached! \n")
            unshift!(pathVertices, beginVertex) #prepend startVertex back to pathVertices
			zcost = costPath(pathVertices)
            return (zcost, true, pathVertices) #list of nodes in solution path

        else
            #@show visited
            #@show curVertex
            if !(curVertex in visited) 
                #print("curVertex not in visited\n")
                push!(visited, curVertex) # Add all successors to the stack

                for newVertex in getSuccessors(curVertex, edgeslist, nlist)
                #print("\n")
                #print("newvertex --> $(newVertex) \n")
                    newEdgeCost = distPt(curVertex.state, newVertex.state) #heuristic is dist(state,state). better to pass Node than to perform node lookup everytime (vs passing id)
                    f_x = totaledgecost + newEdgeCost + distPt(newVertex.state, endVertex.state) #heuristic = distPt 
                    p = deepcopy(pathVertices)
                    push!(p,newVertex)
                #@show pathVertices
                    if !(newVertex in keys(frontier))
                        #print("newvertex --> $(newVertex) >>> was not in frontier \n")
                        tmpq = rrt.tempQueueType(newVertex, p, ceil(totaledgecost + newEdgeCost))
                        enqueue!(frontier,tmpq, ceil(f_x)) 
                        #print("Added state --> $(tmpq) >>> to frontier \n")
                        #print("This is frontier top --> $(peek(frontier)) \n")
                    end
                end

            end
        end
    end    
    # Return None if no solution found
    #@printf("No solution found! This is length of frontier, %d\n", length(frontier))
	zcost = 99999
    return (zcost, false, Void)
end



function plotPath(isPathFound, nlist, elist, solPath, maxDist, obstacleList) #rewrite so don't need to pass in isPathFound, obs1, rrtstart, goal, room 
    # maxDist only used for plot title

    ### <COPIED FOR NOW #Todo fix hardcoding
    #obs1 = rrt.Obstacle(rrt.Point(8,3),rrt.Point(10,18)) #Todo

    rrtstart = rrt.Point(1,0)
    goal = rrt.Point(18,18)
    ### / COPIED FOR NOW>

    h = plot()

    #@printf("%s", "plotted\n")
    plot!(h, show=true, legend=false, size=(600,600),xaxis=((-5,25), 0:1:20 ), yaxis=((-5,25), 0:1:20), foreground_color_grid=:lightcyan)

    title!("PRM with $(length(nlist)) nodes, maxdist = $(maxDist), Path Found = $(isPathFound)")

    # plot room
    dim = 21 
    roomx = [0,0,dim,dim];
    roomy = [0,dim,dim,0];
    plot!(roomx, roomy, color=:black, linewidth=5)

    # plot start and end goals
    circle(1,0, 0.5, :red)
    rectEnd = rrt.Obstacle(rrt.Point(17,17),rrt.Point(19,19)) #Todo
    circle(18,18, 0.5, :forestgreen) #NOTE: in PRM, it is the closest node -- within distance 1
    rectObs(rectEnd)

    # plot obstacles
    for obs in obstacleList
        rectObs(obs)
    end

    # plot all points?  Yes -- there may be points without edges. we only check within maxDist
    x = [v.state.x for v in nlist]
    y = [v.state.y for v in nlist]
    scatter!(x,y, linewidth=0.2, color=:black)

    print("Done plotting $(length(nlist)) nodes\n")

    edgeXs, edgeYs = [], []
    for e in elist
        startV = findNode(e.startID, nlist)
        endV = findNode(e.endID, nlist)
        x1,y1 = startV.state.x, startV.state.y
        x2,y2 = endV.state.x, endV.state.y
        push!(edgeXs, x1, x2, NaN)
        push!(edgeYs, y1, y2, NaN)
    end
    plot!(edgeXs, edgeYs, color=:tan, linewidth=0.3)
    print("Done plotting $(length(elist)) edges\n")

    # plot winning path
    if isPathFound
        cost = plotWinningPath(solPath)
        #@printf("\n!!!! The cost of the path was %d across %d nodes  !!!! \n", cost, length(nlist))
        #nEnd = nlist[end]
    end
    # display winning path cost
	return cost
end


    ### Some helper functions
    function circle(x,y,r,c_color)
        th = 0:pi/50:2*pi;
        xunit = r * cos.(th) + x;
        yunit = r * sin.(th) + y;
        plot!(xunit, yunit,color=c_color,linewidth=3.0);
    end

    function rectObs(obstacle)
        x1,y1 = obstacle.SW.x, obstacle.SW.y
        x2,y2 = obstacle.NE.x, obstacle.NE.y
        r = 0.2
        obsColor = :blue

        plot!([x1,x1,x2,x2,x1], [y1,y2,y2,y1,y1], color=obsColor, linewidth=2)
    end

    function plotWinningPath(solPath)
        xPath = [v.state.x for v in solPath]
        yPath = [v.state.y for v in solPath]
        cost = 0
        for i in 2:length(solPath)
            curV  = solPath[i].state
            prevV = solPath[i-1].state
            cost += distPt(curV, prevV)
        end

        plot!( xPath, yPath, color = :orchid, linewidth=3)
        #print("plotted winning path")
        #@show nlist
        return cost
    end
    function costPath(solPath)
        xPath = [v.state.x for v in solPath]
        yPath = [v.state.y for v in solPath]
        cost = 0
        for i in 2:length(solPath)
            curV  = solPath[i].state
            prevV = solPath[i-1].state
            cost += distPt(curV, prevV)
        end

        return cost
    end

    function findNode(id, nodeslist)
        for n in nodeslist
            #TODO: switch nodeslist to use an array, where indice is the ID...
            #this was a really dumb implementation, making a "loop" find
            #instead of taking advantage of fast lookup libraries
            if n.id == id 
                return n
            end
        end
    end
#end




function genObs()
    done1 = false
    done2 = false
    done2Rect = false
    while done2Rect == false
        randx, randy = rand(1:20, 1,2) 
        randw, randh = rand(1:5, 1,2)
        NEx =  randx+randw
        NEy =  randy+randh

        if (NEx<21 && NEy<21)
            obs1 = rrt.Obstacle(rrt.Point(randx, randy),rrt.Point(NEx,NEy)) #Todo
            area1 = randw * randh
            done1 = true
        end

        randx, randy = rand(1:20, 1,2) 
        randw, randh = rand(1:5, 1,2)

        NEx =  randx+randw
        NEy =  randy+randh

        if (NEx<21 && NEy<21)
            obs2 = rrt.Obstacle(rrt.Point(randx, randy),rrt.Point(NEx,NEy)) #Todo
            area2 = randw * randh
            done2= true
        end
        done2Rect = done1 && done2
    end

    area1 = 2
    area2 = 3
    area = area1+area2
    return obs1, obs2, area
end

function gen2Obs()
    while true
        obs1, obs2, area = genObs()
        if !isCollidingRects(obs1, obs2)
            @show obs1, obs2
            return area, obs1, obs2
        end
    end
end


function main()

    obstacleList = Vector{rrt.Obstacle}()
    area, obs1, obs2 = gen2Obs()
    push!(obstacleList,obs1)
    push!(obstacleList,obs2)


    # nnodes , maxDist
    connectDist = 10
    # 1
    #nodeslist, edgeslist= preprocessPRM(30, connectDist)
    nodeslist, edgeslist= preprocessPRM(30, connectDist, obstacleList)

    start = rrt.Point(0,0)
    goal = rrt.Point(18,18)

    #2
    cost, isPathFound, winningPath = queryPRM(start, goal, nodeslist, edgeslist) #aStarSearch

    #3
    cost = plotPath(isPathFound, nodeslist, edgeslist, winningPath, connectDist, obstacleList)


    #@show nodeslist
    #print("This is the solution path: \n") 
    #@show winningPath

    print("HIIIIIIIIIIIIII")
    isCollidingRects(obs1, obs2)
end
