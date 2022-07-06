import std.stdio;

import common;
import dumbknn;
import bucketknn;
//import your files here
import kdtree;
import quadtree; 

void main()
{

    writeln("data_structure,time,D,k,N"); //output the time elapsed in microseconds
    
    //because dim is a "compile time parameter" we have to use "static foreach"
    //to loop through all the dimensions we want to test.
    //the {{ are necessary because this block basically gets copy/pasted with
    //dim filled in with 1, 2, 3, ... 7.  The second set of { lets us reuse
    //variable names.
    static foreach(dim; 1..8){{
        foreach(N; [100, 1000, 10000, 100000]) {
            //get points of the appropriate dimension
            auto trainingPoints = getGaussianPoints!dim(N);
            auto testingPoints = getUniformPoints!dim(100);
            auto kd = DumbKNN!dim(trainingPoints);
            auto sw = StopWatch(AutoStart.no);

            foreach(k; [1,2,5,10,20,50,100]) {
                sw.start; //start my stopwatch
                foreach(const ref qp; testingPoints){
                    kd.knnQuery(qp, k);
                }
                sw.stop;
                writeln("dumbKNN,", sw.peek.total!"usecs", ",", dim, ",", k, ",", N); //output the time elapsed in microseconds
            }
            //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
            //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
        }
    }}


    //Same tests for the BucketKNN
    static foreach(dim; 1..8){{
        foreach(N; [100, 1000, 10000, 100000]) {
        //get points of the appropriate dimension

        auto trainingPoints = getGaussianPoints!dim(N);
        auto testingPoints = getUniformPoints!dim(100);
        auto kd = BucketKNN!dim(trainingPoints, cast(int)pow(N/64, 1.0/dim)); //rough estimate to get 64 points per cell on average
        auto sw = StopWatch(AutoStart.no);
        foreach(k; [1,2,5,10,20,50,100]) {
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints){
                kd.knnQuery(qp, k);
            }
            sw.stop;
            writeln("bucketKNN,", sw.peek.total!"usecs", ",", dim, ",", k, ",", N); //output the time elapsed in microseconds
        }
        //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
        //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
        }
    }}

    //Same tests for the quadTree
    static foreach(dim; 2..3){{
        foreach(N; [100, 1000, 10000, 100000]) {
        //get points of the appropriate dimension

        auto trainingPoints = getGaussianPoints!dim(N);
        auto testingPoints = getUniformPoints!dim(100);
        auto quad = QuadTree!dim(trainingPoints, boundingBox(trainingPoints)); //rough estimate to get 64 points per cell on average
        auto sw = StopWatch(AutoStart.no);
        foreach(k; [1,2,5,10,20,50,100]) {
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints){
                quad.knnQuery(qp, k);
            }
            sw.stop;
            writeln("quadTree,", sw.peek.total!"usecs", ",", dim, ",", k, ",", N); //output the time elapsed in microseconds
        }
        //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
        //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
        }
    }}

    //Same tests for the kdTree
    static foreach(dim; 1..8){{
        foreach(N; [100, 1000, 10000, 100000]) {
        //get points of the appropriate dimension

        auto trainingPoints = getGaussianPoints!dim(N);
        auto testingPoints = getUniformPoints!dim(100);
        auto kd = KDTree!dim(trainingPoints);
        auto sw = StopWatch(AutoStart.no);
        foreach(k; [1,2,5,10,20,50,100]){
            sw.start; //start my stopwatch
            foreach(const ref qp; testingPoints){
                kd.knnQuery(qp, k);
            }
            sw.stop;
            writeln("kdTree,", sw.peek.total!"usecs", ",", dim, ",", k, ",", N); //output the time elapsed in microseconds
        }
        //NOTE, I SOMETIMES GOT TOTALLY BOGUS TIMES WHEN TESTING WITH DMD
        //WHEN YOU TEST WITH LDC, YOU SHOULD GET ACCURATE TIMING INFO...
        }
    }}
}
