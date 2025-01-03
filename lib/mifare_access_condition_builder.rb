#! /usr/bin/env ruby
# -*- coding: utf-8 -*-
###########################################################################
#    Copyright (C) 2004 by Lars Kanis
#    <kanis@comcard.de>
#
# Copyright: See COPYING file that comes with this distribution
###########################################################################
#

require 'rubygems'
require 'fox16'
require 'fox16/colors'

module MifareAccessConditionBuilder

autoload :VERSION, 'mifare_access_condition_builder/version'

class MainWindow < Fox::FXMainWindow
  include Fox

  AccBlock = Struct.new :bits, :descs, :key_b_readable

  def initialize(app)
    # Initialize base class
    super(app, "Mifare Access Condition Builder #{VERSION}", nil, nil, DECOR_ALL, 0, 0, 750, 250)

    # Tooltips einschalten und auf dauerhafte Anzeige einstellen.
    FXToolTip.new(getApp(), TOOLTIP_PERMANENT)

    #    scrollwindow = FXScrollWindow.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y)
    top = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y){|theFrame|
      theFrame.padLeft = theFrame.padRight = theFrame.padBottom = theFrame.padTop = 5
      theFrame.vSpacing = 5

      FXHorizontalFrame.new(theFrame, LAYOUT_FILL_X|LAYOUT_FILL_Y){|hex_frame|
        FXLabel.new(hex_frame, 'Hex-Eingabe (3 Byte):')
        @hex_input = FXTextField.new(hex_frame,0, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X){|this|
          this.connect(SEL_COMMAND, method(:hex_changed))
          this.text = 'FF 07 80'
        }
      }
      @message = FXLabel.new(theFrame, ''){|this|
        this.textColor = FXColor::Red
      }

      @acc_blocks = []
      FXMatrix.new(theFrame, 8, MATRIX_BY_COLUMNS | LAYOUT_FILL_X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0){|matrix|
        [''].+(DataBitsHead).each{|labeltext|
          FXLabel.new(matrix, labeltext, nil, LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        }

        for blocknr in 0..2 do
          acc_block = AccBlock.new nil, []
          FXLabel.new(matrix, "Block #{blocknr}", nil, LAYOUT_FILL_X)
          acc_block.bits = FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
          acc_block.bits.connect(SEL_COMMAND, method(:bits_changed))
          FXLabel.new(matrix,'->')
          for desc in 0...5
            acc_block.descs << FXLabel.new(matrix, '', nil, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this|
              this.backColor = FXColor::LightGoldenrod1
              bits_field = acc_block.bits
              this.connect(SEL_LEFTBUTTONPRESS){|sender, sel, ptr|
                desc_clicked(sender, sel, ptr, bits_field, acc_block.key_b_readable ? :data_key_b_readable : :data_key_b_secret)
              }
            }
          end
          @acc_blocks << acc_block
        end
      }
      FXMatrix.new(theFrame, 10, MATRIX_BY_COLUMNS | LAYOUT_FILL_X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0){|matrix|
        [''].+(TrailerBitsHead).each{|labeltext|
          FXLabel.new(matrix, labeltext, nil, LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        }

        acc_block = AccBlock.new nil, []
        FXLabel.new(matrix, "Block 3", nil, LAYOUT_FILL_X)
        acc_block.bits = FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        acc_block.bits.connect(SEL_COMMAND, method(:bits_changed))
        FXLabel.new(matrix,'->')
        for desc in 0...7
          acc_block.descs << FXLabel.new(matrix,'', nil, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this|
            this.backColor = FXColor::PaleGreen
            bits_field = acc_block.bits
            this.connect(SEL_LEFTBUTTONPRESS){|sender, sel, ptr|
              desc_clicked(sender, sel, ptr, bits_field, :trailer)
            }
          }
        end
        @acc_blocks << acc_block
      }
    }
    # sinnvolle default-Werte in Felder eintragen
    hex_changed
  end

  def create
    super
    show(PLACEMENT_SCREEN)
    app.addTimeout(1) do
      @hex_input.setFocus
    end
  end

  def display_error
    begin
      yield
    rescue InvalidArgument => e
      @message.text = e.to_s
    else
      @message.text = ''
    end
  end

  def hex_changed(sender=nil, sel=nil, ptr=nil)
    hex = @hex_input.text
#     puts "hex-input: #{hex}"

    bits = nil
    display_error do
      bits = acc_hex_to_bits(hex)
      # puts bits

      @acc_blocks.each_with_index do |bl, blidx|
        bl.bits.text = bits[blidx]
      end
    end

    display_bits_desc
  end

  def bits_changed(sender=nil, sel=nil, ptr=nil)
    blocksbits = @acc_blocks.map{|ab| ab.bits.text }
#     puts "bits-input: #{blocksbits.inspect}"

    hex = ''
    display_error do
      hex = acc_bits_to_hex(blocksbits).upcase
#       puts hex
    end
    display_bits_desc

    @hex_input.text = [hex[0,2], hex[2,2], hex[4..-1]].join(" ")
  end

  class InvalidArgument < RuntimeError # :nodoc:
  end

  def acc_hex_to_bits(hex)
    hex = hex.gsub(/\s/, '')
    raise InvalidArgument, "3 Byte Hex-String erwartet: #{hex.inspect}" unless hex=~/^[0-9a-f]{6,6}$/i

    blocksbits = ['','','','']
    nibbles = [hex[2,1].hex, hex[5,1].hex, hex[4,1].hex]
    nibbles.each do |nibble|
#       puts "nibble: #{nibble.inspect}"
      blocksbits.each_with_index do |blockbits, bbidx|
        onoff = (nibble >> bbidx) & 1
#         puts "onoff: #{onoff.inspect} bits: #{blockbits.inspect}"
        blockbits << (onoff>0 ? '1' : '0')
      end
    end
    hex2 = acc_bits_to_hex(blocksbits)
    raise InvalidArgument, "Hex-Daten sind inkonsistent: #{hex}!=#{hex2}" unless hex.upcase==hex2.upcase

    return blocksbits
  end

  def acc_bits_to_hex(blocksbits)
    raise InvalidArgument, "Bits fuer 4 Bloecke erwartet: #{blocksbits.inspect}" unless blocksbits.length==4

    blocksbits.each_with_index do |bit, bidx|
      raise InvalidArgument, "3 Bit String für Block #{bidx} erwartet: #{bit.inspect}" unless bit=~/^[0-1]{3,3}$/i
    end

    nibbles = [0,0,0]
    blocksbits.each_with_index do |blockbits, bbidx|
      nibbles.each_with_index do |nibble, nidx|
        onoff = blockbits[nidx,1].hex
        nibble |= onoff << bbidx
        nibbles[nidx] = nibble
      end
    end
    return sprintf("%x%x%x%x%x%x",
      nibbles[1] ^ 0xf, nibbles[0] ^ 0xf,
      nibbles[0], nibbles[2] ^ 0xf,
      nibbles[2], nibbles[1])
  end

  DataBitsHead = ['bits','','read', 'write', 'increment', 'dec,tran,dec', 'description']
  DataBitsDesc = {
    '000' => [['A|B', 'A|B', 'A|B', 'A|B'], ['A', 'A', 'A', 'A'], 'transport config'],
    '010' => [['A|B', '-'  , '-'  , '-'  ], ['A', '-', '-', '-'], 'read/write block'],
    '100' => [['A|B', 'B'  , '-'  , '-'  ], ['A', '-', '-', '-'], 'read/write block'],
    '110' => [['A|B', 'B'  , 'B'  , 'A|B'], ['A', '-', '-', 'A'], 'value block'],
    '001' => [['A|B', '-'  , '-'  , 'A|B'], ['A', '-', '-', 'A'], 'value block'],
    '011' => [['B'  , 'B'  , '-'  , '-'  ], ['-', '-', '-', '-'], 'read/write block'],
    '101' => [['B'  , '-'  , '-'  , '-'  ], ['-', '-', '-', '-'], 'read/write block'],
    '111' => [['-'  , '-'  , '-'  , '-'  ], ['-', '-', '-', '-'], 'read/write block'],
  }
  TrailerBitsHead = ['bits','', 'read A', 'write A', 'read ACC', 'write ACC', 'read B', 'write B', 'description']
  TrailerBitsDesc = {
    '000' => ['-', 'A', 'A'  , '-', 'A', 'A', 'Key B may be read'],
    '010' => ['-', '-', 'A'  , '-', 'A', '-', 'Key B may be read'],
    '100' => ['-', 'B', 'A|B', '-', '-', 'B', ' '],
    '110' => ['-', '-', 'A|B', '-', '-', '-', ' '],
    '001' => ['-', 'A', 'A'  , 'A', 'A', 'A', 'Key B may be read, transport config'],
    '011' => ['-', 'B', 'A|B', 'B', '-', 'B', ' '],
    '101' => ['-', '-', 'A|B', 'B', '-', '-', ' '],
    '111' => ['-', '-', 'A|B', '-', '-', '-', ' '],
  }

  def display_bits_desc
    @acc_blocks.each_with_index do |acc_block, blidx|
      if blidx==3
        descs = TrailerBitsDesc[acc_block.bits.text] || Array.new(6,'')
      else
        trailer = TrailerBitsDesc[@acc_blocks.last.bits.text]
        ws_descs, wr_descs, desc = DataBitsDesc[acc_block.bits.text] || [Array.new(4,'')]*2
        if trailer && trailer[4].tr("-","").empty?
          descs = ws_descs + [desc] # Key B can't be read
          acc_block.key_b_readable = false
        else
          descs = wr_descs + [desc] # Key B may be read
          acc_block.key_b_readable = true
        end
      end
      descs.each_with_index{|desc, descidx| acc_block.descs[descidx].text = desc.to_s }
    end
  end

  def desc_clicked(sender, sel, ptr, bits_field, data_or_trailer)
    sd = SelectionDialog.new(data_or_trailer, sender, "Select Access Conditions", opts: DECOR_ALL, height: 320, width: 600)
    if sd.execute > 0
      bits = sd.selected_bits
      bits_field.text = bits
      bits_changed
    end
  end

  class SelectionDialog < FXDialogBox
    include Fox

    attr_reader :selected_bits

    def initialize(data_or_trailer, *args)
      super(*args)

      if data_or_trailer == :data_key_b_readable || data_or_trailer == :data_key_b_secret
        FXLabel.new(self, "Mögliche Bit-Kombinationen für Datenblöcke:")

        FXMatrix.new(self, 7, MATRIX_BY_COLUMNS | LAYOUT_FILL_X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) do |matrix|
          DataBitsHead.each do |labeltext|
            FXLabel.new(matrix, labeltext, nil, LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
          end

          DataBitsDesc.sort.each do |bits, (ws_descs, wr_descs, desc)|
            descs = (data_or_trailer == :data_key_b_readable ? wr_descs : ws_descs) + [desc]
            field = FXLabel.new(matrix, bits, nil, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this| this.backColor = FXColor::LightGoldenrod1 }
            FXLabel.new(matrix,'->')
            for desc in descs
              FXLabel.new(matrix, desc, nil, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY) do |this|
                this.backColor = FXColor::LightGoldenrod1
                b = bits
                this.connect(SEL_LEFTBUTTONPRESS) do
                  @selected_bits = b
                  self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
                end
              end
            end
          end
        end
      elsif data_or_trailer == :trailer
        FXLabel.new(self, "Mögliche Bit-Kombinationen für Trailerblöcke:")

        FXMatrix.new(self, 9, MATRIX_BY_COLUMNS | LAYOUT_FILL_X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) do |matrix|
          TrailerBitsHead.each do |labeltext|
            FXLabel.new(matrix, labeltext, nil, LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
          end

          TrailerBitsDesc.each do |bits, descs|
            field = FXLabel.new(matrix, bits, nil, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this| this.backColor = FXColor::PaleGreen }
            FXLabel.new(matrix,'->')
            for desc in descs
              FXLabel.new(matrix, desc, nil, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY) do |this|
                this.backColor = FXColor::PaleGreen
                b = bits
                this.connect(SEL_LEFTBUTTONPRESS) do
                  @selected_bits = b
                  self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
                end
              end
            end
          end
        end
      end
    end
  end

end
end
