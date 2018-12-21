'''
Created on Jun 17, 2011

@author: Sai Panyam

Unit tests that exercise the algorithms. It is a mixture of both real 'unit' tests and functional tests of search
'''
import unittest
from Helpers.Utilities import basinFunction
from ResultHelpers import TSPResult, BasinResult
class SearchTests(unittest.TestCase):
    
    def setUp(self):
        self.Vector = [1,2]
        # Problem Configuration
        berlin52 = [[565,575],[25,185],[345,750],[945,685],[845,655],
                    [880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],
                    [1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],
                    [415,635],[510,875],[560,365],[300,465],[520,585],[480,415],
                    [835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],
                    [410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],
                    [685,610],[770,610],[795,645],[720,635],[760,650],[475,960],
                    [95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],
                    [830,610],[605,625],[595,360],[1340,725],[1740,245]
                   ]
        self.TSPLIB = berlin52
        
    def tearDown(self):
        self.Vector =[]
        
    #@unittest.skip("Don't run FOR NOW!")           
    def testBasinFunction(self):
        result = basinFunction(self.Vector)
        self.assertTrue(result == -9.5, "Result value is not as expected. Found Result : " + str(result))
        
    #@unittest.skip("Don't run FOR NOW!")             
    def testDoubleBridgeMove(self):
        from StochasticAlgorithms.IteratedLocalSearch import doubleBridgeMove
        
        result = doubleBridgeMove(self.TSPLIB)
        self.assertTrue(len(self.TSPLIB) == len(result))
    
    #@unittest.skip("Don't run FOR NOW!")          
    def testConvertToEdgeList(self):
        from StochasticAlgorithms.ReactiveTabuSearch import convertToEdgeList
        edges = convertToEdgeList(self.TSPLIB)
        self.assertTrue(len(edges)== len(self.TSPLIB))
        
    #@unittest.skip("Don't run FOR NOW!")    
    def testIsEquivalentInRTS(self):
        from StochasticAlgorithms.ReactiveTabuSearch import isEquivalent
        edgeList1 = [[[1,2],[2,3]],[[3,4],[4,5]],[[5,6],[6,7]]]
        edgeList2 = [[[5,6],[6,7]],[[3,4],[4,5]],[[1,2],[2,3]]]
        self.assertTrue(isEquivalent(edgeList1,edgeList2))
        
    #@unittest.skip("Don't run FOR NOW!")         
    def testRandomSearch(self):
        from StochasticAlgorithms.RandomSearch import search
        # Problem Configuration
        searchVector = [-5,5]
        size = 2
        # Algorithm Configuration
        iterations = 10000
        # Execute the random search algorithm
        # Outputs a tuple containing the best cost and best input values
        result = search(searchVector, iterations, size)
        self.assertTrue(basinFunction(result["vector"])== result["cost"], "Failed to get correct best basin value.")
        basin = BasinResult("Random Search")
        print basin.FormattedOutput(result)
    
    #@unittest.skip("Don't run FOR NOW!")          
    def testAdaptiveRandomSearch(self):
        from StochasticAlgorithms.AdaptiveRandomSearch import search
        # Problem Configuration
        searchVector = [-5,5]
        size = 2
        # Algorithm Configuration
        maxIterations = 10000
        initFactor =0.05
        lFactor =3.0
        sFactor =1.3
        iterFactor =10
        maxNoChange =25
        
        # Execute the adaptive random search algorithm
        # Outputs a tuple containing the best cost and best input values
        result = search(maxIterations, size, searchVector, initFactor, sFactor, lFactor, iterFactor, maxNoChange)
        self.assertTrue(basinFunction(result["vector"])== result["cost"], "Failed to get correct best basin value.")
        basin = BasinResult("Adaptive Random Search")
        print basin.FormattedOutput(result)
    
    #@unittest.skip("Don't run FOR NOW!")            
    def testStochasticHillClimbingSearch(self):
        from StochasticAlgorithms.StochasticHillClimbing import search
        # Problem Configuration
        numBits = 64
        # Algorithm Configuration
        maxIterations = 1000
        
        # Execute the SHC algorithm
        result = search(numBits, maxIterations)
        print "Stochastic Hill Climbing Search Results : "
        print "*" * 20
        print "SHC Iteration "
        print "*" * 20
        print result["iteration"]
        print "*" * 20
        
        print "*" * 20
        print "Initial One Max Count"
        print "*" * 20
        print result["initialCost"]
        print "*" * 20
        print "Final One Max Count"
        print "*" * 20
        print result["cost"]
        print "*" * 20
        print "*" * 20
        print "*" * 20
        print "Search FormattedOutput : (Final- Initial)/Iteration"
        print "*" * 20
        efficacy = round(float(result["cost"] - result["initialCost"])/float(result["iteration"]),2)
        print efficacy
    
    #@unittest.skip("Don't run FOR NOW!")         
    def testScatterSearch(self):
        from StochasticAlgorithms.ScatterSearch import search
        # Problem Configuration
        searchVector = [-5,5]
        problemSize = 2
        # Algorithm Configuration
        maxIterations = 100
        stepSize = (searchVector[1]-searchVector[0]) * 0.05  # 5 percent of search space
        maxNoImprove =30
        refSetSize = 10
        diverseSetSize =20
        eliteCount = 5
        
        # execute the algorithm
        result = search(searchVector, problemSize, refSetSize, diverseSetSize, maxIterations, maxNoImprove, eliteCount, stepSize)
        self.assertTrue(basinFunction(result["vector"])== result["cost"], "Failed to get correct best basin value.")
        basin = BasinResult("Scatter Search")
        print basin.FormattedOutput(result)
    
    #@unittest.skip("Don't run FOR NOW!")               
    def testIteratedLocalSearch(self):
        from StochasticAlgorithms.IteratedLocalSearch import search
        # Problem Configuration
        # Use Berlin52 instance of TSPLIB
        # Algorithm Configuration
        maxIterations = 100
        maxNoImprove = 50
        searchHistoryToKeep =1 # since we don't plan to use it now
        # Execute the Algorithm
        result = search(self.TSPLIB, maxIterations, maxNoImprove,searchHistoryToKeep)
        tspResult = TSPResult(7542,"Iterated Local Search Results")
        print tspResult.FormattedOutput(result)         
    
    #@unittest.skip("Don't run FOR NOW!")          
    def testVariableNeighborhoodSearch(self):
        from StochasticAlgorithms.VariableNeighborhoodSearch import search
        # Problem Configuration
        # Use Berlin52 instance of TSPLIB
        # Algorithm Configuration
        maxNoImprove =50
        maxNoImproveLocal =70
        neighborhoods = range(1,21) # since we want 20 runs for neighborhood starting with 1
        
        # Execute the algorithm
        result = search(self.TSPLIB,neighborhoods, maxNoImprove, maxNoImproveLocal)
        tspResult = TSPResult(7542,"Variable Neighborhood Search Results")
        print tspResult.FormattedOutput(result)        
    
    #@unittest.skip("Don't run FOR NOW!")          
    def testGreedyRandomizedAdaptiveSearch(self):
        from StochasticAlgorithms.GreedyRandomizedAdaptiveSearch import search
        # Problem Configuration
        # Use Berlin52 instance of TSPLIB
        # Algorithm Configuration
        maxNoImprove =50
        maxIterations =50
        greedinessFactor =0.3 # should be in the range [0,1]. 0 is more greedy and 1 is more generalized
        
        # Execute the algorithm
        result = search(self.TSPLIB,maxIterations, maxNoImprove, greedinessFactor)
        tspResult = TSPResult(7542,"Greedy Randomized Adaptive Search Results")
        print tspResult.FormattedOutput(result)
        
    #@unittest.skip("Don't run FOR NOW!")          
    def testTabuSearch(self):
        from StochasticAlgorithms.TabuSearch import search
        # Problem Configuration
        # Use Berlin52 instance of TSPLIB
        # Algorithm Configuration
        maxIterations = 100
        maxTabuCount = 15
        maxCandidates = 50
        # Execute the algorithm
        result = search(self.TSPLIB,maxIterations, maxTabuCount, maxCandidates)
        tspResult = TSPResult(7542,"Tabu Search Results")
        print tspResult.FormattedOutput(result)
    
    #@unittest.skip("Don't run FOR NOW!")         
    def testGuidedLocalSearch(self):
        from StochasticAlgorithms.GuidedLocalSearch import search
        # Problem Configuration
        # Use Berlin52 instance of TSPLIB
        # Algorithm Configuration
        maxIterations = 150
        maxNoImprove = 20
        localSearchOptima = 12000.0
        alpha =0.3
        scalingFactor = alpha * (localSearchOptima/float(len(self.TSPLIB)))
        # Execute the algorithm
        result = search(self.TSPLIB, maxIterations, maxNoImprove, scalingFactor)
        tspResult = TSPResult(7542,"Guided Local Search Results")
        print tspResult.FormattedOutput(result)
        
    #@unittest.skip("Don't run FOR NOW!")         
    def testReactiveTabuSearch(self):
        from StochasticAlgorithms.ReactiveTabuSearch import search
        # Problem Configuration
        # Use Berlin52 instance of TSPLIB
        # Algorithm Configuration
        maxIterations =100
        maxCandidates =50
        increase =1.3
        decrease =0.9
        #Execute the algorithm
        result = search(self.TSPLIB, maxIterations, increase, decrease, maxCandidates)
        tspResult = TSPResult(7542,"Reactive Tabu Search")
        print tspResult.FormattedOutput(result)
        
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testRandomSeaarch']
    unittest.main()