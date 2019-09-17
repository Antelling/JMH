import json
from matplotlib import pyplot as plt
from sklearn.preprocessing import MinMaxScaler

with open("test_data.json", "r") as file:
    data = file.read()
    data = json.loads(data)

for alg in data:
    plt.title(alg)

    lines = []
    for problem_results in data[alg]:
        lines.append(problem_results["improvement_points"])

    for line in lines:
        x = [l[0] for l in line]
        y = MinMaxScaler().fit_transform([[l[1]] for l in line])
        plt.plot(x, y)

    plt.show()
