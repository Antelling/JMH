import json
def get_lengths(obj):
    lengths = [len(i) for i in obj]
    ldict = {}
    for n in lengths:
        if n in ldict:
            ldict[n]+=1
        else:
            ldict[n] = 1
    tuples = []
    for key in ldict:
        tuples.append([key, ldict[key]])

    tuples.sort(key=lambda x: -x[0])
    return tuples

files = range(1, 10)
for file in files:
    filename = f"beasley_mdmkp_datasets/{file}_pop180_ls_decimated.json"
    data = json.loads(open(filename).read())
    print(file, ": ", get_lengths(data))
