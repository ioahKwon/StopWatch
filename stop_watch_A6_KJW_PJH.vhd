
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

entity A6_KJW_PJH is
    Port ( reset : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           sw : in  STD_LOGIC;
           digit_con : out  STD_LOGIC_vector (5 downto 0);
           sseg : out  STD_LOGIC_vector (7 downto 0));
end A6_KJW_PJH;

architecture Behavioral of A6_KJW_PJH is

signal clk_dc : std_logic := '0';
signal clk_csec: std_logic := '0';
signal clk_sec : std_logic := '0';
signal clk_min : std_logic := '0';
signal s_sw: std_logic := '0';
signal s_clk : std_logic;
signal clk_chat : std_logic;
signal clean_out : std_logic;

signal csec : std_logic_vector (7 downto 0) := "00000000";
signal sec : std_logic_vector (7 downto 0) := "00000000";
signal min : std_logic_vector (7 downto 0) := "00000000";
signal D : std_logic_vector (7 downto 0) := "00000000";

signal cnt_dc : integer range 0 to 5;

type state_push is (p0, p1);
type state_stop is (cont, stop);
signal push_state : state_push := p0;
signal time_state : state_stop := cont;


--7segment 출력 함수
function seg (data : in std_logic_vector (3 downto 0))
	return std_logic_vector is
	variable seg7 : std_logic_vector (7 downto 0);
	begin
		case data is
			when "0000" => seg7 := "11111100"; 
			when "0001" => seg7 := "01100000";
			when "0010" => seg7 := "11011010";
			when "0011" => seg7 := "11110010";
			when "0100" => seg7 := "01100110";
			when "0101" => seg7 := "10110110";
			when "0110" => seg7 := "10111110";
			when "0111" => seg7 := "11100000";
			when "1000" => seg7 := "11111110";
			when "1001" => seg7 := "11110110";
			when others => null;
		end case;
	return Seg7;
end seg;

