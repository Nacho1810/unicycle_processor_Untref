-- ======================
-- ====    Autor Mart�n V�zquez 
-- ====    arquitectura de Computadoras  - 2024
--
-- ====== MIPS uniciclo
-- ======================

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_SIGNED.all;

entity Processor is
port(
	Clk         : in  std_logic;
	Reset       : in  std_logic;
	-- Instruction memory
	I_Addr      : out std_logic_vector(31 downto 0);
	I_RdStb     : out std_logic;
	I_WrStb     : out std_logic;
	I_DataOut   : out std_logic_vector(31 downto 0);
	I_DataIn    : in  std_logic_vector(31 downto 0);
	-- Data memory
	D_Addr      : out std_logic_vector(31 downto 0);
	D_RdStb     : out std_logic;
	D_WrStb     : out std_logic;
	D_DataOut   : out std_logic_vector(31 downto 0);
	D_DataIn    : in  std_logic_vector(31 downto 0)
);
end Processor;

architecture processor_arch of Processor is 

    -- declaraci�n de componentes ALU
    component ALU 
        port  (a : in std_logic_vector(31 downto 0);
               b : in std_logic_vector(31 downto 0);
               control : in std_logic_vector(2 downto 0);
               zero : out std_logic;
               result : out std_logic_vector(31 downto 0)); 
    end component;
    
    -- declaraci�n de componente Registers
    component Registers 
        port  (clk : in std_logic;
               reset : std_logic;
               wr : in std_logic;
               reg1_rd : in std_logic_vector(4 downto 0);
               reg2_rd : in std_logic_vector(4 downto 0);
               reg_wr : in std_logic_vector(4 downto 0);
               data_wr : in std_logic_vector(31 downto 0);
               data1_rd : out std_logic_vector(31 downto 0);
               data2_rd : out std_logic_vector(31 downto 0));
    end component;

    
    -- se�ales de control 
    signal RegWrite, RegDst, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, Jump: std_logic;
    signal ALUOp: std_logic_vector(1 downto 0); 

    -- declarci�n de otras se�ales 
    signal r_wr: std_logic; -- habilitaci�n de escritura en el banco de registros
    signal reg_wr: std_logic_vector(4 downto 0); -- direcci�n del registro de escritura
    signal data1_reg, data2_reg: std_logic_vector(31 downto 0); -- registros le�dos desde el banco de registro
    signal data_w_reg: std_logic_vector(31 downto 0); -- dato a escribir en el banco de registros
    
    signal pc_4: std_logic_vector(31 downto 0); -- para incremento de PC
    signal pc_branch: std_logic_vector(31 downto 0); -- salto por beq
    signal pc_jump: std_logic_vector(31 downto 0); -- para salto incondicional
    signal reg_pc, next_reg_pc: std_logic_vector(31 downto 0); -- correspondientes al registro del program counter
 
    signal ALU_oper_a : std_logic_vector(31 downto 0); -- correspondiente al primer operando de ALU
    signal ALU_oper_b : std_logic_vector(31 downto 0); -- correspondiente al segundo operando de ALU
    signal ALU_control: std_logic_vector(2 downto 0); -- se�ales de control de la ALU
    signal ALU_zero: std_logic; -- flag zero de la ALU
    signal ALU_result: std_logic_vector(31 downto 0); -- resultado de la ALU  

    signal inm_extended: std_logic_vector(31 downto 0); -- describe el operando inmediato de la instrucci�n extendido a 32 bits

    

begin 	
    
-- Interfaz con memoria de Instrucciones 
    I_Addr <= reg_pc; -- el PC ? <--- agregue esto
    I_RdStb <= '1';
    I_WrStb <= '0';
    I_DataOut <= (others => '0'); -- dato que nunca se carga en memoria de programa

    
-- Instanciaci�n de banco de registros
    E_Regs:  Registers 
	   Port map (
			clk => Clk, 
			reset => reset, 
			wr => RegWrite,
			reg1_rd => I_DataIn(25 downto 21), 
			reg2_rd => I_DataIn(20 downto 16), 
			reg_wr => reg_wr,
			data_wr => data_w_reg, 
			data1_rd => data1_reg,
			data2_rd => data2_reg); 
			
         
-- mux de para destino de escritura en banco de registros
    reg_wr <= I_DataIn(15 downto 11) when RegDst = '1' else I_DataIn(20 downto 16); -- Instruccion Tipo R       agregue esto  

-- extensi�n de signo del operando inmediato de la instrucci�n
    inm_extended <= x"0000" & I_DataIn(15 downto 0);
    
