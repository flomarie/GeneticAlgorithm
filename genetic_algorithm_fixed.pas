program genetic_algorithm;

uses functions, SysUtils;

const
    LEFT_BOUND = 0;
    RIGHT_BOUND = 4;
    INF = 1000000000;
var

	time_start, time_finish, time1, time2, time_write : Qword;
    file_par, file_ans : text;
    str_f, var_name, var_val : string;
    i : longint;
    err : longint;
    
    population, appr_for_crossing: population_type;
    population_volume, appr_volume, population_volume_const : longint;
    curr_population_volume : longint;
    
    
    quality_epsilon : real = 0.00001;
    enough_function_value : real;
    preserved_high_positions : longint;
    preserved_low_positions : longint;
    crossing_volume : real;
    variability : real;
    max_iters : longint = 30;
    iters, valueless_iters : longint;
    max_valueless_iters : longint = 30;
    selection_type, crossing_type, mutation_type : longint;
    mode : longint;
    function_value : real;
    t : real;
    previous_function_value : real;
    max, argmax : real;
{Функция качества}
function Quality_function(x : real) : real;
begin
    Quality_function := x * (x - 2) * (x - 2.75) * cos(x / 10) * (2 - exp(ln(3) * (x - 2))) * exp(x / 10);
end;

{Преобраование дискретного значения в непрерывное}
function Value(ent : longint) : real;
begin
    Value := LEFT_BOUND + ent * (RIGHT_BOUND - LEFT_BOUND) / (1 shl M);
end;

{Формирование популяции}
procedure Form_population(var population : population_type; populaion_volume : longint);
var i, range : longint;
begin
    range := (1 shl M);
    for i := 1 to population_volume do
    begin
        population[i].ent := random(range);
    end;
end;

{Вычисление целевой функции}
procedure Compute_func(var population : population_type; population_volume : longint);
var i : longint;
begin
    for i := 1 to population_volume do
    begin
        population[i].val := Value(population[i].ent);
        population[i].func_val := Quality_function(population[i].val);
    end;
end;

{Пропорциональная селекция}
procedure Proportional_selection(var population : population_type; population_volume : longint;
                               preserved_high_positions, preserved_low_positions : longint);
var i, j, k, crossing_volume1 : longint;
    func_ave, ratio, min, max : real;
begin
    func_ave := 0;
    min := INF;
    max := -INF;
    for i := 1 to population_volume do
    begin
        func_ave := func_ave + population[i].func_val;
        if (population[i].func_val < min) then
            min := population[i].func_val;
        if (population[i].func_val > max) then
            max := population[i].func_val;
    end;
    func_ave := func_ave / population_volume;
    for i := 0 to preserved_high_positions - 1 do
    begin
        appr_for_crossing[i] := population[i];
    end;
    k := preserved_high_positions;
    for i := 1 to preserved_low_positions do
    begin
        appr_for_crossing[k] := population[population_volume - i - 1];
        inc(k);
    end;
    crossing_volume1 := preserved_high_positions + preserved_low_positions;
    for i := 1 to population_volume do
    begin
        if (population[i].func_val > func_ave) then
            ratio := (population[i].func_val - func_ave) / (max - func_ave) * 4
        else
            ratio := exp(-abs((func_ave - population[i].func_val) / (func_ave - min)));
        for j := 1 to trunc(ratio) do
        begin
            appr_for_crossing[k] := population[i];
            inc(k);
            inc(crossing_volume1);
        end;
        if (random < abs(frac(ratio))) then
        begin
            appr_for_crossing[k] := population[i];
            inc(k);
            inc(crossing_volume1);
        end;
    end;
	appr_volume := crossing_volume1;
end;

{Отбор усечением}
procedure Truncation_selection(var population : population_type; population_volume : longint;
                              preserved_high_positions, preserved_low_positions : longint;
                              t : real);
var 
    threshold, i, k, j : longint;
begin
    threshold := trunc(population_volume * t);

    for i := 1 to preserved_high_positions do
    begin
        appr_for_crossing[i] := population[i];
    end;
    k := preserved_high_positions;
    for i := 1 to preserved_low_positions do
    begin
        appr_for_crossing[k] := population[population_volume - i - 1];
        inc(k);
    end;

    for i := 1 to population_volume - preserved_high_positions - preserved_low_positions do
    begin
        j := random(threshold);
        appr_for_crossing[k] := population[j];
        inc(k);
    end;
    appr_volume := population_volume;
end;



{Удаление дубликатов}
procedure Remove_duplicates(var population : population_type; var population_volume : longint);
var i, j, k : longint;
    clear_population : population_type;
    f : boolean;
begin
    k := 0;
    for i := 1 to population_volume do
    begin
        f := true;
        for j := 1 to i do
        begin
            if (population[i].ent = population[j].ent) then
                f := false;
        end;
        if (f) then
        begin
            clear_population[k] := population[i];
            inc(k);
        end;
    end;
    for i := 1 to k do
		population[i] := clear_population[i];
    population_volume := k;
end;

{Дозаполнение случайными значениями}
procedure Padding_with_random_values(var population : population_type; var curr_population_volume : longint;
                                     population_volume_const : longint);
var i, range : longint;
begin
    if (curr_population_volume < population_volume_const) then
    begin
        range := (1 shl M);
        for i := curr_population_volume to population_volume_const - 1 do
        begin
            population[i].ent := random(range);
        end;
    end;
