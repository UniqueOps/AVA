#!/bin/bash

################################################################################
# format.shl
# v1.0.1
# 
# Contributors:
# * Graham L. - Level 2 Support Technician - graham.l@hostdime.com
# 
# Description:
# 
# Globals:
# * FORMAT_FN
# * FORMAT_VER
# * _DEFAULT_COLOR
# * _DEFAULT_GLYPH
# * _DEFAULT_TEXTCOLOR
# * _DEFAULT_WIDTH
# * _RESET
# * _TBL_TITLE
# * _TBL_COLOR
# * _TBL_GLYPH
# * _TBL_HEADING
# * _TBL_PARTITION
# * _TBL_TEXTCOLOR
# * _TBL_ROWS
# * _TBL_ROWTESTCOLORS
# * _TBL_ROWLEN
# * _TBL_ROWOFFSET
# * _TBL_COLW
# * _TBL_COLP
# * _TBL_COLTC
# 
# Functions:
# * init_table
# * add_row()
# * print_table()
# * mkheader()
# * mkpad()
# 
# Dependencies:
# * core.shl
# * colorize.shl
################################################################################

################################################################################
################################### Includes ###################################
################################################################################

if _core_test >/dev/null 2>&1; [ $? != 3 ]
then
  source /proc/self/fd/0 <<<"$(< <(curl -ks https://codesilo.dimenoc.com/grahaml/triton/raw/master/core/include_core_lib))"
fi
include colorize.shl

################################################################################
################################### Globals ####################################
################################################################################

FORMAT_FN="format.shl"
FORMAT_VER="1.0.1"

_DEFAULT_COLOR=$(colorize --color blue --bold)
_DEFAULT_GLYPH='='
_DEFAULT_PARTITION='|'
_DEFAULT_TEXTCOLOR=""
_DEFAULT_WIDTH=80
_RESET=$(colorize)

_TBL_TITLE=""       # Name of the table
_TBL_COLOR=""       # Color of glyphs, and partitions in table
_TBL_GLYPH=""       # Glyph character for table
_TBL_HEADING=1      # Number of table heading rows.
_TBL_PARTITION=""   # Partition character for table
_TBL_TEXTCOLOR=""   # Table text color
_TBL_MINWIDTH=0     # Table minimum width

declare -a _TBL_ROWS            # Stores rows' contents
declare -a _TBL_ROWTEXTCOLORS   # Stores custom color for each field in row
_TBL_ROWLEN=0     # Number of elements per row 
_TBL_ROWOFFSET=0  # Index offset for first index of next row

declare -a _TBL_COLW  # Width of each column
declare -a _TBL_COLP  # Partition of each column (prints to the right of the column)
declare -a _TBL_COLTC  # Text color of each column

################################################################################
################################## Functions ###################################
################################################################################

#*******************************************************************************
# function_name()
# v1.0.0
# 
# Contributors:
# * Graham L. - Level 2 Support Technician - graham.l@hostdime.com
# 
# Description:
# 
# Returns:
# 
# Options:
# None.
# 
# Arguments:
# None.
# 
# Dependencies:
# None.
#*******************************************************************************

#*******************************************************************************
# _format_test() 
# v1.0.0
#
# Contributors:
# * Graham L. - Level 2 Support Technician - graham.l@hostdime.com
#
# Description: Used to test for the presence of format.shl in the current shell.
#
# Returns: Returns 3 indicating that the format.shl has been sourced into the 
# current shell.
#*******************************************************************************

function _format_test()
{
  return 3
}

