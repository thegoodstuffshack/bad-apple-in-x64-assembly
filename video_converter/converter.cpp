#include <iostream>
#include <string>
#include <fstream>
#include <chrono>
#include <vector>
#include "opencv2/core.hpp"
#include "opencv2/imgproc.hpp"
#include "opencv2/imgcodecs.hpp"

#define NUMBER_OF_FRAMES 6562
#define RESIZED_W 640
#define RESIZED_H 400
#define INPUTFOLDER "../../image_sequence/bad_apple_"
#define OUTPUTFOLDER "../CompressedFrameData.bin"


void setBlock(unsigned int num, std::vector<char> *buffer, unsigned int isLastBlock) {
	div_t blocks = div(num, 65536 - 1);
	for (;blocks.quot > 0; blocks.quot--) {
		buffer->push_back((char)0xFF);
		buffer->push_back((char)0xFF);
		if (isLastBlock == 0 || (isLastBlock == 1 && blocks.rem != 0)) {
			buffer->push_back((char)0);
			buffer->push_back((char)0);
		}
	}
	if (blocks.rem != 0) {
		buffer->push_back((char)(blocks.rem & 255));
		buffer->push_back((char)(blocks.rem >> 8));
	}
	else if (isLastBlock == 0) {
		buffer->push_back((char)0);
		buffer->push_back((char)0);
	}
}

// first block is always zero, one and zero blocks alternate
void compressFrame(unsigned char *frame, std::vector<char> *buffer) {
	unsigned int isFirstBlock = 0;
	unsigned int zeroCount = 0;
	unsigned int oneCount = 0;
	for(unsigned int i = 0; i < RESIZED_W * RESIZED_H; i++) {
		unsigned char pixel = frame[i];
		if (pixel == 0) {
			zeroCount++;
			if (oneCount != 0) {
				if (isFirstBlock == 0) { isFirstBlock = 1;  setBlock(0, buffer, 0); }
				setBlock(oneCount, buffer, 0); 
				oneCount = 0; 
			}
		}
		else if (pixel == 255) {
			oneCount++;
			if (zeroCount != 0) { 
				if (isFirstBlock == 0) { isFirstBlock = 1; }
				setBlock(zeroCount, buffer, 0);
				zeroCount = 0; 
			}
		}
		else std::cout << "frame not b and w" << std::endl;
	}
	if (zeroCount != 0) { setBlock(zeroCount, buffer, 1); }
	else if (oneCount != 0) { setBlock(oneCount, buffer, 1); }
}

int main(int argc, char** argv) {
	std::ofstream outputFile(OUTPUTFOLDER, std::ios::binary);

	cv::Mat baseFrame;
	cv::Mat resizedFrame;
	cv::Mat bwFrame;

	std::chrono::time_point time = std::chrono::system_clock::now();

	for(unsigned int count = 1; count <= NUMBER_OF_FRAMES; count++) {
		std::string file = INPUTFOLDER;

		if (count > 99) {}
		else if (count > 9) {file += "0";}
		else {file += "00";}
		file += std::to_string(count) + ".png";

		baseFrame = cv::imread(file, cv::ImreadModes::IMREAD_GRAYSCALE);
		cv::resize(baseFrame, resizedFrame, cv::Size (RESIZED_W, RESIZED_H), 0, 0, cv::InterpolationFlags::INTER_AREA);
		cv::threshold(resizedFrame, bwFrame, 175, 255, cv::THRESH_BINARY);

		std::vector<char> buffer;
		compressFrame(bwFrame.data, &buffer);
		for (int i = 0; i < buffer.size(); i++) {
			outputFile << buffer[i];
		}

		if (count % 1000 == 0) {
			std::cout << std::chrono::duration_cast<std::chrono::milliseconds> (std::chrono::system_clock::now() - time).count() << std::endl;
			time = std::chrono::system_clock::now();
		}
	}

	baseFrame.release();
	resizedFrame.release();
	bwFrame.release();
	outputFile.close();
	return 0;
}
