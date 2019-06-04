import sys

with open(sys.argv[1], "r") as file:
    data = file.read()

def try_round(x):
    try:
        return str(round(float(x), 2))
    except ValueError:
        return x.replace("_", "\\_")

data = data.split("\n")
data = [line.split(",") for line in data]
data = [list(map(try_round, line)) for line in data]

data = [",".join(line) for line in data]
data = "\n".join(data)
with open(sys.argv[2], "w") as file:
    file.write(data)
