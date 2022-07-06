module dub_test_root;
import std.typetuple;
static import bucketknn;
static import common;
static import dumbknn;
static import kdtree;
static import quadtree;
alias allModules = TypeTuple!(bucketknn, common, dumbknn, kdtree, quadtree);

						import std.stdio;
						import core.runtime;

						void main() { writeln("All unit tests have been run successfully."); }
						shared static this() {
							version (Have_tested) {
								import tested;
								import core.runtime;
								import std.exception;
								Runtime.moduleUnitTester = () => true;
								enforce(runUnitTests!allModules(new ConsoleTestResultWriter), "Unit tests failed.");
							}
						}
					