begin
	--6개의 7세그먼트에 출력되도록 동기하는 클럭 분주
	process(reset, clk)
	variable count_dc : integer range 0 to 1000;
	begin
		if (reset = '0') then count_dc := 0; clk_dc <= '0';
		elsif (clk' event and clk = '0') then
			if (count_dc = 1000) then count_dc := 0; clk_dc <= not clk_dc;
			else count_dc := count_dc + 1;
			end if;
		end if;
	end process;
	
	--스위치 디바운싱 부분 가동하는 클럭 분주	
	process(reset, clk)
	variable count_chat : integer range 0 to 19999;
	begin
		if (reset = '0') then count_chat := 0; clk_chat <= '0';
		elsif (clk' event and clk = '0') then
			if (count_chat = 19999) then count_chat := 0; clk_chat <= not clk_chat;
			else count_chat := count_chat + 1;
			end if;
		end if;
	end process;
	
	
	--백분의 일초 클럭 분주
	process(reset, s_clk)
	variable count_csec : integer range 0 to 19999;
	begin
		if (reset = '0') then count_csec := 0; clk_csec <= '0';
		elsif (s_clk' event and s_clk = '0') then
			if (count_csec = 19999) then count_csec := 0; clk_csec <= not clk_csec;
			else count_csec := count_csec + 1;
			end if;
		end if;
	end process;
	
	--초 클럭 분주
	process(reset, clk_csec)
   variable count_sec : integer range 0 to 49;
   begin
      if (reset = '0') then count_sec := 0; clk_sec <= '0';
      elsif (clk_csec' event and clk_csec = '0') then 
         if (count_sec = 49) then count_sec := 0; clk_sec <= not clk_sec;
         else count_sec := count_sec + 1;
         end if;
      end if;
   end process;
   
	--분 클럭 분주
   process(reset, clk_sec)
   variable count_min : integer range 0 to 29;
   begin
      if (reset = '0') then count_min := 0; clk_min <= '0';
      elsif (clk_sec' event and clk_sec = '0') then
         if (count_min = 29) then count_min := 0; clk_min <= not clk_min;
         else count_min := count_min + 1;
         end if;
      end if;
   end process;
	
	
	--백분의 일초가 clk_csec에 동기되어 00부터 99까지 증가를 반복
	process(reset, clk_csec)
	begin
		if(reset = '0') then csec <= "00000000";
		elsif (clk_csec' event and clk_csec = '0') then
			if (csec(3 downto 0) = "1001") then
				if (csec(7 downto 4) = "1001")
					then csec <= "00000000";
				else csec(3 downto 0) <= "0000";
				csec(7 downto 4) <= csec(7 downto 4) + "0001";
				end if;
			else csec(3 downto 0) <= csec(3 downto 0) + "0001";
			end if;
		end if;
	end process;
	
	--초가 clk_sec에 동기되어 00부터 59까지 증가를 반복
	process(reset, clk_sec)
	begin
		if(reset = '0') then sec <= "00000000";
		elsif (clk_sec' event and clk_sec = '0') then
			if (sec(3 downto 0) = "1001") then
				if (sec(7 downto 4) = "0101")
					then sec <= "00000000";
				else sec(3 downto 0) <= "0000";
				sec(7 downto 4) <= sec(7 downto 4) + "0001";
				end if;
			else sec(3 downto 0) <= sec(3 downto 0) + "0001";
			end if;
		end if;
	end process;
	
	--분이 clk_min에 동기되어 00부터 59까지 증가를 반복
	process(reset, clk_min)
	begin
		if(reset = '0') then min <= "00000000";
		elsif (clk_min' event and clk_min = '0') then
			if (min(3 downto 0) = "1001") then
				if (min(7 downto 4) = "0101")
					then min <= "00000000";
				else min(3 downto 0) <= "0000";
				min(7 downto 4) <= min(7 downto 4) + "0001";  
				end if;
			else min(3 downto 0) <= min(3 downto 0) + "0001";
			end if;
		end if;
	end process;
	
	--0부터 5까지 범위의 cnt_dc 카운터
	process(clk_dc)
	begin
		if (clk_dc' event and clk_dc = '1') then
			if (cnt_dc = 5) then cnt_dc <= 0;
			else cnt_dc <= cnt_dc + 1;
			end if;
		end if;
	end process;
	
	--분, 초, 백분의 일초를 6개의 7세그먼트에 cnt_dc 카운터 따라 번갈아가면서 출력
	process(cnt_dc, csec, sec, min)
	begin
		case cnt_dc is
			when 0 => digit_con <= "100000"; sseg <= seg(min(7 downto 4));
			when 1 => digit_con <= "010000"; sseg <= seg(min(3 downto 0));
			when 2 => digit_con <= "001000"; sseg <= seg(sec(7 downto 4));
			when 3 => digit_con <= "000100"; sseg <= seg(sec(3 downto 0));
			when 4 => digit_con <= "000010"; sseg <= seg(csec(7 downto 4));
			when 5 => digit_con <= "000001"; sseg <= seg(csec(3 downto 0));
			when others => null;
		end case;
	end process;
	
	--스위치 디바운싱
	process(clk_chat, D)
	begin
		if (clk_chat' event and clk_chat= '1') then
			D(0) <= sw;
			D(1) <= D(0);
			D(2) <= D(1);
			D(3) <= D(2);
			D(4) <= D(3);
			D(5) <= D(4);
			D(6) <= D(5);
			D(7) <= D(6);
			clean_out <= D(0) or D(1) or D(2) or D(3) 
						 or D(4) or D(5) or D(6) or D(7);
		end if;
	end process;
	
	--스텝 클럭 발생 회로
	process(clean_out, clk_chat)
	begin
		if(clk_chat' event and clk_chat = '1') then
			case push_state is
				when p0 =>
					if clean_out = '1' then 
						push_state <= p0;
					else push_state <= p1; s_sw <= '1';
					end if;
					
				when p1 =>
					if clean_out = '1' then 
						push_state <= p0; s_sw <= '0';
					else push_state <= p1; s_sw <= '0';
					end if;
					
				when others => null;
			end case;
		end if;
	end process;
	
	--스위치 입력에 따른 상태 변화 프로세스
	process(s_sw, clk_chat)
	begin
		if (clk_chat' event and clk_chat = '1') then
			case time_state is
				when cont =>
					if s_sw = '1' then 
					time_state <= stop;
					else 
					time_state <= cont;
					end if;
				when stop =>
					if s_sw = '1' then 
					time_state <= cont;
					else
					time_state <= stop;
					end if;
				when others => null;
			end case;
		end if;
	end process;
	
	--state에 따른 s_clk의 출력값
	process(time_state)
	begin
		case time_state is
			when cont => s_clk <= clk;
			when stop => s_clk <= '0';
		end case;
	end process;
						
end Behavioral;

