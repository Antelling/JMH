import numpy as np
from sklearn.manifold import MDS, TSNE, SpectralEmbedding
from sklearn.preprocessing import MinMaxScaler
from matplotlib import pyplot as plt
import json

def parse_swarm(swarm):
    swarm = json.loads("[" + swarm.replace("(", "[").replace(")", "]") + "]")
    swarm.reverse()
    return swarm

def get_total_score(alg_results):
    total = 0
    for problem_results in alg_results:
        swarm = parse_swarm(problem_results[3])
        total += swarm[0][1]
    return total

for matrix_file, score_file, title in [("../data/ds5_matrix_limited.csv", "../../results/gigantic_search/5.json", "Dataset Five Limited"),
        ("../data/ds4_matrix_limited.csv", "../../results/gigantic_search/4.json", "Dataset Four Limited"),
        ("../data/ds4_matrix.csv", "../../results/gigantic_search/4.json", "Dataset Four"),
        ("../data/ds5_matrix.csv", "../../results/gigantic_search/5.json", "Dataset Five")]:

    data = open(matrix_file, "r").read()

    data = data.split("\n")
    data = [line.split(",") for line in data]
    del data[-1]

    matrix = np.array(data)[1:, 1:]
    labels = data[0][1:]

    mds = MDS(dissimilarity="precomputed")
    # mds = TSNE(metric="precomputed")
    # mds = SpectralEmbedding(affinity="precomputed")
    decomposed = mds.fit_transform(matrix.astype(float))

    results = json.loads(open(score_file, "r").read())

    values = []
    for alg in labels:
        values.append([get_total_score(results[alg])])
    values = MinMaxScaler().fit_transform(values)
    values = [a[0] for a in values] #get rid of the sklearn 2d array constraint

    fig, ax = plt.subplots()
    ax.scatter(decomposed[:, 0], decomposed[:, 1], c=values, cmap="OrRd")
    plt.title(title)

    for i, txt in enumerate(labels):
        ax.annotate(txt, (decomposed[i, 0]+5, decomposed[i, 1]+5))

    plt.show()
