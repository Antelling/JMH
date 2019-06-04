import xlsxwriter
import json, os
from numpy import mean, median

workbook = xlsxwriter.Workbook('partial_results.xlsx')


negative_format = workbook.add_format({'bg_color': 'green'})
normal_format = workbook.add_format({})
bitstring_format = workbook.add_format({'shrink': True, 'font_color': 'gray'})
title_format = workbook.add_format({'bold': True})

i = 0
j = 0
optimals = json.loads(open("beasley_mdmkp_datasets/optimal.json", "r").read())

def only_percentages(worksheet, files):
    i = 0
    j = 0

    complete_total = {}
    complete_total["percentages"] = {}
    complete_total["times"] = {}
    complete_total["diversities"] = {}

    for file, ds in files:
        print("making: " + file)
        results = json.loads(open("results/" + file, "r").read())
        worksheet.write(i, j, str(file), title_format)
        i+=1
        alg_percentage_results = {}
        alg_time_results = {}
        alg_diversity_results = {}
        for p in range(6):
            worksheet.write(i, j, "case " + str(1+p), title_format)
            mask = list(range(p, 90, 6))
            opts = [optimals[ds][m] for m in mask]
            for alg in results:
                worksheet.write(i+1, j, str(alg), title_format)
                data = [results[alg][m] for m in mask]

                percentages = []
                times = []
                diversities = []
                for k in range(len(data)):
                    percent = 0 if opts[k] == 0 else 100*((opts[k]-data[k][0])/opts[k])
                    worksheet.write(i+2+k, j, percent)
                    percentages.append(percent)
                    times.append(data[k][1])
                    diversities.append(data[k][2])
                worksheet.write(i+2+len(data)+1, j, mean(percentages), title_format)
                if not alg in alg_percentage_results:
                    alg_percentage_results[alg] = []
                    alg_time_results[alg] = []
                    alg_diversity_results[alg] = []
                alg_percentage_results[alg].append(mean(percentages))
                alg_time_results[alg].append(mean(times))
                alg_diversity_results[alg].append(mean(diversities))
                j+= 1
            j += 1

        i += 22
        j = 0

        for (name, data) in [("percentages", alg_percentage_results),
                ("times", alg_time_results), ("diversities", alg_diversity_results)]:
            sortable = []
            for (key, val) in data.items():
                sortable.append((key, val))
            sortable.sort(key=lambda x: mean(x[1]))

            worksheet.write(i-1, j, name, title_format)
            for case in range(1, 7):
                worksheet.write(i-1, j+case, "case " + str(case), title_format)
            worksheet.write(i-1, j+7, "average", title_format)
            # worksheet.write(i-1, j+8, "sparkline", title_format)
            old_i = i
            for (alg, results) in sortable:
                worksheet.write(i, j, alg, title_format)
                for (k, result) in enumerate(results):
                    worksheet.write(i, j+k+1, result)
                worksheet.write(i, j+7, mean(results))
                if not (alg in complete_total[name]):
                    complete_total[name][alg] = []
                complete_total[name][alg].append(mean(results))
                # worksheet.add_sparkline(i, j+8, {'range': 'B' + str(i+1) + ':G' + str(i+1), 'type': 'column'})
                i+= 1
            j += 10
            i = old_i
        i+= len(alg_time_results.keys())+2
        j = 0

    i += 2
    for element in ["percentages", "times", "diversities"]:
        sortable = []
        for alg in complete_total[element]:
            sortable.append((alg, complete_total[element][alg]))
        sortable.sort(key=lambda x: mean(x[1]))

        worksheet.write(i-1, j, "complete " + element, title_format)
        for case in range(1, 10):
            worksheet.write(i-1, j+case, "dataset " + str(case), title_format)
        worksheet.write(i-1, j+10, "average", title_format)
        # worksheet.write(i-1, j+8, "sparkline", title_format)
        old_i = i
        for (alg, results) in sortable:
            worksheet.write(i, j, alg, title_format)
            for (k, result) in enumerate(results):
                worksheet.write(i, j+k+1, result)
            worksheet.write(i, j+10, mean(results))
            # worksheet.add_sparkline(i, j+8, {'range': 'B' + str(i+1) + ':G' + str(i+1), 'type': 'column'})
            i+= 1
        j += 12
        i = old_i

def wrong_results(worksheet, files):
    i = 0
    j = 0

    for file, ds in files:
        print("making: " + file)
        results = json.loads(open("results/" + file, "r").read())
        worksheet.write(i, j, str(file), title_format)
        i+=1
        for p in range(6):
            worksheet.write(i, j, "case " + str(1+p))
            mask = list(range(p, 90, 6))
            opts = [optimals[ds][m] for m in mask]
            for k in range(len(opts)):
                worksheet.write(i+2+k, j, opts[k])
            worksheet.write(i+1, j, "CPLEX scores")
            worksheet.write(i+1, j+1, "1st best found score")
            worksheet.write(i+1, j+2, "1st best bitstring")
            worksheet.write(i+1, j+3, "2nd best found score")
            worksheet.write(i+1, j+4, "2nd best bitstring")
            worksheet.write(i+1, j+5, "3rd best found score")
            worksheet.write(i+1, j+6, "3rd best bitstring")
            # worksheet.write(i+1, j+7, "4th best found score")
            # worksheet.write(i+1, j+8, "4th best bitstring")
            for (k, m) in enumerate(mask):
                scores = []
                for alg in results:
                    scores.append((results[alg][m][0], results[alg][m][3]))
                scores.sort(key=lambda i: -i[0])
                worksheet.write(i+2+k, j+1, scores[0][0], negative_format if scores[0][0] > opts[k] else normal_format)
                worksheet.write(i+2+k, j+2, scores[0][1], bitstring_format)
                worksheet.write(i+2+k, j+3, scores[1][0], negative_format if scores[0][0] > opts[k] else normal_format)
                worksheet.write(i+2+k, j+4, scores[1][1], bitstring_format)
                worksheet.write(i+2+k, j+5, scores[2][0], negative_format if scores[0][0] > opts[k] else normal_format)
                worksheet.write(i+2+k, j+6, scores[2][1], bitstring_format)
            i += 18
        i += 2

    w = 18
    worksheet.set_column(0, 0, 12)
    for x in range(1, 7):
        worksheet.set_column(x, x, w)

