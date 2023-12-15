def shift_list_one(lis, dir):
    if dir == 'right':
        out_list = [0] + lis[0:7]
    else:
        out_list = lis[1:8] + [0]
    return out_list

state = [1, 1, 1, 1, 1, 1, 1, 1]  #0 -> 7
noise = [0, 0, 0, 0, 0, 0, 0, 0]
out = []

for i in range(40):
    out.append(state[0])
    newbit = (state[7] & 1) ^ (state[5] & 1) ^ (state[3] & 1) ^ (state[0] & 1)

    state = (shift_list_one(state, 'left'))
    state[7] = newbit
print(out)

""" 
for i in range(8):
    #taps: 8 7 5 3;  feedback polynomial: x^8 + x^7 + x^5 + x^3 + 1
    noise = [0, 0, 0, 0, 0, 0, 0, 0]

    for j in range(8):
        newbit = (state[7] & 1) ^ (state[5] & 1) ^ (state[3] & 1) ^ (state[0] & 1)

        noise = shift_list_one(noise, 'right')
        noise[0] = (noise[0] | (state[0] & 1))

        state = (shift_list_one(state, 'left'))
        state[7] = newbit

    print(f'i: {i}    noise: {list(reversed(noise))}     state: {list(reversed(state))}    newbit: {newbit}')
 """
