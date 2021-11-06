unit functions;

interface
    const M = 16;
		  MAX_POPULATION_VOLUME = 1000;
    type
    individual_t = record
                       ent : longint;
                       val :  single;
                       func_val : single;
                   end;
    population_type = array [1..MAX_POPULATION_VOLUME] of individual_t;
    
    procedure Merge_sort(var population : population_type; left, right : longint); stdcall;
    function Single_point_crossing(parent1, parent2 : longint) : longint; stdcall;
    procedure Two_poin_crossing(var appr_for_crossing : population_type;
                                    var volume : longint; parent1, parent2 : individual_t);
    procedure Universal_crossing(var appr_for_crossing : population_type;
                                    var volume : longint; parent1, parent2 : individual_t);
    procedure Homogeneous_crossing(var appr_for_crossing : population_type;
                                    var volume : longint; parent1, parent2 : individual_t);
    function Random_bit_change(entity_ent : longint) : longint; stdcall;
    procedure Swap_random_bits(var entity : individual_t);
    procedure Reverse_bit_str(var entity : individual_t);
    procedure Mutations(var population : population_type; population_volume : longint; variability : single; mutation_type : integer);
    procedure Crossbreeding(var appr_for_crossing : population_type; var appr_volume : longint;
                            crossing_volume : single; crossing_type : integer);
    function Compare(a, b : single) : longint; stdcall;
    
    
implementation
	{$L something.obj}

	function Compare(a, b : single) : longint; stdcall;
	begin
		if (a >= b) then
			Compare := 0
		else
			Compare := 1
	end;
	
    
    {Сортировка слиянием по убыванию}
    procedure Merge_sort(var population : population_type; left, right : longint);
    stdcall; external name 'merge_sort';
    
        
    {Одноточечное скрещивание}
    function Single_point_crossing(parent1, parent2 : longint) : longint;
    stdcall; external name 'single_point_crossing';
   
   
    {Двухточечное скрещивание}
    procedure Two_poin_crossing(var appr_for_crossing : population_type;
                                    var volume : longint; parent1, parent2 : individual_t);
    var sep1, sep2 : longint;
        part11, part12, part13, part21, part22, part23 : longint;
        child1, child2 : individual_t;
    begin
        sep1 := random(M - 1);
        sep2 := sep1 + random(M - sep1);
        part11 := ((parent1.ent) shr sep2) shl sep2;
        part12 := (parent1.ent and not(part11)) shr sep1 shl sep1;
        part13 := parent1.ent and not(part11) and not(part12);
        part21 := ((parent2.ent) shr sep2) shl sep2;
        part22 := (parent2.ent and not(part21)) shr sep1 shl sep1;
        part23 := parent2.ent and not(part21) and not(part22);
        child1.ent := part11 or part22 or part13;
        child2.ent := part21 or part12 or part23;
        appr_for_crossing[volume + 1] := child1;
        appr_for_crossing[volume + 2] := child2;
        volume := volume + 2;
    end;

    {Универсальное скрещивание}
    procedure Universal_crossing(var appr_for_crossing : population_type;
                                    var volume : longint; parent1, parent2 : individual_t);
    var child1, child2 : individual_t;
        i, pow_2: longint;
        probability : single;
    begin
        child1.ent := 0;
        child2.ent := 0;
        pow_2 := (1 shl (M - 1));
        for i := 1 to M do
        begin
            probability := random();
            if (probability < 0.5) then
                child1.ent := child1.ent shl 1 or ((parent1.ent div pow_2) mod 2)
            else
                child1.ent := child1.ent shl 1 or ((parent2.ent div pow_2) mod 2);
            pow_2 := pow_2 div 2;
        end;
        child2.ent := not(child1.ent);
        appr_for_crossing[volume + 1] := child1;
        appr_for_crossing[volume + 2] := child2;
        volume := volume + 2;
    end;

    {Однородное скрещивание}
    procedure Homogeneous_crossing(var appr_for_crossing : population_type;
                                    var volume : longint; parent1, parent2 : individual_t);
    var child1, child2 : individual_t;
        mask : longint;
    begin
        mask := random((1 shl M));
        child1.ent := (parent1.ent and mask) or (parent2.ent and not(mask));
        child2.ent := not(child1.ent);
        appr_for_crossing[volume + 1] := child1;
        appr_for_crossing[volume + 2] := child2;
        volume := volume + 2;
    end;
    
    {Изменение случайно выбранного бита}
    function Random_bit_change(entity_ent : longint) : longint;
    stdcall; external name 'random_bit_change';
   
   
    {Перестановка случайно выбранных битов местами}
    procedure Swap_random_bits(var entity : individual_t);
    var i, j, bi, bj : longint;
    begin
        i := random(M - 1);
        j := i + random(M - i);
        bi := (entity.ent div (1 shl i) mod 2);
        bj := (entity.ent div (1 shl j) mod 2);
        if (bi <> bj) then
        begin
            entity.ent := entity.ent xor (1 shl i) xor (1 shl j);
        end;
    end;

    {Реверс битовой строки, начиная со случайно выбранного бита}
    procedure Reverse_bit_str(var entity : individual_t);
    var i, j, b, pow_2 : longint;
        part1, part2, ans : longint;
    begin
        i := random(M);
        part1 := entity.ent shr i shl i;
        part2 := entity.ent shl (M - i) shr (M - i);
        ans := part1;
        pow_2 := (1 shl i);
        for j := 0 to i do
        begin
            b := part2 mod 2;
            ans := ans + b * pow_2;
            part2 := part2 div 2;
            pow_2 := pow_2 div 2;
        end;
        entity.ent := ans;
    end;

    {Мутации}
    procedure Mutations(var population : population_type; population_volume : longint; variability : single; mutation_type : integer);
    var amount, i, j : longint;
    begin
        amount := trunc(population_volume * variability);
        for i := 0 to amount - 1 do
        begin
            j := random(population_volume - 1);
            if (mutation_type = 0) then
            begin
                population[j].ent := Random_bit_change(population[j].ent);
            end
            else if (mutation_type = 1) then
                Swap_random_bits(population[j])
            else
                Reverse_bit_str(population[j]);
        end;
    end;
    
    
    {Скрещивание}
    procedure Crossbreeding(var appr_for_crossing : population_type; var appr_volume : longint;
                            crossing_volume : single; crossing_type : integer);
    var amount, i, par1, par2 : longint;
		child : individual_t;
    begin
        amount := trunc(crossing_volume * appr_volume);
        for i := 1 to amount do
        begin
            par1 := random(appr_volume);
            par2 := random(appr_volume);
            if (crossing_type = 0) then
            begin
                child.ent := Single_point_crossing(appr_for_crossing[par1].ent,
                                      appr_for_crossing[par2].ent);
                
				appr_for_crossing[appr_volume] := child;
				inc(appr_volume);
            end
            else if (crossing_type = 1) then
            begin
                Two_poin_crossing(appr_for_crossing, appr_volume, appr_for_crossing[par1],
                                  appr_for_crossing[par2]);
                appr_volume := appr_volume + 2;
            end
            else if (crossing_type = 2) then
            begin
                Universal_crossing(appr_for_crossing, appr_volume, appr_for_crossing[par1],
                                   appr_for_crossing[par2]);
                appr_volume := appr_volume + 2;
            end
            else
            begin
                Homogeneous_crossing(appr_for_crossing, appr_volume, appr_for_crossing[par1],
                                     appr_for_crossing[par2]);
                appr_volume := appr_volume + 2;
            end;
        end;
    end;

end.
