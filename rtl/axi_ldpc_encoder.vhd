--
-- DVB IP
--
-- Copyright 2019 by Suoto <andre820@gmail.com>
--
-- This file is part of DVB IP.
--
-- DVB IP is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- DVB IP is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with DVB IP.  If not, see <http://www.gnu.org/licenses/>.

---------------
-- Libraries --
---------------
library	ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library fpga_cores;
use fpga_cores.common_pkg.all;

use work.dvb_utils_pkg.all;
use work.ldpc_pkg.all;

------------------------
-- Entity declaration --
------------------------
entity axi_ldpc_encoder is
  generic ( DATA_WIDTH : natural := 8 );
  port (
    -- Usual ports
    clk               : in  std_logic;
    rst               : in  std_logic;

    cfg_constellation : in  constellation_t;
    cfg_frame_type    : in  frame_type_t;
    cfg_code_rate     : in  code_rate_t;

    -- AXI LDPC table input
    s_ldpc_tready     : out std_logic;
    s_ldpc_tvalid     : in  std_logic;
    s_ldpc_offset     : in  std_logic_vector(numbits(max(DVB_N_LDPC)) - 1 downto 0);
    s_ldpc_next       : in  std_logic;
    s_ldpc_tuser      : in  std_logic_vector(numbits(max(DVB_N_LDPC)) - 1 downto 0);
    s_ldpc_tlast      : in  std_logic;

    -- AXI data input
    s_tready          : out std_logic;
    s_tvalid          : in  std_logic;
    s_tdata           : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    s_tlast           : in  std_logic;

    -- AXI output
    m_tready          : in  std_logic;
    m_tvalid          : out std_logic;
    m_tlast           : out std_logic;
    m_tdata           : out std_logic_vector(DATA_WIDTH - 1 downto 0));
end axi_ldpc_encoder;

architecture axi_ldpc_encoder of axi_ldpc_encoder is

  ---------------
  -- Constants --
  ---------------
  constant ROM_DATA_WIDTH       : natural := numbits(max(DVB_N_LDPC));
  constant FRAME_RAM_DATA_WIDTH : natural := 16;
  constant FRAME_RAM_ADDR_WIDTH : natural
    := numbits((max(DVB_N_LDPC) + FRAME_RAM_DATA_WIDTH - 1) / FRAME_RAM_DATA_WIDTH);

  -------------
  -- Signals --
  -------------
  signal s_ldpc_dv              : std_logic;

  signal axi_ldpc_constellation : constellation_t;
  signal axi_ldpc_frame_type    : frame_type_t;
  signal axi_ldpc_code_rate     : code_rate_t;

  signal axi_ldpc_tready        : std_logic;
  signal axi_ldpc_tvalid        : std_logic;
  signal axi_ldpc_tdata         : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal axi_ldpc_tlast         : std_logic;
  signal axi_ldpc_dv            : std_logic;

  signal axi_passthrough_tdata  : std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal axi_passthrough_tvalid : std_logic;
  signal axi_passthrough_tready : std_logic;

  signal axi_bit_tready         : std_logic;
  signal axi_bit_tdata          : std_logic;
  signal axi_bit_tvalid         : std_logic;
  signal axi_bit_tlast          : std_logic;

  signal axi_bit_dv             : std_logic;
  signal axi_bit_first_word     : std_logic;
  signal axi_bit_has_data       : std_logic;
  signal axi_bit_tready_p       : std_logic;

  signal axi_bit_frame_type     : frame_type_t;

  -- AXI data synchronized to the frame RAM output data
  signal axi_bit_tdata_sampled  : std_logic;

  signal table_offset           : std_logic_vector(numbits(max(DVB_N_LDPC)) - 1 downto 0);

  signal frame_ram_ready        : std_logic;
  signal frame_bits_remaining   : unsigned(numbits(max(DVB_N_LDPC)) - 1 downto 0);

  -- Interface with the frame RAM
  signal frame_ram_en           : std_logic;
  signal frame_addr_in          : unsigned(FRAME_RAM_ADDR_WIDTH - 1 downto 0);

  -- Frame RAM output
  signal frame_addr_out         : std_logic_vector(FRAME_RAM_ADDR_WIDTH - 1 downto 0);
  -- frame_bit_index is sync with frame_addr_out and rame_ram_rddata
  signal frame_bit_index        : std_logic_vector(numbits(FRAME_RAM_DATA_WIDTH) - 1 downto 0);
  signal frame_ram_rddata       : std_logic_vector(FRAME_RAM_DATA_WIDTH  - 1 downto 0);

  signal frame_in_last          : std_logic;
  signal frame_out_last         : std_logic;

  -- Frame RAM data loop
  signal frame_ram_wrdata       : std_logic_vector(FRAME_RAM_DATA_WIDTH - 1 downto 0);

  signal extract_frame_data     : std_logic;
  signal frame_addr_rst         : std_logic;
  signal frame_addr_rst_reg0    : std_logic;

  signal table_handle_ready     : std_logic;

  signal encoded_wr_mask        : std_logic;
  signal encoded_wr_en          : std_logic;
  signal encoded_wr_full        : std_logic;
  signal encoded_wr_data        : std_logic_vector(FRAME_RAM_DATA_WIDTH - 1 downto 0);
  signal encoded_wr_last        : std_logic;

  signal axi_out_tready         : std_logic;
  signal axi_out_tdata          : std_logic_vector(FRAME_RAM_DATA_WIDTH - 1 downto 0);
  signal axi_out_tvalid         : std_logic;
  signal axi_out_tlast          : std_logic;

  signal output_mux_ctrl        : std_logic;

  signal axi_encoded_tvalid     : std_logic;
  signal axi_encoded_tready     : std_logic;
  signal axi_encoded_tlast      : std_logic;
  signal axi_encoded_tdata      : std_logic_vector(DATA_WIDTH - 1 downto 0);

  signal frame_bit_index_i      : natural range 0 to ROM_DATA_WIDTH - 1;

