import Levenshtein
import tqdm

import random
import sqlite3

with open("split.sql") as f:
    cmd = f.read()
conn = sqlite3.connect(':memory:')
c = conn.cursor()

for _ in tqdm.trange(100):
    s = "".join(random.choices("abcd ", k=random.randint(1, 100)))
    result = [row[0] for row in c.execute(cmd.replace("hello world", s))]
    expected = [x for x in s.strip().split(" ") if x]
    assert len(expected) == len(result) and all(a == b for a, b in zip(result, expected)), \
        f"expect {expected} got {result}"
