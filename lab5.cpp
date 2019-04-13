#include <iostream>
#pragma inline


using namespace std;

void main() {

	float ten = 10;
	float* array = new float[10];
	float buffer;
	float result = 0;
	for (int i = 0; i < 10; i++) {
		do {
			std::cout << "Enter float number(array[" << i << "]) : ";
			std::cin >> buffer;
			if (std::cin.good()) {
				array[i] = buffer;
				break;
			}
			else {
				rewind(stdin);
				std::cin.clear();
			}
		} while (true);	
	}

	_asm {
		xor ecx, ecx
		mov cx, 10
		finit
		mov eax, array
		fld ten
		fld result
		start:
			fadd [eax]
			add eax, 4
			cmp cx, 0
			dec cx
			jnz start

			fdiv st(0),st(1)
			fst result
				
			fwait
	}


	cout << result;
	system("pause");
}