#*******************************************************************************
# init_table()
# v1.1.0
# 
# Contributors:
# * Graham L. - Level 2 Support Technician - graham.l@hostdime.com
# 
# Description: Sets table title, color, partition, and text color. Resets these
# values to default if none are specified by the user. Title is optional.
# 
# Options:
# -c, --color COLOR
#   Controls the color of the table glyphs are partitions. Set to 
#   $_DEFAULT_COLOR if the option is not used. The value 'none' can be given
#   instead of a COLOR which forces no color to be used. This is useful if the
#   table printed is going to be written to a log, or in another situation 
#   where color codes are output.
#
# -C, --col, --column INTEGER
#   Specifies the column for the -P, and --col-partition options. Default value 
#   is 1. Does nothing when not used in conjunction with either the -P, or
#   --col-partition option.
#
# -g, --glyph CHARACTER
#   Controls the glyph character used in the table. Currently, the glyph is 
#   only used to pad the header around the title. Must be exactly 1 character.
#   Set to $_DEFAULT_GLYPH if the option is not used.
#
# -h, --heading INTEGER
#   Sets the number of rows to be printed before printing the headings divider
#   (default 1). Setting this value to anyting greater than 1 will make it no
#   longer compatible with markdown. If this number is greater than or equal to 
#   the number of rows, no divider will be printed.
#
# -m, --min-width INTEGER
#   Sets the minimum table width. If the table width is not equal to or greater
#   than the argument of -m, --min-width, then it will evenly increase the width
#   of each column until the table's width is at least that large.
#
# -p, --partition STRING
#   Controls the partition character used in the table. The parition is the 
#   string used to separate each column. Set to $_DEFAULT_PARTITION if the 
#   option is not used.
#
# -P, --col-partition STRING
#   Specifies a partition used to separate columns that is different the one 
#   used elsewhere in the table. This should be preceded by the -C, --col, or
#   --column options to set which partition is affected. The partition affected
#   will be the partition to the right of the column number. For example, using
#   this option and setting the column to '3' will change the partition between
#   the 3rd and 4th columns. The column specified is the last column, or 
#   greater than the number of columns printed, this option does nothing.
#
# -t, --text-color COLOR
#   Sets the text color for the title, and field text. Set to 
#   $_DEFAULT_TEXTCOLOR if the option is not used.
# 
# -T, --col-text-color COLOR
#   Specifies a column's text color.This should be preceded by the -C, --col, or
#   --column options to set the column. The column affected is the column in the 
#   specified by the -C, --col, or --column option. For example, using this 
#   option and setting the column to '3' will change the text color of the 3rd 
#   column. If the column specified is greater than the number of columns 
#   printed, this option does nothing.
#
# Arguments: Accepts a STRING to set the table title. This argument is optional.
# 
# Dependencies:
# * core.shl::printerr()
#*******************************************************************************

function init_table()
{
  local options
  if ! options=$(getopt -o c:,C:,g:,h:,m:,p:,P:,t:,T: -l color:,col:,column:,glyph:,heading:,min-width:,partition:,col-partition:,text-color:,col-text-color: -- "$@")
  then
    printerr -f "$FORMAT_FN" "$E_GETOPT"
    return 1
  fi

  eval set -- "$options"

  local col=0

  _TBL_TITLE=""
  _TBL_COLOR=""
  _TBL_GLYPH=""
  _TBL_HEADING=1
  _TBL_PARTITION=""
  _TBL_TEXTCOLOR=""
  _TBL_MINWIDTH=""

  _TBL_ROWS=()
  _TBL_ROWTEXTCOLORS=()
  _TBL_ROWLEN=0
  _TBL_ROWOFFSET=0

  _TBL_COLW=()
  _TBL_COLP=()
  _TBL_COLTC=()

  while true 
  do
    case "$1" in
      -c | --color )
        _TBL_COLOR=$2
        shift
        ;;
      -C | --col | --column )
        col=$2
        (( col-- ))
        shift
        ;;
      -g | --glyph )
        _TBL_GLYPH=$2
        shift
        ;;
      -h | --heading )
        _TBL_HEADING=$2
        shift
        ;;
      -m | --min-width )
        _TBL_MINWIDTH=$2
        shift
        ;;
      -p | --partition )
        _TBL_PARTITION=$2
        shift
        ;;
      -P | --col-partition )
        for (( i = 0; i <= $col; i++ ))
        do
          if (( $i < $col ))
          then
            _TBL_COLP[$i]=${_TBL_COLP[$i]:-""}
          else
            _TBL_COLP[$i]=$2
          fi
        done
        shift
        ;;
      -t | --text-color )
        _TBL_TEXTCOLOR=$2
        shift
        ;;
      -T | --col-text-color )
        for (( i = 0; i <= $col; i++ ))
        do
          if (( $i < $col ))
          then
            _TBL_COLTC[$i]=${_TBL_COLTC[$i]:-""}
          else
            _TBL_COLTC[$i]=$2
          fi
        done
        shift
        ;;
      -- )
        shift
        break
        ;;
      * )
        printerr -f "$FORMAT_FN" "$E_OPTPARSE $1"
        return 1
        ;;
    esac
    shift
  done

  _TBL_COLOR=${_TBL_COLOR:-$_DEFAULT_COLOR}
  _TBL_GLYPH=${_TBL_GLYPH:-$_DEFAULT_GLYPH}
  _TBL_PARTITION=${_TBL_PARTITION:-$_DEFAULT_PARTITION}

  if ! [[ $_TBL_HEADING =~ ^[[:digit:]]+$ ]]
  then
    _TBL_HEADING=1
  fi

  if ! [[ $_TBL_MINWIDTH =~ ^[[:digit:]]+$ ]]
  then
    _TBL_MINWIDTH=0
  fi

  _TBL_TITLE=$1

  return 0
}

