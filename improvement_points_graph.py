import json
from matplotlib import pyplot as plt
from sklearn.preprocessing import MinMaxScaler
import numpy as np

with open("results/CGA2_ls_10s_5000f_pop30_ls/3.json", "r") as file:
    data = file.read()
    data = json.loads(data)


def repair_holes(ip):
    i = 1
    repaired = []
    repaired.append(ip[0])
    prevtries, prevtotal, prevbest = ip[0]
    while i < len(ip):
        tries, total, best = ip[i]
        j = 1
        while not (tries == repaired[-1][0] + 1):
            repaired.append([prevtries + j, prevtotal, prevbest])
            j += 1
        repaired.append([tries, total, best])
        prevtries, prevtotal, prevbest = tries, total, best
        i += 1
    return repaired

def split(ip, n_fails=25):
    split_index = 0
    fails = 0
    prev_score = 0
    for point in ip:
        tries, total, best = point
        if total == prev_score:
            fails += 1
        else:
            prev_score = total
            fails = 0
        if fails >= n_fails:
            split_index = tries - 1
            break
    else:
        split_index = ip[-1][0] - 1
    first_half = ip[:split_index]
    second_half = ip[split_index:]
    return first_half, second_half


def get_score(ip, n_fails):
    first, second = split(ip, n_fails)
    return first[-1][2]/ip[-1][2]

for alg in data:
    plt.title(alg)

    lines = []
    for problem_results in data[alg]:
        lines.append(problem_results["improvement_points"])



    all_scores = []
    for line in lines:
        line = repair_holes(line)
        scores = [[get_score(line, n)] for n in range(1, 200)]
        all_scores.append(scores)
    all_scores = np.mean(all_scores, axis=0)
    plt.plot(all_scores)

    """first, second = split(repair_holes(line), 5)
    adjust = first[0][2]
    xf = [l[0] for l in first]
    yf = [l[2] - adjust for l in first]
    xs = [l[0] - 1 for l in second]
    ys = [l[2] - adjust for l in second]
    plt.plot(xf, yf, "k", linewidth=.3)
    plt.plot(xs, ys, "r", linewidth=.3)"""

    plt.show()