end;

{Перевод в двоичную систему}
function Binary_translation(num : longint) : string;
var s, ans, t : string;
    i, j : longint;
begin
    s := '';
    i := 0;
    while (num > 0) do
    begin
        Str(num mod 2, t);
        s := s + t;
        num := num div 2;
        inc(i);
    end;
    ans := '';
    for j := 1 to M - i do
        ans := ans + '0';
    for j := i downto 1 do
        ans := ans + s[j];
    Binary_translation := ans;
end;

{Основная программа, поиск максимума функции}
begin
    randseed := 8;
    Assign(file_par, 'parameters.txt');
    Reset(file_par);
    while not(eof(file_par)) do
    begin
        readln(file_par, str_f);
        var_name := '';
        i := 1;
        while (str_f[i] <> ' ') do
        begin
            var_name := var_name + str_f[i];
            inc(i);
        end;
        i := i + 3;
        var_val := '';
        while (i <= length(str_f)) and (str_f[i] <> '#') do
        begin
            var_val := var_val + str_f[i];
            inc(i);
        end;
        if (var_name = 'mode') then
            Val(var_val, mode, err);
        if (var_name = 'population_volume') then
            Val(var_val, population_volume_const, err);
        if (var_name = 'max_iters') then
            Val(var_val, max_iters, err);
        if (var_name = 'quality_epsilon') then
            Val(var_val, quality_epsilon, err);
        if (var_name = 'max_valueless_iters') then
            Val(var_val, max_valueless_iters, err);
        if (var_name = 'enough_function_value') then
            Val(var_val, enough_function_value, err);
        if (var_name = 'preserved_high_positions') then
            Val(var_val, preserved_high_positions, err);
        if (var_name = 'preserved_low_positions') then
            Val(var_val, preserved_low_positions, err);
        if (var_name = 't') then
            Val(var_val, t, err);
        if (var_name = 'crossing_volume') then
            Val(var_val, crossing_volume, err);
        if (var_name = 'variability') then
            Val(var_val, variability, err);
        if (var_name = 'selection_type') then
            Val(var_val, selection_type, err);
        if (var_name = 'crossing_type') then
            Val(var_val, crossing_type, err);
        if (var_name = 'mutation_type') then
            Val(var_val, mutation_type, err);
    end;
    close(file_par);
    if (mode = 0) then
    begin
        Assign(file_ans, 'answer.txt');
        Rewrite(file_ans);
    end;
    
    population_volume := population_volume_const;
    Form_population(population, population_volume);
	
    iters := 0;
    valueless_iters := 0;
    function_value := INF;
    
    time_start := GetTickCount64;
    time_write := 0;
    
    while (true) do
    begin
        inc(iters);
        Compute_func(population, population_volume);
		Merge_sort(population, 0, population_volume - 1);
        previous_function_value := function_value;
        function_value := population[1].func_val;
        max := population[1].func_val;
        argmax := population[1].val;
        
        time1 := GetTickCount64;
        if (mode = 1) then
        begin
            writeln('Best point, value at that point, iteration number');
            writeln(argmax:10:10, ' ', max:10:10, ' ', iters);
        end;
        if (mode = 0) then
        begin
            writeln(file_ans, iters);
            for i := 1 to population_volume do
            begin
                writeln(file_ans, Binary_translation(population[i].ent), ' ', population[i].val:10:10, ' ', population[i].func_val:10:10);
            end;
        end;
        time2 := GetTickCount64;
        time_write := time_write + time2 - time1;
        
        if (abs(function_value - previous_function_value) < quality_epsilon) then
            inc(valueless_iters);
        if (iters >= max_iters) or (valueless_iters >= max_valueless_iters) or
           (function_value >= enough_function_value) then
           break;
        if (selection_type = 0) then
            Proportional_selection(population, population_volume, preserved_high_positions, preserved_low_positions)
        else
			Truncation_selection(population, population_volume,
                                                      preserved_high_positions, preserved_low_positions, t);
            
        Crossbreeding(appr_for_crossing, appr_volume, crossing_volume, crossing_type);
        for i := 1 to appr_volume do
			population[i] := appr_for_crossing[i];
        curr_population_volume := appr_volume;
        Remove_duplicates(population, curr_population_volume);
        Mutations(population, curr_population_volume, variability, mutation_type);
        Padding_with_random_values(population, curr_population_volume, population_volume_const);
		population_volume := population_volume_const
    end;
	
	time_finish := GetTickCount64;

	
    writeln('Best point, value at that point, number of iteration');
    writeln(argmax:10:10, ' ', max:10:10, ' ', iters);
    writeln('Reason for stopping:');
    if (iters >= max_iters) then
        writeln('Execution by the algorithm of the a priori specified number of iterations max_iters');
    if (valueless_iters >= max_valueless_iters) then
        writeln('Execution of an a priori specified number of iterations by the algorithm without improving the quality of the population for a given quality_epsilon');
    if (function_value >= enough_function_value) then
        writeln('Reaching the a priori specified value of the objective function enough_function_value');
    if (mode = 0) then
        close(file_ans);
    writeln('Elapsed time in millisec: ', time_finish - time_start - time_write);
    readln;
end.