#*******************************************************************************
# add_row()
# v1.0.0
# 
# Contributors:
# * Graham L. - Level 2 Support Technician - graham.l@hostdime.com
# 
# Description: Adds a new row to the table using the command line arguments as 
# field values. The first use of this function after init_table() has been ran 
# defines the number of columns for the table.
# 
# Options:
# -C, --col, --column INTEGER
#   Specifies the column for the -t, and --text-color options. Default value is 
#   1. Does nothing when not used in conjunction with either the -t, or 
#   --text-color option.
#
# -t, --text-color COLOR
#   Sets the text color the fields in the row. Set to $_DEFAULT_TEXTCOLOR if the 
#   option is not used. The value set by the -T, and --col-text-color option 
#   has higher precedence.
#
# -T, --col-text-color COLOR
#   Specifies a field's text color.This should be preceded by the -C, --col, or
#   --column options to set the column. The field affected is the field in the 
#   same column as specified by the -C, --col, or --column option. For example, 
#   using this option and setting the column to '3' will change the text color 
#   of the field in the 3rd column of this row only. The column specified 
#   greater than the number of columns printed, this option does nothing.
# 
# Arguments: The values of in each field of the row should be passed as command 
# line arguments. This uses positional parameters to get the field values, so 
# any value containing a space should be quoted. To specify a field as 
# intentionally blank, use empty quotes ('' or ""). If the number of fields is 
# less than the number of columns, the remaing columns will be blank in this 
# row. If the number of fields is greater than the number of columns, the row is 
# trunctated to include only the first N fields where N is number of columns.
# 
# Dependencies:
# * core.shl::printerr()
#*******************************************************************************

