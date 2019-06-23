filename = "results/aaa/3.json"
import json
data = json.loads(open(filename, "r").read())
data["LBO_ls"] = [a for i, a in enumerate(data["LBO_ls"]) if i%2==0]
file = open(filename, "w")
file.write(json.dumps(data))
file.close()
