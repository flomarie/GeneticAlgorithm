.686
.model flat

.data
	T db 12

    .code 
extern SYSTEM_$$_RANDOM$LONGINT$$LONGINT:near
extern FUNCTIONS_$$_COMPARE$SINGLE$SINGLE$$LONGINT:near

public single_point_crossing
public random_bit_change
public merge


M equ 16
                   
                   
single_point_crossing proc
    push ebp
    mov ebp, esp
			; eax part11
    push ebx; part12
    push ecx; part21
    push edx; part22
    push edi
    push esi
    
    mov edi, [ebp + 12];parent2
    mov esi, [ebp + 8];parent1
    
    mov eax, M
    call SYSTEM_$$_RANDOM$LONGINT$$LONGINT
    mov ecx, eax
    
    mov eax, esi
    shr eax, cl
    shl eax, cl
    
    sub cl, M
    neg cl
    
    mov ebx, edi
    shl ebx, cl
    shr ebx, cl
    
    or eax, ebx
    
    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret 2*4
single_point_crossing endp


random_bit_change proc
    push ebp
    mov ebp, esp
    push edi
    
    mov eax, M
    call SYSTEM_$$_RANDOM$LONGINT$$LONGINT
    mov cl, al
    mov edi, [ebp + 8]
    
    mov ebx, 1
    shl ebx, cl
    xor ebx, edi
    mov edi, ebx
    
    mov eax, edi
    
    pop edi
    pop ebp
    ret 4  
random_bit_change endp


merge proc
    push ebp
    mov ebp, esp
    push eax;-4
    push ebx;-8
    push ecx;-12
    push edx;-16
    push esi;-20
    push edi;-24
    
    right equ dword ptr [ebp + 16]
    left equ dword ptr [ebp + 12]
    
    mov eax, right
    sub eax, left 
    inc eax
    mul T;
    
    sub esp, 4
    sub esp, eax
    middle equ dword ptr [ebp - 28]
    res equ dword ptr [ebp - 32];временный массив
    
    mov eax, right
    add eax, left
    shr eax, 1
    mov middle, eax
    
    i equ ebx
    j equ ecx
    
    mov i, left
    mov j, middle
    inc j
    k equ edx
    mov k, ebp
    sub k, 32
    
Cycle:
    cmp i, middle
    ja CycleI
    cmp j, right
    ja CycleI
    
    mov eax, i
    mul T
    mov esi, eax
    add esi, [ebp + 8]; i * 12 + адрес начала
	
	
	mov eax, j
	mul T
	mov edi, eax
    add edi, [ebp + 8]; j * 12 + адрес начала
    
    push dword ptr [esi + 8]
    push dword ptr [edi + 8]
    call FUNCTIONS_$$_COMPARE$SINGLE$SINGLE$$LONGINT
    cmp eax, 0
    je L1
    
    mov eax, dword ptr [esi]
    mov [k], eax
    mov eax, dword ptr [esi + 4]
    mov [k - 4], eax
    mov eax, dword ptr [esi + 8]
    mov [k - 8], eax
    inc i
    jmp Cont
     
L1: 
	mov eax, dword ptr [edi]
    mov [k], eax
    mov eax, dword ptr [edi + 4]
    mov [k - 4], eax
    mov eax, dword ptr [edi + 8]
    mov [k - 8], eax
    inc j
Cont:
    sub k, 12
    jmp Cycle


CycleI:
    cmp i, middle
    ja CycleJ
    mov eax, i
    mul T
    mov esi, eax
    add esi, dword ptr [ebp + 8]
    mov eax, [esi]
    mov [k], eax
    mov eax, dword ptr [esi + 4]
    mov [k - 4], eax
    mov eax, dword ptr [esi + 8]
    mov [k - 8], eax
    inc i
    sub k, 12
    jmp CycleI

CycleJ:
    cmp j, right
    ja AlmostEnd
    mov eax, j
    mul T
    mov edi, eax
    add edi, [ebp + 8]
    mov eax, [edi]
    mov [k], eax
    mov eax, [edi + 4]
    mov [k - 4], eax
    mov eax, [edi + 8]
    mov [k - 8], eax
    inc j
    sub k, 12
    jmp CycleJ
    
AlmostEnd:
    mov ecx, left; счетчик
    mov eax, left
    mul T
    add eax, [ebp + 8]; адрес population[left]
    mov ebx, ebp
    sub ebx, 32; адрес начала res
    ;mov edx, [ebx] текущий res
    
CycleC:
	mov edx, [ebx]
    mov dword ptr [eax], edx
    mov edx, [ebx - 4]
    mov dword ptr [eax + 4], edx
    mov edx, [ebx - 8]
    mov dword ptr [eax + 8], edx
    inc ecx
    add eax, 12
    sub ebx, 12
    cmp ecx, right
    jbe CycleC  
    
    mov eax, right
    sub eax, left
    inc eax
    shl eax, 2
    
    add esp, eax
    add esp, 4
    pop esi
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    mov esp, ebp
    pop ebp
    ret 12
merge endp

merge_sort proc
    push ebp
    mov ebp, esp
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    
    mov esi, [ebp + 16]
    right equ esi
    
    mov edi, [ebp + 12]
    left equ edi

    
    mov eax, left
    add eax, right
    shr eax, 1; middle
    
    cmp left, right
    jae EndMergeSort    
    
    push eax
    push left
    push dword ptr [ebp + 8]
    call merge_sort
    
    push right
    inc eax
    push eax
    push dword ptr [ebp + 8]
    call merge_sort
    
    push right
    push left
    push dword ptr [ebp + 8]
    call merge
    
EndMergeSort:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret 12
merge_sort endp

end
