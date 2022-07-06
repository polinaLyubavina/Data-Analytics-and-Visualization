import std.stdio;
import std.math;
import std.algorithm;
import std.range;

import common;

//This is similar to the quadtree except that the Node class should 
//take a compile-time int parameter specifying which dimension it "splits" 
//on (does it split points based on point[0] (the x-coordinate), 
//point[1] (the y-coordinate), point[2](the z-coordinate), etc)
struct KDTree(size_t Dim){

    class Node(size_t splitDimension) {
        // If this is an x node, the next level is "y"
        // If this is a y node, the next level is "z", etc
        // This lets you refer to a node's split level with theNode.thisLevel
        enum thisLevel = splitDimension; 
        enum nextLevel = (splitDimension + 1) % Dim;
        // Child nodes split by the next level
        Node!nextLevel left, right;

        Point!Dim splitPoint;
        Point!Dim[] storedPoints;

        this(Point!Dim[] points) {
            // Base case
            if (points.length < 3) {
                storedPoints = points;
                return;
            }

            auto leftHalf = points.medianByDimension!thisLevel;
            auto rightHalf = points[leftHalf.length + 1 .. $];
            splitPoint = points[leftHalf.length];

            left = new Node!nextLevel(leftHalf);
            right = new Node!nextLevel(rightHalf);
        }
    }

   Node!0 root;

    //constructor
    this(Point!Dim[] points){
        root = new Node!0(points);
    }

    Point!Dim[] knnQuery(Point!Dim queryPoint, int k ) {
        auto ret = makePriorityQueue!Dim(queryPoint); 

        void recurse( size_t dim )(Node!dim n, AABB!Dim aabb) {
            // Check stored points
            if (isNaN(n.splitPoint[0])) {
                foreach(point; n.storedPoints) {
                    if (ret.length < k) {
                        ret.insert(point);
                    }
                    else if (distance(point, queryPoint) < distance(queryPoint, ret.front)) {
                        ret.popFront;
                        ret.insert(point); 
                    }
                }
            }
            else {
                // Check split point
                if (ret.length < k) {
                    ret.insert(n.splitPoint);
                }
                else if (distance(n.splitPoint, queryPoint) < distance(queryPoint, ret.front)) {
                    ret.popFront;
                    ret.insert(n.splitPoint); 
                }

                auto left_aabb = aabb;
                left_aabb.max[n.thisLevel] = n.splitPoint[n.thisLevel];
                if (ret.length < k || distance(queryPoint, closest(left_aabb, queryPoint)) < distance(queryPoint, ret.front)) {
                    recurse(n.left, left_aabb);
                }

                auto right_aabb = aabb;
                right_aabb.min[n.thisLevel] = n.splitPoint[n.thisLevel];
                if (ret.length < k || distance(queryPoint, closest(right_aabb, queryPoint)) < distance(queryPoint, ret.front)) {
                    recurse(n.right, right_aabb);
                }
            }
        }

        AABB!Dim root_aabb;
        foreach(i; 0 .. Dim){
            root_aabb.min[i] = -float.infinity;
            root_aabb.max[i] = float.infinity;
        }

        recurse!0(root, root_aabb);
        return ret.release;
    }

    //Like the QuadTree, I suggest using a nested recurse function, but now
    // because the node types are different, it needs to take a compile time
    //parameter as well
    Point!Dim[] rangeQuery( Point!Dim queryPoint, float radius ) {
        //return all points within a distance r of p
        Point!Dim[] ret;
        //void recurse( NodeType )( NodeType n )
        void recurse( size_t dim )(Node!dim n) {
            if (distance(n.splitPoint, queryPoint) < radius) {
                ret ~= n.splitPoint;
            }
            foreach(point; n.storedPoints) {
                if (distance(point, queryPoint) < radius) {
                    ret ~= point;
                }
            }

            if(n.left && queryPoint[n.thisLevel] - radius < n.splitPoint[n.thisLevel]) {
                recurse( n.left );
            }
            if(n.right&& queryPoint[n.thisLevel] + radius > n.splitPoint[n.thisLevel]) {
                recurse(n.right);
            }
        }
        recurse(root);
        return ret;
    }
}

unittest {
    writeln("testing kdtree constructor");

    auto points_small = [Point!2([.5, .5])];
    auto kd_small = KDTree!2(points_small);

    auto points = [Point!2([.5, .5]), Point!2([.55, .55]), Point!2([1, 1]),
                   Point!2([0.75, 0.4]), Point!2([0.4, 0.74])];
    auto kd = KDTree!2(points);

    assert(kd_small.root.storedPoints.length == 1);
    assert(isNaN(kd_small.root.splitPoint[0]));
    assert(isNaN(kd_small.root.splitPoint[1]));
    // assert(kd_small.root.left.isNull);
    // assert(kd_small.root.right.isNull);
    assert(kd_small.root.thisLevel == 0);
    assert(kd_small.root.nextLevel == 1);

    assert(kd.root.storedPoints.length == 0);
    assert(!isNaN(kd.root.splitPoint[0]));
    assert(!isNaN(kd.root.splitPoint[1]));
    // assert(!kd.root.left.isNull);
    // assert(!kd.root.right.isNull);
    assert(kd.root.thisLevel == 0);
    assert(kd.root.nextLevel == 1);

    // assert(!kd.root.left.left.isNull);
    // assert(!kd.root.left.right.isNull);
    assert(kd.root.left.thisLevel == 1);
    assert(kd.root.right.thisLevel == 1);
    assert(kd.root.left.nextLevel == 0);
    assert(kd.root.right.nextLevel == 0);

    assert(kd.root.left.storedPoints.length == 2);
    assert(kd.root.right.storedPoints.length == 2);

    writeln("kd rq");
    foreach(p; kd.rangeQuery(Point!2([1,1]), .7)){
        writeln(p);
    }
    assert(kd.rangeQuery(Point!2([1,1]), .7).length == 4);

    writeln("kd knn");
    foreach(p; kd.knnQuery(Point!2([1,1]), 3)){
        writeln(p);
    }
}
