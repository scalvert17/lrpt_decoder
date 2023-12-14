import serial
ser = serial.Serial(port="/dev/cu.usbserial-8874292300911", baudrate=115200, timeout=1, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE, bytesize=serial.EIGHTBITS)

# Read data form file
with open('bitstoragein.txt', 'wb') as f:
    info_to_send = f.readlines()

# Write data to serial port
if ser.isOpen():
    print('Serial is open, Sending data')
    ser.write(info_to_send)
    ser.close()
    print('Data sent')

# Receive data from serial port
ser.open()
if ser.isOpen():
    print('Serial is open, Receiving data')
    while True:
        line = ser.readline()
        if len(line) > 0:
            print(line)
            print('------------------\n')
            break
    ser.close()
    print('Data received')

# Write data to file
with open('bitstorageout.txt', 'wb') as f:
    f.write(line)



        