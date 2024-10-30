import time
import numpy
import array
import cv2

count = 6562 # number of frames
hRes = 1280
vRes = 800
# frameAlignment = 256
a = 1
binaryFileData = array.array('B')
# zeroArray = [0] * int(frameAlignment - vRes*hRes/8 - 2)

def binarize_image(img):
	binary = numpy.where(img == 255, 1, img)
	# binary = binary.flatten()

	binary = binary.tobytes()
	i = 0
	while i < hRes * vRes:
		lowerbyte = binary[i] * 128 + binary[i+1] * 64 + binary[i+2] * 32 + binary[i+3] * 16 + binary[i+4] * 8 + binary[i+5] * 4 + binary[i+6] * 2 + binary[i+7]
		i += 8
		upperbyte = binary[i] * 128 + binary[i+1] * 64 + binary[i+2] * 32 + binary[i+3] * 16 + binary[i+4] * 8 + binary[i+5] * 4 + binary[i+6] * 2 + binary[i+7]
		binaryFileData.append(upperbyte)
		binaryFileData.append(lowerbyte)
		i += 8

# alternate between zero and 1, starting at zero
# word for count, if max reached, set a max block then zero block then the remainder
def binarize_basicCompression(img):
	binary = numpy.where(img == 255, 1, 0)
	binary = binary.flatten()
	zeroCount = 0
	oneCount = 0
	isfirstblock = True
	size = 2**16

	for i in range(hRes * vRes):
		if((binary[i]).any() == 0):
			zeroCount += 1
			if(oneCount != 0):
				if(isfirstblock):
					isfirstblock = False
					setWordBlock(0)
				setWordBlock(oneCount)
				# remainder = oneCount % (size - 1)
				# for x in range(int(oneCount / (size - 1))):
				# 	setWordBlock(size - 1)
				# 	setWordBlock(0)
				# setWordBlock(remainder)
				oneCount = 0
		else:
			oneCount += 1
			if(zeroCount != 0):
				if(isfirstblock):
					isfirstblock = False
				setWordBlock(zeroCount)
				# remainder = zeroCount % (size - 1)
				# for x in range(int(zeroCount / (size - 1))):
				# 	setWordBlock(size - 1)
				# 	setWordBlock(0)
				# setWordBlock(remainder)
				zeroCount = 0
	if(zeroCount != 0):
		# remainder = zeroCount % (size - 1)
		# for x in range(int(zeroCount / (size - 1))):
		# 	setWordBlock(size - 1)
		# 	setWordBlock(0)
		setWordBlock(zeroCount)
	if(oneCount != 0):
		# remainder = oneCount % (size - 1)
		# for x in range(int(oneCount / (size - 1))):
		# 	setWordBlock(size - 1)
		# 	setWordBlock(0)
		setWordBlock(oneCount)

def setWordBlock(amount):
	blocks = divmod(amount, 2**16-1)
	if(blocks[0] != 0):
		for i in range(blocks[0]):
			binaryFileData.append(255)
			binaryFileData.append(255)
			binaryFileData.append(0)
			binaryFileData.append(0)
	if(blocks[1] != 0):
		upperbyte = blocks[1] >> 8
		lowerbyte = blocks[1] & 255
		binaryFileData.append(lowerbyte)
		binaryFileData.append(upperbyte)
	else:
		binaryFileData.append(0)
		binaryFileData.append(0)


# Main Loop
main_start = time.time()
while (a <= count):
	if a > 99:
		img = 'bad_apple_' + str(a) + '.png'
	elif a > 9:
		img = 'bad_apple_0' + str(a) + '.png'
	else:
		img = 'bad_apple_00' + str(a) + '.png'

	image = cv2.imread('../image_sequence/' + img, cv2.IMREAD_GRAYSCALE)
	resized = cv2.resize(image, (hRes, vRes))
	ret, bw_frame = cv2.threshold(resized, 180, 255, cv2.THRESH_BINARY)
	# binarize_image(bw_frame)
	binarize_basicCompression(bw_frame) # very slow
	# binaryFileData.extend(zeroArray)

	print('\rformatted frame: ' + str(a) + ' / ' + str(count), end='')
	a += 1

binaryFileData = binaryFileData.tobytes()
with open('../HDA_DRIVE/frame_data/frames_compressed.data', 'wb') as file:
	file.write(binaryFileData)

print('\nTotal Time: ' + str(time.time()-main_start))