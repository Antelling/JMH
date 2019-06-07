from sklearn.decomposition import PCA as decomp
from sklearn.preprocessing import MinMaxScaler
from matplotlib import pyplot as plt
import json, sys

name = sys.argv[1]

with open(name + ".json", "r") as file:
    data = file.read()
    X, y = json.loads(data)

X_dec = decomp().fit_transform(X)

X_dec_x = [x[0] for x in X_dec]
X_dec_y = [x[1] for x in X_dec]

y = MinMaxScaler().fit_transform(y)
y = [a[0] for a in y]
plt.scatter(X_dec_x, X_dec_y, c=y, cmap="OrRd")

plt.title(name)
plt.savefig("article/graphs/" + name + "__pca.png")
