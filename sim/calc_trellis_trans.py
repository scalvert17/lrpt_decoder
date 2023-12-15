
def format_int(n, nbits):
  return '0b' + bin(n)[2:].zfill(nbits)

def count_ones(n):
  return bin(n).count('1') % 2


# TODO: there might be an issue here with g
def conv_calc(state, in_bit):
  # returns the output (i, q) for the given input state
  g1 = ((in_bit << 6) | state) & 0b1111001
  g2 = ((in_bit << 6) | state) & 0b1011011
  return (count_ones(g1),  count_ones(g2))

def acs_mod_sig(state_num, conv_calc_0, conv_calc_1, tran_bit, old_state_0, old_state_1):
  # BMU i is more significant
  return f"""acs_butterfly #(
    .TRANSITION_BIT({tran_bit}),
    .STATE_0(6'd{old_state_0}),
    .STATE_1(6'd{old_state_1})
  ) acs_{state_num} (
    .clk(clk),
    .sys_rst(sys_rst),
    .bm_0(met_out[{conv_calc_0[0] * 2 + conv_calc_0[1]}]),
    .bm_1(met_out[{conv_calc_1[0] * 2 + conv_calc_1[1]}]),
    .sm_0(sm_normal[{old_state_0}]),
    .sm_1(sm_normal[{old_state_1}]),
    .valid_in(valid_in),
    .desc(desc[{state_num}]),
    .valid_out(valid_out[{state_num}]),
    .sm_out(sm[{state_num}]),
    .prev_state(prev_state[{state_num}])
  );
  """

states = [x for x in range(2**6)]
state_to_trans = {}
for s in states:
  # want to add either a 0 or 1 to the end of s and remove the msb of s 
  s0 = (s << 1) & 0b111111
  s1 = ((s << 1) | 1) & 0b111111
  inp = s >> 5

  # s0_trans = (format_int(s0, 6), conv_calc(s0, inp), inp)
  # s1_trans = (format_int(s1, 6), conv_calc(s1, inp), inp)
  # state_to_trans[format_int(s, 6)] = [s0_trans, s1_trans]
  s0_trans = (s0, conv_calc(s0, inp), inp)
  s1_trans = (s1, conv_calc(s1, inp), inp)
  state_to_trans[s] = [s0_trans, s1_trans]


with open('acs_headers.txt', 'w') as f:
  for i in state_to_trans:
    # print(f'{i}  ::: {state_to_trans[i]}')
    old_state_0, conv_calc_0, inp = state_to_trans[i][0]
    old_state_1, conv_calc_1, inp = state_to_trans[i][1]
    
    f.write(acs_mod_sig(i,  conv_calc_0, conv_calc_1, inp, old_state_0, old_state_1))