def full_results(worksheet, files):
    i = 0
    j = 0
    for file, ds in files:
        print("making: " + file)
        results = json.loads(open("results/" + file, "r").read())
        worksheet.write(i, j, str(file), title_format)
        i+=1
        for p in range(6):
            worksheet.write(i, j, "case " + str(1+p), title_format)
            i+=1
            mask = list(range(p, 90, 6))
            opts = [optimals[ds][m] for m in mask]
            for k in range(len(opts)):
                worksheet.write(i+2+k, j, opts[k])
            worksheet.write(i+1, j, "optimal scores")
            j += 2
            for alg in results:
                worksheet.write(i, j, str(alg), title_format)
                data = [results[alg][m] for m in mask]

                worksheet.write(i+1, j, "best score")
                worksheet.write(i+1, j+1, "percentage difference")
                worksheet.write(i+1, j+2, "median time")
                worksheet.write(i+1, j+3, "swarm diversity")
                worksheet.write(i+1, j+4, "bitstring")
                percentages = []
                scores = []
                diversities = []
                times = []
                for k in range(len(data)):
                    worksheet.write(i+2+k, j, data[k][0])
                    scores.append(data[k][0])
                    percent = 0 if opts[k] == 0 else 100*((opts[k]-data[k][0])/opts[k])
                    worksheet.write(i+2+k, j+1, percent, negative_format if percent < 0 else normal_format)
                    percentages.append(percent)
                    worksheet.write(i+2+k, j+2, data[k][1])
                    times.append(data[k][1])
                    worksheet.write(i+2+k, j+3, data[k][2])
                    diversities.append(data[k][2])
                    worksheet.write(i+2+k, j+4, data[k][3], bitstring_format)
                worksheet.write(i+2+len(data)+1, j-1, "averages:", title_format)
                worksheet.write(i+2+len(data)+1, j, mean(scores))
                worksheet.write(i+2+len(data)+1, j+1, mean(percentages))
                worksheet.write(i+2+len(data)+1, j+2, median(times))
                worksheet.write(i+2+len(data)+1, j+3, mean(diversities))
                j+= 6
            j += 2
        i += 18
        j = 0

hybrid_files = [
    ("hybrid_60s/1_2019-05-26.json", "1"),
    ("hybrid_60s/2_2019-05-26.json", "2"),
    ("hybrid_60s/3_2019-05-26.json", "3"),
    ("hybrid_60s/4_2019-05-26.json", "4"),
    ("hybrid_60s/5_2019-05-26.json", "5"),
    ("hybrid_60s/6_2019-05-26.json", "6"),
    ("hybrid_60s/7_2019-05-27.json", "7"),
    ("hybrid_60s/8_2019-05-28.json", "8"),
    ("hybrid_60s/9_2019-05-28.json", "9")

]

solo_10s_files = [
    ("solo_10s/1_2019-05-25.json", "1"),
    ("solo_10s/2_2019-05-25.json", "2"),
    ("solo_10s/3_2019-05-25.json", "3"),
    ("solo_10s/4_2019-05-25.json", "4"),
    ("solo_10s/5_2019-05-25.json", "5"),
    ("solo_10s/6_2019-05-26.json", "6"),
    ("solo_10s/7_2019-05-26.json", "7"),
    ("solo_10s/8_2019-05-27.json", "8"),
    ("solo_10s/9_2019-05-27.json", "9"),
]

solo_60s_files = [
    ("solo_60s/1_2019-05-25.json", "1"),
    ("solo_60s/2_2019-05-25.json", "2"),
    ("solo_60s/3_2019-05-26.json", "3"),
    ("solo_60s/4_2019-05-26.json", "4"),
    ("solo_60s/5_2019-05-26.json", "5"),
    ("solo_60s/6_2019-05-27.json", "6"),
    ("solo_60s/7_2019-05-27.json", "7"),
    ("solo_60s/8_2019-05-28.json", "8"),
    ("solo_60s/9_2019-05-29.json", "9"),
]

Brok = workbook.add_worksheet("Wrong Optimals")
HybFulRes = workbook.add_worksheet("Hybrid 60s Results")
HybSum = workbook.add_worksheet("Hybrid 60s Summary")
SolFulRes60 = workbook.add_worksheet("Solo 60s Results")
SolSum60 = workbook.add_worksheet("Solo 60s Summary")
SolFulRes10 = workbook.add_worksheet("Solo 10s Results")
SolSum10 = workbook.add_worksheet("Solo 10s Summary")

wrong_results(Brok, [hybrid_files[4], hybrid_files[6], hybrid_files[7], hybrid_files[8]])
only_percentages(HybSum, hybrid_files)
full_results(HybFulRes, hybrid_files)
only_percentages(SolSum10, solo_10s_files)
full_results(SolFulRes10, solo_10s_files)
only_percentages(SolSum60, solo_60s_files)
full_results(SolFulRes60, solo_60s_files)

workbook.close()
