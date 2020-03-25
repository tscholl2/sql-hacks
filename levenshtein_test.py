import Levenshtein
import tqdm

import random
import sqlite3

s = "gatc"
with open("levenshtein.sql") as f:
    cmd = f.read()
conn = sqlite3.connect(':memory:')
c = conn.cursor()

for _ in tqdm.trange(100):
    w1 = "".join(random.choices(s,k=random.randint(1,25)))
    w2 = "".join(random.choices(s,k=random.randint(1,25)))
    d = Levenshtein.distance(w1,w2)
    c.execute(cmd.replace('"zxy"',f'"{w1}"').replace('"abcdefghij"',f'"{w2}"'))
    dd = c.fetchone()[0]
    assert d == dd, f"d({w1},{w2}) != {d} (got {dd})"