function add_row()
{
  local options
  if ! options=$(getopt -o C:,t:,T: -l col:,column:,text-color:,col-text-color: -- "$@")
  then
    printerr -f "$FORMAT_FN" "$E_GETOPT"
    return 1
  fi

  eval set -- "$options"

  local col=0
  local textcolor=""
  declare -a textcolors

  while true 
  do
    case "$1" in
      -C | --col | --column )
        col=$2
        (( col-- ))
        shift
        ;;
      -t | --text-color )
        textcolor="$2"
        shift
        ;;
      -T | --col-text-color )
        for (( i = 0; i <= $col; i++ ))
        do
          if (( $i < $col ))
          then
            textcolors[$i]=${textcolors[$i]:-""}
          else
            textcolors[$i]=$2
          fi
        done
        shift
        ;;
      -- )
        shift
        break
        ;;
      * )
        printerr -f "$FORMAT_FN" "$E_OPTPARSE $1"
        return 1
        ;;
    esac
    shift
  done

  local row=("$@")

  if (( _TBL_ROWLEN == 0 ))
  then
    _TBL_ROWLEN=${#row[@]}
  fi

  for (( i = 0; i < _TBL_ROWLEN; i++ ))
  do
    row[$i]=$(sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" <<<"${row[$i]}") # Strip control sequences/enforce min row length
    textcolors[$i]=${textcolors[$i]:-$textcolor}
  done

  for (( i = 0; i < $_TBL_ROWLEN; i++ ))
  do
    _TBL_ROWS[(($_TBL_ROWOFFSET + $i))]=${row[$i]}
    _TBL_ROWTEXTCOLORS[(($_TBL_ROWOFFSET + $i))]=${_TBL_COLTC[$i]:-${textcolors[$i]:-$_TBL_TEXTCOLOR}}
    if (( ${_TBL_COLW[$i]:-0} < ${#row[$i]} ))
    then
      _TBL_COLW[$i]=${#row[$i]}
    fi
  done

  (( _TBL_ROWOFFSET += _TBL_ROWLEN ))

  return 0
}

#*******************************************************************************
# print_table()
# v1.0.1
# 
# Contributors:
# * Graham L. - Level 2 Support Technician - graham.l@hostdime.com
# 
# Description: Prints the table as defined by init_table(), and add_row().
# 
# Dependencies:
# * mkheader()
#*******************************************************************************

function print_table()
{
  declare -i width
  local minw=$(( (2**63) - 1 )) # 2^63 - 1 is the max integer value Bash 3.00+

  declare -i row_count
  local index=0

  local color
  local crs=$_RESET # color reset
  local trs=$_RESET # text color reset

  for (( i = 0; i < $_TBL_ROWLEN; i++ ))
  do
    (( minw > ${_TBL_COLW[$i]} ? (minw=${_TBL_COLW[$i]}) : (minw=minw) ))
    _TBL_COLP[$i]=${_TBL_COLP[$i]:-$_TBL_PARTITION}
    (( width += ${_TBL_COLW[$i]} + ${#_TBL_COLP[$i]} + 2 ))
  done

  (( width-- ))

  if (( width < _TBL_MINWIDTH ))
  then

    while (( width < _TBL_MINWIDTH ))
    do
      for (( i = 0; i < $_TBL_ROWLEN; i++ ))
      do
        if (( ${_TBL_COLW[$i]} == minw ))
        then
          _TBL_COLW[$i]=$(( ${_TBL_COLW[$i]} + 1 ))
        (( width++ ))
        fi


        if (( width >= _TBL_MINWIDTH ))
        then
          break
        fi
      done
      (( minw++ ))
    done
  fi

  (( row_count = _TBL_ROWOFFSET / _TBL_ROWLEN ))
  
  if is_not_empty "$_TBL_TITLE"
  then
    mkheader -w $width "$_TBL_TITLE" -g "$_TBL_GLYPH" -c "$_TBL_COLOR" -t "$_TBL_TEXTCOLOR"
  fi

  if [[ $_TBL_COLOR == "none" ]]
  then
    color=""
    crs=""
  else
    color=$_TBL_COLOR
  fi

  for (( i = 0; i < $row_count; i++ ))
  do
    printf " "
    for (( j = 0; j < $_TBL_ROWLEN; j++ ))
    do
      if is_empty "${#_TBL_ROWTEXTCOLLORS[$index]}" && is_empty "${_TBL_COLTC[$j]}"
      then
        trs=""
      else
        trs=$_RESET
      fi

      printf "%b%-*s%b" "${_TBL_ROWTEXTCOLORS[$index]:-$_TBL_TEXTCOLOR}" "${_TBL_COLW[$j]}" "${_TBL_ROWS[$index]}" "$trs"

      if (( j + 1 != _TBL_ROWLEN ))
      then
        printf " %b%s%b " "$color" "${_TBL_COLP[$j]}" "$crs"
      fi

      (( index++ ))
    done
    printf "\n"

    if (( i == (_TBL_HEADING - 1) ))
    then
      for (( k = 0; k < _TBL_ROWLEN; k++ ))
      do
        printf "%b%*s%b" "$color" "$(( ${_TBL_COLW[$k]} + 2 ))" "" "$crs" |\
          tr ' ' '-'
        if (( k + 1 != _TBL_ROWLEN ))
        then
          printf "%b%s%b" "$color" "${_TBL_COLP[$k]}" "$crs"
        fi
      done
      printf "\n"
    fi
  done
}

#*******************************************************************************
# mkheader()
# v1.0.0
# 
# Contributors:
# * Graham L. - Level 2 Support Technician - graham.l@hostdime.com
# 
# Description: Outputs a title padded by glyphs on either side so it is defined
# length with the title centered.
# 
# Options:
# -c, --color COLOR
#   Sets the color of the glyph used to the pad the title. Set to 
#   $_DEFAULT_COLOR if the option is not used.
#
# -g, --glyph CHARACTER
#   Controls the glyph character used in the padding. Must be exactly 1 
#   character. Set to $_DEFAULT_GLYPH if the option is not used.
#
# -t, --text-color COLOR
#   Sets the color of the title text. Set to $_DEFAULT_TEXTCOLOR if the option
#   is not used.
#
# -w, --width INTEGER
#   Sets the length of the header. Set to $_DEFAULT_WIDTH if the option is not 
#   used.
# 
# Arguments: An argument containing the title must be provided on the command
# line.
# 
# Dependencies:
# * core.shl::printerr()
# * mkpad()
#*******************************************************************************

function mkheader()
{
  local options
  if ! options=$(getopt -o c:,g:,t:,w: -l color:,glyph:,--text-color:,width: -- "$@")
  then
    printerr -f "$FORMAT_FN" "$E_GETOPT"
    return 1
  fi

  eval set -- "$options"

  local color_arg
  local glyph_arg
  local textcolor_arg
  local width_arg

  while true
  do
    case "$1" in
      -c | --color )
        color_arg=$2
        shift
        ;;
      -g | --glyph )
        glyph_arg=$2
        shift
        ;;
      -t | --text-color )
        textcolor_arg=$2
        shift
        ;;
      -w | --width )
        width_arg=$2
        shift
        ;;
      -- )
        shift
        break
        ;;
      * )
        printerr -f "$FORMAT_FN" "$E_OPTPARSE $1"
        return 1
        ;;
    esac
    shift
  done

  if is_empty "$1"
  then
    printerr -f "$FORMAT_FN" "Header title cannot be empty."
    return 1
  fi

  local color=${color_arg:-$_DEFAULT_COLOR}
  local glyph=${glyph_arg:-$_DEFAULT_GLYPH}
  local textcolor=${textcolor_arg:-$_DEFAULT_TEXTCOLOR}
  local width=${width_arg:-$_DEFAULT_WIDTH}
  local crs=$_RESET # color reset
  local trs=$_RESET # text color reset

  if [[ $color == "none" ]]
  then
    color=""
    crs=""
  fi
  if (( ${#glyph} != 1 ))
  then
    glyph=$_DEFAULT_GLYPH
  fi
  if is_empty "$textcolor"
  then
    trs=""
  fi
  if is_empty $width || ! [[ $width =~ ^[[:digit:]]+$ ]]
  then
    width=$_DEFAULT_WIDTH
  fi

  local header
  local title=" $1 "
  local title_leftpad
  local title_rightpad
  local title_len=${#title}
  local title_pad_len=$(( (width - title_len) / 2 ))

  title_leftpad=$(mkpad -g "$glyph" -w "$title_pad_len")
  title_rightpad=$title_leftpad

  if (( (width % 2) != (title_len % 2) ))
  then
    title_rightpad+="$glyph"
  fi

  printf "%b%s%b%b%s%b%b%s%b\n" "$color" "$title_leftpad" "$crs" "$textcolor" "$title" "$trs" "$color" "$title_rightpad" "$crs"

  return 0
}


#*******************************************************************************
# mkpad()
# v1.0.0
# 
# Contributors:
# * Graham L. - Level 2 Support Technician - graham.l@hostdime.com
# 
# Description: Creates a string of repeated 'glyphs' of arbitrary length.
# 
# Options:
# -g, --glyph CHARACTER
#   Controls the glyph character used in the padding. Must be exactly 1 
#   character. Set to $_DEFAULT_GLYPH if the option is not used.
#
# -w, --width INTEGER
#   Sets the length of the padding. Set to $_DEFAULT_WIDTH if the option is not 
#   used.
# 
# Dependencies:
# * core.shl::printerr()
#*******************************************************************************

function mkpad()
{
  local options

  if ! options=$(getopt -o g:,w: -l glyph:,width: -- "$@")
  then
    printerr -f "$FORMAT_FN" "$E_GETOPT"
    return 1
  fi

  eval set -- "$options"

  local glyph_arg
  local width_arg

  while true
  do
    case "$1" in
      -g | --glyph )
        glyph_arg=$2
        shift
        ;;
      -w | --width )
        width_arg=$2
        shift
        ;;
      -- )
        shift
        break
        ;;
      * )
        printerr -f "$FORMAT_FN" "$E_OPTPARSE $1"
        return 1
        ;;
    esac
    shift
  done

  local width=${width_arg:=$_DEFAULT_WIDTH}
  local glyph=${glyph_arg:=$_DEFAULT_GLYPH}

  printf "%*s" "$width" |\
    tr ' ' "$glyph"

  return 0
}
