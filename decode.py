#!/usr/bin/env python

for line in open('home.txt', 'r'):
    print(line).decode('unicode_escape').encode('utf-8')