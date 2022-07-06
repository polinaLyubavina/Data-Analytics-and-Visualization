import std.stdio;
import std.math;
import std.algorithm;
import std.range;

import common;

struct QuadTree(size_t dim){

    struct Node {
        /*
        Your node class will store:

        A list of points (if it's a leaf node)
        4 children (if it's an internal node). Note, some of the children might be null.
        An AABB that explains what area this node covers
         boolean to tell you whether or not it's a leaf.
        */

        AABB!2 aabb;
        Node[] children;
        Point!2[] points;
        bool leaf;
        Point!2 midpoint;

        int MAX_POINTS_IN_NODE = 2;

        this(Point!2[] points, AABB!2 aabb) {
            /*
            The Node constructor should take a list of points and an AABB describing what area it covers.
            It will recursively call itself when constructing children (if necessary).
            You'll probably want to use the partitionByDimension method from common.d here.
            */
            

            if(points.length > MAX_POINTS_IN_NODE) {

                midpoint = (aabb.max + aabb.min) / 2;

                auto rightHalf = points.partitionByDimension!0(midpoint[0]);
                auto leftHalf = points[0 .. $ - rightHalf.length];

                auto tl = leftHalf.partitionByDimension!1(midpoint[1]); 
                auto tr = rightHalf.partitionByDimension!1(midpoint[1]); 
                auto bl = leftHalf[0 .. $ - tl.length];
                auto br = rightHalf[0 .. $ - tr.length];

                auto aabbTL = boundingBox!dim([Point!dim([aabb.min[0], midpoint[1]]), Point!dim([midpoint[0], aabb.max[1]])]);
                auto aabbTR = boundingBox!dim([midpoint, aabb.max]);
                auto aabbBL = boundingBox!dim([aabb.min, midpoint]);
                auto aabbBR = boundingBox!dim([Point!dim([midpoint[0], aabb.min[1]]), Point!dim([aabb.max[0], midpoint[1]])]);

                children ~= Node(tl, aabbTL); // Top Left
                children ~= Node(tr, aabbTR); // Top Right
                children ~= Node(bl, aabbBL); // Bottom Left
                children ~= Node(br, aabbBR); // Bottom Right
            }
            else {
                this.points = points.dup;       //copy the incoming array.
                this.leaf = true;
            }
        }

        Point!2[] rangeQuery(Point!2 queryPoint, float radius) {
            // For the query methods, I recommend defining a nested function for recursion:
            Point!2[] recurse(Node n) {
                // decide how to add stuff to ret, and recurse
                // You can access variables defined in rangeQuery here
                // (eg, use p, r, and append to ret)
                if (n.leaf) {
                    Point!2[] ret;
                    // Look through n.points to see if any points are close enough to p
                    foreach(const ref point; n.points) {
                        if (distance(queryPoint, point) < radius) {
                            ret ~= point;   
                        }
                    }
                    return ret;
                }
                else {
                    // determine which child queryPoint is in
                    int[] childIndices;

                    auto x_dif = queryPoint[0] - n.midpoint[0];
                    auto y_dif = queryPoint[1] - n.midpoint[1];

                    if (x_dif < 0) {
                        if (y_dif < 0) {
                            childIndices ~= 2;

                            if (radius > x_dif) {
                                childIndices ~= 3;
                            }
                            if (radius > y_dif) {
                                childIndices ~= 0;
                            }
                            if (radius > y_dif && radius > x_dif) {
                                childIndices ~= 1; 
                            }
                        } 
                        else {
                            childIndices ~= 0;

                            if (radius > x_dif) {
                                childIndices ~= 1;
                            }
                            if (radius > y_dif) {
                                childIndices ~= 2;
                            }
                            if (radius > y_dif && radius > x_dif) {
                                childIndices ~= 3; 
                            }
                        }
                    } 

                    else {
                        if (y_dif < 0) {
                            childIndices ~= 3;

                            if (radius > x_dif) {
                                childIndices ~= 2;
                            }
                            if (radius > y_dif) {
                                childIndices ~= 1;
                            }
                            if (radius > y_dif && radius > x_dif) {
                                childIndices ~= 0; 
                            }
                        } 
                        else {
                            childIndices ~= 1;

                            if (radius > x_dif) {
                                childIndices ~= 0;
                            }
                            if (radius > y_dif) {
                                childIndices ~= 3;
                            }
                            if (radius > y_dif && radius > x_dif) {
                                childIndices ~= 2; 
                            }
                        }
                    } 

                    // Recur
                    Point!2[] ret;
                    foreach(const ref childIndex; childIndices) {
                        ret ~= n.children[childIndex].rangeQuery(queryPoint, radius);
                    }
                    return ret;
                }
            }

            return recurse(this);
        }

        /*
        For the KNNQuery method, you'll do something similar,
        but we'll need to use a priority queue to keep track of the results.
        See the makePriorityQueue and associated unittest in common.d for usage.
        */
        Point!2[] knnQuery(Point!2 queryPoint, int k ) {
            auto ret = makePriorityQueue!2(queryPoint); 

            void recurse(Node n) {
                if (n.leaf) {
                    foreach(point; n.points) {
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
                    foreach(child; n.children) {
                        if (ret.length < k || distance(queryPoint, closest(child.aabb, queryPoint)) < distance(queryPoint, ret.front)) {
                            recurse(child);
                        }
                    }
                }
            }

            recurse(this);
            return ret.release;
        }
    }

    // The Quadtree struct itself will then just store a Node root.
    Node root;
    
    this(Point!2[] points, AABB!2 initialAABB) {
        this.root = Node(points, initialAABB);
    }

    Point!2[] rangeQuery(Point!2 queryPoint, float radius) {
        return root.rangeQuery(queryPoint, radius);
    }

    Point!2[] knnQuery(Point!2 queryPoint, int k) {
        return root.knnQuery(queryPoint, k);
    }

}


unittest{
    //use a small # of points and manually check that you get the answers you expect
    auto points_small = [Point!2([.5, .5])];
    auto quad_small = QuadTree!2(points_small, boundingBox(points_small));

    auto points = [Point!2([.5, .5]), Point!2([.55, .55]), Point!2([1, 1]),
                   Point!2([0.75, 0.4]), Point!2([0.4, 0.74])];
    auto quad = QuadTree!2(points, boundingBox(points));

    writeln("testing quadtree constructor");

    assert(quad_small.root.children.length == 0);
    assert(quad_small.root.leaf == true);

    assert(quad.root.children.length == 4);
    assert(quad.root.leaf == false);
    assert(quad.root.children[0].leaf == true);
    assert(quad.root.children[1].leaf == true);
    assert(quad.root.children[2].leaf == true);
    assert(quad.root.children[3].leaf == true);
    assert(quad.root.children[0].points.length == 1);
    assert(quad.root.children[1].points.length == 1);
    assert(quad.root.children[2].points.length == 2);
    assert(quad.root.children[3].points.length == 1);

    writeln("quad rq");
    foreach(p; quad.rangeQuery(Point!2([1,1]), .7)){
        writeln(p);
    }
    assert(quad.rangeQuery(Point!2([1,1]), .7).length == 4);

    writeln("quad knn");
    foreach(p; quad.knnQuery(Point!2([1,1]), 3)){
        writeln(p);
    }
}
