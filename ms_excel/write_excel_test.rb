#!/usr/bin/env ruby
##########################################################
###
##  File: write_excel_test.rb
##  Desc: Example of how to use the writeexcel gem
##  By:   Dewayne VanHoozer (dvanhoozer@gmail.com)
#

require 'writeexcel'

# Create a new Excel Workbook
workbook = WriteExcel.new('temp.xls')

# Add worksheet(s)
worksheet  = workbook.add_worksheet
worksheet2 = workbook.add_worksheet

# Add and define a format
format = workbook.add_format
format.set_bold
format.set_color('red')
format.set_align('right')

# write a formatted and unformatted string.
# NOTE: zero-based row and column notation
worksheet.write(1, 1, 'Hi Excel.', format)  # cell B2
worksheet.write(2, 1, 'Hi Excel.')          # cell B3

# write a number and formula using A1 notation
worksheet.write('B4', 3.14159)
worksheet.write('B5', '=SIN(B4/4)')

# write to file
workbook.close

