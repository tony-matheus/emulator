
@bus = 16
@word = 16
@buffer = Array.new(128)
@buffer_count_instructions = 0

@booking_length = @word/8 + @bus/8+ @bus/8+ @bus/8
p "espaço reservado #{@booking_length}"
@RAM = Array.new(128)
# valor reservado no buffer, é so pegar, tamanho da word + end + end + end
# ==============================================================================================================
@barramento = 
{
    ram_queue: [],
    cpu_queue: []
}
@registrators = 
{
    A: 0,
    B: 0,
    C: 0,
    D: 0,
    PI: 0
}

@regexps = 
{
    blank_line: /^\s*(#|$)/,
    regexMovE: /(mov)\s+(\w+),\s+(0x\d+)/,
    regexAddE: /(add)\s+(\w+),\s+(0x\d+)/,
    regexMovER: /(mov)\s+(0x\d+),\s+(\w+)/,
    regexAddER: /(add)\s+(0x\d+),\s+(\w+)/,
    regexMovRR: /(mov)\s+(\w+),\s+(\w+)/,
    regexAddRR: /(add)\s+(\w+),\s+(\w+)/,
    regexMovP: /(mov)\s+(\w+),\s+(\d+)/,
    regexMovN: /(mov)\s+(\w+),\s+(-\d+)/,
    regexAddP: /(add)\s+(\w+),\s+(\d+)/,
    regexAddN: /(add)\s+(\w+),\s+(-\d+)/,
    regexInc: /(inc)\s+(\w+)/,
    regexIncE: /(inc)\s+(0x\w+)/,
    regexImulPP: /(imul)\s+(\w+),\s+(\w+),\s+(\w+)/,
    regexImulNN: /(imul)\s+(\w+),\s+(-\w+),\s+(-\w+)/,
    regexImulPN: /(imul)\s+(\w+),\s+(\w+),\s+(-\w+)/,
    regexImulNP: /(imul)\s+(\w+),\s+(-\w+),\s+(\w+)/
}

@regexps_error = 
{
    regexMovL:  /(mov)\s+(\d+),\s+(\w+)/,
    regexAddL:  /(add)\s+(\d+),\s+(\w+)/
}

def get_params 
    p "digite o tamanho do barramento em bits [8, 16 ou 32]"
    get_bus()
    p "digite o tamanho da palavra em bits [16, 32 ou 64] "
    get_word()
    p "digite o tamanho da ram em bytes [128, 256, 512]"
    get_ram_length()
    p "digite o tamanho do buffer I/O em bytes [64, 128, 256]"
    get_buffer_length()
end

def check_params
    if(@bus < @word)
        abort "ERROR => tamanho da palavra maior que o tamanho do barramento"
        return false
    elsif @bus > @word
        p "com esse tamanho de palavra você poderá esta utilizando menos o poder da máquina"
        p "pois pode representar uma quantidade menor de bits do que a desejada"
    end

    possible_ram_length = 2 ** @bus
    if(@RAM.length > possible_ram_length)
        abort "ERROR => tamanho do barramento impossibilita o tamanho da RAM"
        return false
    end
end

def get_bus
    loop do 
        @bus_length = gets.to_i
        options = [8, 16, 32]
        if !options.include?(@bus_length)
            p "barramento com opção inexistente"
        end
        @buffer_count_instructions = 0
        @barramento = 
        {
            ram_queue: [],
            cpu_queue: []
        }
        @bus = @bus_length
        break if(@bus_length == 8 || @bus_length == 16 ||@bus_length == 32)
    end
end
# ==============================================================================================================

def get_word()
    loop do
        @word_length = gets.to_i
        options = [16, 32, 64]
        
        if !options.include?(@word_length)
            p "palavra com opção inexistente"
        end
        @word = @word_length
    
        @booking_length = @word/8 + @bus/8+ @bus/8+ @bus/8
        p "espaço reservado #{@booking_length}"
        break if(@word_length == 16 || @word_length == 32 || @word_length == 64)
    end
end

def get_ram_length
    loop do 
        @ram_length = gets.to_i
        options = [128, 256, 512]
        if !options.include?(@ram_length)
            p "ram com opção inexistente"
        end
        @RAM = Array.new(@ram_length)
        
        break if @ram_length == 128 || @ram_length == 256 ||@ram_length == 512  
    end
end

def get_buffer_length
    loop do 
        @buffer_length = gets.to_i
        options = [64, 128, 256]
        if !options.include?(@buffer_length)
            p "buffer com opção inexistente"
        end
        @buffer_count_instructions = 0;
        @buffer = Array.new(@buffer_length)

        break if @ram_length == 512 ||@ram_length == 128 || @ram_length == 256 
    end
end
# ==============================================================================================================
def valid_address?(address, count, line_code)
    # p address
    # size = (address.length) -2
    # size_bus = @bus/4
    # if(size > size_bus)
    #     abort("Error linha #{count} => address #{address} invalido para o tamanho do barramento")
    # end
    # if(size < size_bus)
    #     abort("Error linha #{count} => address #{address} invalido para o tamanho do barramento, deveria ser #{size_bus}, pois o #{address} deveria espressar o tamanho correto")
    # end
    # address.slice! "0x"
    # address = address.hex.to_s(10)
    # if (address.to_i > @RAM.length)
    #     abort("Error linha #{count} => address #{address} invalido para o tamanho do barramento, deveria ser #{@RAM.length - 1}, pois o #{address} aponta para um endereço maior que o tamanho da ram")
    # end
end

def valid_literal?(literal, count, line_code)
    limit_negative = (((2**(@bus-1))-1 )/ 2) * -1
    limit_positive = ((2**(@bus-1))-1 )/ 2
    if(literal.to_i < limit_negative || literal.to_i > limit_positive)
        abort("Error linha #{count} => address #{address} invalido para o tamanho do barramento")
    end
end

def valid_registrator?(registrator, count, line_code)
    p "registrator #{registrator }"
    if(check_registrator(registrator, count, line_code) == nil)
        abort("Error linha #{count} => numero literal excede o tamanho suportado pela palavra")
    end
end

def read_assembly_file 
    count = 1
    File.open("/Users/tonymatheus/Documents/Tony/Rails/CPU_Emulator/V3/assembly.txt").each do |line_code|
        if check_assembly_sintax(line_code) && @code_line != nil && @code_line[1] != ""
            p"message"
            message = encode_assebly_code(count)
            if(message == "error")
                return
            end
            send_buffer(message)
            p @buffer
            #    a ram vai verficar a fila da ram, pega a msg, e coloca nos espaço vazio designado
            # aqui já é a segunda instrução que é onde eu tenho de enviar
            if @buffer_count_instructions == 2
                message_to_io_module = Array.new
                byte_instruction = 0
                sent_msg = 0
                instructions = 0
                @buffer.each do |byte|
                    if(byte_instruction == @booking_length && sent_msg < 2)
                        byte_instruction = 0
                        # p "mtd read_assembly_file message #{message_to_io_module}"
                        send_to_IO_module(message_to_io_module)
                        ram_exec()
                        # p "ram_exected"
                        # #    cpu ver que chego  algo na ram para ela olhar, pq ela verifica na fila da cpu que tem um INTERUPTION mandada pelo ES
                        cpu_exec() # interruption
                        # #     a ram verifica que tipo de operação ela tem de fazer baseado na fila da ram nesse caso um READ
                        ram_exec()
                        # # pega a resposta da ram e desencodefica
                        cpu_exec()
                        instructions += 1
                        # p "\n############ FIM DE EXECUÇÃO DE INSTRUÇÃO #{instructions} ##########\n"
                        message_to_io_module = []
                        sent_msg += 1
                    end
                    message_to_io_module << byte
                    byte_instruction += 1
                end
                @buffer_count_instructions = 0
                clear_ram()
                clear_buffer()
            end
        else
            render_error(count, line_code, "tururuuuuu")
        end
        count += 1
    end
    exec_instructions()
end

def exec_instructions( whichInstructions = 1)
    message_to_io_module = Array.new
    byte_instruction = 0
    sent_msg = 0
    instructions = 0
    @buffer.each do |byte|
        if(byte_instruction == @booking_length && sent_msg < whichInstructions)
            byte_instruction = 0
            # p "mtd read_assembly_file message #{message_to_io_module}"
            send_to_IO_module(message_to_io_module)
            ram_exec()
            # p "ram_exected"
            # #    cpu ver que chego  algo na ram para ela olhar, pq ela verifica na fila da cpu que tem um INTERUPTION mandada pelo ES
            cpu_exec() # interruption
            # #     a ram verifica que tipo de operação ela tem de fazer baseado na fila da ram nesse caso um READ
            ram_exec()
            # # pega a resposta da ram e desencodefica
            cpu_exec()
            instructions += 1
            # p "\n############ FIM DE EXECUÇÃO DE INSTRUÇÃO #{instructions} ##########\n"
            message_to_io_module = []
            sent_msg += 1
        end
        message_to_io_module << byte
        byte_instruction += 1
    end
    @buffer_count_instructions = 0
    clear_ram()
    clear_buffer()
end

def clear_ram()
    for i in 0..@booking_length * 2
        @RAM[i] = nil
    end
end

def clear_buffer()
    for i in 0..@buffer.length
        @buffer[i] = nil
    end
end

def cpu_exec
    response = recieve_cpu()
    case response[:info]
        when "interruption"
            @registrators[:PI] = response[:address]
            instruction = 
            {
                operation: "read",
                read_instruction: true,
                address: response[:address],
                length: response[:length]
            }
            send_to_ram(instruction)
        when "ram_response_instruction"
            instruction = edit_response_data(response[:data])
            decode(instruction)
        when "ram_response_value"
            p response[:data][0]
            if(response[:data][0] == "1")
                response[:data][0] = ""
                value = response[:data].to_s.to_i(2) * -1
                return value
            end
            return response[:data].to_s.to_i(2)
    end
end

def edit_response_data(datas)
    # verificar o tamanho do barramento e tamanho da palavra
    response = ["", "", "", ""]
    response_return = [0, 0, 0, 0]
    negative1 = false
    negative2 = false
    for i in 0...datas.length
        if(i < @first_pin_point)
            #imul
            response[0] = response[0] + datas[i]
            response_return[0] = response[0].to_i(2)
        elsif((i < @second_pin_point) && (datas[i] != nil)) 
            # R E
            if(i == @first_pin_point)
            end
            response[1] += datas[i]
            response_return[1] = response[1].to_i(2)
        elsif((i < @thrid_pin_point) && (datas[i] != nil))
            # R E 2
            if(i == @second_pin_point)
                p datas[i]
                if( datas[i][0] == "1")
                    datas[i][0] = ""
                    negative1 = true
                end
            else
                response[2] += datas[i]
            end
            if( negative1)
                response_return[2] = (response[2].to_i(2)) * -1
            else
                response_return[2] = response[2].to_i(2)
            end
        elsif((i < @fourth_pin_point) && (datas[i] != nil))
            if(i == @thrid_pin_point)
                if( datas[i][0] == "1")
                    datas[i][0] = ""
                    negative2 = true
                end
            else 
                response[3] += datas[i]
            end
            if( negative2)
                response_return[3] = (response[3].to_i(2)) * -1
            else
                response_return[3] = response[3].to_i(2)
            end
        end
    end
    return response_return
end

def decode(instruction)
    code = instruction[0]
    negative = false
    case code
        when 91
            p "#91 mov E, 2"
            p "instruction #{instruction}"
            registrator = decode_registrator(instruction[2])
            address = instruction[1]
            if( instruction[2].to_i < 0)
                p instruction[2]
                instruction[2] = instruction[2] * -1
                negative = true
            end
            data = instruction[2]
            set_value_in_ram(address, data, negative)
        when 92
            p "#92 mov E, R"
            p "instruction #{instruction}"
            registrator = decode_registrator(instruction[2])
            address = instruction[1]
            data = @registrators[registrator]
            set_value_in_ram(address, data, negative)
        when 93
            p "\n93 mov R, E"
            p "instruction #{instruction}"
            address = instruction[2]
            address_value = get_value_in_ram(address)
            registrator = decode_registrator(instruction[1])
            @registrators[registrator] = address_value
        when 94
            p " 152 94 mov R, 2"
            registrator = decode_registrator(instruction[1])
            @registrators[registrator] = instruction[2]
            p " 155 registrador #{@registrator}"
        when 95
            p "mov R, R"
            p "instruction #{instruction}"
            registrator1 = decode_registrator(instruction[1])
            registrator2 = decode_registrator(instruction[2])
            @registrators[registrator1] = @registrators[registrator2]
        when 96
            p "96 add E, 2"
            p "instruction #{instruction}"
            address = instruction[1]
            address_value = get_value_in_ram(address)
            data = address_value + instruction[2]
            if( data.to_i < 0)
                p data
                data = data * -1
                negative = true
            end
            set_value_in_ram(address, data, negative)
        when 97
            p "97 add E, R"
            registrator = decode_registrator(instruction[2])
            address = instruction[1]
            address_value = get_value_in_ram(address)
            data = address_value + @registrators[registrator]
            if( data.to_i < 0)
                p data
                data = data * -1
                negative = true
            end
            set_value_in_ram(address, data, negative)
        when 98
            p "98 add R, E"
            p "instruction #{instruction}"
            address = instruction[2]
            address_value = get_value_in_ram(address)
            registrator = decode_registrator(instruction[1])
            @registrators[registrator] = @registrators[registrator] + address_value
        when 99
            p "99 add R, 2"
            registrator = decode_registrator(instruction[1])
            @registrators[registrator] = @registrators[registrator] + instruction[2]
        when 100
            p "add R, R"
            p "instruction #{instruction}"
            registrator1 = decode_registrator(instruction[1])
            registrator2 = decode_registrator(instruction[2])
            @registrators[registrator1] = @registrators[registrator1] + @registrators[registrator2]
        when 101
            p "inc E"
            address = instruction[1]
            p address
            value = get_value_in_ram(address)
            data = value + 1
            set_value_in_ram(address, data, negative)
        when 102
            registrator = decode_registrator(instruction[1])
            @registrators[registrator] += 1
        when 103
            p "imul E, E, E"
            p instruction
            address1 = instruction[1]
            address2 = instruction[2]
            address3 = instruction[3]

            value1 = get_value_in_ram(address2)
            value2 = get_value_in_ram(address3)

            data = value1 * value2
            set_value_in_ram(address1, data, negative)
        when 104
            p "imul E, E, 2"
            p instruction
            address1 = instruction[1]
            address2 = instruction[2]

            value = get_value_in_ram(address2)
            p value
            data = value * instruction[3]
            if( data.to_i < 0)
                p data
                data = data * -1
                negative = true
            end
            set_value_in_ram(address1, data, negative)
        when 105
            p "imul E, E, R"
            p instruction
            address1 = instruction[1]
            address2 = instruction[2]
            
            value = get_value_in_ram(address2)
            
            if(value == nil)
                p "ERROR PQ ESSE ENDEREÇO DE MEMORIA E NIL"
            end
            registrator = decode_registrator(instruction[3])
            p @registrators[registrator]
            data = value * @registrators[registrator]
            set_value_in_ram(address1, data, negative)
        when 106
            p "imul E, 2, E"
            p instruction
            address1 = instruction[1]
            address2 = instruction[3]

            value = get_value_in_ram(address2)
            p value
            if(value == nil)
                p "ERROR PQ ESSE ENDEREÇO DE MEMORIA E NIL"
            end
            data =  instruction[2] * value
            set_value_in_ram(address1, data, negative)
        when 107
            p "imul E, 2, 2"
            p instruction
            address = instruction[1]
            
            data = instruction[2] * instruction[3]
            p "########"
            p "########"
            p "data #{data}"
            p "########"
            
            set_value_in_ram(address, data, negative)
        when 108
            p "imul E, 2, R"
            p instruction 
            address = instruction[1]
            registrator = decode_registrator(instruction[3])
            data = instruction[2] * @registrators[registrator]
            set_value_in_ram(address, data, negative)
        when 109
            p "imul E, R, E"
            p instruction 
            
            address1 = instruction[1]
            registrator = decode_registrator(instruction[2])
            address2 = instruction[3]
            
            value = get_value_in_ram(address2)
            data = @registrators[registrator] * value
            set_value_in_ram(address1, data, negative)
        when 110
            p "imul E, R, 2"
            p instruction 

            address1 = instruction[1]
            registrator = decode_registrator(instruction[2])
            value = instruction[3]
            
            data = @registrators[registrator] * value
            set_value_in_ram(address1, data, negative)
        when 111
            p "imul E, R, R"
            p instruction 

            address = instruction[1]
            registrator1 = decode_registrator(instruction[2])
            registrator2 = decode_registrator(instruction[3])
            
            data = @registrators[registrator1] * @registrators[registrator2]
            set_value_in_ram(address, data, negative)
        when 112
            p "imul R, E, E"
            p instruction
            
            registrator = decode_registrator(instruction[1])
            address1 = instruction[2]
            address2 = instruction[3]

            value1 = get_value_in_ram(address1)
            value2 = get_value_in_ram(address2)

            @registrators[registrator1] = value1 * value2
        when 113
            p "imul R, E, 2"
            p instruction
            
            registrator = decode_registrator(instruction[1])
            address = instruction[2]

            value = get_value_in_ram(address)
            
            @registrators[registrator] = value * instruction[3]
        when 114
            p "imul R, E, R"
            p instruction
            
            registrator = decode_registrator(instruction[1])
            address = instruction[2]
            value = get_value_in_ram(address)
            registrator2 = decode_registrator(instruction[3])
            @registrators[registrator] = value * @registrators[registrator2]
         when 115
            p "imul R, 2, E"
            p instruction
            
            registrator = decode_registrator(instruction[1])
            value1 = instruction[2]
            address = instruction[3]
            value2 = get_value_in_ram(address)
            @registrators[registrator] = value1 * value2
        when 116
            p "imul R, 2, 2"
            p instruction
            
            registrator = decode_registrator(instruction[1])
            value1 = instruction[2]    
            value2 = instruction[3]
            
            @registrators[registrator] = value1 * value2
        when 117
            p "imul R, 2, R"
            p instruction
            
            registrator1 = decode_registrator(instruction[1])
            value = instruction[2]
            registrator2 = decode_registrator(instruction[3])
            p @registrators[registrator1]
            p value 
            p @registrators[registrator2]
            @registrators[registrator1] = value * @registrators[registrator2]
        when 118
            p "imul R, R, E"
            p instruction
            
            registrator1 = decode_registrator(instruction[1])
            registrator2 = decode_registrator(instruction[2])
            address = instruction[3]
            value = get_value_in_ram(address)

            @registrators[registrator1] = @registrators[registrator2] * value
        when 119
            p "imul R, R, 2"
            p instruction
            
            registrator1 = decode_registrator(instruction[1])
            registrator2 = decode_registrator(instruction[2])
            value = instruction[3]
            @registrators[registrator1] = @registrators[registrator2] * value
        when 120
            p "imul R, R, R"
            p instruction
            
            registrator1 = decode_registrator(instruction[1])
            registrator2 = decode_registrator(instruction[2])
            registrator3 = decode_registrator(instruction[3])


            @registrators[registrator1] = @registrators[registrator2] * @registrators[registrator3]

    end
    p "methdo decode() RAM => #{@RAM}"
    p "methdo decode() Registradores => #{@registrators}"
end

def get_value_in_ram(address)
    msg_to_ram = 
    {
        operation: "read",
        read_instruction: false,
        address: address
    }
    send_to_ram(msg_to_ram)
    ram_exec()
    response = cpu_exec()
    return response
end

def set_value_in_ram(address, data, negative)
    msg_to_ram = 
    {
        operation: "write",
        instruction?: false,
        address: address,
        data: data,
        negative?: negative
    }
    send_to_ram(msg_to_ram)
    ram_exec()
end

def encode_assebly_code(count)
    instruction = @code_line[1]
    case instruction
        when "mov"
            if(@code_line[2].include?("0x"))
                valid_address?(@code_line[2], count, @code_line[0]) 
                if(check_registrator(@code_line[3], count, @code_line[0]) == nil)
                    valid_registrator?(@code_line[3], count, @code_line[0])
                    if @code_line[3].include?("0x")
                        render_error(count, @code_line, "Não se pode colocar um Endereço de memoria em um Endereço de memoria")
                    elsif @code_line[3].match(/\d+/)
                        p "#91 mov E, 2"
                        p "entrou aqui"
                        valid_literal?(@code_line[3], count, @code_line[0])
                        code = 91
                    else
                        render_error(count, @code_line, "Não se pode Atribuir valores a numeros literais")
                        return "error"
                    end
                else
                    valid_registrator?(@code_line[3], count, @code_line[0])
                    p "#92 mov E, R"
                    code = 92
                end
            elsif(check_registrator(@code_line[2], count, @code_line[0]) != nil)
                valid_registrator?(@code_line[2], count, @code_line[0])
                if @code_line[3].to_s.include?("0x")
                    p "93 mov R, E"
                    abort()
                    code = 93
                elsif @code_line[3].match(/\d+/)
                    p "94 mov R, 2"
                    valid_literal?(@code_line[3], count, @code_line[0])
                    # abort()
                    code = 94
                elsif check_registrator(@code_line[3], count,@code_line[0]) != nil
                    valid_registrator?(@code_line[3], count, @code_line[0])
                    p "95 mov R, R"
                    # abort()
                    code = 95
                end
            end
            message = encode(code, @code_line[2], @code_line[3], false)
        when "add"
            if(@code_line[2].include?("0x"))
                valid_address?(@code_line[2], count, @code_line[0])
                if(check_registrator(@code_line[3], count,@code_line[0]) == nil)
                    valid_registrator?(@code_line[3], count, @code_line[0])
                    if @code_line[3].include?("0x")
                        abort('endereço de memoria para endereço de memoria, não suportado')
                    elsif @code_line[3].match(/\d+/)
                        valid_literal?(@code_line[3], count, @code_line[0])
                        p "96 add E, 2"
                        p "checar se existe o Registrador"
                        code = 96
                    else
                        p "error"
                    end
                else
                    p "97 add E, R"
                    code = 97
                end
            elsif(check_registrator(@code_line[2], count,@code_line[0]) != nil)
                valid_registrator?(@code_line[2], count, @code_line[0])
                if @code_line[3].to_s.include?("0x")
                    p "98 add R, E"
                    code = 98
                elsif @code_line[3].match(/\d+/)
                    # valid_literal?(@code_line[3], count, @code_line[0])
                    p "99 add R, 2"
                    code = 99
                elsif check_registrator(@code_line[3], count,@code_line[0]) != nil
                    # valid_registrator?(@code_line[3], count, @code_line[0])
                    p "19 add R, R"
                    code = 100
                end
            end
            message = encode(code, @code_line[2], @code_line[3], false)
        when "inc"
            p "entrou aqui"
            if(@code_line[2].include?("0x"))
                # valid_address?(@code_line[2], count, @code_line[0])
                p "101 inc E encode"
                code = 101
            elsif(@code_line[2].match(/\d+/))
                # valid_literal?(@code_line[2], count, @code_line[0])
                abort("ERROR linha -> #{count}, pois não se poder usar inc com numeros literais ")
            elsif check_registrator(@code_line[2], count,@code_line[0]) != nil
                # valid_registrator?(@code_line[2], count, @code_line[0])
                p "102 inc R"
                code =102
            end
             message = encode(code, @code_line[2], false, false)
        when "imul"
           if(@code_line[2].include?("0x"))
            valid_address?(@code_line[2], count, @code_line[0])
                if(@code_line[3].include?("0x"))
                    valid_address?(@code_line[3], count, @code_line[0])
                    if(@code_line[4].include?("0x"))
                        valid_address?(@code_line[4], count, @code_line[0])
                        p "imul E, E, E"
                        code = 103
                    elsif(@code_line[4].match(/\d+/))
                        valid_literal?(@code_line[4], count, @code_line[0])
                        p "imul E, E, 2"
                        code = 104
                    elsif check_registrator(@code_line[4], count,@code_line[0])
                        p "imul E, E, R"
                        code = 105
                    end
                elsif (@code_line[3].match(/\d+/))
                    valid_literal?(@code_line[3], count, @code_line[0])
                    if(@code_line[4].include?("0x"))
                        valid_address?(@code_line[4], count, @code_line[0])
                        p "imul E, 2, E"
                        code = 106
                    elsif(@code_line[4].match(/\d+/))
                        valid_literal?(@code_line[4], count, @code_line[0])
                        p "imul E, 2, 2"
                        code = 107
                    elsif check_registrator(@code_line[4], count,@code_line[0])
                        p "imul E, 2, R"
                        code = 108
                    end
                elsif check_registrator(@code_line[3], count,@code_line[0]) != nil
                    if(@code_line[4].include?("0x"))
                        valid_address?(@code_line[4], count, @code_line[0])
                        p "imul E, R, E"
                        code = 109
                    elsif(@code_line[4].match(/\d+/))
                        valid_literal?(@code_line[4], count, @code_line[0])
                        p "imul E, R, 2"
                        code = 110
                    elsif check_registrator(@code_line[4], count,@code_line[0])
                        p "imul E, R, R"
                        code = 111
                    end
                end
            elsif(@code_line[2].match(/\d+/))
                abort("ERROR linha -> #{count}, pois não se poder usar imul com primeiro parametro sendo numero literais ")
            elsif(check_registrator(@code_line[2], count,@code_line[0]))
                if(@code_line[3].include?("0x"))
                    valid_address?(@code_line[3], count, @code_line[0])
                    if(@code_line[4].include?("0x"))
                        valid_address?(@code_line[4], count, @code_line[0])
                        p "imul R, E, E"
                        code = 112
                    elsif(@code_line[4].match(/\d+/))
                        p "imul R, E, 2"
                        code = 113
                    elsif check_registrator(@code_line[4], count,@code_line[0])
                        p "imul R, E, R"
                        code = 114
                    end
                elsif (@code_line[3].match(/\d+/))
                    if(@code_line[4].include?("0x"))
                        valid_address?(@code_line[4], count, @code_line[0])
                        p "imul R, 2, E"
                        code = 115
                    elsif(@code_line[4].match(/\d+/))
                        p "imul R, 2, 2"
                        code = 116
                    elsif check_registrator(@code_line[4], count,@code_line[0])
                        p "imul R, 2, R"
                        code = 117
                    end
                elsif check_registrator(@code_line[3], count,@code_line[0]) != nil
                    if(@code_line[4].include?("0x"))
                        valid_address?(@code_line[4], count, @code_line[0])
                        p "imul R, R, E"
                        code = 118
                    elsif(@code_line[4].match(/\d+/))
                        p "imul R, R, 2"
                        code = 119
                    elsif check_registrator(@code_line[4], count,@code_line[0])
                        p "imul R, R, R"
                        code = 120
                    end
                end
            end
            message = encode(code, @code_line[2], @code_line[3], @code_line[4])
    end
    return message
end

def ram_exec
    response = recieve_ram()
    case response[:operation]
        when "write"
            if(response[:instruction?])
                write_ram_instruction(response[:address], response[:data])
            else
                write_ram_value(response[:address], response[:data], response[:negative?])
            end
        when "read"
            if response[:read_instruction]
                ram_response = 
                {
                    info: "ram_response_instruction",
                    data: read_ram_instruction(response[:address], response[:length])
                }
            else
                p "#########"
                p "#########"
                p response
                p "#########"
                p "#########"
                ram_response = 
                {
                    info: "ram_response_value",
                    data: read_ram_value(response[:address])
                }
                p ram_response
            end
            send_to_cpu(ram_response)
    end   
end

def write_ram_instruction(start_position, datas)
    datas.each do |byte|
        @RAM[start_position] = byte
        start_position += 1
    end
end

def write_ram_value(address, value, negative)
    address += (@booking_length * 2)
    p address
    value = value.to_s(2)
    if(negative)
        value = value.insert(0, "1")
        p value
    else 
        value = value.insert(0, "0")
        p value
    end
    @RAM[address] = value
end

def read_ram_instruction(start_position, length)
    response = []
    count = 0
    for i in start_position...start_position + length
        response << @RAM[i];
        count += 1
    end

    return response
end

def read_ram_value(address)
    address += (@booking_length * 2)
    p @RAM
    value = @RAM[address].dup
    return value
end

def send_to_IO_module(message)
    p "", "", "############"
    p "mtd send_to_IO_module #{message}"
    p "", "", "############"
    @send_instruction = true
    free_address = ask_ram_to_free_address(message.length)
    msg_to_ram = {
        operation: "write",
        instruction?: true,
        address: free_address,
        data: message
    }
    send_to_ram(msg_to_ram)
    
    msg_to_cpu = {
        info: "interruption",
        address: free_address,
        length: message.length
    }
    send_to_cpu(msg_to_cpu)
end

def send_to_ram(instruction)
    @barramento[:ram_queue] << instruction
end

def send_to_cpu(interruption)
    @barramento[:cpu_queue] << interruption
end

def recieve_cpu()
    response = @barramento[:cpu_queue][0]
    @barramento[:cpu_queue].shift
    return response
end

def recieve_ram
    response = @barramento[:ram_queue][0]
    @barramento[:ram_queue].shift
    return response
end

def encapsulate_message(message, byte_a)
    byte_a[0].each do |byte|
        message << byte
    end
    return message    
end
def encode(code, op1, op2, op3)
    
    message = []
    @first_pin_point = 0
    @second_pin_point = 0
    @thrid_pin_point = 0
    @fourth_pin_point = 0
    negative = false

    code = code.to_i.to_s(2)
    
    code = complete_bytes_by_word(code, negative)
    @first_pin_point = code[0].length
    message = encapsulate_message(message, code)
    if (op1 != false)
        registrator = check_registrator_code(op1)
        if registrator != nil
            registrator = registrator.to_i.to_s(2)
            registrator = complete_bytes_by_word(registrator, negative)
            @second_pin_point = @first_pin_point + registrator[0].length
            
            message = encapsulate_message(message, registrator)
        else
            op1.slice! "0x"
            op1 = op1.hex.to_s(2)
            op1 = complete_bytes_by_bus(op1)
            @second_pin_point = @first_pin_point + op1[0].length
            
            message = encapsulate_message(message, op1)
        end
    end
    if ( op2 != false)
        registrator = check_registrator_code(op2)
        if registrator != nil
            registrator = registrator.to_i.to_s(2)
            registrator = complete_bytes_by_word(registrator, negative)
            @thrid_pin_point = @second_pin_point + registrator[0].length
            message = encapsulate_message(message, registrator)
        elsif(op2.include?("0x"))
            op2.slice!"0x"
            op2 = op2.hex.to_s(2)
            op2 = complete_bytes_by_bus(op2)
            @thrid_pin_point = @second_pin_point + op2[0].length
            message = encapsulate_message(message, op2)
        else 
            if( op2.to_i < 0 )
                op2 = op2.to_i * -1
                negative = true
            end
            op2 = op2.to_i.to_s(2)
            op2 = complete_bytes_by_word(op2, negative)
            @thrid_pin_point = @second_pin_point + op2[0].length
            message = encapsulate_message(message, op2)
        end
    end
    negative = false
    
    if( op3 != false)
        registrator = check_registrator_code(op3)
        if registrator != nil
            registrator = registrator.to_i.to_s(2)
            registrator = complete_bytes_by_word(registrator, negative)
            @fourth_pin_point = @thrid_pin_point + registrator[0].length
            message = encapsulate_message(message, registrator)
        elsif(op3.include?("0x"))
            op3.slice!"0x"
            op3 = op3.hex.to_s(2)
            op3 = complete_bytes_by_bus(op3)
            @fourth_pin_point = @thrid_pin_point + op3[0].length
            message = encapsulate_message(message, op3)
        else 
            if( op3.to_i < 0 )
                op3 = op3.to_i * -1
                negative = true
            end
            op3 = op3.to_i.to_s(2)
            op3 = complete_bytes_by_word(op3, negative)
            @fourth_pin_point = @thrid_pin_point + op3[0].length
            message = encapsulate_message(message, op3)
        end
    end
    return message
end

def complete_bytes_by_bus(bits)
    bits = bits.to_s
    size = bits.length
    # return
    for i in size ...@bus
        bits.insert(0,"0")
    end
    bits = bytes_transform_by_bus(bits)
    return bits
end

def complete_bytes_by_word(bits, negative)
    size = bits.length
    for i in size  ... @word
        if(i == @word-1 && negative)
            bits.to_s.insert(0,"1")
        else
            bits.to_s.insert(0,"0")
        end
    end
    
    bits = bytes_transform_by_word(bits)
    return bits
end

def bytes_transform_by_bus(bits)
    case @bus
        when 8
            return bits.scan(/(........)/)
        when 16
            return bits.scan(/(........)(........)/)
        when 32
            return bits.scan(/(........)(........)(........)(........)/)
    end
end

def bytes_transform_by_word(bits)
    case @word
        when 16
            return bits.scan(/(........)(........)/)
        when 32
            return bits.scan(/(........)(........)(........)(........)/)
        when 64
            return bits.scan(/(........)(........)(........)(........)(........)(........)(........)(........)/)
    end
end


def check_assembly_sintax(line_code)
    @regexps.each do |key, regexp|
        @code_line = line_code.to_s.match(regexp)
        if(@code_line != nil)
            p @code_line
            # p regexp
            return true
        end
    end
    # check_assembly_errors()
    return false
end

def check_assembly_errors
    instruction = @code_line[1]
    case instruction
        when "mov"
            for i in 0..@code_line.length
                
            end
        when "add"
    end
end

def check_registrator(data, count, line_code)
    case data
        when "A"
            return :A
        when "B"
            return :B
        when "C"
            return :C
        when "D"
            return :D
        when "PI"
            return :PI
    end
    return nil
end

def check_registrator_code(registrator)
    case registrator
        when "A"
            return 50
        when "B"
            return 51
        when "C"
            return 52
        when "D"
            return 53
        when "PI"
            return 54
    end
    return nil
end

def decode_registrator(registrator_code)
    case registrator_code
        when 50
            return :A
        when 51
            return :B
        when 52
            return :C
        when 53
            return :D
        when 54
            return :PI
    end
    return nil
end

def render_error(count, line_code, because)
    puts "erro na linha #{count}, codigo => #{line_code}, pois a sintax não está correta"
end

def send_buffer(message)
    if(@buffer_count_instructions != 2 && check_buffer_space(message.length))
        last_buffer_space = check_buffer_white_space()
        count = 0
        message.each do |byte|
            @buffer[last_buffer_space] = byte
            last_buffer_space += 1
            count += 1
        end
        if(count < @booking_length)
            last_buffer_space += (@booking_length - count)
        end
        @buffer_count_instructions += 1
    else
        send_to_IO_module(message)  
    end
end

def check_buffer_white_space()
    for i in 0...@buffer.length
        if @buffer[i] == nil
            if @buffer_count_instructions == 0
                return i
            elsif(@buffer_count_instructions == 1)
                return @booking_length
            elsif @buffer_count_instructions == 2
                return @booking_length * 2
            end
        end
    end
end

def check_buffer_space(length)
    count = 0
    for i in 0 ... @buffer.length
        if @buffer[i] == nil
            count += 1
        end
    end
    if(@booking_length <= count)
        return true
    end
    return false
end

def ask_ram_to_free_address(length)
    count = 0
    for i in 0...@RAM.length
        if @RAM[i] == nil
            for j in i...i+length
                if(@RAM[j] == nil)
                  count = count + 1
                end
            end
            if(count == length)
                count = 0
                return i
            else
                count = 0
            end  

        end
    end
end


# get_params()
# check_params()
read_assembly_file();

# send_buffer(message)
# exec_instructions()