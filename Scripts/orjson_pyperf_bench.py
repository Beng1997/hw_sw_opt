#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# orjson_pyperf_bench.py - apples-to-apples orjson.dumps using the official pyperformance payload

import sys
import pyperf
import orjson

# Official pyperformance payload definitions
EMPTY = ({}, 2000)
SIMPLE_DATA = {'key1': 0, 'key2': True, 'key3': 'value', 'key4': 'foo',
               'key5': 'string'}
SIMPLE = (SIMPLE_DATA, 1000)
NESTED_DATA = {'key1': 0, 'key2': SIMPLE[0], 'key3': 'value', 'key4': SIMPLE[0],
               'key5': SIMPLE[0], 'key': '\\u0105\\u0107\\u017c'}
NESTED = (NESTED_DATA, 1000)
HUGE = ([NESTED[0]] * 1000, 1)

CASES = ['EMPTY', 'SIMPLE', 'NESTED', 'HUGE']

def get_data(selected=None):
    """
    Return a list of (obj, range(count)) tuples matching pyperformance's logic.
    If selected is None, use all CASES.
    """
    if selected is None:
        selected = CASES
    data = []
    g = globals()
    for name in selected:
        obj, count = g[name]
        data.append((obj, range(count)))
    return data

def add_cmdline_args(cmd, args):
    if args.cases:
        cmd.extend(("--cases", args.cases))

def main():
    runner = pyperf.Runner(add_cmdline_args=add_cmdline_args)
    runner.argparser.add_argument("--cases",
                                  help="Comma separated list of cases. Available cases: %s. By default, run all cases." % ', '.join(CASES))
    runner.metadata['description'] = "Benchmark orjson.dumps() apples-to-apples with pyperformance payload"

    args = runner.parse_args()
    if args.cases:
        cases = [case.strip() for case in args.cases.split(',') if case.strip()]
        if not cases:
            print("ERROR: empty list of cases")
            sys.exit(1)
    else:
        cases = CASES

    data = get_data(cases)

    def bench():
        for obj, count_it in data:
            for _ in count_it:
                orjson.dumps(obj)

    runner.bench_func('orjson_dumps', bench)

if __name__ == '__main__':
    main()