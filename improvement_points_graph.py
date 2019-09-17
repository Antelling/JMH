import json
from matplotlib import pyplot as plt
from sklearn.preprocessing import MinMaxScaler

with open("test_data.json", "r") as file:
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
    split_index = max(split_index, 1)
    first_half = ip[:split_index]
    second_half = ip[split_index:]
    print(split_index)
    return first_half, second_half


algs = ["jaya[VND]"]
for alg in algs:
    plt.title(alg)

    lines = []
    for problem_results in data[alg]:
        lines.append(problem_results["improvement_points"])

    for line in lines:
        first, second = split(repair_holes(line))
        adjust = first[0][1]
        xf = [l[0] for l in first]
        yf = [l[1] - adjust for l in first]
        xs = [l[0] for l in second]
        ys = [l[1] - adjust for l in second]
        plt.plot(xf, yf, "k", linewidth=.3)
        plt.plot(xs, ys, "r", linewidth=.3)

    plt.show()
