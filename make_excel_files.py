import xlsxwriter
import json, os
from numpy import mean, median

workbook = xlsxwriter.Workbook('results.xlsx')
worksheet1 = workbook.add_worksheet()
worksheet2 = workbook.add_worksheet()

i = 0
j = 0
optimals = json.loads(open("beasley_mdmkp_datasets/optimal.json", "r").read())

full_files = [
    ("1__2019-05-13.json", "1"),
    ("1_manhattan_diversity__2019-05-13.json", "1"),
    ("2__2019-05-13.json", "2"),
    ("4__2019-05-13.json", "4"),
    ("1_useful_algs_only__2019-05-13.json", "1")
]

def wrong_results(worksheet, files):
    i = 0
    j = 0
    for file, ds in files:
        results = json.loads(open("results/" + file, "r").read())
        worksheet.write(i, j, str(file))
        i+=1
        for p in range(6):
            worksheet.write(i, j, "case " + str(1+p))
            mask = list(range(p, 90, 6))
            opts = [optimals[ds][m] for m in mask]
            for k in range(len(opts)):
                worksheet.write(i+2+k, j, opts[k])
            worksheet.write(i+1, j, "CNET scores")
            worksheet.write(i+1, j+1, "1st best found score")
            worksheet.write(i+1, j+2, "1st best bitstring")
            worksheet.write(i+1, j+3, "2nd best found score")
            worksheet.write(i+1, j+4, "2nd best bitstring")
            worksheet.write(i+1, j+5, "3rd best found score")
            worksheet.write(i+1, j+6, "3rd best bitstring")
            worksheet.write(i+1, j+7, "4th best found score")
            worksheet.write(i+1, j+8, "4th best bitstring")
            for (k, m) in enumerate(mask):
                scores = []
                for alg in results:
                    scores.append((results[alg][m][0], results[alg][m][3]))
                scores.sort(key=lambda i: i[0])
                worksheet.write(i+2+k, j+1, scores[0][0])
                worksheet.write(i+2+k, j+2, scores[0][1])
                worksheet.write(i+2+k, j+3, scores[1][0])
                worksheet.write(i+2+k, j+4, scores[1][1])
                worksheet.write(i+2+k, j+5, scores[2][0])
                worksheet.write(i+2+k, j+6, scores[2][1])
                worksheet.write(i+2+k, j+7, scores[3][0])
                worksheet.write(i+2+k, j+8, scores[3][1])
            i += 18
        j += 10

def full_results(worksheet, files):
    i = 0
    j = 0
    for file, ds in files:
        results = json.loads(open("results/" + file, "r").read())
        worksheet.write(i, j, str(file))
        i+=1
        for p in range(6):
            worksheet.write(i, j, "case " + str(1+p))
            i+=1
            mask = list(range(p, 90, 6))
            opts = [optimals[ds][m] for m in mask]
            for k in range(len(opts)):
                worksheet.write(i+2+k, j, opts[k])
            worksheet.write(i+1, j, "optimal scores")
            j += 2
            for alg in results:
                worksheet.write(i, j, str(alg))
                data = [results[alg][m] for m in mask]

                worksheet.write(i+1, j, "best score")
                worksheet.write(i+1, j+1, "percentage difference")
                worksheet.write(i+1, j+2, "median time")
                worksheet.write(i+1, j+3, "swarm diversity")
                worksheet.write(i+1, j+4, "best found bitstring")
                percentages = []
                scores = []
                diversities = []
                times = []
                for k in range(len(data)):
                    worksheet.write(i+2+k, j, data[k][0])
                    scores.append(data[k][0])
                    percent = 0 if opts[k] == 0 else 100*((opts[k]-data[k][0])/opts[k])
                    worksheet.write(i+2+k, j+1, percent)
                    percentages.append(percent)
                    worksheet.write(i+2+k, j+2, data[k][1])
                    times.append(data[k][1])
                    worksheet.write(i+2+k, j+3, data[k][2])
                    diversities.append(data[k][2])
                    worksheet.write(i+2+k, j+4, data[k][3])
                worksheet.write(i+2+len(data)+1, j-1, "averages:")
                worksheet.write(i+2+len(data)+1, j, mean(scores))
                worksheet.write(i+2+len(data)+1, j+1, mean(percentages))
                worksheet.write(i+2+len(data)+1, j+2, median(times))
                worksheet.write(i+2+len(data)+1, j+3, mean(diversities))
                j+= 8
            j += len(results.keys()) + 2
        i += 18
        j = 0


wrong_results(worksheet1, [("7_useful_algs_only__2019-05-14.json", "7")])
full_results(worksheet2, full_files)


workbook.close()