-- mux correspondiente a segundo operando de ALU
    ALU_oper_a <= data1_reg;
    ALU_oper_b <= inm_extended when ALUSrc = '1' else data2_reg; -- agregue esto
    
-- Instanciaci�n de ALU
    E_ALU: ALU port map(
            a => ALU_oper_a, 
            b => ALU_oper_b, 
            control => ALU_control,
            zero => ALU_zero, 
            result => ALU_result);

-- determina salto incondicional
    pc_jump <= I_DataIn(31 downto 28) & ((I_DataIn(25 downto 0)) & "00");

-- determina salto condicional por iguales
    pc_branch <= (inm_extended sll 2) + pc_4;

-- incremento de PC
    pc_4 <= (reg_pc) + 4;

-- mux que maneja carga de PC 
process(clk,Reset)
begin
    if Reset = '1' then
    next_reg_pc <= (others => '0');
    elsif Jump = '1' then
        next_reg_pc <= pc_jump;
    elsif ALU_zero = '1' and Branch = '1' then
        next_reg_pc <= pc_branch;
    else 
        next_reg_pc <= pc_4;
    end if;
    --Contador de programa
    if(rising_edge(Clk)) then
        reg_pc <= next_reg_pc;
    end if;
end process;

-- ALU CONTROL
process(I_DataIn)
begin
    case ALUOp is
        -- Tipo R 
        when "10" =>
            case I_DataIn(5 downto 0) is
                when "100000" => ALU_control <= "010"; -- add
                when "100010" => ALU_control <= "110"; -- subtract
                when "100100" => ALU_control <= "000"; -- and
                when "100101" => ALU_control <= "001"; -- or
                when "101010" => ALU_control <= "111"; -- set on less than
                when others   => ALU_control <= "000"; -- Eda Playground nos pidio cubrir others
            end case;
        -- BEQ 
        when "01" =>
            ALU_control <= "110"; -- subtract
        -- LW o SW 
        when "00" =>
            ALU_control <= "010"; -- add
        when others =>
            ALU_control <= "000"; -- Default
    end case;
end process;

    

-- Unidad de Control

process (I_DataIn)
begin
    case I_DataIn(31 downto 26) is

        -- Tipo R
        when "000000" =>
            RegWrite <= '1'; 
            RegDst <= '1';
            Branch <= '0'; 
            MemRead <= '0'; 
            MemtoReg <= '0';
            MemWrite <= '0'; 
            ALUSrc <= '0';
            Jump <= '0';
            ALUOp <= "10";
        
        -- LW
        when "100011" =>
            RegDst <= '0';
            ALUSrc <= '1';
            MemtoReg <= '1';
            RegWrite <= '1';
            MemRead <= '1'; 
            MemWrite <= '0';
            Branch <= '0';
            ALUOp <= "00";
            Jump <= '0';

        -- SW
        when "101011" =>
            RegDst <= 'X';
            ALUSrc <= '1';
            MemtoReg <= 'X';
            RegWrite <= '0';
            MemRead <= '0'; 
            MemWrite <= '1';
            Branch <= '0';
            ALUOp <= "00";
            Jump <= '0';       

        -- BEQ
        when "000100" =>
            RegDst <= 'X';
            ALUSrc <= '0';
            MemtoReg <= 'X';
            RegWrite <= '0';
            MemRead <= '0'; 
            MemWrite <= '0';
            Branch <= '1';
            ALUOp <= "01";
            Jump <= '0';   
 
        -- JUMP
        when "000010" =>
            RegDst <= 'X';
            ALUSrc <= 'X';
            MemtoReg <= 'X';
            RegWrite <= '0';
            MemRead <= '0'; 
            MemWrite <= '0';
            Branch <= '0';
            ALUOp <= "XX";
            Jump <= '1';   

        when others =>
            RegDst <= '0';
            ALUSrc <= '0';
            MemtoReg <= '0';
            RegWrite <= '0';
            MemRead <= '0'; 
            MemWrite <= '0';
            Branch <= '0';
            ALUOp <= "00";
            Jump <= '0'; 
    end case;
end process;

    -- mux que maneja escritura en banco de registros
    data_w_reg <= D_Datain when MemtoReg = '1' else ALU_result;

    -- Manejo de memorias de Datos
--    D_Addr <= ; resultado de la ALU
    D_Addr <= ALU_result;
--    D_RdStb <= MemRead;
    D_RdStb <= MemRead;
--    D_WrStb <= MemWrite;
    D_WrStb <= MemWrite;
--    D_DataOut <= ALU_result ;
    D_DataOut <= data2_reg;

end processor_arch;