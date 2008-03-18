#! /usr/bin/env ruby
# -*- coding: utf-8 -*-
###########################################################################
#    Copyright (C) 2004 by Lars Kanis                                      
#    <kanis@comcard.de>                                                             
#
# Copyright: See COPYING file that comes with this distribution
#
# $Id: mifare_acc.rb,v 1.6 2008/03/18 19:13:09 kanis Exp $
###########################################################################
#

require 'rubygems'
require 'fox16'
require 'fox16/colors'


class String
  def without_left_whitespace
    gsub(/^[\t ]*(.*)$/){ $1 }
  end
end


class MifAccMain < Fox::FXMainWindow
  include Fox
  
  AccBlock = Struct.new :bits, :descs
  
	def initialize(app)
		# Initialize base class
		super(app, "Mifare Access Conditions", nil, nil, DECOR_ALL, 0, 0, 650, 670)
		
    # Tooltips einschalten und auf dauerhafte Anzeige einstellen.
    FXToolTip.new(getApp(), TOOLTIP_PERMANENT)
    
		top = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y){|theFrame|
			theFrame.padLeft = theFrame.padRight = theFrame.padBottom = theFrame.padTop = 5
			theFrame.vSpacing = 5
      
      FXHorizontalFrame.new(theFrame, LAYOUT_FILL_X|LAYOUT_FILL_Y){|hex_frame|
        FXLabel.new(hex_frame, 'Hex-Eingabe (3 Byte):')
        @hex_input = FXTextField.new(hex_frame,0, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_X){|this|
          this.setFocus
          this.connect(SEL_COMMAND, method(:hex_changed))
          this.text = 'FF0780'
        }
      }
      @message = FXLabel.new(theFrame, ''){|this|
        this.textColor = FXColor::Red
      }
      
      @acc_blocks = []
      FXMatrix.new(theFrame, 8, MATRIX_BY_COLUMNS | LAYOUT_FILL_X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0){|matrix|
        ['','bits','','read', 'write', 'increment', 'dec,tran,dec'].each{|labeltext|
          FXLabel.new(matrix, labeltext, nil, LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        }
        FXLabel.new(matrix, 'description                 ')
        
        for blocknr in 0..2 do
          acc_block = AccBlock.new nil, []
          FXLabel.new(matrix, "Block #{blocknr}", nil, LAYOUT_FILL_X)
          acc_block.bits = FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
          acc_block.bits.connect(SEL_COMMAND, method(:bits_changed))
          FXLabel.new(matrix,'->')
          for desc in 0...5
            acc_block.descs << FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this| this.backColor = FXColor::AntiqueWhite }

          end
          @acc_blocks << acc_block
        end
      }
      FXMatrix.new(theFrame, 10, MATRIX_BY_COLUMNS | LAYOUT_FILL_X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0){|matrix|
        ['','bits','', 'read A', 'write A', 'read ACC', 'write ACC', 'read B', 'write B'].each{|labeltext|
          FXLabel.new(matrix, labeltext, nil, LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        }
        FXLabel.new(matrix, 'description                 ')
        
        acc_block = AccBlock.new nil, []
        FXLabel.new(matrix, "Block 3", nil, LAYOUT_FILL_X)
        acc_block.bits = FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        acc_block.bits.connect(SEL_COMMAND, method(:bits_changed))
        FXLabel.new(matrix,'->')
        for desc in 0...7
          acc_block.descs << FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this| this.backColor = FXColor::AntiqueWhite }
        end
        @acc_blocks << acc_block
      }
		
      FXLabel.new(theFrame, "\n\nMögliche Bit-Kombinationen für Datenblöcke:")
    
      FXMatrix.new(theFrame, 7, MATRIX_BY_COLUMNS | LAYOUT_FILL_X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0){|matrix|
        ['bits','','read', 'write', 'increment', 'dec,tran,dec'].each{|labeltext|
          FXLabel.new(matrix, labeltext, nil, LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        }
        FXLabel.new(matrix, 'description                 ')
        
        for bits, descs in DataBitsDesc.sort do
          field = FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this| this.backColor = FXColor::AntiqueWhite }
          field.text = bits
          FXLabel.new(matrix,'->')
          for desc in descs
            field = FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this| this.backColor = FXColor::AntiqueWhite }
            field.text = desc
          end
        end
      }
      FXLabel.new(theFrame, "Mögliche Bit-Kombinationen für Trailerblöcke:")
      FXMatrix.new(theFrame, 9, MATRIX_BY_COLUMNS | LAYOUT_FILL_X, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0){|matrix|
        ['bits','', 'read A', 'write A', 'read ACC', 'write ACC', 'read B', 'write B'].each{|labeltext|
          FXLabel.new(matrix, labeltext, nil, LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        }
        FXLabel.new(matrix, 'description                 ')
        
        for bits, descs in AccBitsDesc.sort do
          field = FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this| this.backColor = FXColor::AntiqueWhite }
          field.text = bits
          FXLabel.new(matrix,'->')
          for desc in descs
            field = FXTextField.new(matrix,10, nil, 0, TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X|TEXTFIELD_READONLY){|this| this.backColor = FXColor::AntiqueWhite }
            field.text = desc
          end
        end
      }
    }
    
    # sinnvolle default-Werte in Felder eintragen
    hex_changed(nil,nil,nil)
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
  
  def hex_changed(sender, sel, ptr)
    hex = @hex_input.text