begin

  -------------------
  -- Port mappings --
  -------------------
  -- Duplicate input stream, one leaf will connect to the output and the other to the
  -- actual LDPC calculation that will be appended
  input_duplicate_block : block -- {{
    constant WIDTHS : integer_vector := (
      0 => DATA_WIDTH,
      1 => 1,
      2 => FRAME_TYPE_WIDTH,
      3 => CONSTELLATION_WIDTH,
      4 => CODE_RATE_WIDTH);

    constant AXI_DUP_DATA_WIDTH   : integer := sum(WIDTHS);

    signal s_tdata_agg            : std_logic_vector(AXI_DUP_DATA_WIDTH - 1 downto 0);

    signal axi_dup0_tdata         : std_logic_vector(AXI_DUP_DATA_WIDTH - 1 downto 0);
    signal axi_dup1_tdata         : std_logic_vector(AXI_DUP_DATA_WIDTH - 1 downto 0);

  begin

    s_tdata_agg <= encode(cfg_code_rate) &
                   encode(cfg_constellation) &
                   encode(cfg_frame_type) &
                   s_tlast &
                   s_tdata;

    axi_passthrough_tdata  <= extract(axi_dup0_tdata, 0, WIDTHS);

    axi_ldpc_tdata         <= extract(axi_dup1_tdata, 0, WIDTHS);
    axi_ldpc_tlast         <= extract(axi_dup1_tdata, 1, WIDTHS);
    axi_ldpc_frame_type    <= decode(extract(axi_dup1_tdata, 2, WIDTHS));
    axi_ldpc_constellation <= decode(extract(axi_dup1_tdata, 3, WIDTHS));
    axi_ldpc_code_rate     <= decode(extract(axi_dup1_tdata, 4, WIDTHS));

    input_duplicate_u : entity fpga_cores.axi_stream_duplicate
      generic map ( TDATA_WIDTH => AXI_DUP_DATA_WIDTH )
      port map (
        -- Usual ports
        clk       => clk,
        rst       => rst,

        -- AXI stream input
        s_tready  => s_tready,
        s_tdata   => s_tdata_agg,
        s_tvalid  => s_tvalid,
        -- AXI stream output 0
        m0_tready => axi_passthrough_tready,
        m0_tdata  => axi_dup0_tdata,
        m0_tvalid => axi_passthrough_tvalid,
        -- AXI stream output 1
        m1_tready => axi_ldpc_tready,
        m1_tdata  => axi_dup1_tdata,
        m1_tvalid => axi_ldpc_tvalid);

  end block; -- }}

  -- Convert from FRAME_RAM_DATA_WIDTH to the specified data width
  input_conversion_block : block -- {{
    signal axi_bit_tid  : std_logic_vector(FRAME_TYPE_WIDTH - 1 downto 0);

  begin

    axi_bit_frame_type    <= decode(axi_bit_tid);

    input_width_conversion_u : entity fpga_cores.axi_stream_width_converter
      generic map (
        INPUT_DATA_WIDTH  => DATA_WIDTH,
        OUTPUT_DATA_WIDTH => 1,
        AXI_TID_WIDTH     => FRAME_TYPE_WIDTH)
      port map (
        -- Usual ports
        clk        => clk,
        rst        => rst,
        -- AXI stream input
        s_tready   => axi_ldpc_tready,
        s_tdata    => mirror_bits(axi_ldpc_tdata), -- width converter is little endian, we need big endian
        s_tkeep    => (others => to_01(axi_ldpc_tlast)),
        s_tid      => encode(axi_ldpc_frame_type),
        s_tvalid   => axi_ldpc_tvalid,
        s_tlast    => axi_ldpc_tlast,
        -- AXI stream output
        m_tready   => axi_bit_tready,
        m_tdata(0) => axi_bit_tdata,
        m_tkeep    => open,
        m_tid      => axi_bit_tid,
        m_tvalid   => axi_bit_tvalid,
        m_tlast    => axi_bit_tlast);
    end block; -- }}

  frame_ram_u : entity fpga_cores.pipeline_context_ram
    generic map (
      ADDR_WIDTH => FRAME_RAM_ADDR_WIDTH,
      DATA_WIDTH => FRAME_RAM_DATA_WIDTH,
      RAM_TYPE   => "block")
    port map (
      clk         => clk,
      -- Checkout request interface
      en_in       => frame_ram_en,
      addr_in     => std_logic_vector(frame_addr_in),
      -- Data checkout output
      en_out      => frame_ram_ready,
      addr_out    => frame_addr_out,
      context_out => frame_ram_rddata,
      -- Updated data input
      context_in  => frame_ram_wrdata);

  -- Can't stop reading from the frame RAM instantly, allow some slack
  frame_ram_adapter_u : entity fpga_cores.axi_stream_master_adapter
    generic map (
      MAX_SKEW_CYCLES => 3,
      TDATA_WIDTH     => encoded_wr_data'length)
    port map (
      -- Usual ports
      clk      => clk,
      reset    => rst,
      -- wanna-be AXI interface
      wr_en    => encoded_wr_en,
      wr_full  => encoded_wr_full,
      wr_data  => encoded_wr_data,
      wr_last  => encoded_wr_last,
      -- AXI master
      m_tvalid => axi_out_tvalid,
      m_tready => axi_out_tready,
      m_tdata  => axi_out_tdata,
      m_tlast  => axi_out_tlast);

  -- Convert from FRAME_RAM_DATA_WIDTH to the specified data width
  output_width_conversion_u : entity fpga_cores.axi_stream_width_converter
    generic map (
      INPUT_DATA_WIDTH  => FRAME_RAM_DATA_WIDTH,
      OUTPUT_DATA_WIDTH => DATA_WIDTH,
      AXI_TID_WIDTH     => 0)
    port map (
      -- Usual ports
      clk        => clk,
      rst        => rst,
      -- AXI stream input
      s_tready   => axi_out_tready,
      s_tdata    => axi_out_tdata,
      s_tkeep    => (others => axi_out_tlast),
      s_tid      => (others => '0'),
      s_tvalid   => axi_out_tvalid,
      s_tlast    => axi_out_tlast,
      -- AXI stream output
      m_tready   => axi_encoded_tready,
      m_tdata    => axi_encoded_tdata,
      m_tkeep    => open,
      m_tid      => open,
      m_tvalid   => axi_encoded_tvalid,
      m_tlast    => axi_encoded_tlast);

  frame_addr_in_rst_u : entity fpga_cores.edge_detector
    generic map (
      SYNCHRONIZE_INPUT => False,
      OUTPUT_DELAY      => 0)
    port map (
      -- Usual ports
      clk     => clk,
      clken   => '1',
      --
      din     => extract_frame_data,
      -- Edges detected
      rising  => frame_addr_rst,
      falling => open,
      toggle  => open);

  ------------------------------
  -- Asynchronous assignments --
  ------------------------------
  -- Values synchronized with data from pipeline_context_ram
  frame_bit_index_i      <= to_integer(unsigned(frame_bit_index));
  s_ldpc_tready          <= table_handle_ready and (not rst and not extract_frame_data);

  -- AXI slave specifics
  axi_bit_dv             <= '1' when axi_bit_tready = '1' and axi_bit_tvalid = '1' else '0';
  axi_ldpc_dv            <= '1' when axi_ldpc_tready = '1' and axi_ldpc_tvalid = '1' else '0';
  s_ldpc_dv              <= '1' when s_ldpc_tready = '1' and s_ldpc_tvalid = '1' else '0';
  axi_bit_tready         <= axi_bit_tready_p and not (rst or extract_frame_data);

  -- Mux output data
  axi_encoded_tready     <= m_tready and output_mux_ctrl;
  axi_passthrough_tready <= m_tready and not output_mux_ctrl;
  m_tlast                <= output_mux_ctrl and axi_encoded_tlast;

  m_tdata                <= axi_passthrough_tdata when output_mux_ctrl = '0' else
                            mirror_bits(axi_encoded_tdata);

  m_tvalid               <= (axi_passthrough_tvalid and axi_passthrough_tready and not output_mux_ctrl)
                             or axi_encoded_tvalid;

  frame_in_last          <= extract_frame_data when frame_bits_remaining <= FRAME_RAM_DATA_WIDTH
                            else '0';

  ---------------
  -- Processes --
  ---------------
  axi_flow_ctrl_p : process(clk, rst) -- {{
    variable has_table_data  : boolean := False;
    variable has_axi_data    : boolean := False;

    variable completed_table : boolean := False;
    variable completed_data  : boolean := False;
  begin
    if rst = '1' then
      axi_bit_tready_p     <= '1';
      encoded_wr_mask      <= '0';
      extract_frame_data   <= '0';
      table_handle_ready   <= '1';

      completed_data       := False;
      completed_table      := False;
      has_axi_data         := False;
      has_table_data       := False;

      encoded_wr_last      <= 'U';
      frame_addr_in        <= (others => 'U');
      frame_addr_rst_reg0  <= 'U';
      frame_bit_index      <= (others => 'U');
      frame_bits_remaining <= (others => 'U');
      frame_out_last       <= 'U';
      frame_ram_en         <= 'U';
      table_offset         <= (others => 'U');

    elsif rising_edge(clk) then

      frame_ram_en          <= '0';
      frame_bit_index       <= table_offset(numbits(FRAME_RAM_DATA_WIDTH) - 1 downto 0);
      frame_out_last        <= frame_in_last;
      encoded_wr_last       <= frame_out_last;

      if frame_ram_ready = '1' then
        frame_addr_rst_reg0 <= frame_addr_rst;
      end if;

      if frame_addr_rst_reg0 = '1' then
        encoded_wr_mask     <= '1';
      elsif encoded_wr_last = '1' then
        encoded_wr_mask     <= '0';
      end if;

      -- Frame RAM addressing depends if we're calculating the codes or extracting them
      -- Respect AXI master adapter
      ldpc_append_addr_ctrl : if extract_frame_data = '1' and encoded_wr_full = '0' then
        -- When extracting frame data, we need to complete the given frame. Since the
        -- frame size is not always an integer multiple of the frame length, we also need
        -- to check if data bit cnt has wrapped (MSB is 1).
        if frame_addr_rst = '1' then
          frame_ram_en         <= '1';
          frame_addr_in        <= (others => '0');
        elsif frame_out_last = '1' then
          frame_addr_in        <= (others => '0');
          extract_frame_data   <= '0';
        else
          frame_ram_en         <= '1';
          frame_addr_in        <= frame_addr_in + 1;
          frame_bits_remaining <= frame_bits_remaining - FRAME_RAM_DATA_WIDTH;
        end if;

      end if ldpc_append_addr_ctrl;

      -- AXI LDPC table control
      if s_ldpc_dv = '1' then
        has_table_data     := True;

        table_offset       <= s_ldpc_offset;
        table_handle_ready <= '0';
        frame_addr_in      <= unsigned(s_ldpc_offset(ROM_DATA_WIDTH - 1 downto numbits(FRAME_RAM_DATA_WIDTH)));

        if extract_frame_data = '0' and s_ldpc_next = '1' then
          axi_bit_tready_p <= '1';
        end if;

        if s_ldpc_tlast = '1' then
          completed_table := True;
        end if;
      end if;

      -- AXI frame data control
      if axi_bit_dv = '1' then
        has_axi_data     := True;
        axi_bit_tready_p <= '0';

        if axi_bit_tlast = '1' then
          completed_data := True;
        end if;

        -- Set the expected frame length. Data will passthrough and LDPC codes will be
        -- appended to complete the appropriate n_ldpc length (either 16,200 or 64,800).
        -- Timing-wise, the best way to do this is by setting the counter to - N + 2;
        -- whenever it gets to 1 it will have counted N items.
        if axi_bit_first_word = '1' then
          if axi_bit_frame_type = FECFRAME_SHORT then
            frame_bits_remaining <= to_unsigned(FECFRAME_SHORT_BIT_LENGTH - 1,
                                                frame_bits_remaining'length);
          elsif axi_bit_frame_type = FECFRAME_NORMAL then
            frame_bits_remaining <= to_unsigned(FECFRAME_NORMAL_BIT_LENGHT - 1,
                                                frame_bits_remaining'length);
          else
            report "Don't know how to handle frame type=" & quote(frame_type_t'image(axi_bit_frame_type))
              severity Error;
          end if;
        else
          frame_bits_remaining <= frame_bits_remaining - 1;
        end if;
      end if;

      -- Once we completed both the table and the data, switch to extracting data from the
      -- frame RAM
      if completed_table and completed_data then
        completed_table    := False;
        completed_data     := False;
        extract_frame_data <= '1';
      end if;

      if has_axi_data and has_table_data then
        frame_ram_en <= '1';
      end if;

      if encoded_wr_mask = '0' and has_axi_data then
        has_table_data     := False;
        table_handle_ready <= '1';
      end if;

      if has_table_data and s_ldpc_dv = '1' and s_ldpc_next = '0' then
        has_axi_data       := False;
        axi_bit_tready_p   <= '1';
      end if;
    end if;
  end process; -- }}

  frame_ram_data_handle_p : process(clk, rst) -- {{
    variable xored_data    : std_logic_vector(FRAME_RAM_DATA_WIDTH - 1 downto 0);
  begin
    if rst = '1' then
      encoded_wr_en    <= '0';

      encoded_wr_data  <= (others => 'U');
      frame_ram_wrdata <= (others => 'U');

    elsif rising_edge(clk) then

      encoded_wr_en   <= '0';

      -- Always return the context, will change only when needed
      frame_ram_wrdata <= to_01(frame_ram_rddata);

      -- When calculating the final XOR'ed value, the first bit will depend on the
      -- address. We can safely assign here and avoid extra logic levels on the FF control
      if unsigned(frame_addr_out) = 0 then
        xored_data(0) := frame_ram_rddata(0);
      else
        xored_data(0) := encoded_wr_data(FRAME_RAM_DATA_WIDTH - 1) xor frame_ram_rddata(0);
      end if;

      -- Handle data coming out of the frame RAM, either by using the input data of by
      -- calculating the actual final XOR'ed value
      if frame_ram_ready = '1' then
        if encoded_wr_mask = '0' then
          frame_ram_wrdata(frame_bit_index_i) <= axi_bit_tdata_sampled
                                                 xor to_01(frame_ram_rddata(frame_bit_index_i));
        else
          frame_ram_wrdata <= (others => '0');
        end if;

        if frame_ram_ready = '1' and extract_frame_data = '1' then
        -- Calculate the final XOR between output bits
          for i in 1 to FRAME_RAM_DATA_WIDTH - 1 loop
            xored_data(i) := frame_ram_rddata(i) xor xored_data(i - 1);
          end loop;

          -- Assign data out and decrement the bits consumed
          encoded_wr_en    <= encoded_wr_mask;
          encoded_wr_data  <= xored_data;
        end if;
      end if;

    end if;
  end process; -- }}

  -- The config ports are valid at the first word of the frame, but we must not rely on
  -- the user keeping it unchanged. Hide this on a block to leave the core code a bit
  -- cleaner
  config_sample_block  : block -- {{
    signal tdata : std_logic;
  begin

    process(clk, rst)
    begin
      if rst = '1' then
        axi_bit_first_word    <= '1';
        output_mux_ctrl       <= '0';
        -- We don't want things muxed with rst here
        axi_bit_tdata_sampled <= 'U';
        tdata                 <= 'U';
      elsif rising_edge(clk) then

        axi_bit_tdata_sampled <= tdata;

        if axi_ldpc_tvalid = '1' and axi_ldpc_tready = '1' and axi_ldpc_tlast = '1' then
          output_mux_ctrl     <= '1';
        end if;

        if axi_encoded_tvalid = '1' and axi_encoded_tready = '1' and axi_encoded_tlast = '1' then
          output_mux_ctrl     <= '0';
        end if;

        if axi_bit_tready = '1' then
          axi_bit_has_data    <= '0';
        end if;

        if axi_bit_dv = '1' then
          axi_bit_has_data   <= '1';
          axi_bit_first_word <= axi_bit_tlast;
          tdata              <= axi_bit_tdata;
        end if;

      end if;
    end process;
  end block config_sample_block; -- }}

end axi_ldpc_encoder;

-- vim: set foldmethod=marker foldmarker=--\ {{,--\ }} :
