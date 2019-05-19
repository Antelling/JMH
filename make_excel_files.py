import xlsxwriter
import json, os
from numpy import mean, median

workbook = xlsxwriter.Workbook('four_hybrids.xlsx')
worksheet1 = workbook.add_worksheet("Broken Optimals")
worksheet2 = workbook.add_worksheet("Hybrid Full Results")
worksheet3 = workbook.add_worksheet("Hybrid Percentage Summary")
worksheet4 = workbook.add_worksheet("Solo Full Results")
worksheet5 = workbook.add_worksheet("Solo Percentage Summary")
worksheet6 = workbook.add_worksheet("GA Percentage Summary")

negative_format = workbook.add_format({'bg_color': 'green'})
normal_format = workbook.add_format({})
bitstring_format = workbook.add_format({'shrink': True, 'font_color': 'gray'})
title_format = workbook.add_format({'bold': True})

i = 0
j = 0
optimals = json.loads(open("beasley_mdmkp_datasets/optimal.json", "r").read())

hybrid_files = [
    ("1_four_hybrids__2019-05-15.json", "1"),
    ("2_four_hybrids__2019-05-15.json", "2"),
    ("3_four_hybrids__2019-05-15.json", "3"),
    ("4_four_hybrids__2019-05-15.json", "4"),
    ("5_four_hybrids__2019-05-15.json", "5"),
    ("6_four_hybrids__2019-05-16.json", "6"),
    ("7_four_hybrids__2019-05-16.json", "7"),
    ("8_four_hybrids__2019-05-16.json", "8"),
    ("9_four_hybrids__2019-05-17.json", "9"),
]

files_with_broken_optimals = [
    ("7_four_hybrids__2019-05-16.json", "7"),
    ("8_four_hybrids__2019-05-16.json", "8"),
    ("9_four_hybrids__2019-05-17.json", "9"),
]

solo_files = [
    ("11_solo_metaheuristics__2019-05-18.json", "1"),
    ("21_solo_metaheuristics__2019-05-18.json", "2"),
    ("31_solo_metaheuristics__2019-05-18.json", "2"),
    ("41_solo_metaheuristics__2019-05-18.json", "2"),
]

ga_test = [
    ("1_GA_parents_test__2019-05-18.json", "1"),
    ("2_GA_parents_test__2019-05-18.json", "2"),
    ("3_GA_parents_test__2019-05-18.json", "3"),
    ("4_GA_parents_test__2019-05-18.json", "4"),
]

def only_percentages(worksheet, files):
    i = 0
    j = 0
    for file, ds in files:
        results = json.loads(open("results/" + file, "r").read())
        worksheet.write(i, j, str(file), title_format)
        i+=1
        alg_case_results = {}
        for p in range(6):
            worksheet.write(i, j, "case " + str(1+p), title_format)
            mask = list(range(p, 90, 6))
            opts = [optimals[ds][m] for m in mask]
            for alg in results:
                worksheet.write(i+1, j, str(alg), title_format)
                data = [results[alg][m] for m in mask]

                percentages = []
                for k in range(len(data)):
                    percent = 0 if opts[k] == 0 else 100*((opts[k]-data[k][0])/opts[k])
                    worksheet.write(i+2+k, j, percent)
                    percentages.append(percent)
                worksheet.write(i+2+len(data)+1, j, mean(percentages), title_format)
                if not alg in alg_case_results:
                    alg_case_results[alg] = []
                alg_case_results[alg].append(mean(percentages))
                j+= 1
            j += 1

        i += 22
        j = 0

        sortable = []
        for (key, val) in alg_case_results.items():
            sortable.append((key, val))
        sortable.sort(key=lambda x: mean(x[1]))

        for case in range(1, 7):
            worksheet.write(i-1, j+case, "case " + str(case), title_format)
        worksheet.write(i-1, j+7, "average", title_format)
        worksheet.write(i-1, j+8, "sparkline", title_format)
        for (alg, results) in sortable:
            worksheet.write(i, j, alg, title_format)
            for (k, result) in enumerate(results):
                worksheet.write(i, j+k+1, result)
            worksheet.write(i, j+7, mean(results))
            worksheet.add_sparkline(i, j+8, {'range': 'B' + str(i+1) + ':G' + str(i+1), 'type': 'column'})
            i+= 1
        i+= 5

def wrong_results(worksheet, files):
    i = 0
    j = 0

    for file, ds in files:
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


wrong_results(worksheet1, files_with_broken_optimals)
only_percentages(worksheet3, hybrid_files)
full_results(worksheet2, hybrid_files)
full_results(worksheet4, solo_files)
only_percentages(worksheet5, solo_files)
only_percentages(worksheet6, ga_test)

workbook.close()