#     puts "hex-input: #{hex}"
    
    bits = nil
    display_error{
      bits = acc_hex_to_bits(hex)
#       puts bits
      
      @acc_blocks.each_with_index{|bl, blidx|
        bl.bits.text = bits[blidx]
      }  
    }
    
    display_bits_desc
  end
  
  def bits_changed(sender, sel, ptr)
    blocksbits = @acc_blocks.map{|ab| ab.bits.text }
#     puts "bits-input: #{blocksbits.inspect}"
    
    hex = ''
    display_error{
      hex = acc_bits_to_hex(blocksbits)
#       puts hex
    }
    display_bits_desc
    
    @hex_input.text = hex.upcase
  end
  
  class InvalidArgument < RuntimeError # :nodoc:
  end
  
  def acc_hex_to_bits(hex)
    raise InvalidArgument, "3 Byte Hex-String erwartet: #{hex.inspect}" unless hex=~/^[0-9a-f]{6,6}$/i
    
    blocksbits = ['','','','']
    nibbles = [hex[2,1].hex, hex[5,1].hex, hex[4,1].hex]
    nibbles.each{|nibble|
#       puts "nibble: #{nibble.inspect}"
      blocksbits.each_with_index{|blockbits, bbidx|
        onoff = (nibble >> bbidx) & 1
#         puts "onoff: #{onoff.inspect} bits: #{blockbits.inspect}"
        blockbits << (onoff>0 ? '1' : '0')
      }
    }
    hex2 = acc_bits_to_hex(blocksbits)
    raise InvalidArgument, "Hex-Daten sind inkonsistent: #{hex}!=#{hex2}" unless hex.upcase==hex2.upcase
    
    return blocksbits
  end

  def acc_bits_to_hex(blocksbits)
    raise InvalidArgument, "Bits fuer 4 Bloecke erwartet: #{blocksbits.inspect}" unless blocksbits.length==4
    
    blocksbits.each_with_index{|bit, bidx|
      raise InvalidArgument, "3 Bit String für Block #{bidx} erwartet: #{bit.inspect}" unless bit=~/^[0-1]{3,3}$/i
    }
    
    nibbles = [0,0,0]
    blocksbits.each_with_index{|blockbits, bbidx|
      nibbles.each_with_index{|nibble, nidx|
        onoff = blockbits[nidx,1].hex
        nibble |= onoff << bbidx
        nibbles[nidx] = nibble
      }
    }
    return sprintf("%x%x%x%x%x%x", nibbles[1] ^ 0xf, nibbles[0] ^ 0xf,
      nibbles[0], nibbles[2] ^ 0xf,
      nibbles[2], nibbles[1])
  end
  
  DataBitsDesc = {
    '000' => ['A|B¹', 'A|B¹', 'A|B¹', 'A|B¹', 'transport config'],
    '010' => ['A|B¹', '-', '-', '-', 'read/write block'],
    '100' => ['A|B¹', 'B¹', '-', '-', 'read/write block'],
    '110' => ['A|B¹', 'B¹', 'B¹', 'A|B¹', 'value block'],
    '001' => ['A|B¹', '-', '-', 'A|B¹', 'value block'],
    '011' => ['B¹', 'B¹', '-', '-', 'read/write block'],
    '101' => ['B¹', '-', '-', '-', 'read/write block'],
    '111' => ['-', '-', '-', '-', 'read/write block'],
  }
  AccBitsDesc = {
    '000' => ['-', 'A', 'A', '-', 'A', 'A', 'Key B may be read'],
    '010' => ['-', '-', 'A', '-', 'A', '-', 'Key B may be read'],
    '100' => ['-', 'B', 'A|B', '-', '-', 'B', ''],
    '110' => ['-', '-', 'A|B', '-', '-', '-', ''],
    '001' => ['-', 'A', 'A', 'A', 'A', 'A', 'Key B may be read, transport config'],
    '011' => ['-', 'B', 'A|B', 'B', '-', 'B', ''],
    '101' => ['-', '-', 'A|B', 'B', '-', '-', ''],
    '111' => ['-', '-', 'A|B', '-', '-', '-', ''],
  }
  
  def display_bits_desc
    @acc_blocks.each_with_index{|acc_block, blidx|
      if blidx==3
        descs = AccBitsDesc[acc_block.bits.text] || Array.new(6,'')
      else
        descs = DataBitsDesc[acc_block.bits.text] || Array.new(4,'')
      end
      descs.each_with_index{|desc, descidx| acc_block.descs[descidx].text = desc.to_s }
    }
  end

  def create
    super
    show(PLACEMENT_SCREEN)
  end

end

if __FILE__ == $0
	app = Fox::FXApp.new("MifAccMain", "ComCard")
	MifAccMain.new(app)
	app.create
	app.run
end 

