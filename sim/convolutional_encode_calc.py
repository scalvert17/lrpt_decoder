import random
random.seed(10)
def conv_calc(state, in_bit):
  # returns the output (i, q) for the given input state
  g1 = ((in_bit << 6) | state) & 0b1111001
  g2 = ((in_bit << 6) | state) & 0b1011011
  return (count_ones(g1),  count_ones(g2))

def count_ones(n):
  return bin(n).count('1') % 2

def display_output(bit_len, output):
    out = ""
    for o in output:
        if o:
            out = f"7F" + out
        else:
            out = f"80"  + out
    out = f"{bit_len}'h" + out
    return out

state = 0b000000
inps = []
output = []
states = []
steps = 200
for _ in range(steps): 
    inp = random.choice([0b1, 0b0])
    inps.append(inp)
    output.extend(conv_calc(state, inp))
    state = (state >> 1) | (inp << 5)
    states.append(state)
print(inps)
print(output)


print(display_output(8*2*steps, output))



