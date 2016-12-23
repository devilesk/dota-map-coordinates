line_starts = []
line_ends = []
with open('data/dota.vmap.txt', 'r') as f:
    c = 0
    current_brace = 0
    start_buffer = False
    dump_buffer = False
    b = []
    save_next_closing_brace = False
    for line in f.readlines():
        if line.startswith('	"'):
            current = line
        if line.startswith('{'):
            current_brace = c
        if line == '		"CDmeDotaTileGrid"\n':
            print line
            start_buffer = True
        if start_buffer:
            b.append(line)
        if start_buffer and line.startswith('		}'):
            start_buffer = False
            if dump_buffer:
                with open('data/dota.vmap' + str(c) + 'b.txt', 'w') as g:
                    for l in b:
                        g.write(l)
                dump_buffer = False
            b = []
            print 'end'
        if line.startswith('}'):
            if save_next_closing_brace:
                line_ends.append(c)
                save_next_closing_brace = False
        if '"19244"' in line:
            print current, line
            line_starts.append(current_brace)
            save_next_closing_brace = True
            dump_buffer = True
        c = c + 1
print line_starts, line_ends
print 'done'
