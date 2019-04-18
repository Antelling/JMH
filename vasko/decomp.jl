#for a problem with 100 variables, the solution space is a 100 dimensional hypercube
#this is really hard to do anything with, since there's no halfway
#we are limited to discrete optimization methods, which I personally consider to be gross
#BUT, we could cleverly transform our high dimensional hyercube into a lower dimensional blob
#which we can then use continous methods on
#giving us VECTORS, and polynomials, and maybe even gradient descent

#we have a lot of methods for dimensional reduction, but only a few are reversible
#and can operate on new samples. Basically just PCA or VAE. And VAE wouldn't work
#here for many, many reasons so lets analyze some principal components
